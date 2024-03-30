// Comparison micro-ops

const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

fn _cmp(register: u8, operand: u8, mpu: *MPU) void {
    mpu.registers.sr.zero = register == operand;
    mpu.registers.sr.carry = register >= operand;
    mpu.registers.sr.update_negative(register -% operand);
}

pub fn cmp(mpu: *MPU) MicroOpError!void {
    _cmp(mpu.registers.ac, mpu.data, mpu);
}

pub fn cmp_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    _cmp(mpu.registers.ac, mpu.data, mpu);
}

pub fn cpx(mpu: *MPU) MicroOpError!void {
    _cmp(mpu.registers.xr, mpu.data, mpu);
}

pub fn cpx_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    _cmp(mpu.registers.xr, mpu.data, mpu);
}

pub fn cpy(mpu: *MPU) MicroOpError!void {
    _cmp(mpu.registers.yr, mpu.data, mpu);
}

pub fn cpy_immediate(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    _cmp(mpu.registers.yr, mpu.data, mpu);
}
