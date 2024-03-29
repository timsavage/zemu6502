//! Peripheral interface for data-bus.
//!
//! Defines the various interactions between sub systems that make up a computer
//! system.

const std = @import("std");
const Peripheral = @This();

/// Errors from peripherals.
///
/// Errors are only reported, they do not impact the operation of the MPU, and
/// error will return a value of 0.
pub const PeripheralError = error{
    /// Caused a hardware failure reading data
    HardwareFailure,
    /// Address a value outside of possible range
    AddressIndex,
    /// Peripheral is read-only
    ReadOnly,
    /// Peripheral is write-only
    WriteOnly,
};

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    /// Clock tick.
    clock: ?*const fn (ctx: *anyopaque) PeripheralError!void,

    /// Read data from the supplied address.
    read: *const fn (ctx: *anyopaque, addr: u16) PeripheralError!u8,

    /// Write data to the supplied address.
    write: *const fn (ctx: *anyopaque, addr: u16, data: u8) PeripheralError!void,
};

/// Clock tick.
pub inline fn clock(self: Peripheral) PeripheralError!void {
    return if (self.vtable.clock) |value| value(self.ptr);
}

/// Read data from the supplied address.
pub inline fn read(self: Peripheral, addr: u16) PeripheralError!u8 {
    return self.vtable.read(self.ptr, addr);
}

/// Write data to the supplied address.
pub inline fn write(self: Peripheral, addr: u16, data: u8) PeripheralError!void {
    return self.vtable.write(self.ptr, addr, data);
}
