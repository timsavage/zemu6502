const std = @import("std");
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

    // Create system and add devices defined in config.
    var system = try System.init(allocator, system_config.clockFreq);
    defer system.deinit();
    std.log.info(
        "Initialised system @ {d}Hz",
        .{system_config.clockFreq},
    );

    // Add peripherals to the system.
    for (system_config.dataBus) |bus_address_config| {
        const peripheral = try devices.createDevice(allocator, &bus_address_config.peripheral);
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

    // Reset the system into a known running state.
    system.reset();

    while (true) {
        system.loop();
    }
}

test {
    // Work around because testing is ...
    std.testing.refAllDecls(@This());
}
