//! Keyboard peripheral device.

const std = @import("std");
const rl = @import("raylib");
const Peripheral = @import("../../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;
const KeyboardKey = rl.KeyboardKey;

const Self = @This();

key: u8 = 0,

/// Initialise Keyboard device.
pub fn init(allocator: std.mem.Allocator) !*Self {
    const instance = try allocator.create(Self);
    instance.* = .{};
    return instance;
}

pub fn peripheral(self: *Self) Peripheral {
    return .{
        .ptr = self,
        .vtable = &.{
            .name = "Keyboard",
            .description = "Keyboard input.",
            .loop = loop,
            .nmi = nmi,
            .read = read,
            .write = write,
        },
    };
}

pub fn loop(ctx: *anyopaque) PeripheralError!void {
    const self: *Self = @ptrCast(@alignCast(ctx));

    const char: u8 = switch (rl.getKeyPressed()) {
        KeyboardKey.key_enter => 0x0A,
        KeyboardKey.key_backspace => 0x08,
        KeyboardKey.key_escape => 0x1B,
        else => @intCast(rl.getCharPressed()),
    };
    if (char > 0) {
        self.key = char;
    }
}

fn nmi(ctx: *anyopaque) bool {
    const self: *Self = @ptrCast(@alignCast(ctx));
    return self.key > 0;
}

fn read(ctx: *anyopaque, addr: u16) PeripheralError!u8 {
    const self: *Self = @ptrCast(@alignCast(ctx));
    switch (addr) {
        0 => {
            defer self.key = 0;
            return self.key;
        },
        else => return PeripheralError.AddressIndex,
    }
}

fn write(_: *anyopaque, _: u16, _: u8) PeripheralError!void {
    return PeripheralError.ReadOnly;
}
