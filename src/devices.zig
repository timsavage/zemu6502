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
pub fn createDevice(io: std.Io, gpa: std.mem.Allocator, system_dir: std.Io.Dir, config: *const BusAddressConfig, system_config: *const SystemConfig) !Peripheral {
    const device_config = config.peripheral;
    const device = Device.fromString(device_config.type) orelse {
        std.log.err("Unknown device type: {s}", .{device_config.type});
        return DeviceError.UnknownDevice;
    };

    var peripheral = switch (device) {
        .keyboard => (try builtin.Keyboard.init(gpa)).peripheral(),
        .ram => (try builtin.RAM.init(gpa, config.size())).peripheral(),
        .rom => (try builtin.ROM.init(gpa, 0)).peripheral(),
        .terminal => (try builtin.Terminal.init(gpa, &system_config.video)).peripheral(),
        .@"text-terminal" => (try builtin.TextTerminal.init(io, gpa)).peripheral(),
        .@"via.w65c22" => (try via.W65c22.init(gpa)).peripheral(),
        .@"apple1.keyboard" => (try apple1.Keyboard.init(gpa)).peripheral(),
        .@"apple1.display" => (try apple1.Display.init(gpa, &system_config.video)).peripheral(),
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

        const MAX_IMAGE_SIZE: usize = 0x1_0000;

        // Load initial rom bin
        if (system_dir.openFile(io, image_path, .{})) |file| {
            var file_reader = file.reader(io, &.{});
            const contents = try file_reader.interface.allocRemaining(gpa, .limited(MAX_IMAGE_SIZE + 1));
            defer gpa.free(contents);
            try peripheral.load(contents);
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
