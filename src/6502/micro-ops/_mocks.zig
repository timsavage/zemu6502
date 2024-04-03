const std = @import("std");
const mpu = @import("../mpu.zig");
const DataBus = @import("../../data-bus.zig");
const RAM = @import("../../peripherals/memory.zig").RAM;

/// Generate a mock MPU struct for testing.
///
/// Includes a databus with a single ram peripheral covering the entire
/// address range.
pub fn mock_mpu(comptime data: u8, comptime registers: mpu.Registers) !mpu.MPU {
    var data_bus = DataBus.init(std.testing.allocator);
    var ram = RAM{.size = 0xFFFF};

    try data_bus.addPeripheral(.{
        .start = 0,
        .end = 0xFFFF,
        .peripheral = ram.peripheral(),
    });
    return .{
        .registers = registers,
        .addr = 0,
        .data = data,
        .data_bus = &data_bus,
    };
}
