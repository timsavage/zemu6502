//! Emulation of the WDC 65c22 Versatile Interface Adapter (VIA)

const std = @import("std");
const Peripheral = @import("../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

const Self = @This();

const PeripheralDataPort = struct { input: u8 = 0, output: u8 = 0, ddr: u8 = 0 };

port_a: PeripheralDataPort = .{},
port_b: PeripheralDataPort = .{},

pub fn peripheral(self: *Self) Peripheral {
    return .{ .ptr = self, .vtable = &.{
        .clock = null,
        .read = read,
        .write = write,
    } };
}

/// Read a value from the peripheral.
fn read(ctx: *anyopaque, addr: u16) PeripheralError!u8 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return switch (addr) {
        0x0 => self.port_b.input,
        0x1 => self.port_a.input,
        0x2 => self.port_b.ddr,
        0x3 => self.port_a.ddr,
        0x4 => 0, // Timer 1 Counter Low
        0x5 => 0, // Timer 1 Counter High
        0x6 => 0, // Timer 1 Latches Low
        0x7 => 0, // Timer 1 Latches High
        0x8 => 0, // Timer 1 Counter Low
        0x9 => 0, // Timer 1 Counter High
        0xA => 0, // Shift Register
        0xB => 0, // AUX control register
        0xC => 0, // Peripheral control register
        0xD => 0, // Interrupt flag register
        0xE => 0, // Interrupt enable register
        0xF => self.port_a.input, // Shift Register (no handshakes)
        else => PeripheralError.AddressIndex,
    };
}

/// Write a value to the peripheral.
fn write(ctx: *anyopaque, addr: u16, data: u8) PeripheralError!void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    switch (addr) {
        0x0 => self.port_b.output = data,
        0x1 => self.port_a.output = data,
        0x2 => self.port_b.ddr = data,
        0x3 => self.port_a.ddr = data,
        0x4 => {}, // Timer 1 Counter Low
        0x5 => {}, // Timer 1 Counter High
        0x6 => {}, // Timer 1 Latches Low
        0x7 => {}, // Timer 1 Latches High
        0x8 => {}, // Timer 1 Counter Low
        0x9 => {}, // Timer 1 Counter High
        0xA => {}, // Shift Register
        0xB => {}, // AUX control register
        0xC => {}, // Peripheral control register
        0xD => {}, // Interrupt flag register
        0xE => {}, // Interrupt enable register
        0xF => self.port_a.output = data, // Shift Register (no handshakes)
        else => return PeripheralError.AddressIndex,
    }
}
