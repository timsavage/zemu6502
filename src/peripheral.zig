//! Peripheral interface for data-bus.
//!
//! Defines the various interactions between sub systems that make up a computer
//! system.

const std = @import("std");
const Self = @This();

/// Errors from peripherals.
///
/// Errors are only reported, they do not impact the operation of the MPU, and
/// error will return a value of 0.
pub const PeripheralError = error{
    /// Hardware failure (simulated)
    HardwareFailure,
    /// Address is outside of address range.
    AddressIndex,
    /// Peripheral is read-only
    ReadOnly,
    /// Peripheral is write-only
    WriteOnly,
    /// Feature not supported by peripheral
    NotSupported,
};

ptr: *anyopaque,
vtable: *const VTable,

pub const VTable = struct {
    /// Name of the peripheral
    name: []const u8,

    /// Name of the peripheral
    description: []const u8,

    /// Clock tick(s).
    clock: ?*const fn (ctx: *anyopaque, edge: bool) PeripheralError!void = null,

    /// Read a value from a peripheral register.
    read: *const fn (ctx: *anyopaque, addr: u16) PeripheralError!u8,

    /// Write a value to a peripheral register.
    write: *const fn (ctx: *anyopaque, addr: u16, data: u8) PeripheralError!void,

    /// Load data into peripheral registers.
    load: ?*const fn (ctx: *anyopaque, data: []const u8) PeripheralError!void = null,

    /// Provide access to all registers for debug.
    registers: ?*const fn (ctx: *anyopaque) PeripheralError![]u8 = null,
};

/// Clock tick.
pub inline fn clock(self: Self, edge: bool) PeripheralError!void {
    return if (self.vtable.clock) |func| func(self.ptr, edge);
}

/// Read a value from a peripheral register.
pub inline fn read(self: Self, addr: u16) PeripheralError!u8 {
    return self.vtable.read(self.ptr, addr);
}

/// Write a value to a peripheral register.
pub inline fn write(self: Self, addr: u16, data: u8) PeripheralError!void {
    return self.vtable.write(self.ptr, addr, data);
}

/// Load data into peripheral registers.
pub inline fn load(self: Self, data: []const u8) PeripheralError!void {
    return if (self.vtable.load) |func| func(self.ptr, data) else PeripheralError.NotSupported;
    }

/// Get all data registers.
pub inline fn registers(self: Self) PeripheralError![]u8 {
return if (self.vtable.registers) |func| func(self.ptr) else PeripheralError.NotSupported;
}
