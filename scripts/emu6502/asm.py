from typing import Callable, Generic, TypeVar

from emu6502.opcodes import OpCode
from emu6502.errors import ASMError, ASMValueError, ASMLabelNotFound, ASMSyntaxError
from emu6502.address import ZeroPageAddress, Address, RelAddress, ByteAddress


def _address(addr: int):
    """Helper function to validate address"""
    if addr < 0 or addr > 0xFFFF:
        raise ASMValueError("Address must be between 0 and 65535")
    return (addr & 0xFF), (addr >> 8) & 0xFF


class MemoryRef:
    _x: bool = False
    _y: bool = False

    @property
    def address(self) -> int:
        return self._addr

    @property
    def is_zero_page(self) -> bool:
        return False

    @property
    def is_x_indexed(self) -> bool:
        return False

    @is_x_indexed.setter
    def is_x_indexed(self, value: bool):
        self._x = value
        self._y = False

    @property
    def is_y_indexed(self) -> bool:
        return False

    @is_y_indexed.setter
    def is_y_indexed(self, value: bool):
        self._y = value
        self._x = False


class _Abs(MemoryRef):
    """Absolute address."""

    def __init__(self, addr: int):
        self._addr = Address(addr)

    def map_instruction(
            self,
            name: str,
            addr: OpCode | None,
            addr_x: OpCode | None,
            addr_y: OpCode | None,
            addr_zp: OpCode | None = None,
            addr_x_zp: OpCode | None = None,
            addr_y_zp: OpCode | None = None,
    ) -> tuple[OpCode, Address | ZeroPageAddress]:
        if self._addr.is_zero_page:
            if self._x:
                if addr_x_zp is None:
                    raise SyntaxError(
                        f"{name} does not support absolute X indexed addressing on Zero page"
                    )
                return addr_x_zp, self._addr.zero_page
            elif self._y:
                if addr_y_zp is None:
                    raise SyntaxError(
                        f"{name} does not support absolute Y indexed addressing on Zero page"
                    )
                return addr_y_zp, self._addr.zero_page
            else:
                if addr_zp is None:
                    if addr is None:
                        raise SyntaxError(
                            f"{name} does not support absolute addressing"
                        )
                    return addr, self._addr
                return addr_zp, self._addr.zero_page
        else:
            if self._x:
                if addr_x is None:
                    raise SyntaxError(
                        f"{name} does not support absolute X indexed addressing"
                    )
                return addr_x, self._addr
            elif self._y:
                if addr_y is None:
                    raise SyntaxError(
                        f"{name} does not support absolute Y indexed addressing"
                    )
                return addr_y, self._addr
            else:
                if addr is None:
                    raise SyntaxError(f"{name} does not support absolute addressing")
                return addr, self._addr


class _Ind(MemoryRef):
    """Indirect address."""

    def __init__(self, addr: int):
        self._addr = ByteAddress(addr)

    def map_instruction(
            self,
            name: str,
            addr: OpCode | None,
            addr_x: OpCode | None,
            addr_y: OpCode | None,
    ):
        if self._x:
            if addr_x is None:
                raise SyntaxError(
                    f"{name} does not support indirect X indexed addressing"
                )
            return addr_x, self._addr
        elif self._y:
            if addr_y is None:
                raise SyntaxError(
                    f"{name} does not support indirect Y indexed addressing"
                )
            return addr_y, self._addr
        else:
            if addr is None:
                raise SyntaxError(f"{name} does not support indirect addressing")
            return addr, self._addr


class X:
    pass


class Y:
    pass


A = TypeVar("A")


class AddressAlias(Generic[A]):
    """Map addressing modes to addresses."""

    def __init__(self, address_type: Callable[[int], A]):
        self._address_type = address_type

    def __getitem__(self, item: int | slice):
        if isinstance(item, slice):
            addr, mode = item.start, item.stop
            if not isinstance(addr, int):
                raise ASMValueError("Address must be an integer")

            ref = self._address_type(addr)
            if mode is X:
                ref.is_x_indexed = True
            elif mode is Y:
                ref.is_y_indexed = True
            else:
                raise ASMValueError("Invalid addressing mode")
            return ref

        if isinstance(item, int):
            return self._address_type(item)

        raise ASMValueError("Invalid addressing mode")


Abs = AddressAlias(_Abs)
Ind = AddressAlias(_Ind)


