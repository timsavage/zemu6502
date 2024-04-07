//! Transfers between registers

const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// Copy accumulator to x-register
pub fn ac_to_xr(mpu: *MPU) MicroOpError!void {
    mpu.registers.xr = mpu.registers.ac;
}

/// Copy accumulator to y-register
pub fn ac_to_yr(mpu: *MPU) MicroOpError!void {
    mpu.registers.yr = mpu.registers.ac;
}

/// Copy stack-pointer to x-register
pub fn sp_to_xr(mpu: *MPU) MicroOpError!void {
    mpu.registers.xr = mpu.registers.sp;
}

/// Copy x-register to accumulator
pub fn xr_to_ac(mpu: *MPU) MicroOpError!void {
    mpu.registers.ac = mpu.registers.xr;
}

/// Copy x-register to stack-pointer
pub fn xr_to_sp(mpu: *MPU) MicroOpError!void {
    mpu.registers.sp = mpu.registers.xr;
}

/// Copy y-register to accumulator
pub fn yr_to_ac(mpu: *MPU) MicroOpError!void {
    mpu.registers.ac = mpu.registers.yr;
}
