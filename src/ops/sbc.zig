const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// Subtract memory from accumulator with carry.
pub fn sbc(mpu: *MPU) MicroOpError!void {
    var value = @as(u16, ~mpu.registers.ac) + @as(u16, mpu.data);

    if (!mpu.registers.sr.carry) {
        value += 1;
    }
    mpu.registers.ac = @intCast(~value);
    mpu.registers.sr.carry = (value <= 0xFF);
    mpu.registers.sr.update_zero(mpu.registers.ac);
    mpu.registers.sr.update_negative(mpu.registers.ac);
}

pub fn sbc_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    try sbc(mpu);
}

test "given ac = 10 and data 3 ac is updated to 7" {
    var mpu = @import("_mocks.zig").mock_mpu(
        10,
        .{
            .ac = 7,
            .sr = .{ .carry = true },
            },
    );

    try sbc(&mpu);

    try std.testing.expectEqual(7, mpu.registers.ac);
    try std.testing.expect(mpu.registers.sr.carry);
}

test "given ac = 7 and data 10 ac is updated to 252 and the carry flag set" {
    var mpu = @import("_mocks.zig").mock_mpu(
        10,
        .{
            .ac = 7,
            .sr = .{ .carry = true },
        },
    );

    try sbc(&mpu);

    try std.testing.expectEqual(252, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.carry);
}
