const std = @import("std");
const mpu = @import("mpu.zig");
const System = @import("system.zig");
const Clock = @import("clock.zig");
const posix = std.posix;

pub fn main() !void {
    var system = System.init();
    const core_mpu = mpu.MPU{ .data_bus = system.peripheral() };
    var clock = try Clock.init(10_000, core_mpu);

    // Load inititial rom bin
    const file = try std.fs.cwd().openFile("init.rom.bin", .{});
    try system.rom.load_file(file);

    while (true) {
        clock.loop();
    }
}

test {
    // Work around because testing is ...
    std.testing.refAllDecls(@This());
}
