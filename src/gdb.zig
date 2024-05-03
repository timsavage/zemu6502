const std = @import("std");
const net = std.net;
const posix = std.posix;

const System = @import("system.zig");
const RunMode = @import("6502/mpu.zig").RunMode;
const PacketBuffer = @import("gdb/packet.zig").PacketBuffer;
const utils = @import("gdb/utils.zig");

const Self = @This();

allocator: std.mem.Allocator,

// Listener and single connection.
server: net.Server,
connection: ?net.Server.Connection = null,

// Buffers
in: PacketBuffer,
out: PacketBuffer,

/// Initialise server and start listening for connections
pub fn init(allocator: std.mem.Allocator, address: net.Address) !Self {
    std.log.info("Waiting for GDB connection on {}...", .{address});
    return .{
        .allocator = allocator,
        .server = try address.listen(.{
            .kernel_backlog = 1, // Only allow a single connection at a time.
            .reuse_address = true,
        }),
        .in = PacketBuffer.init(),
        .out = PacketBuffer.init(),
    };
}

pub fn deinit(self: *Self) void {
    std.log.info("Shutting down GDB server...", .{});

    if (self.connection) |connection| connection.stream.close();
    self.server.deinit();
}

fn processPacket(self: *Self, system: *System) !void {
    // Return if there is an incomplete packet
    const start = self.in.findFirstChar('$') catch return;
    const end = self.in.findFirstChar('#') catch return;
    const packet_end = end + 3; // End + checksum
    if (self.in.len < packet_end) return;

    const packet = self.in.data[(start + 1)..end];
    const checksum = utils.modulo256Sum(packet);
    const expectedSum = try std.fmt.parseUnsigned(u8, self.in.data[(end + 1)..(end + 3)], 16);

    // Packet good?
    if (checksum != expectedSum) {
        try self.out.append("-");
        return;
    }
    try self.out.append("+");

    std.log.debug("[GDB] > {s}", .{packet});
    switch (packet[0]) {
        '?' => {
            // Halt reason
            switch (system.mpu.mode) {
                RunMode.Run => try self.write_packet("S13"),
                RunMode.Halt => try self.write_packet("S11"),
                RunMode.RunInstruction => try self.write_packet("S11"),
            }
        },
        'g' => {
            // Read registers
            const registers: [7]u8 = .{
                system.mpu.registers.ac,
                system.mpu.registers.xr,
                system.mpu.registers.yr,
                system.mpu.registers.sp,
                @truncate(system.mpu.registers.pc >> 8),
                @truncate(system.mpu.registers.pc),
                @bitCast(system.mpu.registers.sr),
            };
            const out = std.fmt.bytesToHex(registers, std.fmt.Case.upper);
            try self.write_packet(&out);
        },
        'G' => {
            // Write registers
        },
        'm' => {
            // Read memory
            if (packet.len >= 8) {
                const addr = try std.fmt.parseInt(u16, packet[1..5], 16);
                const length = try std.fmt.parseInt(u16, packet[6..], 16);
                const data = try self.allocator.alloc(u8, length);
                defer self.allocator.free(data);
                for (0..length) |idx| {
                    const offset: u16 = @truncate(idx);
                    data[idx] = system.data_bus.read(addr + offset);
                }
                try self.write_binary_packet(data);
            } else {
                std.log.warn("[GDB] Ignoring bad packet: {s}", .{packet});
            }
        },
        'M' => {
            // Write memory
            // TODO: Write memory!
            try self.write_packet("OK");
        },
        'c' => {
            system.mpu.run();
            try self.write_packet("S13"); // 0x13 (19)
        },
        's' => {
            system.mpu.step();
            try self.write_packet("S11"); // 0x11 (17)
        },
        't' => {
            system.mpu.halt();
            try self.write_packet("S11"); // 0x11 (17)
        },
        'r', 'R' => {
            system.reset();
        },
        else => {
            std.log.info("[GDB] Unknown packet: {s}", .{packet});
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

fn write_binary_packet(self: *Self, data: []const u8) !void {
    const bytes = try self.allocator.alloc(u8, data.len * 2);
    defer self.allocator.free(bytes);
    _ = try std.fmt.bufPrint(bytes, "{}", .{std.fmt.fmtSliceHexUpper(data)});

    const checksum = utils.modulo256Sum(bytes);
    try self.out.append("$");
    try self.out.append(bytes);
    try self.out.append("#");
    try self.out.append(&utils.hexDigits(checksum));
}

/// Check for an incoming connection.
pub fn checkConnection(self: *Self) !void {
    var fds: [1]posix.pollfd = .{.{
        .fd = self.server.stream.handle,
        .events = posix.POLL.IN,
        .revents = undefined,
    }};
    const result = try posix.poll(&fds, 0);
    if (result >= 0 and fds[0].revents > 0) {
        const connection = try self.server.accept();
        std.log.info("[GDB] Connection from {}", .{connection.address});
        self.connection = connection;
    }
}

/// Check for incoming data and process response.
pub fn pollData(self: *Self, connection: net.Server.Connection, system: *System) !void {
    var fds: [1]posix.pollfd = .{.{
        .fd = connection.stream.handle,
        .events = posix.POLL.IN,
        .revents = undefined,
    }};
    const result = try posix.poll(&fds, 0);
    if (result >= 0 and fds[0].revents > 0) {
        var read_buffer: [4096]u8 = [_]u8{0} ** 4096;
        const read = try connection.stream.read(&read_buffer);
        if (read == 0) {
            // Connection closed
            std.log.info("[GDB] Connection closed.", .{});
            self.connection = null;
        } else {
            try self.in.append(read_buffer[0..read]);
            try self.processPacket(system);

            // Write out anything in the output buffer.
            if (self.out.len > 0) {
                try connection.stream.writeAll(self.out.asSlice());
                std.log.debug("[GDB] < {s}", .{self.out.asSlice()});
                self.out.clear();
            }
        }
    }
}

/// Loop handler, poll for any events and respond if required.
pub fn loop(self: *Self, system: *System) !void {
    if (self.connection) |connection| {
        try self.pollData(connection, system);
    } else {
        try self.checkConnection();
    }
}
