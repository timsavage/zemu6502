const std = @import("std");

const PACKET_BUFFER_SIZE: usize = 0x8000;

const BufferError = error{
    Overflow,
    CharNotFound,
};

/// Buffer for handing input data stream.
pub const PacketBuffer = struct {
    data: [PACKET_BUFFER_SIZE]u8,
    len: usize,

    pub fn init() PacketBuffer {
        return .{
            .data = undefined,
            .len = 0,
        };
    }

    /// Slice of the netire active range.
    pub inline fn asSlice(self: PacketBuffer) []const u8 {
        return self.data[0..self.len];
    }

    pub fn append(self: *PacketBuffer, data: []const u8) BufferError!void {
        if (self.len + data.len >= self.data.len) {
            return BufferError.Overflow;
        }
        @memcpy(self.data[self.len..(self.len + data.len)], data);
        self.len += data.len;
    }

    pub fn removeHead(self: *PacketBuffer, size: usize) void {
        std.mem.copyForwards(
            u8,
            self.data[0 .. self.len - size],
            self.data[size..self.len],
        );
        self.len -= size;
    }

    pub fn clear(self: *PacketBuffer) void {
        self.len = 0;
    }

    pub fn findFirstChar(self: PacketBuffer, char: u8) BufferError!usize {
        for (0..self.len) |idx| {
            if (self.data[idx] == char) {
                return idx;
            }
        }
        return BufferError.CharNotFound;
    }

    /// Partition off the start of the buffer up to a specified character.
    /// Returns true if character was found.
    pub fn partionBy(self: *PacketBuffer, char: u8) bool {
        const start_idx = self.findFirstChar(char) catch {
            self.clear();
            return false;
        };

        self.removeHead(start_idx);
        return true;
    }
};

test "Append into buffer and slice matches." {
    var buffer = PacketBuffer.init();

    try buffer.append(&[_]u8{ 1, 2, 3 });
    try buffer.append(&[_]u8{ 4, 5, 6 });

    try std.testing.expectEqual(6, buffer.len);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2, 3, 4, 5, 6 }, buffer.asSlice());
}

test "Insert returns Overflow if to full." {
    var buffer = PacketBuffer.init();
    const large: [PACKET_BUFFER_SIZE - 1]u8 = [_]u8{0} ** (PACKET_BUFFER_SIZE - 1);

    try buffer.append(&large);

    const actual = buffer.append(&[_]u8{ 0xDE, 0xAD });

    try std.testing.expectError(BufferError.Overflow, actual);
}

test "Remove from buffer and slice matches." {
    var buffer = PacketBuffer.init();
    try buffer.append(&[_]u8{ 1, 2, 3, 4, 5, 6 });

    buffer.removeHead(2);

    try std.testing.expectEqual(4, buffer.len);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 3, 4, 5, 6 }, buffer.asSlice());
}

test "Partition by removes head of buffer." {
    var buffer = PacketBuffer.init();
    try buffer.append(&[_]u8{ 1, 2, 3, 4, 5, 6, '$', 3, 2, 1 });

    const actual = buffer.partionBy('$');

    try std.testing.expectEqual(actual, true);
    try std.testing.expectEqualSlices(u8, &[_]u8{ '$', 3, 2, 1 }, buffer.asSlice());
}
