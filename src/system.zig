//! Definition of a basic hardware system.

const std = @import("std");
const Clock = @import("clock.zig");
const DataBus = @import("data-bus.zig");
const MPU = @import("6502.zig").MPU;

const Self = @This();

allocator: std.mem.Allocator,
data_bus: *DataBus,
mpu: *MPU,
clock: Clock,

/// Initialise system.
pub fn init(allocator: std.mem.Allocator, freq_hz: u64) !Self {
    const data_bus = try allocator.create(DataBus);
    errdefer allocator.destroy(data_bus);
    data_bus.* = DataBus.init(allocator);

    const mpu = try allocator.create(MPU);
    errdefer allocator.destroy(mpu);
    mpu.* = MPU.init(data_bus);

    return .{
        .allocator = allocator,
        .data_bus = data_bus,
        .mpu = mpu,
        .clock = try Clock.init(freq_hz, mpu),
    };
}

/// Clean up MCU instance.
pub fn deinit(self: *Self) void {
    self.allocator.destroy(self.mpu);
    self.data_bus.deinit();
    self.allocator.destroy(self.data_bus);
}

/// Reset the system to a known state.
pub fn reset(self: *Self) void {
    self.mpu.reset();
    self.data_bus.reset();
    self.clock.start();
}

/// Run loop
pub fn loop(self: *Self) void {
    self.clock.loop();
    self.data_bus.loop();
}
