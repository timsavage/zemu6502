//! Memory peripheral devices.

const std = @import("std");

const Peripheral = @import("../../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

/// RAM device.
pub const RAM = struct {
    const Self = @This();

    // Actual data, always just use a fixed 64k
    data: [0x1_0000]u8 = [_]u8{0} ** 0x1_0000,
    size: u16 = 0xFFFF,

    /// Initialise RAM device.
    pub fn init(allocator: std.mem.Allocator, size: u16) !*Self {
        const instance = try allocator.create(Self);
        instance.* = .{
            .size = size,
        };
        return instance;
    }

    /// Fetch the peripheral interface
    pub fn peripheral(self: *Self) Peripheral {
        return .{
            .ptr = self,
            .vtable = &.{
                .name = "RAM",
                .description = "Random Access Memory.",
                .read = read,
                .write = write,
                .load = load,
                .registers = registers,
            },
        };
    }

    /// Read a value from the a peripheral register.
    fn read(ctx: *anyopaque, addr: u16) PeripheralError!u8 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (addr >= self.size) {
            return PeripheralError.AddressIndex;
        }
        return self.data[addr];
    }

    /// Write a value to a peripheral register.
    fn write(ctx: *anyopaque, addr: u16, data: u8) PeripheralError!void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (addr >= self.size) {
            return PeripheralError.AddressIndex;
        }
        self.data[addr] = data;
    }

    /// Load a file image (up to 64k).
    fn load(ctx: *anyopaque, data: []const u8) PeripheralError!void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (data.len > self.data.len) return PeripheralError.AddressIndex;
        @memcpy(self.data[0..data.len], data);
        self.size = @truncate(data.len - 1);
    }

    /// View of registers
    fn registers(ctx: *anyopaque) PeripheralError![]u8 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.data[0..self.size];
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
    data: [0x1_0000]u8 = [_]u8{0} ** 0x1_0000,
    size: u16 = 0,

    /// Initialise ROM device.
    pub fn init(allocator: std.mem.Allocator) !*Self {
        const instance = try allocator.create(Self);
        instance.* = .{};
        return instance;
    }

    /// Fetch the peripheral interface
    pub fn peripheral(self: *Self) Peripheral {
        return .{
            .ptr = self,
            .vtable = &.{
                .name = "ROM",
                .description = "Read Only Memory.",
                .read = read,
                .write = write,
                .load = load,
                .registers = registers,
            },
        };
    }

    /// Read a value from the a peripheral register.
    fn read(ctx: *anyopaque, addr: u16) PeripheralError!u8 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (addr >= self.size) {
            return PeripheralError.AddressIndex;
        }
        return self.data[addr];
    }

    /// Write a value to a peripheral register.
    fn write(_: *anyopaque, _: u16, _: u8) PeripheralError!void {
        return PeripheralError.ReadOnly;
    }

    /// Load a file image (up to 64k).
    fn load(ctx: *anyopaque, data: []const u8) PeripheralError!void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (data.len > self.data.len) return PeripheralError.AddressIndex;
        @memcpy(self.data[0..data.len], data);
        self.size = @truncate(data.len - 1);
    }

    /// View of registers
    fn registers(ctx: *anyopaque) PeripheralError![]u8 {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.data[0..self.size];
    }
};
