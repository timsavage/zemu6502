const std = @import("std");
const System = @import("system.zig");
const Clock = @import("clock.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() == std.heap.Check.leak) {
            std.log.warn("Memory leak detected.", .{});
        }
    }

    var system = try System.init(allocator, 1_000_000);
    defer system.deinit();
    try system.addPeripherals();

    // Load inititial rom bin
    const file = try std.fs.cwd().openFile("init.rom.bin", .{});
    try system.rom.load_file(file);

    while (true) {
        system.loop();
    }
}

test {
    // Work around because testing is ...
    std.testing.refAllDecls(@This());
}
