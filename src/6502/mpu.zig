//! MPU Core
//! Core of the 65c02 Micro processor.
//!
//! Both the Register bank and clock driven
const std = @import("std");
const ops = @import("instructions.zig");
const DataBus = @import("../data-bus.zig");
const Peripheral = @import("../peripheral.zig");

/// Status register defition.
pub const StatusRegister = packed struct(u8) {
    const Self = @This();

    carry: bool = false,
    zero: bool = false,
    interrupt: bool = false,
    decimal: bool = false,
    break_: bool = false,
    _: bool = false,
    overflow: bool = false,
    negative: bool = false,

    /// Update state of zero register
    pub inline fn update_zero(self: *Self, val: u8) void {
        self.zero = val == 0;
    }

    /// Update state of negative register.
    pub inline fn update_negative(self: *Self, val: u8) void {
        self.negative = (val & 0x80) != 0;
    }

    /// Output the status of the status register to log
    pub fn toLog(self: *Self) void {
        const carry: u8 = if (self.carry) 'C' else 'c';
        const zero: u8 = if (self.zero) 'Z' else 'z';
        const interrupt: u8 = if (self.interrupt) 'I' else 'i';
        const decimal: u8 = if (self.decimal) 'D' else 'd';
        const break_: u8 = if (self.break_) 'B' else 'b';
        const overflow: u8 = if (self.overflow) 'O' else 'o';
        const negative: u8 = if (self.negative) 'N' else 'n';

        std.log.info(
            "Status Register: {c}{c}{c}{c}{c}{c}{c}",
            .{ carry, zero, interrupt, decimal, break_, overflow, negative },
        );
    }
};

test "update_negative with high bit set" {
    var target = StatusRegister{};

    target.update_negative(155);

    try std.testing.expect(target.negative);
}
test "update_negative with high bit clear" {
    var target = StatusRegister{};

    target.update_negative(42);

    try std.testing.expect(!target.negative);
}

/// Register bank
pub const Registers = struct {
    const Self = @This();

    ac: u8 = 0, // Accumulator
    xr: u8 = 0, // X-Register
    yr: u8 = 0, // Y-Register
    sp: u8 = 0xFF, // Stack pointer
    pc: u16 = 0, // Program counter
    sr: StatusRegister = .{}, // Status register

    /// Reset the register state.
    fn reset(self: *Self) void {
        self.ac = 0;
        self.xr = 0;
        self.yr = 0;
        self.sp = 0xFF;
        self.pc = 0;
        self.sr = .{};
    }

    /// Output the status of the status register to log
    pub fn toLog(self: *Self) void {
        std.log.info(
            "Registers - AC: {0d} (0x{0X:0>2}); XR: {1d}; YR: {2d}; SP: 0x{3X:0>2}; PC: 0x{4X:0>4}",
            .{ self.ac, self.xr, self.yr, self.sp, self.pc },
        );
        self.sr.toLog();
    }
};

pub const MicroOpError = error{
    /// Has not been implemented
    NotImplemented,
    /// Not implemented in current MCU mode
    ModeNotImplemented,
    /// Skip the next micro-op (used for operations that can take an extra
    /// to complete).
    SkipNext,
    /// Stock overflow (Move stack pointer beyond 0x00)
    StackOverflow,
    /// Stock underflow (Move stack pointer over 0xFF)
    StackUnderflow,
};
pub const MicroOp = fn (*MPU) MicroOpError!void;
pub const Instruction = struct {
    size: u8 = 0, // Size of the instruction (number of bytes)
    len: usize, // Length of instruction (max number of clock cycles)
    micro_ops: [6]*const MicroOp, // Ops that make up an Instruction
    syntax: []const u8, // Syntax used to represent the instruction.
};

pub const RunMode = enum {
    Run,
    Halt,
    RunInstruction,
};

