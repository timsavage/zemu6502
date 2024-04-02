const std = @import("std");
const mpu = @import("../mpu.zig");
const Peripheral = @import("../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

/// Placeholder peripheral, always returns Read/Write only
pub const MockPeripheral = struct {
    const Self = @This();

    /// Fetch the peripheral interface
    pub fn peripheral(self: *Self) Peripheral {
        return .{ .ptr = self, .vtable = &.{
            .clock = null,
            .read = Self.read,
            .write = Self.write,
        } };
    }

    /// Read a value from the peripheral.
    fn read(_: *anyopaque, _: u16) PeripheralError!u8 {
        return PeripheralError.WriteOnly;
    }

    /// Write a value to the peripheral.
    fn write(_: *anyopaque, _: u16, _: u8) PeripheralError!void {
        return PeripheralError.ReadOnly;
    }
};

/// Generate a mock MPU struct for testing.
pub fn mock_mpu(comptime data: u8, comptime registers: mpu.Registers) mpu.MPU {
    var mock_peripheral = MockPeripheral{};
    return .{
        .registers = registers,
        .addr = 0,
        .data = data,
        .data_bus = mock_peripheral.peripheral(),
    };
}
