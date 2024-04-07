//! Stack micro-micro-ops

const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const StatusRegister = @import("../mpu.zig").StatusRegister;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// Push accumulator to the stack
pub fn push_ac(mpu: *MPU) MicroOpError!void {
    mpu.data = mpu.registers.ac;
    try mpu.push_stack();
}

/// Pull accumulator from the stack
pub fn pull_ac(mpu: *MPU) MicroOpError!void {
    try mpu.pop_stack();
    mpu.registers.ac = mpu.data;
}

/// Push low byte of program counter to stack and replace addr
pub fn push_pc_l(mpu: *MPU) MicroOpError!void {
    mpu.data = @truncate(mpu.registers.pc);
    try mpu.push_stack();
}

/// Pull low byte of program counter from stack and merge with addr
pub fn pull_pc_l(mpu: *MPU) MicroOpError!void {
    try mpu.pop_stack();
    mpu.addr = mpu.data;
}

/// Push high byte of program counter to stack and replace addr
pub fn push_pc_h(mpu: *MPU) MicroOpError!void {
    mpu.data = @truncate(mpu.registers.pc >> 8);
    try mpu.push_stack();
}

/// Pull high byte of program counter from stack and merge with addr
pub fn pull_pc_h(mpu: *MPU) MicroOpError!void {
    try mpu.pop_stack();
    mpu.addr += @as(u16, mpu.data) << 8;
}

/// Push status register to the stack
pub fn push_sr(mpu: *MPU) MicroOpError!void {
    mpu.data = @bitCast(mpu.registers.sr);
    // TODO: handle bit masking
    try mpu.push_stack();
}

/// PUll status register from the stack
pub fn pull_sr(mpu: *MPU) MicroOpError!void {
    try mpu.pop_stack();
    // TODO: handle bit masking
    mpu.registers.sr = @bitCast(mpu.data);
}
