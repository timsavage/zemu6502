//! Branching micro-micro-ops
const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

/// If the carry flag is set jump to value in data
pub fn bcs(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (mpu.registers.sr.carry) {
        mpu.registers.pc_add_relative(mpu.data);
    }
}

/// If the carry flag is clear jump to value in data
pub fn bcc(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (!mpu.registers.sr.carry) {
        mpu.registers.pc_add_relative(mpu.data);
    }
}

/// If the zero flag is set jump to value in data
pub fn beq(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (mpu.registers.sr.zero) {
        mpu.registers.pc_add_relative(mpu.data);
    }
}

/// If the zero flag is clear jump to value in data
pub fn bne(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (!mpu.registers.sr.zero) {
        mpu.registers.pc_add_relative(mpu.data);
    }
}

/// If the negative flag is set jump to value in data
pub fn bmi(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (mpu.registers.sr.negative) {
        mpu.registers.pc_add_relative(mpu.data);
    }
}

/// If the negative flag is clear jump to value in data
pub fn bpl(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (!mpu.registers.sr.negative) {
        mpu.registers.pc_add_relative(mpu.data);
    }
}

/// If the overflow flag is set jump to value in data
pub fn bvs(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (mpu.registers.sr.overflow) {
        mpu.registers.pc_add_relative(mpu.data);
    }
}

/// If the overflow flag is clear jump to value in data
pub fn bvc(mpu: *MPU) MicroOpError!void {
    mpu.read_pc();
    if (!mpu.registers.sr.overflow) {
        mpu.registers.pc_add_relative(mpu.data);
    }
}
