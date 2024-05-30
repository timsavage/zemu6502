#!/bin/env python3
"""Python emulator of GDB client."""

import asyncio
import logging
import readline
import sys
from enum import Enum
from typing import NamedTuple
from pathlib import Path

import vasm
from pyapp.app import CliApplication

app = CliApplication()
log = logging.getLogger("gdb-6502")


class CommandError(RuntimeError):
    pass


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


class Peripheral(NamedTuple):
    name: str
    start_addr: int
    end_addr: int

    @classmethod
    def from_string(cls, string: str):
        name, start_addr, end_addr = string.split(":")
        return cls(name, int(start_addr, 16), int(end_addr, 16))

    def __str__(self):
        return f"{self.name}: {self.start_addr:04X}-{self.end_addr:04X}"


class StatusSignal(Enum):
    Running = 0x13
    Stopped = 0x11


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

    @staticmethod
    def _decode_stop_response(packet: bytes) -> tuple[int, int | None]:
        """Decode the stop response."""
        match packet[0:1]:
            case b"E":
                raise CommandError(packet[1:].decode("ascii"))
            case b'S':
                return int(packet[1:3], 16), None
            case b'T':
                return int(packet[1:3], 16), int(packet[6:10], 16)
            case _:
                raise CommandError(packet.decode("ascii"))

    async def get_state(self) -> tuple[int, int | None]:
        """Read halt state"""
        await self.send_packet(b"?")
        packet = await self.next_packet()
        return self._decode_stop_response(packet)

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

    async def send_stop(self) -> tuple[int, int | None]:
        """Stop."""
        await self.send_packet(b"t")
        packet = await self.next_packet()
        return self._decode_stop_response(packet)

    async def send_step(self) -> tuple[int, int | None]:
        """Step."""
        await self.send_packet(b"s")
        packet = await self.next_packet()
        return self._decode_stop_response(packet)

    async def send_continue(self) -> tuple[int, int | None]:
        """Continue."""
        await self.send_packet(b"c")
        packet = await self.next_packet()
        return self._decode_stop_response(packet)

    async def query_peripherals(self) -> list[Peripheral]:
        """Query peripherals."""
        await self.send_packet(b"qPeripherals")
        packet = await self.next_packet()
        items = packet.decode("ascii").split(";")
        return [Peripheral.from_string(item) for item in items]


class GDBTextInterface:
    def __init__(self, address: str, port: int = 6502):
        self.address = address
        self.port = port

        self.lst: vasm.AssemblyLst | None = None
        self._current_addr = 0

    async def run(self):
        reader, writer = await asyncio.open_connection(self.address, self.port)
        client = GDBClient(reader, writer)

        client.writer.write(b"+")
        print(await client.get_state())
        while True:
            try:
                cmd = input(">").strip()
            except EOFError:
                return

            try:
                await self.parse_command(cmd, client)
            except Exception:
                log.exception("Un-handled error")

    async def parse_command(self, command: str, client: GDBClient):
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
            "l": "bin-lst",
            "?": "help",
        }.get(atoms[0], atoms[0])

        match atoms:
            case ["help"]:
                print(
                    "q | quit               Quit app\n"
                    "b | break              Add breakpoint (not yet supported)\n"
                    "c | cont | continue    Add breakpoint (not yet supported)\n"
                    "s | step               Step one instruction\n"
                    "i | info               Get info\n"
                    "  r | reg | registers  Get info on registers\n"
                    "x|examine ADDR         Examine memory at address ADDR (hex)\n"
                    "x/n ADDR               Example n bytes of memory from address ADDR (hex)\n"
                    "set ADDR VALUE         Set the value of an address (can accept 0x, 0o prefixes)\n"
                    "h | halt               Halt processor\n"
                    "r | reset              Reset the target system\n"
                    "l | bin-lst            Load VASM lst file\n"
                )

            case ["break"]:
                print("Add Breakpoint")

            case ["halt"]:
                response = await client.send_stop()
                self._handle_status_response(response)

            case ["continue"]:
                response = await client.send_continue()
                self._handle_status_response(response)

            case ["step"]:
                response = await client.send_step()
                self._handle_status_response(response)

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
                await client.send_reset()

            case ["info", *args]:
                await self.parse_info(args, client)

            case ["examine", *args]:
                await self.parse_examine(args, client)

            case ["list", line_num]:
                line_num = parse_number(line_num)
                if not self._render_code(self.lst.get_source_block(line_num)):
                    print(f"No code matches line: {line_num:03d}")

            case ["bin-lst", file_name]:
                self.load_image(file_name)

            case ["quit"]:
                print("Quit")
                sys.exit(0)

            case _:
                if atoms[0].startswith("x/") and len(atoms) == 2:
                    await self.parse_examine([atoms[1], atoms[0][2:]], client)
                else:
                    print("Unknown command")

    def _handle_status_response(self, response: tuple[int, int | None]):
        """Render the code location."""
        status, address = response
        status = StatusSignal(status)

        if address is None:
            print(status.name)
        else:
            self._current_addr = address
            if self.lst:
                if not self._render_code(self.lst.get_source_block_from_addr(address)):
                    print(f"{status.name} @ address: 0x{address:04X}")

    async def parse_info(self, args, client: GDBClient):
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
                peripherals = await client.query_peripherals()
                print("\n".join(map(str, peripherals)))

            case ["line"]:
                address = self._current_addr
                if not self._render_code(self.lst.get_source_block_from_addr(address)):
                    print(f"No code matches address: 0x{address:04X}")

            case ["line", address]:
                address = parse_number(address)
                if not self._render_code(self.lst.get_source_block_from_addr(address)):
                    print(f"No code matches address: 0x{address:04X}")

            case _:
                print("Unknown info command")

    async def parse_examine(self, args, client: GDBClient):
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

    def load_image(self, file_name: Path | str):
        """Load image file."""
        try:
            with Path(file_name).open("r") as f_in:
                self.lst = vasm.AssemblyLstParser(f_in).parse()
        except FileNotFoundError:
            print("File not found: ", file_name)

    def _render_code(self, block: vasm.SourceBlock) -> bool:
        """Render the code block."""
        if self.lst:
            before, source, after = block
            if source:
                if before:
                    print("\n".join(f"  {num:3d}: {line}" for num, line in before))
                print(f"> {source[0]:3d}: {source[1]}")
                if after:
                    print("\n".join(f"  {num:3d}: {line}" for num, line in after))
                return True
        else:
            print("! No source loaded")

        return False


@app.command
async def target(*, address: str = "::1", port: int = 6502, image_lst: Path = None):
    """Run the GDB client."""
    interface = GDBTextInterface(address, port)
    if image_lst:
        interface.load_image(image_lst)
    await interface.run()


if __name__ == '__main__':
    app.dispatch()
