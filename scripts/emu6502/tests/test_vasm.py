import io
from pathlib import Path

import pytest
from emu6502.vasm import (
    AssemblyLst,
    AssemblyLstParser,
    Section,
    SourceAddrIndex,
)

SAMPLE_LST = """Sections:
00: "org0001:ff00" (FF00-0)
01: "data:0200" (0200-0)

Source: "test.asm"
                        	     1: ; Test comment
00:FF00 D8              	     2: RESET:          CLD
00:FF01 A900            	     3:                 LDA #$00
                        	     4: ; Subroutine
00:FF03 2007FF          	     5:                 JSR SUB
00:FF06 60              	     6:                 RTS
00:FF07 EA              	     7: SUB:            NOP
00:FF08 60              	     8:                 RTS

Symbols by name:
RESET                            A:FF00
SUB                              A:FF07
VAR                              E:0200

Symbols by value:
0200 VAR
FF00 RESET
FF07 SUB
"""


class TestSectionEnum:
    def test_section_enum_values(self):
        assert Section.SECTIONS.value == "Sections"
        assert Section.SOURCE.value == "Source"
        assert Section.SYMBOLS_BY_NAME.value == "Symbols by name"
        assert Section.SYMBOLS_BY_VALUE.value == "Symbols by value"


class TestAssemblyLstParser:
    def test_parse_sample_lst(self):
        f = io.StringIO(SAMPLE_LST)
        parser = AssemblyLstParser(f)
        result = parser.parse()

        # Sections
        assert result.sections == {
            "00": '"org0001:ff00" (FF00-0)',
            "01": '"data:0200" (0200-0)',
        }

        # Source
        assert '"test.asm"' in result.source
        assert len(result.source['"test.asm"']) == 8
        assert result.source['"test.asm"'][0] == "; Test comment"
        assert result.source['"test.asm"'][1] == "RESET:          CLD"
        assert result.source['"test.asm"'][2] == "                LDA #$00"
        assert result.source['"test.asm"'][3] == "; Subroutine"
        assert result.source['"test.asm"'][4] == "                JSR SUB"
        assert result.source['"test.asm"'][5] == "                RTS"
        assert result.source['"test.asm"'][6] == "SUB:            NOP"
        assert result.source['"test.asm"'][7] == "                RTS"

        # Source Address Index
        assert 0xFF00 in result.source_addr_index
        assert result.source_addr_index[0xFF00] == SourceAddrIndex(
            file_name='"test.asm"',
            source_index=1,
            section="00",
            machine_code=bytes.fromhex("D8"),
        )
        assert result.source_addr_index[0xFF01] == SourceAddrIndex(
            file_name='"test.asm"',
            source_index=2,
            section="00",
            machine_code=bytes.fromhex("A900"),
        )
        assert result.source_addr_index[0xFF03] == SourceAddrIndex(
            file_name='"test.asm"',
            source_index=4,
            section="00",
            machine_code=bytes.fromhex("2007FF"),
        )

        # Symbols by name
        assert result.symbols_by_name == {
            "RESET": (0xFF00, "A"),
            "SUB": (0xFF07, "A"),
            "VAR": (0x0200, "E"),
        }

        # Symbols by value
        assert result.symbols_by_value == {
            0x0200: "VAR",
            0xFF00: "RESET",
            0xFF07: "SUB",
        }

    def test_parse_multiple_sources(self):
        content = """Source: "file1.asm"
                        	     1: ; File 1
00:1000 EA              	     2:                 NOP

Source: "file2.asm"
                        	     1: ; File 2
00:2000 60              	     2:                 RTS
"""
        parser = AssemblyLstParser(io.StringIO(content))
        result = parser.parse()

        assert '"file1.asm"' in result.source
        assert '"file2.asm"' in result.source
        assert result.source['"file1.asm"'] == ["; File 1", "                NOP"]
        assert result.source['"file2.asm"'] == ["; File 2", "                RTS"]

        assert result.source_addr_index[0x1000] == SourceAddrIndex(
            file_name='"file1.asm"',
            source_index=1,
            section="00",
            machine_code=bytes.fromhex("EA"),
        )
        assert result.source_addr_index[0x2000] == SourceAddrIndex(
            file_name='"file2.asm"',
            source_index=1,
            section="00",
            machine_code=bytes.fromhex("60"),
        )

    def test_empty_content(self):
        parser = AssemblyLstParser(io.StringIO(""))
        result = parser.parse()
        assert result.sections == {}
        assert result.source == {}
        assert result.source_addr_index == {}
        assert result.symbols_by_name == {}
        assert result.symbols_by_value == {}


