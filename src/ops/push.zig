const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

pub fn push_ac(mpu: *MPU) MicroOpError!void {
    mpu.data = mpu.registers.ac;
    mpu.push_stack();
}

pub fn push_pc_l(mpu: *MPU) MicroOpError!void {
    mpu.data = @truncate(mpu.registers.pc);
    mpu.push_stack();
}

pub fn push_pc_h(mpu: *MPU) MicroOpError!void {
    mpu.data = @truncate(mpu.registers.pc >> 8);
    mpu.push_stack();
}

pub fn push_sr(_: *MPU) MicroOpError!void {
    // TODO: handle status register
    return MicroOpError.NotImplemented;
}
