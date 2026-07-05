const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");
const devices = @import("devices.zig");
const System = @import("system.zig");
const GDB = @import("gdb.zig");

const Allocator = std.mem.Allocator;

// var gpa: std.heap.DebugAllocator(.{}) = .init;
pub const std_options: std.Options = .{
    // Set default log level to info.
    .log_level = .debug,
};

/// Stupidly simple command line arguments
const Args = struct {
    config_file: []const u8,
    gdb: bool = false,
};

fn processArgs(argv: []const [:0]const u8) !Args {
    if (argv.len != 2) {
        std.log.err("Missing config file argument.\n{s} CONFIG_FILE", .{argv[0]});
        return error.Unimplemented;
    }

    return .{ .config_file = argv[1] };
}

fn createPeripherals(io: std.Io, gpa: Allocator, system_dir: std.Io.Dir, system: *System, system_config: config.SystemConfig) !void {
    for (system_config.dataBus) |bus_address_config| {
        const peripheral = try devices.createDevice(io, gpa, system_dir, &bus_address_config, &system_config);
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

/// Clone of the method from std library to return a sentential
pub fn realpathAlloc(self: std.Io.Dir, io: std.Io, gpa: Allocator, pathname: []const u8) ![:0]u8 {
    var buf: [std.Io.Dir.max_path_bytes:0]u8 = undefined;
    const len = try self.realPathFile(io, pathname, buf[0..]);
    return gpa.dupeSentinel(u8, buf[0..len], 0);
}

fn loadShaderFromConfig(io: std.Io, gpa: Allocator, base_dir: std.Io.Dir, video_config: config.VideoConfig) !rl.Shader {
    if (video_config.shader) |shader| {
        const vert_file_path = realpathAlloc(base_dir, io, gpa, shader.vert) catch |err| switch (err) {
            error.FileNotFound => {
                std.log.err("Unable to load vertical shader: {s}", .{shader.vert});
                return err;
            },
            else => return err,
        };
        defer gpa.free(vert_file_path);

        const frag_file_path = realpathAlloc(base_dir, io, gpa, shader.frag) catch |err| switch (err) {
            error.FileNotFound => {
                std.log.err("Unable to load fragment shader: {s}", .{shader.frag});
                return err;
            },
            else => return err,
        };
        defer gpa.free(frag_file_path);

        return rl.loadShader(vert_file_path, frag_file_path);
    }
    return rl.loadShader(null, null);
}

fn keyInput(system: *System) void {
    if (rl.isKeyPressed(rl.KeyboardKey.f6)) {
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
                        "[{X:0>4}] {X} {X} {X} {X} {X} {X} {X} {X}",
                        .{
                            item.start + (idx * 32),
                            data[start .. start + 4],
                            data[start + 4 .. start + 8],
                            data[start + 8 .. start + 12],
                            data[start + 12 .. start + 16],
                            data[start + 16 .. start + 20],
                            data[start + 20 .. start + 24],
                            data[start + 24 .. start + 28],
                            data[start + 28 .. start + 32],
                        },
                    );
                }
            } else |_| {}
        }
        return;
    }
    if (rl.isKeyPressed(rl.KeyboardKey.f10)) {
        std.log.info("Reset...", .{});
        system.reset();
        return;
    }
}

/// Main entry point
pub fn main(init: std.process.Init) !void {
    const io = std.Io;
    const allocator = init.arena.allocator();
    const argv = try init.minimal.args.toSlice(allocator);

    const cwd = io.Dir.cwd();

    // Parse command line and load system config
    const args = processArgs(argv) catch |err| switch (err) {
        error.Unimplemented => return,
    };

    const config_path = cwd.realPathFileAlloc(init.io, args.config_file, allocator) catch |err| switch (err) {
        error.FileNotFound => {
            std.log.err("Config file not found: {s}", .{args.config_file});
            return;
        },
        else => return err,
    };
    defer allocator.free(config_path);

    // Resolve system working dir (relative to config file)
    var system_dir: std.Io.Dir = undefined;
    if (std.Io.Dir.path.dirname(config_path)) |path| {
        system_dir = try std.Io.Dir.openDirAbsolute(init.io, path, .{});
    } else {
        system_dir = std.Io.Dir.cwd();
    }

    const system_config = try config.from_file(init.io, config_path, allocator);

    // Initialise GDB
    var gdb: ?GDB = null;
    if (system_config.gdb) |gdb_config| {
        const address = try std.Io.net.IpAddress.parseIp6(gdb_config.address, gdb_config.port);
        gdb = try GDB.init(init.io, address, init.gpa);
    }
    defer if (gdb) |*instance| {
        instance.deinit();
    };

    // Activate window
    rl.initWindow(system_config.video.width, system_config.video.height, "ZEMU6502 - Display");
    defer rl.closeWindow();
    const shader = try loadShaderFromConfig(init.io, allocator, system_dir, system_config.video);
    defer rl.unloadShader(shader);
    rl.setExitKey(rl.KeyboardKey.f4);

    // Create system and add devices defined in config.
    var system = try System.init(init.io, init.gpa, system_config.clockFreq);
    defer system.deinit();
    std.log.info("Initialised system @ {d}Hz", .{system_config.clockFreq});
    try createPeripherals(init.io, init.gpa, system_dir, &system, system_config);

    // Attach GDB
    if (gdb) |*instance| {
        system.mpu.debug_port = instance.debugPort();
    }

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
