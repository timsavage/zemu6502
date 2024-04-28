const std = @import("std");
const PacketBuffer = @import("./packet.zig").PacketBuffer;

const Token = enum(u8) {
    StartPacket = '$',
    CheckSum = '#',
    Ack = '+',
    Nak = '-',
};

inline fn escape_char(char: u8) [2]u8 {
    return .{ 0x7d, char ^ 0x20 };
}

inline fn rle_char(char: u8, n: u8) [3]u8 {
    return .{ char, '*', n + 29 };
}

/// Calculate the checksum of the buffer.
inline fn modulo256Sum(buffer: []const u8) u8 {
    var sum: u8 = 0;
    for (buffer) |c| {
        sum = @addWithOverflow(sum, c).@"0";
    }
    return sum;
}

test "modulo256Sum of $qSupported:multiprocess+;swbreak+;hwbreak+;qRelocInsn+;fork-events+;vfork-events+;exec-events+;vContSupported+;QThreadEvents+;no-resumed+;memory-tagging+;xmlRegisters=i386#77" {
    const actual = modulo256Sum("qSupported:multiprocess+;swbreak+;hwbreak+;qRelocInsn+;fork-events+;vfork-events+;exec-events+;vContSupported+;QThreadEvents+;no-resumed+;memory-tagging+;xmlRegisters=i386");

    try std.testing.expectEqual(0x77, actual);
}

fn process_packet(buffer: *PacketBuffer) !bool {
    const end = buffer.findFirstChar('#') catch {
        // Packet not complete.
        return false;
    };
    const packet_len = end + 3; // End + checksum
    if (buffer.len < packet_len) {
        // Packet missing checksum.
        return false;
    }
    const packet = try buffer.slice(1, end);
    const checksum = modulo256Sum(packet);
    const expectedSum = try std.fmt.parseUnsigned(
        u8,
        try buffer.slice(end + 1, end + 3),
        16,
    );
    if (checksum != expectedSum) {
        return false;
    }

    // switch (packet[0]) {
    //
    // }

    buffer.removeHead(packet_len);
    return true;
}

test "Parse identify packet and validate checksum" {
    var buffer = PacketBuffer.init();
    try buffer.insert("$qSupported:multiprocess+;swbreak+;hwbreak+;qRelocInsn+;fork-events+;vfork-events+;exec-events+;vContSupported+;QThreadEvents+;no-resumed+;memory-tagging+;xmlRegisters=i386#77");

    const actual = process_packet(&buffer);

    try std.testing.expectEqual(true, actual);
    try std.testing.expectEqual(0, buffer.len);
}
