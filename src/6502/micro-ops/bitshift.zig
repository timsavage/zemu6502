//! Bitshift micro-micro-ops

const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// Arithmetic shift left (shifts in a zero bit on the right)
pub fn asl(mpu: *MPU) MicroOpError!void {
    mpu.registers.ac = mpu.data << 1;

    mpu.registers.sr.carry = (mpu.data & 0x80) > 0;
    mpu.registers.sr.update_negative(mpu.registers.ac);
    mpu.registers.sr.update_zero(mpu.registers.ac);
}

pub fn asl_immediate(mpu: *MPU) MicroOpError!void {
    mpu.data = mpu.registers.ac;
    return asl(mpu);
}

test "asl where result is non zero" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        0b0101_0101,
        .{},
    );
    defer mpu.data_bus.deinit();

    try asl(&mpu);

    try std.testing.expectEqual(0b1010_1010, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
    try std.testing.expect(mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}

test "asl where result is zero" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        0b1000_0000,
        .{},
    );
    defer mpu.data_bus.deinit();

    try asl(&mpu);

    try std.testing.expectEqual(0b0000_0000, mpu.registers.ac);
    try std.testing.expect(mpu.registers.sr.carry);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(mpu.registers.sr.zero);
}

/// Shift data 1 bit right
pub fn lsr(mpu: *MPU) MicroOpError!void {
    mpu.registers.ac = mpu.data >> 1;

    mpu.registers.sr.carry = (mpu.data & 0x01) > 0;
    mpu.registers.sr.negative = false;
    mpu.registers.sr.update_zero(mpu.registers.ac);
}

pub fn lsr_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    return lsr(mpu);
}

test "lsr where result is non-zero" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        0b1010_1010,
        .{
            .sr = .{ .zero = true },
        },
    );
    defer mpu.data_bus.deinit();

    try lsr(&mpu);

    try std.testing.expectEqual(0b0101_0101, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}

test "lsr where result is zero" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        0b0000_0001,
        .{},
    );
    defer mpu.data_bus.deinit();

    try lsr(&mpu);

    try std.testing.expectEqual(0b0000_0000, mpu.registers.ac);
    try std.testing.expect(mpu.registers.sr.carry);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(mpu.registers.sr.zero);
}

/// Rotate left (shifts in carry bit on the right)
pub fn rol(mpu: *MPU) MicroOpError!void {
    const carry = (mpu.data & 0x80) >> 7;

    mpu.registers.ac = (mpu.data << 1) | carry;

    mpu.registers.sr.carry = carry > 0;
    mpu.registers.sr.update_negative(mpu.registers.ac);
    mpu.registers.sr.update_zero(mpu.registers.ac);
}

pub fn rol_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    return rol(mpu);
}

test "rol" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        0b1010_0000,
        .{},
    );
    defer mpu.data_bus.deinit();

    try rol(&mpu);

    try std.testing.expectEqual(0b0100_0001, mpu.registers.ac);
    try std.testing.expect(mpu.registers.sr.carry);
    try std.testing.expect(!mpu.registers.sr.zero);
    try std.testing.expect(!mpu.registers.sr.negative);
}

/// Rotate right (shifts in zero bit on the left)
pub fn ror(mpu: *MPU) MicroOpError!void {
    const carry = (mpu.data & 0x01) << 7;

    mpu.registers.ac = (mpu.data >> 1) | carry;

    mpu.registers.sr.carry = carry > 0;
    mpu.registers.sr.update_negative(mpu.registers.ac);
    mpu.registers.sr.update_zero(mpu.registers.ac);
}

pub fn ror_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    return ror(mpu);
}

test "ror" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        0b0000_0101,
        .{},
    );
    defer mpu.data_bus.deinit();

    try ror(&mpu);

    try std.testing.expectEqual(0b1000_0010, mpu.registers.ac);
    try std.testing.expect(mpu.registers.sr.carry);
    try std.testing.expect(!mpu.registers.sr.zero);
    try std.testing.expect(mpu.registers.sr.negative);
}
