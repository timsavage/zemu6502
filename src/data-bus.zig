//! # Data Bus
//!
//! The data-bus mediates all interactions between devices and the MCU.
//! Covering address and data buses and signels for NMI, IRQ and clock.

const std = @import("std");
const Peripheral = @import("peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

const Self = @This();

const BusAddress = struct {
    start: u16,
    end: u16,
    peripheral: Peripheral,

    /// Address is within the target address range (inclusive).
    fn containsAddress(self: *const BusAddress, address: u16) bool {
        return self.start <= address and address <= self.end;
    }
};

peripherals: std.ArrayList(BusAddress),

/// Initialise data bus.
pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .peripherals = std.ArrayList(BusAddress).init(allocator),
    };
}

/// Deinit
pub fn deinit(self: *Self) void {
    self.peripherals.deinit();
}

/// Add a peripheral to the databus
pub fn addPeripheral(self: *Self, bus_address: BusAddress) !void {
    try self.peripherals.append(bus_address);
}

/// Resolve an address to a peripheral
/// @param address - Bus address
/// @returns Optional peripheral
fn resolve(self: *Self, address: u16) ?struct { u16, Peripheral } {
    for (self.peripherals.items) |item| {
        if (item.containsAddress(address)) return .{ address - item.start, item.peripheral };
    }
    return null;
}

/// Pass a clock signal to the data-bus.
pub fn clock(self: *Self, edge: bool) void {
    for (self.peripherals.items) |item| {
        item.peripheral.clock(edge) catch |err| {
            std.log.warn("Error clocking peripheral: {}", .{err});
        };
    }
}

/// Read value at specified address.
pub fn read(self: *Self, address: u16) u8 {
    if (self.resolve(address)) |result| {
        return result.@"1".read(result.@"0") catch |err| {
            std.log.warn("Error reading from peripheral @ 0x{X:0^4}: {}", .{ address, err });
            return 0;
        };
    } else {
        std.log.warn("No peripheral @ 0x{X:0^4}", .{address});
    }
    return 0;
}

/// Write a value to specified address.
pub fn write(self: *Self, address: u16, data: u8) void {
    if (self.resolve(address)) |result| {
        result.@"1".write(result.@"0", data) catch |err| {
            std.log.warn("Error writing to peripheral @ 0x{X:0^2} value 0x{X:0^4}({1d}: {}", .{ address, data, err });
        };
    } else {
        std.log.warn("No peripheral @ 0x{X:0^4}", .{address});
    }
}

/// Get the state of the NMI (non-maskable interrupt) line.
pub fn nmi(_: *Self) bool {
    return false;
}

/// Get the state of the IRQ (interrupt request) line.
pub fn irq(_: *Self) bool {
    return false;
}
