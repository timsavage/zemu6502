//! Definition of a basic hardware system.
const std = @import("std");

const Peripheral = @import("peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;
const RAM = @import("memory.zig").RAM;
const ROM = @import("memory.zig").ROM;
const Terminal = @import("terminal.zig");

const Self = @This();

// Peripherals
ram: RAM,
rom: ROM,
terminal: Terminal,

pub fn init() Self {
    return .{
        .ram = RAM{.size = 0x4000},
        .rom = ROM{},
        .terminal = Terminal{},
    };
}

pub fn peripheral(self: *Self) Peripheral {
    return .{ .ptr = self, .vtable = &.{
        .clock = clock,
        .read = read,
        .write = write,
    } };
}

/// Resolve address to a peripheral.
fn resolvePeripheral(self: *Self, addr: u16) ?std.meta.Tuple(&.{ u16, Peripheral }) {
    return switch (addr) {
        0...0x3FFF => .{ 0, self.ram.peripheral() },
        0x8000 => .{ 0x8000, self.terminal.peripheral() },
        0xFF00...0xFFFF => .{ 0xFF00, self.rom.peripheral() },
        else => null,
    };
}

/// Handle a clock signal (via the MCU).
fn clock(ctx: *anyopaque) PeripheralError!void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    self.ram.peripheral().clock() catch {};
    self.rom.peripheral().clock() catch {};
    self.terminal.peripheral().clock() catch {};
}

/// Read a byte from the data bus
fn read(ctx: *anyopaque, addr: u16) PeripheralError!u8 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    if (self.resolvePeripheral(addr)) |value| {
        const peripheral_addr = addr - value[0];
        return value[1].read(peripheral_addr);
    }
    return 0;
}

/// Write a byte to the data bus
fn write(ctx: *anyopaque, addr: u16, data: u8) PeripheralError!void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    if (self.resolvePeripheral(addr)) |value| {
        const peripheral_addr = addr - value[0];
        return value[1].write(peripheral_addr, data);
    }
}
