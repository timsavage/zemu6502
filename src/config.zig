//! System configuration.
const std = @import("std");
const yaml = @import("yaml");

/// GDB config
pub const GDBConfig = struct {
    address: []const u8,
    port: u16,
};

/// Display Config
pub const VideoConfig = struct {
    width: i32 = 640,
    height: i32 = 480,
    scale: i32 = 2,
    shader: ?struct {
        vert: []const u8,
        frag: []const u8,
    } = null,
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

    pub inline fn size(self: BusAddressConfig) u16 {
        return self.end - self.start;
    }
};

/// Top-level system config.
pub const SystemConfig = struct {
    clockFreq: u64,
    gdb: ?GDBConfig = null,
    video: VideoConfig,
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
