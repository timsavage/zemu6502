//! Hardware devices

const std = @import("std");
const BusAddressConfig = @import("config.zig").BusAddressConfig;
const SystemConfig = @import("config.zig").SystemConfig;
const Peripheral = @import("peripheral.zig");

pub const builtin = @import("devices/builtin.zig");
pub const via = @import("devices/via.zig");
pub const apple1 = @import("devices/apple1.zig");

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
    // Apple1 devices
    @"apple1.keyboard",
    @"apple1.display",

    fn fromString(name: []const u8) ?Self {
        return std.meta.stringToEnum(Self, name);
    }
};

const DeviceError = error{
    UnknownDevice,
    ImageNotFound,
};

/// Create a peripheral device from a config entry.
pub fn createDevice(allocator: std.mem.Allocator, system_dir: std.fs.Dir, config: *const BusAddressConfig, system_config: *const SystemConfig) !Peripheral {
    const device_config = config.peripheral;
    const device = Device.fromString(device_config.type) orelse {
        std.log.err("Unknown device type: {s}", .{device_config.type});
        return DeviceError.UnknownDevice;
    };

    var peripheral = switch (device) {
        .keyboard => (try builtin.Keyboard.init(allocator)).peripheral(),
        .ram => (try builtin.RAM.init(allocator, config.size())).peripheral(),
        .rom => (try builtin.ROM.init(allocator)).peripheral(),
        .terminal => (try builtin.Terminal.init(allocator, &system_config.video)).peripheral(),
        .@"text-terminal" => (try builtin.TextTerminal.init(allocator)).peripheral(),
        .@"via.w65c22" => (try via.W65c22.init(allocator)).peripheral(),
        .@"apple1.keyboard" => (try apple1.Keyboard.init(allocator)).peripheral(),
        .@"apple1.display" => (try apple1.Display.init(allocator, &system_config.video)).peripheral(),
    };

    std.log.info(
        "Initialised device {s} - {s}",
        .{ peripheral.vtable.name, peripheral.vtable.description },
    );

    // Load binary file.
    if (device_config.load) |image_path| {
        std.log.info(
            "Loading {s} into {s}",
            .{ image_path, peripheral.vtable.name },
        );

        const MAX_IMAGE_SIZE: usize = 0x10000;

        // Load initial rom bin
        if (system_dir.openFile(image_path, .{})) |file| {
            const buffer = try file.readToEndAlloc(allocator, MAX_IMAGE_SIZE);
            defer allocator.free(buffer);
            try peripheral.load(buffer);
        } else |err| switch (err) {
            error.FileNotFound => {
                std.log.err("Initial peripheral image not found: {s}", .{image_path});
            },
            error.FileTooBig => {
                std.log.err("File {s} exceeds maximum images size {}bytes", .{ image_path, MAX_IMAGE_SIZE });
            },
            else => return err,
        }
    }

    return peripheral;
}
