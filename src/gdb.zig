const std = @import("std");
const net = std.net;
const GDBConfig = @import("config.zig").GDBConfig;

const Self = @This();

server: net.Server,
connection: net.Server.Connection = undefined,
buffer: [0xFF]u8 = [_]u8{0} ** 0xFF,
buffer_cursor: usize = 0,

pub fn init(gdb_config: GDBConfig) !Self {
    const addr = try net.Address.parseIp4(gdb_config.address, gdb_config.port);
    return .{
        .server = try addr.listen(.{
            .reuse_address = true,
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
    const read = try self.connection.stream.read(&self.buffer);
    std.debug.print("{}: {s}", .{ read, self.buffer });
}