pub const MPU = struct {
    const Self = @This();

    mode: RunMode = RunMode.Run,

    // Address bus
    data_bus: *DataBus,

    // Register bank and state variables
    registers: Registers = .{},
    addr: u16 = 0,
    data: u8 = 0,
    interrupt: bool = false,

    // Current instruction
    current: Instruction = ops.RESET_OPERATION,
    current_loc: u16 = ops.RESET_VECTOR_L,
    op_idx: usize = 0,

    // Statistics
    executed_ops: u64 = 0,
    executed_micro_ops: u64 = 0,

    pub fn init(data_bus: *DataBus) Self {
        return .{
            .data_bus = data_bus,
        };
    }

    /// Trigger a reset
    pub fn reset(self: *Self) void {
        self.registers.reset();
        self.current = ops.RESET_OPERATION;
        self.current_loc = ops.RESET_VECTOR_L;
        self.interrupt = false;
        self.op_idx = 0;
        self.addr = 0;
        self.data = 0;
    }

    /// Halt at the next instruction.
    pub fn halt(self: *Self) void {
        if (self.mode == RunMode.Run) {
            std.log.info("Halt...", .{});
            self.mode = RunMode.RunInstruction;
        }
    }

    /// Run the next instruction.
    pub fn step(self: *Self) void {
        if (self.mode == RunMode.Halt) {
            self.mode = RunMode.RunInstruction;
        } else {
            std.log.warn("Cannot step outside the halt state.", .{});
        }
    }

    /// Run the next instruction.
    pub fn run(self: *Self) void {
        if (self.mode != RunMode.Run) {
            std.log.info("Run!", .{});
            self.mode = RunMode.Run;
        }
    }

    /// Clock tick (advance to the next micro-operation)
    pub fn clock(self: *Self, edge: bool) void {
        self.data_bus.clock(edge);
        if (edge) {
            if (self.current.len <= self.op_idx) {
                self.executed_ops +%= 1;
                self.decode_next_op();

                if (self.mode != RunMode.Run) {
                    self.mode = RunMode.Halt;
                    std.log.info("> [{X:0>2}] {s}", .{ self.current_loc, self.current.syntax });
                }
            } else if (self.mode != RunMode.Halt) {
                self.executed_micro_ops +%= 1;
                self.execute_next_micro_op();
            }
        }
    }

    /// Decode the next operation
    fn decode_next_op(self: *Self) void {
        self.op_idx = 0;
        if (!self.interrupt and self.data_bus.nmi()) {
            self.interrupt = true;
            self.current_loc = ops.NMI_VECTOR_L;
            self.current = ops.NMI_OPERATION;
        } else if (!self.interrupt and !self.registers.sr.interrupt and self.data_bus.irq()) {
            self.interrupt = true;
            self.current_loc = ops.IRQ_VECTOR_L;
            self.current = ops.IRQ_OPERATION;
        } else {
            self.current_loc = self.registers.pc;
            self.read_pc();
            self.current = ops.OPERATIONS[self.data];
        }
    }

    fn execute_next_micro_op(self: *Self) void {
        const micro_op = self.current.micro_ops[self.op_idx];
        micro_op(self) catch |err| switch (err) {
            MicroOpError.ModeNotImplemented => std.log.warn(
                "{s} micro-op {d} mode not implemented",
                .{ self.current.syntax, self.op_idx },
            ),
            MicroOpError.NotImplemented => std.log.warn(
                "{s} micro-op {d} not implemented",
                .{ self.current.syntax, self.op_idx },
            ),
            MicroOpError.SkipNext => self.op_idx += 1,
            MicroOpError.StackOverflow => std.log.err("Stack overflow!", .{}),
            MicroOpError.StackUnderflow => std.log.err("Stack underflow!", .{}),
        };
        self.op_idx += 1;
    }

    /// Read value from addr into self.data
    pub inline fn read(self: *Self, addr: u16) void {
        self.data = self.data_bus.read(addr);
    }

    /// Read next value from program counter and increment
    pub fn read_pc(self: *Self) void {
        defer self.registers.pc += 1;
        self.data = self.data_bus.read(self.registers.pc);
    }

    /// Write value from self.data to specified addr
    pub inline fn write(self: *Self, addr: u16) void {
        self.data_bus.write(addr, self.data);
    }

    /// Write value from self.data to stack location and move pointer.
    pub fn push_stack(self: *Self) MicroOpError!void {
        const addr = 0x0100 + @as(u16, self.registers.sp);
        if (self.registers.sp == 0x00) {
            return MicroOpError.StackOverflow;
        }
        self.registers.sp -= 1;
        self.write(addr);
    }

    /// Read value into self.data from stack location and move pointer.
    pub fn pop_stack(self: *Self) MicroOpError!void {
        if (self.registers.sp == 0xFF) {
            return MicroOpError.StackUnderflow;
        }
        self.registers.sp += 1;
        const addr = 0x0100 + @as(u16, self.registers.sp);
        self.read(addr);
    }
};
