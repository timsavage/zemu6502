const std = @import("std");
const mpu = @import("mpu.zig");
const System = @import("system.zig");
const posix = std.posix;

pub fn main() !void {
    var system = System.init();
    var core_mpu = mpu.MPU{ .data_bus = system.peripheral() };

    // Load inititial rom bin
    const file = try std.fs.cwd().openFile("init.rom.bin", .{});
    try system.rom.load_file(file);

    while (true) {
        core_mpu.clock();
    }
}

test {
    // Work around because testing is ...
    std.testing.refAllDecls(@This());
}