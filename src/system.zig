//! Definition of a basic hardware system.

const std = @import("std");
const Clock = @import("clock.zig");
const DataBus = @import("data-bus.zig");
const MPU = @import("6502.zig").MPU;

const Self = @This();

gpa: std.mem.Allocator,
data_bus: *DataBus,
mpu: *MPU,
clock: Clock,

/// Initialise system.
pub fn init(io: std.Io, gpa: std.mem.Allocator, freq_hz: u64) !Self {
    const data_bus = try gpa.create(DataBus);
    errdefer gpa.destroy(data_bus);
    data_bus.* = DataBus.init(gpa);

    const mpu = try gpa.create(MPU);
    errdefer gpa.destroy(mpu);
    mpu.* = MPU.init(data_bus);

    return .{
        .gpa = gpa,
        .data_bus = data_bus,
        .mpu = mpu,
        .clock = try Clock.init(io, freq_hz, mpu),
    };
}

/// Clean up MCU instance.
pub fn deinit(self: *Self) void {
    self.gpa.destroy(self.mpu);
    self.data_bus.deinit();
    self.gpa.destroy(self.data_bus);
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
