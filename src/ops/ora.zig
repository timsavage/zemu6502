const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// Read data at addr and or with accumulator
pub fn ora(mpu: *MPU) MicroOpError!void {
    mpu.registers.ac |= mpu.data;
}

/// Read data at pc and or with accumulator
pub fn ora_ac(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    mpu.registers.ac |= mpu.data;
}

test "ac or with data" {
    var mpu = @import("_mocks.zig").mock_mpu(
        56,
        .{
            .ac = 21,
        },
    );

    try ora(&mpu);

    try std.testing.expectEqual(61, mpu.registers.ac);
    try std.testing.expect(!mpu.registers.sr.negative);
    try std.testing.expect(!mpu.registers.sr.zero);
}