class TestAssemblyLst:
    @pytest.fixture
    def parsed_lst(self) -> AssemblyLst:
        return AssemblyLstParser(io.StringIO(SAMPLE_LST)).parse()

    def test_get_symbol(self, parsed_lst):
        assert parsed_lst.get_symbol("RESET") == 0xFF00
        assert parsed_lst.get_symbol("SUB") == 0xFF07
        assert parsed_lst.get_symbol("VAR") == 0x0200
        assert parsed_lst.get_symbol("NON_EXISTENT") is None

    def test_get_source_block(self, parsed_lst):
        # Line index 4 (0-based) is line 5: "                JSR SUB"
        before, line, after = parsed_lst.get_source_block(4, '"test.asm"', expand=2)
        assert line == (5, "                JSR SUB")
        assert before == [
            (3, "                LDA #$00"),
            (4, "; Subroutine"),
        ]
        assert after == [
            (6, "                RTS"),
            (7, "SUB:            NOP"),
        ]

    def test_get_source_block_boundary_conditions(self, parsed_lst):
        # First line (idx 0)
        before, line, after = parsed_lst.get_source_block(0, '"test.asm"', expand=2)
        assert line == (1, "; Test comment")
        assert before == []
        assert after == [
            (2, "RESET:          CLD"),
            (3, "                LDA #$00"),
        ]

        # Last line (idx 7)
        before, line, after = parsed_lst.get_source_block(7, '"test.asm"', expand=2)
        assert line == (8, "                RTS")
        assert before == [
            (6, "                RTS"),
            (7, "SUB:            NOP"),
        ]
        assert after == []

    def test_get_source_block_default_file_name(self, parsed_lst):
        # When file_name is None, defaults to first file in self.source
        before, line, after = parsed_lst.get_source_block(1, expand=1)
        assert line == (2, "RESET:          CLD")
        assert before == [(1, "; Test comment")]
        assert after == [(3, "                LDA #$00")]

    def test_get_source_block_non_existent_file(self, parsed_lst):
        before, line, after = parsed_lst.get_source_block(0, "nonexistent.asm")
        assert before == []
        assert line is None
        assert after == []

    def test_get_source_block_out_of_range_index(self, parsed_lst):
        before, line, after = parsed_lst.get_source_block(999, '"test.asm"')
        assert before == []
        assert line is None
        assert after == []

    def test_get_source_block_from_addr(self, parsed_lst):
        before, line, after = parsed_lst.get_source_block_from_addr(0xFF03, expand=1)
        assert line == (5, "                JSR SUB")
        assert before == [(4, "; Subroutine")]
        assert after == [(6, "                RTS")]

    def test_get_source_block_from_non_existent_addr(self, parsed_lst):
        before, line, after = parsed_lst.get_source_block_from_addr(0x1234)
        assert before == []
        assert line is None
        assert after == []

    def test_str_representation(self, parsed_lst):
        output = str(parsed_lst)
        assert "Sections:" in output
        assert '00: "org0001:ff00" (FF00-0)' in output
        assert "Source:" in output
        assert "RESET:          CLD" in output
        assert "Source: Index" in output
        assert "FF00:00 d8       RESET:          CLD" in output
        assert "Symbols by name:" in output
        assert "RESET A:FF00" in output
        assert "Symbols by value:" in output
        assert "FF00 RESET" in output


class TestSourceAddrIndex:
    def test_source_addr_index_named_tuple(self):
        index = SourceAddrIndex("main.asm", 10, "00", b"\xea")
        assert index.file_name == "main.asm"
        assert index.source_index == 10
        assert index.section == "00"
        assert index.machine_code == b"\xea"


class TestRealLstFiles:
    def test_parse_wozmon_lst_file(self):
        lst_path = Path(__file__).parents[3] / "systems" / "apple1" / "wozmon-rom.bin.lst"
        if not lst_path.exists():
            pytest.skip(f"{lst_path} does not exist")

        with open(lst_path, "r", encoding="utf-8") as f:
            result = AssemblyLstParser(f).parse()

        assert "00" in result.sections
        assert '"wozmon-rom.asm"' in result.source
        assert 0xFF00 in result.source_addr_index
        assert result.get_symbol("RESET") == 0xFF00
        assert result.get_symbol("ECHO") == 0xFFEF

        _, line, _ = result.get_source_block_from_addr(0xFF00, expand=2)
        assert line is not None
        assert line[0] == 27
        assert "RESET:          CLD" in line[1]
