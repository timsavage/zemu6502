//! Terminal peripheral device.

const std = @import("std");
const Peripheral = @import("../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;
const stdout = std.io.getStdOut().writer();
const Self = @This();

pub fn peripheral(self: *Self) Peripheral {
    return .{ .ptr = self, .vtable = &.{
        .clock = null,
        .read = read,
        .write = write,
    } };
}

fn read(_: *anyopaque, _: u16) PeripheralError!u8 {
    return PeripheralError.WriteOnly;
}

fn write(_: *anyopaque, addr: u16, data: u8) PeripheralError!void {
    switch (addr) {
        0 => {
            stdout.print("{c}", .{data}) catch return PeripheralError.HardwareFailure;
        },
        else => return PeripheralError.AddressIndex,
    }
}
