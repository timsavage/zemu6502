const std = @import("std");
const rl = @import("raylib");
const config = @import("config.zig");
const devices = @import("devices.zig");
const System = @import("system.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const std_options = .{
    // Set default log level to info.
    .log_level = .info,
};

/// Stupidly simple command line arguments
const Args = struct {
    config_file: []const u8,
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
        const peripheral = try devices.createDevice(allocator, &bus_address_config.peripheral, &system_config);
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

    // Activate window
    rl.initWindow(system_config.video.width, system_config.video.height, "ZEMU6502 - Display");
    defer rl.closeWindow();

    // Create system and add devices defined in config.
    var system = try System.init(allocator, system_config.clockFreq);
    defer system.deinit();
    std.log.info("Initialised system @ {d}Hz", .{system_config.clockFreq});
    try createPeripherals(allocator, &system, system_config);

    // Reset the system into a known running state.
    system.reset();

    while (!rl.windowShouldClose()) {
        switch (rl.getKeyPressed()) {
            rl.KeyboardKey.key_f1 => {
                std.log.info(
                    \\F1 - This help
                    \\      F6 - Dump registers
                    \\      F7 - Halt at next instruction
                    \\      F8 - Step one instruction
                    \\      F9 - Run/Continue
                    \\      F10 - Reset
                    \\      F12 - Screenshot
                ,
                    .{},
                );
            },
            rl.KeyboardKey.key_f6 => {
                system.mpu.registers.toLog();
            },
            rl.KeyboardKey.key_f7 => {
                system.mpu.halt();
            },
            rl.KeyboardKey.key_f8 => {
                system.mpu.step();
            },
            rl.KeyboardKey.key_f9 => {
                system.mpu.run();
            },
            rl.KeyboardKey.key_f10 => {
                std.log.info("Reset...", .{});
                system.reset();
            },
            else => {},
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        if (rl.isKeyPressed(rl.KeyboardKey.key_f6)) {
            std.log.info("Reset...", .{});
            system.mpu.reset();
        } else if (rl.isKeyPressed(rl.KeyboardKey.key_f7)) {
            // Dump Status Register
            system.mpu.registers.toLog();
            system.mpu.registers.sr.toLog();
        }

        system.loop();
    }
}

test {
    // Work around because testing is ...
    std.testing.refAllDecls(@This());
}
