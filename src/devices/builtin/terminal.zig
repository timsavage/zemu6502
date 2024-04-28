//! Terminal peripheral device.

const std = @import("std");
const rl = @import("raylib");
const VideoConfig = @import("../../config.zig").VideoConfig;
const Peripheral = @import("../../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

const Self = @This();

width: i32,
height: i32,
scale: i32,
font_size: i32 = 10,
cursor_pos: usize = 0,
cursor_on: bool = true,
line_buffer: [24][40:0]u8 = undefined,

pub fn init(allocator: std.mem.Allocator, video_config: *const VideoConfig) !*Self {
    const instance = try allocator.create(Self);
    instance.* = .{
        .width = video_config.width,
        .height = video_config.height,
        .scale = video_config.scale,
    };
    instance.clear_buffers();
    return instance;
}

pub fn peripheral(self: *Self) Peripheral {
    return .{
        .ptr = self,
        .vtable = &.{
            .name = "Terminal",
            .description = "Video display text terminal.",
            .reset = reset,
            .loop = loop,
            .read = read,
            .write = write,
        },
    };
}

fn clear_buffers(self: *Self) void {
    // Zero all buffers
    for (0..self.line_buffer.len) |idx| {
        const line = &self.line_buffer[idx];
        @memset(line, 0);
    }
}

fn reset(ctx: *anyopaque) PeripheralError!void {
    const self: *Self = @ptrCast(@alignCast(ctx));
    self.clear_buffers();
    self.cursor_pos = 0;
}

fn loop(ctx: *anyopaque) PeripheralError!void {
    const self: *Self = @ptrCast(@alignCast(ctx));

    const font_size = self.font_size * self.scale;
    const offset = self.height;

    rl.clearBackground(rl.Color.black);
    for (1.., self.line_buffer) |row_number, line| {
        const slice = std.mem.sliceTo(&line, 0);
        const row: i32 = @intCast(row_number);
        rl.drawText(slice, 0, offset - (row * font_size), font_size, rl.Color.green);
    }
}

/// Read a value from a peripheral register.
fn read(_: *anyopaque, _: u16) PeripheralError!u8 {
    return PeripheralError.WriteOnly;
}

/// Write a value to a peripheral register.
fn write(ctx: *anyopaque, addr: u16, data: u8) PeripheralError!void {
    const self: *Self = @ptrCast(@alignCast(ctx));

    switch (addr) {
        0 => {
            switch (data) {
                '\n', '\r' => {
                    // Shift each line up
                    var idx = self.line_buffer.len - 1;
                    while (idx > 0) {
                        @memcpy(&self.line_buffer[idx], &self.line_buffer[idx - 1]);
                        idx -= 1;
                    }

                    // Clear current line.
                    @memset(&self.line_buffer[0], 0);
                    self.cursor_pos = 0;
                },
                else => {
                    if (self.cursor_pos < (self.line_buffer[0].len - 1)) {
                        self.line_buffer[0][self.cursor_pos] = data;
                        self.cursor_pos += 1;
                    }
                },
            }
        },
        1 => {
            // Cursor flag
            self.cursor_on = (data & 0x01) > 0;
        },
        else => return PeripheralError.AddressIndex,
    }
}
