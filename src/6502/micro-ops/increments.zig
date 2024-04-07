//! Decrement and Increment operations

const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// Decrement data
pub fn dec(_: *MPU) MicroOpError!void {
    return MicroOpError.NotImplemented;
}

/// Decrement x-index
pub fn dex(mpu: *MPU) MicroOpError!void {
    mpu.registers.xr -= 1;
    mpu.registers.sr.update_zero(mpu.registers.xr);
    mpu.registers.sr.update_negative(mpu.registers.xr);
}

/// Decrement y-index
pub fn dey(mpu: *MPU) MicroOpError!void {
    mpu.registers.yr -= 1;
    mpu.registers.sr.update_zero(mpu.registers.yr);
    mpu.registers.sr.update_negative(mpu.registers.yr);
}

/// Increment data
pub fn inc(_: *MPU) MicroOpError!void {
    return MicroOpError.NotImplemented;
}

/// Increment x-index
pub fn inx(mpu: *MPU) MicroOpError!void {
    mpu.registers.xr +%= 1;

    mpu.registers.sr.update_negative(mpu.registers.xr);
    mpu.registers.sr.update_zero(mpu.registers.xr);
}

/// Increment y-index
pub fn iny(mpu: *MPU) MicroOpError!void {
    mpu.registers.yr +%= 1;

    mpu.registers.sr.update_negative(mpu.registers.yr);
    mpu.registers.sr.update_zero(mpu.registers.yr);
}
