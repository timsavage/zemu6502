import pytest

from emu6502 import address
from emu6502.errors import ASMValueError


class TestByteAddress:
    @pytest.mark.parametrize(
        "value, expected_bytes, expected_str",
        [
            (0x00, b"\x00", "0x00"),
            (0x08, b"\x08", "0x08"),
            (0x42, b"\x42", "0x42"),
            (0xf2, b"\xf2", "0xF2"),
        ],
    )
    def test_usage(self, value, expected_bytes, expected_str):
        actual = address.ByteAddress.from_asm(expected_bytes)

        assert actual == value
        assert str(actual) == expected_str
        assert bytes(actual) == expected_bytes

    def test_from_asm_where_invalid(self):
        with pytest.raises(ASMValueError):
            address.ByteAddress.from_asm(b"\x00\x00")

    @pytest.mark.parametrize("value", [-20, 0x100])
    def test_new_where_out_of_range(self, value):
        with pytest.raises(ASMValueError):
            address.ByteAddress(value)


class TestRelAddress:
    @pytest.mark.parametrize(
        "value, expected_bytes, expected_str",
        [
            (0x00, b"\x00", "0 (0x00)"),
            (-0x8, b"\xf8", "-8 (0x-8)"),
            (-0x42, b"\xbe", "-66 (0x-42)"),
            (0x42, b"\x42", "66 (0x42)"),
        ],
    )
    def test_usage(self, value, expected_bytes, expected_str):
        actual = address.RelAddress.from_asm(expected_bytes)

        assert actual == value
        assert str(actual) == expected_str
        assert bytes(actual) == expected_bytes

    def test_from_asm_where_invalid(self):
        with pytest.raises(ASMValueError):
            address.RelAddress.from_asm(b"\x00\x00")

    @pytest.mark.parametrize("value", [-0x101, 0x80])
    def test_new_where_out_of_range(self, value):
        with pytest.raises(ASMValueError):
            address.RelAddress(value)


class TestWordAddress:
    @pytest.mark.parametrize(
        "value, expected_bytes, expected_str, expected_zp",
        [
            (0x0000, b"\x00\x00", "0x0000", address.ByteAddress(0x00)),
            (0x0001, b"\x01\x00", "0x0001", address.ByteAddress(0x01)),
            (0x1234, b"\x34\x12", "0x1234", address.ByteAddress(0x34)),
            (0x1200, b"\x00\x12", "0x1200", address.ByteAddress(0x00)),
        ],
    )
    def test_usage(self, value, expected_bytes, expected_str, expected_zp):
        actual = address.WordAddress.from_asm(expected_bytes)

        assert actual == value
        assert str(actual) == expected_str
        assert bytes(actual) == expected_bytes
        assert actual.zero_page == expected_zp

    def test_from_asm_where_invalid(self):
        with pytest.raises(ASMValueError):
            address.WordAddress.from_asm(b"\x00\x00\x00")

    @pytest.mark.parametrize("value", [-0x01, 0x18888])
    def test_new_where_out_of_range(self, value):
        with pytest.raises(ASMValueError):
            address.WordAddress(value)

    def test_is_zero_page(self):
        assert address.WordAddress(0x0).is_zero_page is True
        assert address.WordAddress(0x0F).is_zero_page is True
        assert address.WordAddress(0xFF).is_zero_page is True
        assert address.WordAddress(0x100).is_zero_page is False
        assert address.WordAddress(0x1FF).is_zero_page is False

    def test_hi_lo(self):
        assert address.WordAddress(0x1234).hi == 0x12
        assert address.WordAddress(0x1234).lo == 0x34
