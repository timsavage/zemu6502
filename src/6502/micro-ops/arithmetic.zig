//! Addition micro-micro-ops

const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// Add memory to accumulator with carry
pub fn adc(mpu: *MPU) MicroOpError!void {
    if (mpu.registers.sr.decimal) return MicroOpError.ModeNotImplemented;

    var value: u16 = @as(u16, mpu.data) + mpu.registers.ac;
    if (mpu.registers.sr.carry) {
        value += 1;
    }

    mpu.registers.sr.carry = value > 0xFF;
    mpu.registers.ac = @truncate(value);
    mpu.registers.sr.update_zero(mpu.registers.ac);
    mpu.registers.sr.update_negative(mpu.registers.ac);
}

pub fn adc_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    try adc(mpu);
}

test "ac is added to data" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        2,
        .{
            .ac = 3,
            .sr = .{ .carry = false }, // Typically cleared before this op.
        },
    );
    defer mpu.data_bus.deinit();

    try adc(&mpu);

    try std.testing.expectEqual(5, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}

test "ac is added to data with overflow" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        250,
        .{
            .ac = 8,
            .sr = .{ .carry = false }, // Typically cleared before this op.
        },
    );
    defer mpu.data_bus.deinit();

    try adc(&mpu);

    try std.testing.expectEqual(2, mpu.registers.ac);
    try std.testing.expect(mpu.registers.sr.carry);
}

test "ac is added to data when carry is set" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        3,
        .{
            .ac = 7,
            .sr = .{ .carry = true },
        },
    );
    defer mpu.data_bus.deinit();

    try adc(&mpu);

    try std.testing.expectEqual(11, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
}

test "ac is added to data when carry is set at extremes" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        250,
        .{
            .ac = 5,
            .sr = .{ .carry = true },
        },
    );
    defer mpu.data_bus.deinit();

    try adc(&mpu);

    try std.testing.expectEqual(0, mpu.registers.ac);
    try std.testing.expect(mpu.registers.sr.carry);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(mpu.registers.sr.zero);
}

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
    var mpu = try @import("_mocks.zig").mock_mpu(
        8,
        .{
            .ac = 15,
            .sr = .{ .carry = true }, // Typically set before this op.
        },
    );
    defer mpu.data_bus.deinit();

    try sbc(&mpu);

    try std.testing.expectEqual(7, mpu.registers.ac);
    try std.testing.expect(mpu.registers.sr.carry);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}

test "data is subtracted from ac with overflow" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        15,
        .{
            .ac = 3,
            .sr = .{ .carry = true }, // Typically set before this op.
        },
    );
    defer mpu.data_bus.deinit();

    try sbc(&mpu);

    try std.testing.expectEqual(244, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
    try std.testing.expect(mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}

test "data is subtracted from ac where carry is clear" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        15,
        .{
            .ac = 3,
            .sr = .{ .carry = false },
        },
    );
    defer mpu.data_bus.deinit();

    try sbc(&mpu);

    try std.testing.expectEqual(243, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
}

test "data is subtracted from ac at extremes" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        5,
        .{
            .ac = 5,
            .sr = .{ .carry = false },
        },
    );
    defer mpu.data_bus.deinit();

    try sbc(&mpu);

    try std.testing.expectEqual(255, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
}
