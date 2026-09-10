//! Terminal peripheral device.

const std = @import("std");
const Peripheral = @import("../../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

const Self = @This();

stdout: std.Io.Writer,

pub fn init(io: std.Io, gpa: std.mem.Allocator) !*Self {
    const instance = try gpa.create(Self);
    instance.* = .{ .stdout = std.Io.File.stdout().writer(io, &.{}).interface };
    return instance;
}

pub fn peripheral(self: *Self) Peripheral {
    return .{
        .ptr = self,
        .vtable = &.{
            .name = "Terminal stdout",
            .description = "Simple text terminal.",
            .read = read,
            .write = write,
        },
    };
}

/// Read a value from a peripheral register.
fn read(_: *anyopaque, _: u16) PeripheralError!u8 {
    return PeripheralError.WriteOnly;
}

/// Write a value to a peripheral register.
fn write(ctx: *anyopaque, addr: u16, data: u8) PeripheralError!void {
    const self: *Self = @ptrCast(@alignCast(ctx));

    switch (addr) {
        0 => {
            self.stdout.printAsciiChar(data, .{}) catch return PeripheralError.HardwareFailure;
        },
        else => return PeripheralError.AddressIndex,
    }
}
