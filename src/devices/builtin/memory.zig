//! Memory peripheral devices.

const std = @import("std");

const Peripheral = @import("../../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

fn Memory(comptime TReadonly: bool) type {
    return struct {
        const Self = @This();

        // Actual data, always just use a fixed 64k
        data: [0x1_0000]u8 = [_]u8{0} ** 0x1_0000,
        // Excess-1 notation, so that the full memory range can be used. Zero size memory is not possible.
        size: u16,

        /// Initialise RAM/ROM device.
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
                    .name = if (TReadonly) "ROM" else "RAM",
                    .description = if (TReadonly) "Read Only Memory." else "Random Access Memory.",
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
            if (TReadonly) {
                return PeripheralError.ReadOnly;
            }

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
            if (TReadonly) {
                self.size = @truncate(data.len - 1);
            }
        }

        /// View of registers
        fn registers(ctx: *anyopaque) PeripheralError![]u8 {
            const self: *Self = @ptrCast(@alignCast(ctx));
            return self.data[0 .. self.size + 1];
        }
    };
}

/// RAM device.
pub const RAM = Memory(false);

/// **ROM device**
///
/// A ROM device has an initial size or zero that changes depending on data
/// loaded into the ROM. If a binary image is loaded the ROM will be set to
/// the size of the loaded image.
pub const ROM = Memory(true);
