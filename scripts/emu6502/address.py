from typing import Self

from .errors import ASMValueError


class Address(int):
    pass


class ByteAddress(Address):
    """Byte (8 bit) address."""

    @classmethod
    def from_asm(cls, b: bytes) -> Self:
        if len(b) == 1:
            return cls(int.from_bytes(b, "little", signed=False))
        raise ASMValueError("ByteAddress must be 1 byte")

    def __new__(cls, value: int):
        if value < 0 or value > 0xFF:
            raise ASMValueError("ByteAddress byte must be within 0 and 255")
        return super().__new__(cls, value)

    def __str__(self) -> str:
        return f"0x{self:02X}"

    def __bytes__(self):
        return self.to_bytes(1, "little", signed=False)


class RelAddress(Address):
    """Relative (8 bit) address."""

    @classmethod
    def from_asm(cls, b: bytes) -> Self:
        if len(b) == 1:
            return cls(int.from_bytes(b, "little", signed=True))
        raise ASMValueError("RelAddress must be 1 byte")

    def __new__(cls, value):
        if value < -0x80 or value > 0x7F:
            raise ASMValueError("RelAddress byte must be within -128 and 127")
        return super().__new__(cls, value)

    def __str__(self) -> str:
        return f"{self:d} (0x{self:02X})"

    def __bytes__(self) -> bytes:
        return int.to_bytes(self, 1, "little", signed=True)


class WordAddress(Address):
    """Word (16bit) address."""

    @classmethod
    def from_asm(cls, b: bytes) -> Self:
        if len(b) == 2:
            return cls(int.from_bytes(b, "little", signed=False))
        raise ASMValueError("WordAddress must be 2 bytes")

    def __new__(cls, value):
        if value < 0 or value > 0xFFFF:
            raise ASMValueError("WordAddress byte must be within 0 and 65535")
        return super().__new__(cls, value)

    def __str__(self) -> str:
        return f"0x{self:04X}"

    def __bytes__(self) -> bytes:
        return int.to_bytes(self, 2, "little", signed=False)

    @property
    def is_zero_page(self) -> bool:
        return self < 0x100

    @property
    def lo(self) -> int:
        return ByteAddress(self & 0xFF)

    zero_page = lo

    @property
    def hi(self) -> int:
        return (self >> 8) & 0xFF
