const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const StatusRegister = @import("../mpu.zig").StatusRegister;
const MicroOpError = @import("../mpu.zig").MicroOpError;

pub fn pull_ac(mpu: *MPU) MicroOpError!void {
    mpu.pop_stack();
    mpu.registers.ac = mpu.data;
}

pub fn pull_pc_l(mpu: *MPU) MicroOpError!void {
    mpu.pop_stack();
    mpu.addr = mpu.data;
}

pub fn pull_pc_h(mpu: *MPU) MicroOpError!void {
    mpu.pop_stack();
    mpu.addr += @as(u16, mpu.data) << 8;
}

pub fn pull_sr(mpu: *MPU) MicroOpError!void {
    // TODO: handle status register
    mpu.pop_stack();
    // mpu.registers.sr = @volatileCast(mpu.data);
}
