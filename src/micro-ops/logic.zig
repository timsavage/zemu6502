//! Logic operations

const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// And operation with accumulator and data
pub fn and_(mpu: *MPU) MicroOpError!void {
    mpu.registers.ac &= mpu.data;

    mpu.registers.sr.update_negative(mpu.registers.ac);
    mpu.registers.sr.update_zero(mpu.registers.ac);
}

/// Read PC to data then perform and operation
pub fn and_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    try and_(mpu);
}

test "ac and with data" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        56,
        .{
            .ac = 21,
        },
    );
    defer mpu.data_bus.deinit();

    try and_(&mpu);

    try std.testing.expectEqual(16, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}

/// Or operation with accumulator and data
pub fn ora(mpu: *MPU) MicroOpError!void {
    mpu.registers.ac |= mpu.data;

    mpu.registers.sr.update_negative(mpu.registers.ac);
    mpu.registers.sr.update_zero(mpu.registers.ac);
}

/// Read PC to data then perform or operation
pub fn ora_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    try ora(mpu);
}

test "ac or with data" {
    var mpu = try @import("_mocks.zig").mock_mpu(
        56,
        .{
            .ac = 21,
        },
    );
    defer mpu.data_bus.deinit();

    try ora(&mpu);

    try std.testing.expectEqual(61, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}

/// Xor operation with accumulator and data
pub fn eor(mpu: *MPU) MicroOpError!void {
    mpu.registers.ac ^= mpu.data;

    mpu.registers.sr.update_negative(mpu.registers.ac);
    mpu.registers.sr.update_zero(mpu.registers.ac);
}

/// Read PC to data then perform xor operation
pub fn eor_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    try eor(mpu);
}
