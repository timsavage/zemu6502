//! Definition of a basic hardware system.

const std = @import("std");
const Clock = @import("clock.zig");
const DataBus = @import("data-bus.zig");
const MPU = @import("6502.zig").MPU;
const RAM = @import("peripherals/memory.zig").RAM;
const ROM = @import("peripherals/memory.zig").ROM;
const Terminal = @import("peripherals/terminal.zig");
const Keyboard = @import("peripherals/keyboard.zig");

const Self = @This();

allocator: std.mem.Allocator,
data_bus: *DataBus,
mpu: *MPU,
clock: Clock,
// Peripherals
ram: RAM,
rom: ROM,
keyboard: Keyboard,
terminal: Terminal,

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

        .ram = .{ .size = 0x4000 },
        .rom = .{},
        .keyboard = .{},
        .terminal = .{},
    };
}

pub fn deinit(self: *Self) void {
    self.data_bus.deinit();

    self.allocator.destroy(self.mpu);
    self.allocator.destroy(self.data_bus);
}

pub fn addPeripherals(self: *Self) !void {
    try self.data_bus.addPeripheral(.{ .start = 0x0000, .end = 0x3FFF, .peripheral = self.ram.peripheral() });
    try self.data_bus.addPeripheral(.{ .start = 0xFF00, .end = 0xFFFF, .peripheral = self.rom.peripheral() });
    try self.data_bus.addPeripheral(.{ .start = 0x8000, .end = 0x8000, .peripheral = self.terminal.peripheral() });
    try self.data_bus.addPeripheral(.{ .start = 0x5010, .end = 0x5010, .peripheral = self.keyboard.peripheral() });
}

/// Run loop
pub fn loop(self: *Self) void {
    self.clock.loop();
}
