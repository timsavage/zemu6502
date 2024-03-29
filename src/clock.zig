//! System clock

const std = @import("std");
const MPU = @import("mpu.zig").MPU;

const Self = @This();

timer: std.time.Timer,
period: u64,
next: u64,
mpu: MPU,
edge: bool = true,

/// Initialise clock with a frequency in Hertz.
pub fn init(freq_hz: u64, mpu: MPU) !Self {
    // Period is halved to provide both rise and falling edges.
    const period = 500_000_000 / freq_hz;
    var timer = try std.time.Timer.start();
    return .{
        .timer = timer,
        .period = period,
        .next = timer.read() + period,
        .mpu = mpu,
    };
}

pub fn loop(self: *Self) void {
    if (self.timer.read() >= self.next) {
        self.next += self.period;
        self.mpu.clock(self.edge);
        self.edge = !self.edge;
    }
}
