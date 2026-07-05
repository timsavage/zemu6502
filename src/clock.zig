//! System clock

const std = @import("std");
const MPU = @import("6502.zig").MPU;

const Self = @This();
const NANOSECONDS_PER_HALF_SECOND = 500_000_000;

const clock = std.Io.Clock.awake;

io: std.Io,
period: std.Io.Duration,
next: std.Io.Timestamp,
mpu: *MPU,
running: bool = true,
edge: bool = true,

/// Initialise clock with a frequency in Hertz.
pub fn init(io: std.Io, freq_hz: u64, mpu: *MPU) !Self {
    // Period is halved to provide both rising and falling edges.
    const period = std.Io.Duration.fromNanoseconds(NANOSECONDS_PER_HALF_SECOND / freq_hz);
    return .{
        .io = io,
        .period = period,
        .next = clock.now(io).addDuration(period),
        .mpu = mpu,
    };
}

/// Call from main run loop
pub fn loop(self: *Self) void {
    if (self.next.untilNow(self.io, clock).nanoseconds <= 0) {
        self.next = self.next.addDuration(self.period);
        self.mpu.clock(self.edge);
        self.edge = !self.edge;
    }
}

/// Start a stopped timer.
pub fn start(self: *Self) void {
    self.running = true;
    self.next = clock.now(self.io);
}

/// Stop the timer from running
pub fn stop(self: *Self) void {
    self.running = false;
}

/// Step the clock (ignored if running).
/// This will generate two clock signals both positive and negative edges.
pub fn step(self: *Self) void {
    if (!self.running) {
        self.mpu.clock(self.edge);
        self.mpu.clock(!self.edge);
    }
}

/// Get the current frequency.
pub fn freq(self: *Self) u64 {
    return NANOSECONDS_PER_HALF_SECOND / self.period;
}

/// Set the frequency.
pub fn setFreq(self: *Self, freq_ns: u64) void {
    self.period = NANOSECONDS_PER_HALF_SECOND / freq_ns;
}

/// Get the running state of the timer.
pub fn isRunning(self: *Self) bool {
    return self.running;
}
