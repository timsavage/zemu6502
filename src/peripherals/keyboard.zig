//! Keyboard peripheral device.

const std = @import("std");
const Peripheral = @import("../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;
const stdin = std.io.getStdIn().reader();
const Self = @This();

key: u8 = 0,

pub fn peripheral(self: *Self) Peripheral {
    return .{
        .ptr = self,
        .vtable = &.{
            .name = "Keyboard",
            .description = "Keyboard input",
            .read = read,
            .write = write,
        },
    };
}

pub fn loop(_: *Self) void {
    // var buffer = [1]u8{0};
    // if (stdin.readNoEof(&buffer)) |_| {
    //     self.key = buffer[0];
    // } else |_| {}
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
