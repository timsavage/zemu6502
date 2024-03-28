//! Hardware interfaces within the computer system.
//! Defines the various interactions between sub systems that make up a computer
//! system.

const std = @import("std");

/// Errors from peripherals.
///
/// Errors are only reported, they do not impact the operation of the MPU, and
/// error will return a value of 0.
pub const PeripheralError = error {
    /// Caused a hardware failure reading data
    HardwareFailure,
    /// Peripheral is read-only
    ReadOnly,
    /// Peripheral is write-only
    WriteOnly,
};

/// Peripheral interface.
pub const Peripheral = struct {
    /// Clock signal.
    clockFn: fn (*Peripheral) void!PeripheralError,

    /// Read a value from the peripheral.
    readFn: fn (*Peripheral, u16) u8!PeripheralError,
    /// Write a value to the peripheral.
    writeFn: fn (*Peripheral, u16, u16) void!PeripheralError,

    pub fn clock(iface: *Peripheral) void!PeripheralError {
        return iface.readFn(iface);
    }
};
