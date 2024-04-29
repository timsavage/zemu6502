const std = @import("std");
const net = std.net;
const posix = std.posix;

const GDBConfig = @import("config.zig").GDBConfig;
const PacketBuffer = @import("gdb/packet.zig").PacketBuffer;
const processPacket = @import("gdb/parser.zig").processPacket;
const Self = @This();

// allocator: std.mem.Allocator,

server: net.Server,
connection: net.Server.Connection = undefined,
buffer: PacketBuffer,

pub fn init(_: std.mem.Allocator, gdb_config: GDBConfig) !Self {
    const addr = try net.Address.parseIp4(gdb_config.address, gdb_config.port);
    return .{
        // .allocator = allocator,
        .buffer = PacketBuffer.init(),
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
            try self.buffer.insert(read_buffer[0..read]);
            if (try processPacket(&self.buffer)) {
                _ = try self.connection.stream.write("+$#00");
            }
        }
    }
}
