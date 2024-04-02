const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// Subtract memory from accumulator with carry.
pub fn sbc(mpu: *MPU) MicroOpError!void {
    var value = @as(u16, ~mpu.registers.ac) + mpu.data;

    if (!mpu.registers.sr.carry) {
        value += 1;
    }
    mpu.registers.ac = @truncate(~value);
    mpu.registers.sr.carry = (value <= 0xFF);
    mpu.registers.sr.update_zero(mpu.registers.ac);
    mpu.registers.sr.update_negative(mpu.registers.ac);
}

pub fn sbc_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    try sbc(mpu);
}

test "data is subtracted from ac" {
    var mpu = @import("_mocks.zig").mock_mpu(
        8,
        .{
            .ac = 15,
            .sr = .{ .carry = true },  // Typically set before this op.
        },
    );

    try sbc(&mpu);

    try std.testing.expectEqual(7, mpu.registers.ac);
    try std.testing.expect(mpu.registers.sr.carry);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}

test "data is subtracted from ac with overflow" {
    var mpu = @import("_mocks.zig").mock_mpu(
        15,
        .{
            .ac = 3,
            .sr = .{ .carry = true },  // Typically set before this op.
        },
    );

    try sbc(&mpu);

    try std.testing.expectEqual(244, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
    try std.testing.expect(mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}

test "data is subtracted from ac where carry is clear" {
    var mpu = @import("_mocks.zig").mock_mpu(
        15,
        .{
            .ac = 3,
            .sr = .{ .carry = false },
        },
    );

    try sbc(&mpu);

    try std.testing.expectEqual(243, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
}

test "data is subtracted from ac at extremes" {
    var mpu = @import("_mocks.zig").mock_mpu(
        5,
        .{
            .ac = 5,
            .sr = .{ .carry = false },
        },
    );

    try sbc(&mpu);

    try std.testing.expectEqual(255, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
}
