//! MPU Core
//! Core of the 65c02 Micro processor.
//!
//! Both the Register bank and clock driven
const std = @import("std");
const ops = @import("ops.zig");
const Peripheral = @import("peripheral.zig");

/// Status register defition.
const StatusRegister = packed struct(u8) {
    carry: bool = false,
    zero: bool = false,
    interrupt: bool = false,
    decimal: bool = false,
    break_: bool = false,
    _: bool = false,
    overflow: bool = false,
    negative: bool = false,

    /// Update state of zero register
    pub inline fn update_zero(self: *StatusRegister, val: u8) void {
        self.zero = val == 0;
    }

    /// Update state of negative register.
    pub inline fn update_negative(self: *StatusRegister, val: u8) void {
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
    ac: u8 = 0, // Accumulator
    xr: u8 = 0, // X-Register
    yr: u8 = 0, // Y-Register
    sp: u8 = 0, // Stack pointer
    pc: u16 = 0, // Program counter
    sr: StatusRegister = StatusRegister{}, // Status register

    /// Reset the register state.
    fn reset(self: *Registers) void {
        self.ac = 0;
        self.xr = 0;
        self.yr = 0;
        self.sp = 0;
        self.pc = 0;
        self.sr = 0;
    }

    /// Add a relative offset to the program counter.
    pub inline fn pc_add_relative(self: *Registers, offset: u8) void {
        if ((offset & 0x80) == 0) {
            self.pc += offset;
        } else {
            self.pc -= offset & 0x7F;
        }
    }
};

test "add_relative with high bit unset is added" {
    var target = Registers{ .pc = 40 };
    target.pc_add_relative(2);

    try std.testing.expectEqual(@as(u16, 42), target.pc);
}

test "add_relative with high bit set is subtracted" {
    var target = Registers{ .pc = 40 };
    target.pc_add_relative(155);

    try std.testing.expectEqual(@as(u16, 13), target.pc);
}

pub const MicroOpError = error{
    /// Has not been implemented
    NotImplemented,
    /// Not implemented in current MCU mode
    ModeNotImplemented,
    /// Skip the next micro-op (used for operations that can take an extra
    /// to complete).
    SkipNext,
};
pub const MicroOp = fn (*MPU) MicroOpError!void;
pub const Operation = struct { len: usize, micro_ops: [6]*const MicroOp, syntax: []const u8 };

pub const MPU = struct {
    // Address bus
    data_bus: Peripheral,

    // Register bank and state variables
    registers: Registers = Registers{},
    addr: u16 = 0,
    data: u8 = 0,

    // Current operation
    op_code: u8 = 0,
    op_current: Operation = ops.RESET_OPERATION,
    op_idx: usize = 0,

    // Statistics
    executed_ops: u64 = 0,
    executed_micro_ops: u64 = 0,

    /// Trigger a reset
    pub fn reset(self: *MPU) void {
        self.registers.reset();
        self.op_code = 0;
        self.op_current = ops.RESET_OPERATION;
        self.op_idx = 0;
        self.addr = 0;
        self.data = 0;
    }

    /// Clock tick (advance to the next micro-operation)
    pub fn clock(self: *MPU, edge: bool) void {
        if (edge) {
            self.data_bus.clock(edge) catch {};

            if (self.op_current.len == self.op_idx) {
                self.executed_ops +%= 1;
                self.decode_next_op();
            } else {
                self.executed_micro_ops +%= 1;

                const micro_op = self.op_current.micro_ops[self.op_idx];
                micro_op(self) catch |err| switch (err) {
                    MicroOpError.ModeNotImplemented => std.debug.print(
                        "{s} micro-op {d} mode not implemented",
                        .{ self.op_current.syntax, self.op_idx },
                    ),
                    MicroOpError.NotImplemented => std.debug.print(
                        "{s} micro-op {d} not implemented",
                        .{ self.op_current.syntax, self.op_idx },
                    ),
                    MicroOpError.SkipNext => return,
                };
                self.op_idx += 1;
            }
        }
    }

    /// Decode the next operation
    fn decode_next_op(self: *MPU) void {
        self.op_idx = 0;
        // if (self._nmi) {
        //     self._nmi = false;
        //     self.op_code = 0;
        //     self.op_current = ops.NMI_OPERATION;
        // } else if (self._irq) {
        //     self._irq = false;
        //     self.op_code = 0;
        //     self.op_current = ops.IRQ_OPERATION;
        // } else {
        self.read_pc();
        self.op_code = self.data;
        self.op_current = ops.OPERATIONS[self.op_code];
        // }
    }

    /// Read value from _addr into _data
    pub fn read(self: *MPU, addr: u16) void {
        self.data = self.data_bus.read(addr) catch 0;
    }

    /// Read next value from program counter and increment
    pub fn read_pc(self: *MPU) void {
        self.data = self.data_bus.read(self.registers.pc) catch 0;
        self.registers.pc += 1;
    }

    /// Write value from _data to _addr
    pub fn write(self: *MPU, addr: u16) void {
        self.data_bus.write(addr, self.data) catch {};
    }
};
