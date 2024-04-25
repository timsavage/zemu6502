//! Terminal peripheral device.

const std = @import("std");
const rl = @import("raylib");
const Peripheral = @import("../../peripheral.zig");
const PeripheralError = Peripheral.PeripheralError;

const Self = @This();

cursor_pos: usize = 0,
character_buffer: [24][40:0]u8 = undefined,

pub fn init(allocator: std.mem.Allocator) !*Self {
    const instance = try allocator.create(Self);
    instance.* = .{};
    return instance;
}

pub fn peripheral(self: *Self) Peripheral {
    return .{
        .ptr = self,
        .vtable = &.{
            .name = "Terminal",
            .description = "Video display text terminal.",
            .loop = loop,
            .read = read,
            .write = write,
        },
    };
}

fn loop(ctx: *anyopaque) PeripheralError!void {
    const self: *Self = @ptrCast(@alignCast(ctx));

    rl.clearBackground(rl.Color.black);
    for (1.., self.character_buffer) |row_number, line| {
        const slice = std.mem.sliceTo(&line, 0);
        const row: i32 = @intCast(row_number);
        rl.drawText(slice, 0, 480 - (row * 20), 20, rl.Color.green);
    }
}

/// Read a value from a peripheral register.
fn read(_: *anyopaque, _: u16) PeripheralError!u8 {
    return PeripheralError.WriteOnly;
}

/// Write a value to a peripheral register.
fn write(ctx: *anyopaque, addr: u16, data: u8) PeripheralError!void {
    switch (addr) {
        0 => {
            const self: *Self = @ptrCast(@alignCast(ctx));

            if (data == '\n') {
                // Shift each line up
                var idx = self.character_buffer.len - 1;
                while (idx > 0) {
                    @memcpy(&self.character_buffer[idx], &self.character_buffer[idx - 1]);
                    idx -= 1;
                }

                // Clear current line.
                @memset(&self.character_buffer[0], 0);
                self.cursor_pos = 0;
            } else {
                if (self.cursor_pos < self.character_buffer[0].len) {
                    self.character_buffer[0][self.cursor_pos] = data;
                    self.cursor_pos += 1;
                }
            }
        },
        else => return PeripheralError.AddressIndex,
    }
}
