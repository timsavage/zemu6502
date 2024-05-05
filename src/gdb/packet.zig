const std = @import("std");
const utils = @import("./utils.zig");

const PACKET_BUFFER_SIZE: usize = 0x8000;

pub const BufferError = error{
    Overflow,
    CharNotFound,
    InvalidCharacter,
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

    // Get a packet wrapper over a slice of the input buffer.
    pub inline fn packet(self: PacketBuffer, start: usize, end: usize) !Packet {
        return .{ .data = self.data[start..end] };
    }

    // Append data to the buffer
    pub fn append(self: *PacketBuffer, data: []const u8) BufferError!void {
        if (self.len + data.len >= self.data.len) {
            return BufferError.Overflow;
        }
        @memcpy(self.data[self.len..(self.len + data.len)], data);
        self.len += data.len;
    }

    // Append byte as encoded hex to the buffer
    pub inline fn appendByte(self: *PacketBuffer, value: u8) BufferError!void {
        return self.append(&utils.hexDigits(value));
    }

    // Append word as encoded hex to the buffer
    pub inline fn appendWord(self: *PacketBuffer, value: u16) BufferError!void {
        try self.append(&utils.hexDigits(@truncate(value >> 8)));
        return self.append(&utils.hexDigits(@truncate(value)));
    }

    // Append bytes as encoded hex to the buffer
    pub fn appendBytes(self: *PacketBuffer, data: []const u8) BufferError!void {
        const written = std.fmt.bufPrint(
            self.data[self.len..],
            "{}",
            .{std.fmt.fmtSliceHexUpper(data)},
        ) catch {
            return BufferError.Overflow;
        };
        self.len += written.len;
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

    pub inline fn indexOf(self: *PacketBuffer, value: u8) BufferError!usize {
        if (std.mem.indexOfScalar(u8, &self.data, value)) |result| return result;
        return BufferError.CharNotFound;
    }

    pub inline fn indexOfPos(self: *PacketBuffer, value: u8, start_index: usize) BufferError!usize {
        if (std.mem.indexOfScalarPos(u8, &self.data, start_index, value)) |result| return result;
        return BufferError.CharNotFound;
    }

    /// Partition off the start of the buffer up to a specified character.
    /// Returns true if character was found.
    pub fn partionBy(self: *PacketBuffer, char: u8) bool {
        const start_idx = self.indexOf(char) catch {
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

/// Reference to packet within packet buffer.
/// Note this struct is valid only when
pub const Packet = struct {
    data: []const u8,

    fn create(data: []const u8) Packet {
        return .{
            .data = data,
        };
    }

    pub inline fn indexOf(self: Packet, value: u8) !usize {
        if (std.mem.indexOfScalar(u8, self.data, value)) |result| return result;
        return BufferError.CharNotFound;
    }

    pub inline fn indexOfPos(self: Packet, value: u8, start_index: usize) !usize {
        if (std.mem.indexOfScalarPos(u8, self.data, start_index, value)) |result| return result;
        return BufferError.CharNotFound;
    }

    pub inline fn startsWith(self: Packet, value: []const u8) bool {
        return std.mem.startsWith(u8, self.data, value);
    }

    pub inline fn hexByteAt(self: Packet, index: usize) !u8 {
        const byte = self.data[index .. index + 2];
        return std.fmt.parseUnsigned(u8, byte, 16) catch |err| switch (err) {
            error.InvalidCharacter => return BufferError.InvalidCharacter,
            else => return err,
        };
    }

    pub inline fn hexWordAt(self: Packet, index: usize) !u16 {
        const word = self.data[index .. index + 4];
        return std.fmt.parseUnsigned(u16, word, 16) catch |err| switch (err) {
            error.InvalidCharacter => return BufferError.InvalidCharacter,
            else => return err,
        };
    }

    pub inline fn checksum(self: Packet) u8 {
        return utils.modulo256Sum(self.data);
    }
};
