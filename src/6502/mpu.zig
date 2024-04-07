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

pub const MPU = struct {
    const Self = @This();

    // Address bus
    data_bus: *DataBus,

    // Register bank and state variables
    registers: Registers = .{},
    addr: u16 = 0,
    data: u8 = 0,

    // Current operation
    op_code: u8 = 0,
    op_current: Instruction = ops.RESET_OPERATION,
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
        self.op_code = 0;
        self.op_current = ops.RESET_OPERATION;
        self.op_idx = 0;
        self.addr = 0;
        self.data = 0;
    }

    /// Clock tick (advance to the next micro-operation)
    pub fn clock(self: *Self, edge: bool) void {
        if (edge) {
            self.data_bus.clock(edge);

            if (self.op_current.len <= self.op_idx) {
                self.executed_ops +%= 1;
                self.decode_next_op();
            } else {
                self.executed_micro_ops +%= 1;
                self.execute_next_micro_op();
            }
        }
    }

    /// Decode the next operation
    fn decode_next_op(self: *Self) void {
        self.op_idx = 0;
        if (self.data_bus.nmi()) {
            self.op_code = 0;
            self.op_current = ops.NMI_OPERATION;
        } else if (!self.registers.sr.interrupt and self.data_bus.irq()) {
            self.op_code = 0;
            self.op_current = ops.IRQ_OPERATION;
        } else {
            self.read_pc();
            self.op_code = self.data;
            self.op_current = ops.OPERATIONS[self.op_code];
        }
    }

    fn execute_next_micro_op(self: *Self) void {
        const micro_op = self.op_current.micro_ops[self.op_idx];
        micro_op(self) catch |err| switch (err) {
            MicroOpError.ModeNotImplemented => std.log.warn(
                "{s} micro-op {d} mode not implemented",
                .{ self.op_current.syntax, self.op_idx },
            ),
            MicroOpError.NotImplemented => std.log.warn(
                "{s} micro-op {d} not implemented",
                .{ self.op_current.syntax, self.op_idx },
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
        self.data = self.data_bus.read(self.registers.pc);
        self.registers.pc += 1;
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
