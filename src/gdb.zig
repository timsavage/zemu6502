const std = @import("std");
const net = std.net;
const posix = std.posix;

const GDBConfig = @import("config.zig").GDBConfig;
const PacketBuffer = @import("gdb/packet.zig").PacketBuffer;
const utils = @import("gdb/utils.zig");

const Self = @This();

server: net.Server,
connection: net.Server.Connection = undefined,
in: PacketBuffer,
out: PacketBuffer,

pub fn init(_: std.mem.Allocator, gdb_config: GDBConfig) !Self {
    const addr = try net.Address.parseIp4(gdb_config.address, gdb_config.port);
    return .{
        // .allocator = allocator,
        .in = PacketBuffer.init(),
        .out = PacketBuffer.init(),
        .server = try addr.listen(.{
            .kernel_backlog = 1,
            .reuse_address = true,
            // .force_nonblocking = true,
        }),
    };
}

pub fn deinit(self: *Self) void {
    self.server.deinit();
}

fn processQuery(self: *Self, packet: []const u8) !void {
    _ = packet;
    try self.write_packet("");
}

fn processVPacket(self: *Self, packet: []const u8) !void {
    if (std.mem.startsWith(u8, packet, "vMustReplyEmpty")) {
        try self.write_packet("");
    }
}

fn processPacket(self: *Self) !void {
    // Return if there is an incomplete packet
    const start = self.in.findFirstChar('$') catch return;
    const end = self.in.findFirstChar('#') catch return;
    const packet_end = end + 3; // End + checksum
    if (self.in.len < packet_end) return;

    const packet = try self.in.slice(start + 1, end);
    const checksum = utils.modulo256Sum(packet);
    const expectedSum = try std.fmt.parseUnsigned(
        u8,
        try self.in.slice(end + 1, end + 3),
        16,
    );

    // Packet good?
    if (checksum != expectedSum) {
        try self.out.append("-");
        return;
    }
    try self.out.append("+");

    std.log.debug("> {s}", .{try self.in.slice(0, packet_end)});
    switch (packet[0]) {
        '!' => {
            // Enable extended mode
            try self.write_packet("OK");
        },
        '?' => {
            // Query reason for halt
        },
        'A' => {},
        'g' => {},
        'q' => try self.processQuery(packet),
        'v' => try self.processVPacket(packet),
        else => {
            std.log.info("Unknown packet: {s}", .{packet});
            try self.write_packet("");
        },
    }

    self.in.removeHead(packet_end);
}

fn write_packet(self: *Self, data: []const u8) !void {
    const checksum = utils.modulo256Sum(data);
    try self.out.append("$");
    try self.out.append(data);
    try self.out.append("#");
    try self.out.append(&utils.hexDigits(checksum));
}

pub fn waitForConnection(self: *Self) !void {
    std.log.info("Waiting for connection on {}...", .{self.server.listen_address});
    self.connection = try self.server.accept();
    std.log.info("Connection from {}", .{self.connection.address});
}

pub fn loop(self: *Self) !void {
    var fds: [1]posix.pollfd = .{.{
        .fd = self.server.stream.handle,
        .events = posix.POLL.IN,
        .revents = undefined,
    }};
    const result = try posix.poll(&fds, 0);
    if (result >= 0) {
        var read_buffer: [4096]u8 = [_]u8{0} ** 4096;
        const read = try self.connection.stream.read(&read_buffer);
        if (read > 0) {
            try self.in.append(read_buffer[0..read]);
            try self.processPacket();
            if (self.out.len > 0) {
                try self.connection.stream.writeAll(self.out.asSlice());
                std.log.info("< {s}", .{self.out.asSlice()});
                self.out.clear();
            }
        }
    }
}

// test "Parse identify packet and validate checksum" {
//     var in = PacketBuffer.init();
//     var out = PacketBuffer.init();
//     try in.append("$qSupported:multiprocess+;swbreak+;hwbreak+;qRelocInsn+;fork-events+;vfork-events+;exec-events+;vContSupported+;QThreadEvents+;no-resumed+;memory-tagging+;xmlRegisters=i386#77");
//
//     const actual = processPacket(&in, &out);
//
//     try std.testing.expectEqual(true, actual);
//     try std.testing.expectEqual(0, in.len);
//     try std.testing.expectEqual(1, out.len);
//     try std.testing.expectEqualSlices(u8, "+", out.asSlice());
// }
