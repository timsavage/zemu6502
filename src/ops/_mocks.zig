const mpu = @import("../mpu.zig");
const Peripheral = @import("../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

/// Peripheral for use in test cases.
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
        return 0;
    }

    /// Write a value to the peripheral.
    fn write(_: *anyopaque, _: u16, _: u8) PeripheralError!void {}
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
