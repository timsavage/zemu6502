//! Bitshift micro-micro-ops

const std = @import("std");
const MPU = @import("../mpu.zig").MPU;
const MicroOpError = @import("../mpu.zig").MicroOpError;

pub fn asl(_: *MPU) MicroOpError!void {
    return MicroOpError.NotImplemented;
}

pub fn asl_immediate(_: *MPU) MicroOpError!void {
    return MicroOpError.NotImplemented;
}

/// Shift data 1 bit right
pub fn lsr(mpu: *MPU) MicroOpError!void {
    mpu.data >>= 1;

    // TODO: Update status register
}

pub fn lsr_immediate(_: *MPU) MicroOpError!void {
    return MicroOpError.NotImplemented;
}

pub fn rol(_: *MPU) MicroOpError!void {
    return MicroOpError.NotImplemented;
}

pub fn rol_immediate(_: *MPU) MicroOpError!void {
    return MicroOpError.NotImplemented;
}

pub fn ror(_: *MPU) MicroOpError!void {
    return MicroOpError.NotImplemented;
}

pub fn ror_immediate(_: *MPU) MicroOpError!void {
    return MicroOpError.NotImplemented;
}
