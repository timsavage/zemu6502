const std = @import("std");
const ops = @import("ops.zig");

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
    inline fn update_zero(self: *StatusRegister, val: u8) void {
        self.zero = val == 0;
    }

    /// Update state of negative register.
    inline fn update_negative(self: *StatusRegister, val: u8) void {
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
    fn pc_add_relative(self: *Registers, offset: u8) void {
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

pub const MicroOp = fn (*MPU) void;
pub const Operation = struct { len: usize, micro_ops: [6]*const MicroOp, syntax: []const u8 };

pub const MPU = struct {
    // Register bank
    registers: Registers = Registers{},

    // Current operation
    op_code: u8 = 0,
    op_current: Operation = ops.RESET_OPERATION,
    op_idx: usize = 0,

    // Bus values
    _addr: u16 = 0,
    _data: u8 = 0,

    // Non-Maskable Interrupt has been triggered
    _nmi: bool = false,
    // Interrupt has been triggered
    _irq: bool = false,

    /// Trigger a reset
    pub fn reset(self: *MPU) void {
        self.registers.reset();
        self.op_code = 0;
        self.op_current = ops.RESET_OPERATION;
        self.op_idx = 0;
        self._addr = 0;
        self._data = 0;
        self._irq = false;
        self._nmi = false;
    }

    /// Clock tick (advance to the next micro-operation)
    pub fn clock_tick(self: *MPU) void {
        if (self.op_current.len == self.op_idx) {
            self.op_idx = 0;

            if (self._nmi) {
                self._nmi = false;
                self.op_code = 0;
                self.op_current = ops.NMI_OPERATION;
            } else if (self._irq) {
                self._irq = false;
                self.op_code = 0;
                self.op_current = ops.IRQ_OPERATION;
            } else {
                self.decode_next_op_code();
            }
        } else {
            const micro_op = self.op_current.micro_ops[self.op_idx];
            micro_op(self);
            self.op_idx += 1;
        }
    }

    /// Decode the next operation
    fn decode_next_op_code(self: *MPU) void {
        self.read_pc();
        self.op_code = self._data;
        self.op_current = ops.RESET_OPERATION; // OPERATIONS[self.op_code];
    }

    /// Read value from _addr into _data
    fn read(self: *MPU) void {
        self._data = 42; // self.address_bus.read(self._addr);
    }

    /// Read next value from program counter and increment
    fn read_pc(self: *MPU) void {
        self._data = 42; // self.address_bus.read(self.registers.pc);
        self.registers.pc += 1;
    }

    /// Write value from _data to _addr
    fn write(_: *MPU) void {
        // self.address_bus.write(self._addr, self._data);
    }
};
