//! Instructions for modifying the status register

const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// Set carry flag in status register
pub fn sec(mpu: *MPU) MicroOpError!void {
    mpu.registers.sr.carry = true;
}

/// Clear carry flag in status register
pub fn clc(mpu: *MPU) MicroOpError!void {
    mpu.registers.sr.carry = false;
}

/// Set decimal mode flag in status register
pub fn sed(mpu: *MPU) MicroOpError!void {
    mpu.registers.sr.decimal = true;
}

/// Clear decimal mode flag in status register
pub fn cld(mpu: *MPU) MicroOpError!void {
    mpu.registers.sr.decimal = false;
}

/// Set interrupt disable flag in status register
pub fn sei(mpu: *MPU) MicroOpError!void {
    mpu.registers.sr.interrupt = true;
}

/// Clear interrupt disable flag in status register
pub fn cli(mpu: *MPU) MicroOpError!void {
    mpu.registers.sr.interrupt = false;
}

/// Clear overflow flag in status register
pub fn clv(mpu: *MPU) MicroOpError!void {
    mpu.registers.sr.overflow = false;
}
