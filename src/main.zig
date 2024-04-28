const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");
const devices = @import("devices.zig");
const System = @import("system.zig");
const GDB = @import("gdb.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const std_options = .{
    // Set default log level to info.
    .log_level = .info,
};

/// Stupidly simple command line arguments
const Args = struct {
    config_file: []const u8,
    gdb: bool = false,
};

fn processArgs(allocator: std.mem.Allocator) !Args {
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

fn createPeripherals(allocator: std.mem.Allocator, system: *System, system_config: config.SystemConfig) !void {
    for (system_config.dataBus) |bus_address_config| {
        const peripheral = try devices.createDevice(allocator, &bus_address_config, &system_config);
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

fn keyInput(system: *System) void {
    if (rl.isKeyPressed(rl.KeyboardKey.key_f1)) {
        std.log.info(
            \\F1 - This help
            \\      F5 - Dump registers
            \\      F6 - Dump memory (if associated)
            \\      F7 - Halt at next instruction
            \\      F8 - Step one instruction
            \\      F9 - Run/Continue
            \\      F10 - Reset
            \\      F12 - Screenshot
        ,
            .{},
        );
        return;
    }
    if (rl.isKeyPressed(rl.KeyboardKey.key_f5)) {
        system.mpu.registers.toLog();
        return;
    }
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
    if (rl.isKeyPressed(rl.KeyboardKey.key_f7)) {
        system.mpu.halt();
        return;
    }
    if (rl.isKeyPressed(rl.KeyboardKey.key_f8)) {
        system.mpu.step();
        return;
    }
    if (rl.isKeyPressed(rl.KeyboardKey.key_f9)) {
        system.mpu.run();
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
    const system_config = try config.from_file(allocator, args.config_file);

    // Initialise GDB
    var gdb: ?GDB = null;
    defer if (gdb) |*instance| {
        instance.deinit();
    };
    if (system_config.gdb) |gdb_config| {
        var gdb_instance = try GDB.init(allocator, gdb_config);
        try gdb_instance.waitForConnection();
        gdb = gdb_instance;
    }

    // Activate window
    rl.initWindow(system_config.video.width, system_config.video.height, "ZEMU6502 - Display");
    defer rl.closeWindow();
    //const shader = rl.loadShader(
    //    std.mem.sliceTo(system_config.video.shader.vert, 0),
    //    std.mem.sliceTo(system_config.video.shader.frag, 0),
    //);
    const shader = rl.loadShader("systems/scan.vert", "systems/scan.frag");
    defer rl.unloadShader(shader);

    // Create system and add devices defined in config.
    var system = try System.init(allocator, system_config.clockFreq);
    defer system.deinit();
    std.log.info("Initialised system @ {d}Hz", .{system_config.clockFreq});
    try createPeripherals(allocator, &system, system_config);
    system.reset();

    while (!rl.windowShouldClose()) {
        if (gdb) |*instance| {
            try instance.loop();
        }
        keyInput(&system);

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.beginShaderMode(shader);
        defer rl.endShaderMode();

        system.loop();
    }
}

test {
    // Work around because testing is ...
    std.testing.refAllDecls(@This());
}
