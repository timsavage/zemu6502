//! Branching micro-micro-ops
const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// Add a relative offset to the program counter.
pub inline fn jump_relative(mpu: *MPU) void {
    const offset = mpu.data;

    if ((offset & 0x80) == 0) {
        mpu.registers.pc +%= offset;
    } else {
        // Twos complement.
        mpu.registers.pc -%= (~offset + 1);
    }
}

test "jump_relative for positive jumps" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        0x02,
        .{
            .pc = 0x8000,
        },
    );
    defer mpu.data_bus.deinit();

    jump_relative(&mpu);

    try std.testing.expectEqual(0x8002, mpu.registers.pc);
}

test "jump_relative for negative jumps" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        0xEE,
        .{
            .pc = 0x8000,
        },
    );
    defer mpu.data_bus.deinit();

    jump_relative(&mpu);

    try std.testing.expectEqual(0x7FEE, mpu.registers.pc);
}

/// If the carry flag is set jump to value in data
pub fn bcs(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (mpu.registers.sr.carry) {
        jump_relative(mpu);
    } else {
        return MicroOpError.SkipNext;
    }
}

/// If the carry flag is clear jump to value in data
pub fn bcc(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (!mpu.registers.sr.carry) {
        jump_relative(mpu);
    } else {
        return MicroOpError.SkipNext;
    }
}

/// If the zero flag is set jump to value in data
pub fn beq(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (mpu.registers.sr.zero) {
        jump_relative(mpu);
    } else {
        return MicroOpError.SkipNext;
    }
}

/// If the zero flag is clear jump to value in data
pub fn bne(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (!mpu.registers.sr.zero) {
        jump_relative(mpu);
    } else {
        return MicroOpError.SkipNext;
    }
}

/// If the negative flag is set jump to value in data
pub fn bmi(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (mpu.registers.sr.negative) {
        jump_relative(mpu);
    } else {
        return MicroOpError.SkipNext;
    }
}

/// If the negative flag is clear jump to value in data
pub fn bpl(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (!mpu.registers.sr.negative) {
        jump_relative(mpu);
    } else {
        return MicroOpError.SkipNext;
    }
}

/// If the overflow flag is set jump to value in data
pub fn bvs(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (mpu.registers.sr.overflow) {
        jump_relative(mpu);
    } else {
        return MicroOpError.SkipNext;
    }
}

/// If the overflow flag is clear jump to value in data
pub fn bvc(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (!mpu.registers.sr.overflow) {
        jump_relative(mpu);
    } else {
        return MicroOpError.SkipNext;
    }
}
