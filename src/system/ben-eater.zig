//! System based on Ben Eaters 65c02 breadboard computer.
const std = @import("std");

const Peripheral = @import("../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

const RAM = @import("../peripherals/memory.zig").RAM;
const ROM = @import("../peripherals/memory.zig").ROM;
const W65c22 = @import("../peripherals/via-w65c22.zig");
// const Terminal = @import("peripherals/terminal.zig");
// const Keyboard = @import("peripherals/keyboard.zig");

const Self = @This();

// Peripherals
ram: RAM,
rom: ROM,
via: W65c22,
// terminal: Terminal,
// keyboard: Keyboard,

pub fn init() Self {
    return .{
        .ram = RAM{ .size = 0x4000 },
        .rom = ROM{},
        .via = W65c22{},
        // .terminal = Terminal{},
        // .keyboard = Keyboard{},
    };
}

pub fn peripheral(self: *Self) Peripheral {
    return .{ .ptr = self, .vtable = &.{
        .clock = clock,
        .read = read,
        .write = write,
    } };
}

/// Run loop
pub fn loop(_: *Self) void {
    // self.keyboard.loop();
}

/// Resolve address to a peripheral.
fn resolvePeripheral(self: *Self, addr: u16) ?std.meta.Tuple(&.{ u16, Peripheral }) {
    return switch (addr) {
        0x0000...0x3FFF => .{ 0, self.ram.peripheral() },
        // 0x4000...0x4FFF => null,
        // 0x5000...0x5FFF => null,
        0x6000...0x600F => .{0x6000, self.via.peripheral() },
        // 0x6010...0x6FFF => null,
        // 0x7000...0x7FFF => null,
        0x8000...0xFFFF => .{ 0x8000, self.rom.peripheral() },
        else => null,
    };
}

/// Handle a clock signal (via the MCU).
fn clock(ctx: *anyopaque, edge: bool) PeripheralError!void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    self.ram.peripheral().clock(edge) catch {};
    self.rom.peripheral().clock(edge) catch {};
    // self.terminal.peripheral().clock(edge) catch {};
    // self.keyboard.peripheral().clock(edge) catch {};
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
