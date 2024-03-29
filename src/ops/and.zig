const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

pub fn and_(mpu: *MPU) MicroOpError!void {
    mpu.registers.ac &= mpu.data;

    mpu.registers.sr.update_negative(mpu.registers.ac);
    mpu.registers.sr.update_zero(mpu.registers.ac);
}

pub fn and_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    try and_(mpu);
}

test "ac and with data" {
    var mpu = @import("_mocks.zig").mock_mpu(
        56,
        .{
            .ac = 21,
        },
    );

    try and_(&mpu);

    try std.testing.expectEqual(16, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}
