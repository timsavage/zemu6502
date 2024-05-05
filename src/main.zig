const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");
const devices = @import("devices.zig");
const System = @import("system.zig");
const GDB = @import("gdb.zig");

const Allocator = std.mem.Allocator;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const std_options = .{
    // Set default log level to info.
    .log_level = .debug,
};

/// Stupidly simple command line arguments
const Args = struct {
    config_file: []const u8,
    gdb: bool = false,
};

fn processArgs(allocator: Allocator) !Args {
    const args = try std.process.argsAlloc(allocator);
    if (args.len != 2) {
        try std.io.getStdErr().writer().print(
            "Missing config file argument.\n{s} CONFIG_FILE",
            .{args[0]},
        );
        return error.Unimplemented;
    }

    return .{ .config_file = args[1] };
}

fn createPeripherals(allocator: Allocator, system_dir: std.fs.Dir, system: *System, system_config: config.SystemConfig) !void {
    for (system_config.dataBus) |bus_address_config| {
        const peripheral = try devices.createDevice(allocator, system_dir, &bus_address_config, &system_config);
        try system.data_bus.addPeripheral(.{
            .start = bus_address_config.start,
            .end = bus_address_config.end,
            .peripheral = peripheral,
        });
        std.log.info(
            "Added {s} to bus at @{X:0^4}-{X:0^4}",
            .{ peripheral.vtable.name, bus_address_config.start, bus_address_config.end },
        );
    }
}

/// Clone of the method from std library to return a sentenal
pub fn realpathAlloc(self: std.fs.Dir, allocator: Allocator, pathname: []const u8) ![:0]u8 {
    var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    return allocator.dupeZ(u8, try self.realpath(pathname, buf[0..]));
}

fn loadShaderFromConfig(allocator: Allocator, base_dir: std.fs.Dir, video_config: config.VideoConfig) !rl.Shader {
    if (video_config.shader) |shader| {
        const vert_file_path = realpathAlloc(base_dir, allocator, shader.vert) catch |err| switch (err) {
            error.FileNotFound => {
                std.log.err("Unable to load vertical shader: {s}", .{shader.vert});
                return err;
            },
            else => return err,
        };
        defer allocator.free(vert_file_path);

        const frag_file_path = realpathAlloc(base_dir, allocator, shader.frag) catch |err| switch (err) {
            error.FileNotFound => {
                std.log.err("Unable to load fragment shader: {s}", .{shader.frag});
                return err;
            },
            else => return err,
        };
        defer allocator.free(frag_file_path);

        return rl.loadShader(vert_file_path, frag_file_path);
    }
    return rl.loadShader(null, null);
}

fn keyInput(system: *System) void {
    if (rl.isKeyPressed(rl.KeyboardKey.key_f6)) {
        for (system.data_bus.peripherals.items) |item| {
            if (item.peripheral.registers()) |data| {
                std.log.info(
                    "Peripheral: {s} - {}bytes",
                    .{ item.peripheral.vtable.name, data.len },
                );

                std.log.info(
                    "       00....03 04....07 08....0B 0C....0F 10....13 14....17 18....1B 1C....1F",
                    .{},
                );
                const size = @min(data.len, 0x3FF);
                for (0..(size / 32)) |idx| {
                    const start = idx * 32;
                    std.log.info(
                        "[{X:0>4}] {} {} {} {} {} {} {} {}",
                        .{
                            item.start + (idx * 32),
                            std.fmt.fmtSliceHexUpper(data[start .. start + 4]),
                            std.fmt.fmtSliceHexUpper(data[start + 4 .. start + 8]),
                            std.fmt.fmtSliceHexUpper(data[start + 8 .. start + 12]),
                            std.fmt.fmtSliceHexUpper(data[start + 12 .. start + 16]),
                            std.fmt.fmtSliceHexUpper(data[start + 16 .. start + 20]),
                            std.fmt.fmtSliceHexUpper(data[start + 20 .. start + 24]),
                            std.fmt.fmtSliceHexUpper(data[start + 24 .. start + 28]),
                            std.fmt.fmtSliceHexUpper(data[start + 28 .. start + 32]),
                        },
                    );
                }
            } else |_| {}
        }
        return;
    }
    if (rl.isKeyPressed(rl.KeyboardKey.key_f10)) {
        std.log.info("Reset...", .{});
        system.reset();
        return;
    }
}

/// Main entry point
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    // Parse command line and load system config
    const args = processArgs(allocator) catch |err| switch (err) {
        error.Unimplemented => return,
        else => return err,
    };
    const config_path = std.fs.realpathAlloc(allocator, args.config_file) catch |err| switch (err) {
        error.FileNotFound => {
            std.log.err("Config file not found: {s}", .{args.config_file});
            return;
        },
        else => return err,
    };
    defer allocator.free(config_path);

    // Resolve system working dir (relative to config file)
    var system_dir: std.fs.Dir = undefined;
    if (std.fs.path.dirname(config_path)) |path| {
        system_dir = try std.fs.openDirAbsolute(path, .{});
    } else {
        system_dir = std.fs.cwd();
    }

    const system_config = try config.from_file(allocator, config_path);

    // Initialise GDB
    var gdb: ?GDB = null;
    if (system_config.gdb) |gdb_config| {
        const address = try std.net.Address.parseIp6(gdb_config.address, gdb_config.port);
        gdb = try GDB.init(address);
    }
    defer if (gdb) |*instance| {
        instance.deinit();
    };

    // Activate window
    rl.initWindow(system_config.video.width, system_config.video.height, "ZEMU6502 - Display");
    defer rl.closeWindow();
    const shader = try loadShaderFromConfig(allocator, system_dir, system_config.video);
    defer rl.unloadShader(shader);

    // Create system and add devices defined in config.
    var system = try System.init(allocator, system_config.clockFreq);
    defer system.deinit();
    std.log.info("Initialised system @ {d}Hz", .{system_config.clockFreq});
    try createPeripherals(allocator, system_dir, &system, system_config);
    system.reset();

    while (!rl.windowShouldClose()) {
        if (gdb) |*instance| {
            try instance.loop(&system);
        }
        keyInput(&system);

        rl.beginDrawing();
        rl.beginShaderMode(shader);
        system.loop();
        rl.endShaderMode();
        rl.endDrawing();
    }
}

test {
    // Work around because testing is ...
    std.testing.refAllDecls(@This());
}
