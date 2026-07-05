//! System configuration.
const std = @import("std");
const Yaml = @import("yaml").Yaml;

pub const ConfigError = error{
    FileNotFound,
};

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

    pub inline fn length(self: BusAddressConfig) usize {
        return (self.end - self.start) + 1;
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
pub fn from_file(io: std.Io, file_path: []const u8, gpa: std.mem.Allocator) !SystemConfig {
    const file = std.Io.Dir.cwd().readFileAlloc(
        io,
        file_path,
        gpa,
        std.Io.Limit.unlimited,
    ) catch |err| switch (err) {
        error.FileNotFound => return ConfigError.FileNotFound,
        else => return err,
    };
    defer gpa.free(file);

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var yaml: Yaml = .{ .source = file };
    try yaml.load(arena_allocator);

    return try yaml.parse(arena_allocator, SystemConfig);
}