class Assembler:
    def __init__(self):
        self.instructions = []
        self.labels = {}
        self._offset = 0

    def __str__(self) -> str:
        def _instructions():
            idx = 0
            for op, *operands in self.instructions:
                yield f"{idx:04X}: {op.name:9s} {' '.join(hex(o) for o in operands)}"
                idx += len(operands) + 1

        return "\n".join(_instructions())

    def _append(self, op: OpCode, opr: int | None = None):
        instruction = [op] if opr is None else [op, *bytes(opr)]
        self.instructions.append(instruction)
        self._offset += len(instruction)
        return self

    def label(self, name: str):
        self.labels[name] = self._offset
        return self

    def label_addr_relative(self, label: str):
        """Relative offset to a label relative to the current offset."""
        try:
            addr = self.labels[label]
        except KeyError as e:
            raise ASMLabelNotFound(label) from e

        rel_addr = addr - self._offset
        if rel_addr < -0x7F or rel_addr > 0x7F:
            raise ASMValueError(
                f"Label '{label}' must be within 127 (0x7F) instruction bytes"
            )

        rel_addr = twos_complement(rel_addr, 8)

        return rel_addr

    def nop(self):
        """No operation."""
        self._append(OpCode.NOP, None)

    # <editor-fold> Transfer instructions

    def lda(self, v: int | _Abs | _Ind):
        """Load Accumulator with Memory"""
        if isinstance(v, int):
            self._append(OpCode.LDA_imm, ByteAddress(v))
        elif isinstance(v, _Abs):
            self._append(
                *v.map_instruction(
                    "LDA",
                    OpCode.LDA_abs,
                    OpCode.LDA_abs_X,
                    OpCode.LDA_abs_Y,
                    # Zero page
                    OpCode.LDA_zpg,
                    OpCode.LDA_zpg_X,
                )
            )
        elif isinstance(v, _Ind):
            self._append(
                *v.map_instruction(
                    "LDA",
                    None,
                    OpCode.LDA_X_ind,
                    OpCode.LDA_ind_Y,
                )
            )
        else:
            raise ASMValueError("Unsupported addressing mode")

    def ldx(self, v: int | _Abs):
        """Load Index X with Memory"""
        if isinstance(v, int):
            self._append(OpCode.LDX_imm, ByteAddress(v))
        elif isinstance(v, _Abs):
            self._append(
                *v.map_instruction(
                    "LDX",
                    OpCode.LDX_abs,
                    None,
                    OpCode.LDX_abs_Y,
                    # Zero page
                    OpCode.LDX_zpg,
                    None,
                    OpCode.LDX_zpg_Y,
                )
            )
        else:
            raise ASMValueError("Unsupported addressing mode")

    def ldy(self, v: int | _Abs):
        """Load Index Y with Memory"""
        if isinstance(v, int):
            self._append(OpCode.LDY_imm, ByteAddress(v))
        elif isinstance(v, _Abs):
            self._append(
                *v.map_instruction(
                    "LDY",
                    OpCode.LDY_abs,
                    OpCode.LDY_abs_X,
                    None,
                    # Zero page
                    OpCode.LDY_zpg,
                    OpCode.LDY_zpg_X,
                    None
                )
            )
        else:
            raise ASMValueError("Unsupported addressing mode")

    def sta(self, v: _Abs | _Ind):
        """Store Accumulator"""
        if isinstance(v, _Abs):
            self._append(
                *v.map_instruction(
                    "STA",
                    OpCode.STA_abs,
                    OpCode.STA_abs_X,
                    OpCode.STA_abs_Y,
                    # Zero page
                    OpCode.STA_zpg,
                    OpCode.STA_zpg_X,
                )
            )
        elif isinstance(v, _Ind):
            self._append(
                *v.map_instruction(
                    "STA",
                    None,
                    OpCode.STA_X_ind,
                    OpCode.STA_ind_Y,
                )
            )
        else:
            raise ASMValueError("Unsupported addressing mode")

    def stx(self, v: _Abs):
        """Store X Register"""
        if isinstance(v, _Abs):
            self._append(
                *v.map_instruction(
                    "STX",
                    OpCode.STX_abs,
                    None,
                    None,
                    # Zero page
                    OpCode.STX_zpg,
                    None,
                    OpCode.STX_zpg_Y,
                )
            )
        else:
            raise ASMValueError("Unsupported addressing mode")

    def sty(self, v: _Abs):
        """Store Y Register"""
        if isinstance(v, _Abs):
            self._append(
                *v.map_instruction(
                    "STY",
                    OpCode.STY_abs,
                    None,
                    None,
                    # Zero page
                    OpCode.STY_zpg,
                    OpCode.STY_zpg_X,
                )
            )
        else:
            raise ASMValueError("Unsupported addressing mode")

    def tax(self):
        """Transfer accumulator to X."""
        self._append(OpCode.TAX, None)

    def tay(self):
        """Transfer accumulator to Y."""
        self._append(OpCode.TAY, None)

    def tsx(self):
        """Transfer stack-pointer register to X."""
        self._append(OpCode.TSX, None)

    def txa(self):
        """Transfer X to accumulator."""
        self._append(OpCode.TXA, None)

    def txs(self):
        """Transfer X to stack-pointer register."""
        self._append(OpCode.TXS, None)

    def tya(self):
        """Transfer Y to accumulator."""
        self._append(OpCode.TYA, None)

    # </editor-fold>

    # Stack Instructions

    # Logical

    def and_(self, v):
        """AND Memory with Accumulator"""
        if isinstance(v, int):
            self._append(OpCode.AND_imm, ByteAddress(v))
        elif isinstance(v, _Abs):
            self._append(
                *v.map_instruction(
                    "AND",
                    OpCode.AND_abs,
                    OpCode.AND_abs_X,
                    OpCode.AND_abs_Y,
                    # Zero page
                    OpCode.AND_zpg,
                    OpCode.AND_zpg_X,
                )
            )
        elif isinstance(v, _Ind):
            self._append(
                *v.map_instruction(
                    "AND",
                    None,
                    OpCode.AND_X_ind,
                    OpCode.AND_ind_Y,
                )
            )

    # Arithmetic

    def adc(self, v: int | _Abs | _Ind):
        """Add Memory to Accumulator with Carry"""
        if isinstance(v, int):
            self._append(OpCode.ADC_imm, ByteAddress(v))
        elif isinstance(v, _Abs):
            self._append(
                *v.map_instruction(
                    "ADC",
                    OpCode.ADC_abs,
                    OpCode.ADC_abs_X,
                    OpCode.ADC_abs_Y,
                    # Zero page
                    OpCode.ADC_zpg,
                    OpCode.ADC_zpg_X,
                )
            )
        elif isinstance(v, _Ind):
            self._append(
                *v.map_instruction(
                    "ADC",
                    None,
                    OpCode.ADC_X_ind,
                    OpCode.ADC_ind_Y,
                )
            )

    # Increments & Decrements

    # Shifts

    # <editor-fold> Flag Instructions

    def clc(self):
        """Clear carry flag"""
        return self._append(OpCode.CLC)

    def cld(self):
        """Clear decimal mode flag"""
        return self._append(OpCode.CLD)

    def cli(self):
        """Clear interrupt disable flag"""
        return self._append(OpCode.CLI)

    def clv(self):
        """Clear overflow flag"""
        return self._append(OpCode.CLV)

    def sec(self):
        """Set carry flag"""
        return self._append(OpCode.SEC)

    def sed(self):
        """Set decimal mode flag"""
        return self._append(OpCode.SED)

    def sei(self):
        """Set interrupt disable flag"""
        return self._append(OpCode.SEI)

    # </editor-fold>

    # Jumps and Calls

    # Branches

    def bcc(self, label: str):
        """Branch if carry flag clear"""
        return self._append(OpCode.BCC, self.labels[label])

    def bcs(self):
        """Branch if carry flag set"""
        return self._append(OpCode.BCS)

    def beq(self):
        """Branch if zero flag set"""
        return self._append(OpCode.BEQ)

    def bmi(self):
        """Branch if negative flag set"""
        return self._append(OpCode.BMI)

    def bne(self):
        """Branch if zero flag clear"""
        return self._append(OpCode.BNE)

    def bpl(self):
        """Branch if negative flag clear"""
        return self._append(OpCode.BPL)

    def bvc(self):
        """Branch if overflow flag clear"""
        return self._append(OpCode.BVC)

    def bvs(self):
        """Branch if overflow flag set"""
        return self._append(OpCode.BVS)

    # <editor-fold> Interrupts

    def brk(self):
        """Force an interrupt"""
        return self._append(OpCode.BRK)

    def rti(self):
        """Return from Interrupt"""
        return self._append(OpCode.RTI)

    # </editor-fold>

if __name__ == "__main__":
    a = Assembler()

    a.adc(0x42)
    a.adc(Abs[0x32])
    a.adc(Abs[0x4323])
    a.adc(Abs[0x4323:X])
    a.adc(Abs[0x4323:Y])
    a.adc(Ind[0x23:X])

    print(a)
