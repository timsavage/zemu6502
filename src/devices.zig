//! Hardware devices

const std = @import("std");
const DeviceConfig = @import("config.zig").DeviceConfig;
const SystemConfig = @import("config.zig").SystemConfig;
const Peripheral = @import("peripheral.zig");

pub const builtin = @import("devices/builtin.zig");
pub const via = @import("devices/via.zig");

/// Definition of all devices.
const Device = enum {
    const Self = @This();

    // Builtin devices
    ram,
    rom,
    terminal,
    @"text-terminal",
    keyboard,
    // VIA devices
    @"via.w65c22",

    fn fromString(name: []const u8) ?Self {
        return std.meta.stringToEnum(Self, name);
    }
};

const DeviceError = error{
    UnknownDevice,
};

/// Create a peripheral device from a config entry.
pub fn createDevice(allocator: std.mem.Allocator, device_config: *const DeviceConfig, system_config: *const SystemConfig) !Peripheral {
    const device = Device.fromString(device_config.type) orelse {
        std.log.err("Unknown device type: {s}", .{device_config.type});
        return DeviceError.UnknownDevice;
    };

    var peripheral = switch (device) {
        .keyboard => (try builtin.Keyboard.init(allocator)).peripheral(),
        .ram => (try builtin.RAM.init(allocator)).peripheral(),
        .rom => (try builtin.ROM.init(allocator)).peripheral(),
        .terminal => (try builtin.Terminal.init(allocator, &system_config.video)).peripheral(),
        .@"text-terminal" => (try builtin.TextTerminal.init(allocator)).peripheral(),
        .@"via.w65c22" => (try via.W65c22.init(allocator)).peripheral(),
    };

    std.log.info(
        "Initialised device {s} - {s}",
        .{ peripheral.vtable.name, peripheral.vtable.description },
    );

    // Load binary file.
    if (device_config.load) |path| {
        std.log.info(
            "Loading {s} into {s}",
            .{ path, peripheral.vtable.name },
        );

        // Load inititial rom bin
        const file = try std.fs.cwd().openFile(path, .{});

        const buffer = try allocator.alloc(u8, 0x10000);
        defer allocator.free(buffer);

        const read = try file.readAll(buffer);
        try peripheral.load(buffer[0..read]);
    }

    return peripheral;
}
