"""Parsers for VASM outputs"""

from pathlib import Path
from enum import Enum


class Section(Enum):
    SECTIONS = "Sections"
    SOURCE = "Source"
    SYMBOLS_BY_NAME = "Symbols by name"
    SYMBOLS_BY_VALUE = "Symbols by value"


class AssemblyLstParser:
    def __init__(self, file):
        self.file = file

        self.result = AssemblyLst()
        self.section = None
        self.arg = None

    def parse(self):
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
                print("Section:", self.section, self.arg)

    def parse_sections(self, line):
        code, _, name = line.partition(":")
        self.result.sections[code] = name.strip()

    def parse_source(self, line):
        pass

    def parse_symbols_by_name(self, line):
        name, _, type_and_value = line.partition(" ")
        type_, _, value = type_and_value.strip().partition(":")
        self.result.symbols_by_name[name] = (type_, int(value, 16))

    def parse_symbols_by_value(self, line):
        value, _, name = line.partition(" ")
        self.result.symbols_by_value[int(value, 16)] = name


class AssemblyLst:
    """Parse vasm lst files"""
    
    def __init__(self):
        self.sections = {}
        self.source = None
        self.symbols_by_name = {}
        self.symbols_by_value = {}

    def __str__(self):
        out = []

        out.append("Sections:")
        for code, name in self.sections.items():
            out.append(f"{code}: {name}")

        out.append("")
        out.append("Symbols by name:")
        for symbol, (type_, value) in self.symbols_by_name.items():
            out.append(f"{symbol} {type_}:{value:04X}")

        out.append("")
        out.append("Symbols by value:")
        for value, symbol in self.symbols_by_value.items():
            out.append(f"{value:04X} {symbol}")

        return "\n".join(out)


if __name__ == "__main__":
    HERE = Path(__file__).parent
    with Path(HERE, "../systems/input.lst").open() as file:
        parser = AssemblyLstParser(file)
        parser.parse()
        print(parser.result)


