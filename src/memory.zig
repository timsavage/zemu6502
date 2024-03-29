//! Memory peripheral devices.

const std = @import("std");

const Peripheral = @import("peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

/// RAM device.
pub const RAM = struct {
    const Self = @This();

    // Actual data, always just use a fixed 64k
    data: [0x10000]u8 = [_]u8{0} ** 0x10000,
    size: u16,

    /// Fetch the peripheral interface
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
        if (addr >= self.size) {
            return PeripheralError.AddressIndex;
        }
        return self.data[addr];
    }

    /// Write a value to the peripheral.
    fn write(ctx: *anyopaque, addr: u16, data: u8) PeripheralError!void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (addr >= self.size) {
            return PeripheralError.AddressIndex;
        }
        self.data[addr] = data;
    }
};

/// **ROM device**
///
/// A ROM device has an initial size or zero that changes depending on data
/// loaded into the ROM. If a binary image is loaded the ROM will be set to
/// the size of the loaded image.
pub const ROM = struct {
    const Self = @This();

    // Actual data, always just use a fixed 64k
    data: [0x10000]u8 = [_]u8{0} ** 0x10000,
    size: u16 = 0,

    /// Fetch the peripheral interface
    pub fn peripheral(self: *Self) Peripheral {
        return .{ .ptr = self, .vtable = &.{
            .clock = null,
            .read = read,
            .write = write,
        } };
    }

    /// Load a file image (up to 64k).
    pub fn load_file(self: *Self, file: std.fs.File) !void {
        self.size = @intCast(try file.readAll(&self.data));
    }

    /// Read a value from the peripheral.
    fn read(ctx: *anyopaque, addr: u16) PeripheralError!u8 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (addr >= self.size) {
            return PeripheralError.AddressIndex;
        }
        return self.data[addr];
    }

    /// Write a value to the peripheral.
    fn write(_: *anyopaque, _: u16, _: u8) PeripheralError!void {
        return PeripheralError.ReadOnly;
    }
};
