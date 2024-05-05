#!/bin/env python3
"""Python emulator of GDB client."""

import asyncio
import logging
import readline
import sys

from pyapp.app import CliApplication

app = CliApplication()
log = logging.getLogger("gdb-6502")

ARCH = {
    "regs": ["ac", "xr", "yr", "sp", "pch", "pcl", "sr"],
    "endian": "little",
    "bit_size": 8,
}


def modulo256_sum(data: bytes) -> int:
    """Calculate the modulo 256 sum."""
    return sum(data) % 256


def parse_number(value):
    if value.startswith("0x"):
        base = 16
        value = value[2:]
    elif value.startswith("0o"):
        base = 8
        value = value[2:]
    else:
        base = 10

    return int(value, base)



class GDBClient:
    """GDB client."""

    def __init__(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        self.reader = reader
        self.writer = writer

        self._read_packet_iter = aiter(self._read_next_packet())

    async def send_packet(self, data: bytes):
        """Send data."""
        checksum = sum(data) % 256
        packet = b"$" + data + f"#{checksum:02X}".encode("ascii")
        self.writer.write(packet)
        log.debug("< %s", packet.decode("ascii"))


    async def _read_next_packet(self):
        """Read packet."""
        buffer = bytearray()
        while True:
            buffer.extend(await self.reader.read(1024))

            # Check for a valid packet
            if (start := buffer.find(b"$")) == -1:
                continue
            if (end := buffer.find(b"#")) == -1:
                continue
            packet_end = end + 3
            if len(buffer) < packet_end:
                continue

            # Extract the packet and checksum
            packet = buffer[start + 1:end]
            expected_sum = int(buffer[end + 1:end + 3], 16)
            del buffer[:packet_end]

            # Check the checksum and respond accordingly
            checksum = modulo256_sum(packet)
            if checksum != expected_sum:
                self.writer.write(b"-")
                continue
            self.writer.write(b"+")

            log.debug("> %s", packet.decode("ascii"))
            yield packet

    async def next_packet(self) -> bytes:
        """Read packet."""
        return await anext(self._read_packet_iter)

    async def get_state(self) -> str:
        """Read halt state"""
        await self.send_packet(b"?")
        packet = await self.next_packet()
        return packet.decode("ascii")

    async def get_registers(self) -> bytes:
        """Read registers."""
        await self.send_packet(b"g")
        packet = await self.next_packet()
        return bytes.fromhex(packet.decode("ascii"))

    async def get_memory(self, address: int, length: int = 1) -> bytes:
        """Read registers."""
        await self.send_packet(f"m{address:04X},{length:04X}".encode("ascii"))
        packet = await self.next_packet()
        return bytes.fromhex(packet.decode("ascii"))

    async def set_memory(self, address: int, data: bytes) -> bool:
        """Read registers."""
        await self.send_packet(f"M{address:04X},{len(data):04X}:{data.hex()}".encode("ascii"))
        packet = await self.next_packet()
        return packet == b'OK'

    async def send_reset(self):
        """Reset hardware."""
        await self.send_packet(b"r")

    @staticmethod
    def _decode_stop_response(packet: bytes):
        """Decode the stop response."""
        if packet[0] == b'S':
            return "Stopped", int(packet[1:3], 16)
        return packet.decode("ascii")

    async def send_stop(self):
        """Stop."""
        await self.send_packet(b"t")
        packet = await self.next_packet()
        return self._decode_stop_response(packet)

    async def send_step(self):
        """Step."""
        await self.send_packet(b"s")
        packet = await self.next_packet()
        return self._decode_stop_response(packet)

    async def send_continue(self):
        """Continue."""
        await self.send_packet(b"c")
        packet = await self.next_packet()
        return self._decode_stop_response(packet)

    async def list_peripherals(self):
        await self.send_packet(b"qPeripherals")
        packet = await self.next_packet()
        items = packet.decode("ascii").split(";")
        return [tuple(item.split(":")) for item in items]



async def parse_info(args, client: GDBClient):
    if not args:
        print("No info command")
        return

    args[0] = {
        "r": "registers",
        "reg": "registers",
        "p": "peripherals",
        "peri": "peripherals",
    }.get(args[0], args[0])

    match args:
        case ["registers"]:
            print("Registers")
            registers = await client.get_registers()

            def print_reg(name, in_slice):
                value = int(registers[in_slice])
                print(f"{name}: 0x{value:02X} ({value})")

            print_reg("AC", 0)
            print_reg("XR", 1)
            print_reg("YR", 2)
            print_reg("SP", 3)
            print(f"PC: 0x{registers[4:6].hex()}")
            print_reg("SP", 6)

        case ["peripherals"]:
            print("Peripherals")
            peripherals = await client.list_peripherals()
            for name, start_addr, end_addr in peripherals:
                print(f"{name}:\t{start_addr}:{end_addr}")

        case _:
            print("Unknown info command")


async def parse_examine(args, client: GDBClient):
    match args:
        case [addr]:
            address = int(addr, 16)
            memory = await client.get_memory(address, 1)
            print(memory.hex(":", 2))

        case [addr, ops]:
            address = int(addr, 16)
            length = int(ops)
            memory = await client.get_memory(address, length)
            print(memory.hex(":", 2))


async def parse_command(command: str, client: GDBClient):
    """Parse the command."""
    if not (atoms := command.split(" ")):
        return

    # Translate first command
    atoms[0] = {
        "q": "quit",
        "b": "break",
        "c": "continue",
        "cont": "continue",
        "s": "step",
        "i": "info",
        "x": "examine",
        "h": "halt",
        "r": "reset",
    }.get(atoms[0], atoms[0])

    match atoms:
        case ["help"]:
            print(
                "q|quit :          Quit app\n"
                "b|break :         Add breakpoint (not yet supported)\n"
                "c|cont|continue : Add breakpoint (not yet supported)\n"
                "s|step :          Step one instruction\n"
                "i|info :          Get info\n"
                "\tr|reg|registers : Get info on registers\n"
                "x|examine ADDR :  Examine memory at address ADDR (hex)\n"
                "x/n ADDR :        Example n bytes of memory from address ADDR (hex)\n"
                "set ADDR VALUE :  Set the value of an address (can accept 0x, 0o prefixes)\n"
                "h|halt :          Halt processor\n"
                "r|reset :         Reset the target system\n"
            )

        case ["break"]:
            print("Add Breakpoint")

        case ["halt"]:
            result = await client.send_stop()
            print(result)

        case ["continue"]:
            result = await client.send_continue()
            print(result)

        case ["step"]:
            result = await client.send_step()
            print(result)

        case ["set", addr, value]:
            try:
                addr = parse_number(addr)
                value = parse_number(value)
            except ValueError as ex:
                print("Invalid value:", ex)
            else:
                if await client.set_memory(addr, value.to_bytes()):
                    print("OK")
                else:
                    print("Failed to set memory")

        case ["reset"]:
            result = await client.send_reset()
            print(result)

        case ["info", *args]:
            await parse_info(args, client)

        case ["examine", *args]:
            await parse_examine(args, client)

        case ["quit"]:
            print("Quit")
            sys.exit(0)

        case _:
            if atoms[0].startswith("x/") and len(atoms) == 2:
                await parse_examine([atoms[1], atoms[0][2:]], client)
            else:
                print("Unknown command")


@app.command
async def target(*, address: str = "::1", port: int = 6502):
    reader, writer = await asyncio.open_connection(address, port)
    client = GDBClient(reader, writer)

    client.writer.write(b"+")
    print(await client.get_state())
    while True:
        try:
            cmd = input(">").strip()
        except EOFError:
            return

        try:
            await parse_command(cmd, client)
        except Exception as e:
            print(f"Error: {e}")



if __name__ == '__main__':
    app.dispatch()
