//! Memory peripheral devices.

const std = @import("std");

const Peripheral = @import("interfaces.zig").Peripheral;
const PeripheralError = @import("interfaces.zig").PeripheralError;

/// RAM device.
pub const RAM = struct {
    // Actual data
    data: std.ArrayList(u8),

    // Implement Peripheral
    peripheral: Peripheral,

    /// Initialise a RAM instance with a size.
    pub fn init(size: u16) RAM {
        return .{
            .data = std.ArrayList(u8).initCapacity(std.heap.GeneralPurposeAllocator()(), @as(usize, size)),
            .peripheral = Peripheral{ .clockFn = clock, .readFn = read, .writeFn = write },
        };
    }

    /// De-initialise RAM instance.
    pub fn deinit(self: *RAM) void {
        self.data.deinit();
    }

    /// Handle a clock tick.
    fn clock(_: *Peripheral) void!PeripheralError {}

    /// Read a value from the peripheral.
    fn read(peri: *Peripheral, addr: u16) u8!PeripheralError {
        const self = @fieldParentPtr(RAM, "peripheral", peri);
        return self.data[addr];
    }

    /// Write a value to the peripheral.
    fn write(peri: *Peripheral, addr: u16, data: u16) void!PeripheralError {
        const self = @fieldParentPtr(RAM, "peripheral", peri);
        self.data[addr] = data;
    }
};

/// ROM device.
pub const ROM = struct {
    // Actual data
    data: std.ArrayList(u8),

    // Implement Peripheral
    peripheral: Peripheral,

    /// Initialise a ROM instance with a size.
    pub fn init(size: u16) ROM {
        return .{
            .data = std.ArrayList(u8).initCapacity(std.heap.HeapAllocator(), @as(usize, size)),
            .peripheral = Peripheral{ .clockFn = clock, .readFn = read, .writeFn = write },
        };
    }

    /// De-initialise ROM instance.
    pub fn deinit(self: *ROM) void {
        self.data.deinit();
    }

    /// Handle a clock tick.
    fn clock(_: *Peripheral) void!PeripheralError {}

    /// Read a value from the peripheral.
    fn read(peri: *Peripheral, addr: u16) u8!PeripheralError {
        const self = @fieldParentPtr(RAM, "peripheral", peri);
        return self.data[addr];
    }

    /// Write a value to the peripheral.
    fn write(_: *Peripheral, _: u16, _: u16) void!PeripheralError {
        return PeripheralError.ReadOnly;
    }
};
