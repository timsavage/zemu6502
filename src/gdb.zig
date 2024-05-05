//! GDB server for the 6502 emulator.
const std = @import("std");
const net = std.net;
const posix = std.posix;

const System = @import("system.zig");
const RunMode = @import("6502/mpu.zig").RunMode;
const BufferError = @import("gdb/packet.zig").BufferError;
const PacketBuffer = @import("gdb/packet.zig").PacketBuffer;
const Packet = @import("gdb/packet.zig").Packet;
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

// Process a Query (q) packet
fn processQuery(self: *Self, system: *System, packet: Packet) !void {
    if (packet.startsWith("qPeripherals")) {
        const start = try self.start_packet();
        for (system.data_bus.peripherals.items) |item| {
            try self.out.append(item.peripheral.vtable.name);
            try self.out.append(":");
            try self.out.append(&utils.hexDigits(@truncate(item.start >> 8)));
            try self.out.append(&utils.hexDigits(@truncate(item.start)));
            try self.out.append(":");
            try self.out.append(&utils.hexDigits(@truncate(item.end >> 8)));
            try self.out.append(&utils.hexDigits(@truncate(item.end)));
            try self.out.append(";");
        }
        self.out.len -= 1; // Remove last final separator.
        try self.end_packet(start);
    } else {
        // std.log.debug("Unknown query: {s}", .{packet.data});
        try self.write_packet("");
    }
}

fn processPacket(self: *Self, system: *System) !void {
    // Return if there is an incomplete packet
    const start = self.in.indexOf('$') catch return;
    const end = self.in.indexOf('#') catch return;
    const packet_end = end + 3; // End + checksum
    if (self.in.len < packet_end) return;

    const packet = try self.in.packet(start + 1, end);
    const checksum = packet.checksum();
    const expectedSum = try std.fmt.parseUnsigned(u8, self.in.data[(end + 1)..(end + 3)], 16);

    // Packet good?
    if (checksum != expectedSum) {
        try self.write_packet("E01");
        return;
    }
    try self.out.append("+");

    std.log.debug("[GDB] > {s}", .{packet.data});
    switch (packet.data[0]) {
        '?' => {
            // Halt reason
            switch (system.mpu.mode) {
                RunMode.Run => try self.write_packet("S13"),
                RunMode.Halt => try self.write_packet("S11"),
                RunMode.RunInstruction => try self.write_packet("S11"),
            }
        },
        'g' => {
            const packet_start = try self.start_packet();
            try self.out.appendByte(system.mpu.registers.ac);
            try self.out.appendByte(system.mpu.registers.xr);
            try self.out.appendByte(system.mpu.registers.yr);
            try self.out.appendByte(system.mpu.registers.sp);
            try self.out.appendWord(system.mpu.registers.pc);
            try self.out.appendByte(@bitCast(system.mpu.registers.sr));
            try self.end_packet(packet_start);
        },
        'G' => {
            // Write registers
            // TODO: Write registers!
        },
        'm' => {
            // Read memory
            if (packet.data.len >= 10) {
                var addr = try packet.hexWordAt(1);
                var length = try packet.hexWordAt(6);

                // Calculate length with overflow check.
                const addr_end = std.math.add(u16, addr, length) catch std.math.maxInt(u16);
                length = addr_end - addr;

                const packet_start = try self.start_packet();
                for (0..length) |_| {
                    try self.out.appendByte(system.data_bus.read(addr));
                    addr += 1;
                }
                try self.end_packet(packet_start);
            } else {
                std.log.warn("[GDB] Bad packet: {s}", .{packet.data});
                try self.write_packet("E02");
            }
        },
        'M' => {
            // Write memory
            if (packet.data.len >= 10) {
                var addr = try packet.hexWordAt(1);
                var length = try packet.hexWordAt(6);

                // Calculate length with overflow check.
                const addr_end = std.math.add(u16, addr, length) catch std.math.maxInt(u16);
                length = addr_end - addr;

                for (0..length) |idx| {
                    system.data_bus.write(addr, try packet.hexByteAt(11 + (idx * 2)));
                    addr += 1;
                }

                try self.write_packet("OK");
            } else {
                std.log.warn("[GDB] Bad packet: {s}", .{packet.data});
                try self.write_packet("E03");
            }
        },
        'c' => {
            system.mpu.run();
            try self.write_packet("S13"); // 0x13 (19)
        },
        's' => {
            system.mpu.step();
            const packet_start = try self.start_packet();
            try self.out.append("T1104:");
            try self.out.appendWord(system.mpu.registers.pc);
            try self.end_packet(packet_start);
        },
        't' => {
            system.mpu.halt();
            const packet_start = try self.start_packet();
            try self.out.append("T1104:");
            try self.out.appendWord(system.mpu.registers.pc);
            try self.end_packet(packet_start);
        },
        'r', 'R' => system.reset(),
        'q' => try self.processQuery(system, packet),
        else => {
            std.log.info("[GDB] Unknown packet: {s}", .{packet.data});
            try self.write_packet("");
        },
    }

    self.in.removeHead(packet_end);
}

fn start_packet(self: *Self) !usize {
    try self.out.append("$");
    return self.out.len;
}

fn end_packet(self: *Self, start: usize) !void {
    const checksum = utils.modulo256Sum(self.out.data[start..self.out.len]);
    try self.out.append("#");
    try self.out.append(&utils.hexDigits(checksum));
}

fn write_packet(self: *Self, data: []const u8) !void {
    const start = try self.start_packet();
    try self.out.append(data);
    try self.end_packet(start);
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
            self.processPacket(system) catch |err| switch (err) {
                BufferError.CharNotFound, BufferError.InvalidCharacter => {
                    std.log.warn("[GDB] Invalid packet", .{});
                    try self.write_packet("E04");
                },
                BufferError.Overflow => {
                    std.log.err("[GDB] Unable to process packet", .{});
                    try self.write_packet("E05");
                },
                else => return err,
            };

            // Write out anything in the output buffer.
            if (self.out.len > 0) {
                try connection.stream.writeAll(&self.out.data);
                std.log.debug("[GDB] < {s}", .{self.out.data});
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
