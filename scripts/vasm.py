"""Parsers for VASM outputs"""

import logging
from collections import defaultdict
from enum import Enum
from typing import TextIO, NamedTuple

log = logging.getLogger("vasm")


class Section(Enum):
    SECTIONS = "Sections"
    SOURCE = "Source"
    SYMBOLS_BY_NAME = "Symbols by name"
    SYMBOLS_BY_VALUE = "Symbols by value"


class AssemblyLstParser:
    """Parse a VASM lst file."""

    def __init__(self, file: TextIO):
        """Initialise the AssemblyLstParser instance."""

        self.file = file

        self.result = AssemblyLst()
        self.section = None
        self.arg = None

    def parse(self) -> "AssemblyLst":
        """Parse the file."""
        self.section = None

        for line in self.file:
            line = line.rstrip()

            # Empty line ends a section
            if not line:
                self.section = None
                continue

            if self.section:
                {
                    Section.SECTIONS: self.parse_sections,
                    Section.SOURCE: self.parse_source,
                    Section.SYMBOLS_BY_VALUE: self.parse_symbols_by_value,
                    Section.SYMBOLS_BY_NAME: self.parse_symbols_by_name,
                }[self.section](line)

            else:
                section_name, _, arg = line.partition(":")
                self.section = Section(section_name)
                self.arg = arg.strip()
                log.debug("Section:", self.section, self.arg)

        return self.result

    def parse_sections(self, line: str):
        """Parse the sections section."""
        code, _, name = line.partition(":")
        self.result.sections[code] = name.strip()

    def parse_source(self, line: str):
        """Parse the source section."""
        source_code = self.result.source[self.arg]

        if line[0] == " ":
            code = line
        else:
            addr, machine_code, code = line.split(" ", maxsplit=2)
            section, _, addr = addr.partition(":")
            self.result.source_addr_index[int(addr, 16)] = SourceAddrIndex(
                self.arg, len(source_code), section, bytes.fromhex(machine_code)
            )

        _, _, code = code.strip().partition(": ")
        source_code.append(code)

    def parse_symbols_by_name(self, line: str):
        """Parse the Symbols by name section."""
        name, _, type_and_value = line.partition(" ")
        type_, _, value = type_and_value.strip().partition(":")
        self.result.symbols_by_name[name] = (int(value, 16), type_)

    def parse_symbols_by_value(self, line: str):
        """Parse the Symbols by value section."""
        value, _, name = line.partition(" ")
        self.result.symbols_by_value[int(value, 16)] = name


class SourceAddrIndex(NamedTuple):
    file_name: str
    source_index: int
    section: str
    machine_code: bytes


SourceLine = tuple[int, str]
SourceLines = list[SourceLine]
SourceBlock = tuple[SourceLines, SourceLine | None, SourceLines]


class AssemblyLst:
    """Parse vasm lst files"""

    def __init__(self):
        """Initialise the AssemblyLst instance."""

        self.sections: dict[str, str] = {}
        self.source: dict[str, list[str]] = defaultdict(list)
        self.source_addr_index: dict[int, SourceAddrIndex] = {}
        self.symbols_by_name: dict[str, tuple[int, str]] = {}
        self.symbols_by_value: dict[int, str] = {}

    def __str__(self):
        out: list[str] = [
            "Sections:",
            *(f"{code}: {name}" for code, name in self.sections.items()),
            "",
            "Source:",
            *(f"{line}" for source in self.source.values() for line in source),
            "",
            "Source: Index",
            *(
                f"{addr:04X}:{section} {machine_code.hex():8s} {self.source[file_name][source_index]}"
                for addr, (file_name, source_index, section, machine_code) in self.source_addr_index.items()
            ),
            "",
            "Symbols by name:",
            *(f"{name} {type_}:{value:04X}" for name, (value, type_) in self.symbols_by_name.items()),
            "",
            "Symbols by value:",
            *(f"{value:04X} {name}" for value, name in self.symbols_by_value.items()),
        ]

        return "\n".join(out)

    def get_symbol(self, name: str) -> int | None:
        """Get the symbol by name."""

        try:
            return self.symbols_by_name[name][0]
        except KeyError:
            return

    def get_source_block(self, line_idx: int, file_name: str = None, *, expand: int = 2) -> SourceBlock:
        """Fetch code block around a line number."""

        # Default to first file name
        file_name = file_name or next(iter(self.source))

        try:
            lines = self.source[file_name]
            line = (line_idx + 1, lines[line_idx])
            before = [
                (idx + 1, lines[idx])
                for idx in range(max(0, line_idx - expand), line_idx)
            ]
            after = [
                (idx + 1, lines[idx])
                for idx in range(line_idx + 1, min(len(lines), line_idx + 1 + expand))
            ]
        except LookupError:
            return [], None, []

        return before, line, after

    def get_source_block_from_addr(self, addr: int, *, expand: int = 2) -> SourceBlock:
        """Get a line of code related to an address.

        Will fetch code line around the address to provide more context.
        """
        try:
            file_name, line_num, *_ = self.source_addr_index[addr]
        except KeyError:
            return [], None, []

        return self.get_source_block(line_num, file_name, expand=expand)
