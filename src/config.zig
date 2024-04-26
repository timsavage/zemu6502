//! System configuration.
const std = @import("std");
const yaml = @import("yaml");

/// Display Config
pub const VideoConfig = struct {
    width: i32 = 640,
    height: i32 = 480,
    scale: i32 = 2,
};

/// Individual device configuration.
pub const DeviceConfig = struct {
    type: []const u8,
    load: ?[]const u8,
};

/// Bus address configration and accociated peripheral device.
pub const BusAddressConfig = struct {
    start: u16,
    end: u16,
    peripheral: DeviceConfig,
};

/// Top-level system config.
pub const SystemConfig = struct {
    clockFreq: u64,
    video: VideoConfig = .{},
    dataBus: []BusAddressConfig,
};

/// Load configuration from a file.
pub fn from_file(allocator: std.mem.Allocator, path: []const u8) !SystemConfig {
    const file = try std.fs.cwd().readFileAlloc(allocator, path, 1_000_000);
    defer allocator.free(file);

    var raw = try yaml.Yaml.load(allocator, file);
    defer raw.deinit();

    return try raw.parse(SystemConfig);
}
