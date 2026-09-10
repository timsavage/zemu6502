from collections.abc import Callable
from pathlib import Path
from typing import Generic, NamedTuple, Self, TypeVar

from emu6502.address import Address, ByteAddress, RelAddress, ZeroPageAddress
from emu6502.errors import ASMLabelNotFound, ASMValueError
from emu6502.opcodes import OpCode

__all__ = ("Abs", "Assembler", "Ind", "Val", "X", "Y")


class MemoryRef:
    _x: bool = False
    _y: bool = False

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
        addr_x: OpCode | None = None,
        addr_y: OpCode | None = None,
        addr_zp: OpCode | None = None,
        addr_x_zp: OpCode | None = None,
        addr_y_zp: OpCode | None = None,
    ) -> tuple[OpCode, Address | ZeroPageAddress]:
        if self._addr.is_zero_page:
            if self._x:
                if addr_x_zp is None:
                    raise SyntaxError(f"{name} does not support absolute X indexed addressing on Zero page")
                return addr_x_zp, self._addr.zero_page
            elif self._y:
                if addr_y_zp is None:
                    raise SyntaxError(f"{name} does not support absolute Y indexed addressing on Zero page")
                return addr_y_zp, self._addr.zero_page
            else:
                if addr_zp is None:
                    if addr is None:
                        raise SyntaxError(f"{name} does not support absolute addressing")
                    return addr, self._addr
                return addr_zp, self._addr.zero_page
        else:
            if self._x:
                if addr_x is None:
                    raise SyntaxError(f"{name} does not support absolute X indexed addressing")
                return addr_x, self._addr
            elif self._y:
                if addr_y is None:
                    raise SyntaxError(f"{name} does not support absolute Y indexed addressing")
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
        addr_x: OpCode | None = None,
        addr_y: OpCode | None = None,
    ):
        if self._x:
            if addr_x is None:
                raise SyntaxError(f"{name} does not support indirect X indexed addressing")
            return addr_x, self._addr
        elif self._y:
            if addr_y is None:
                raise SyntaxError(f"{name} does not support indirect Y indexed addressing")
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


class Val(int):
    """Value that must be within 0 and 255"""

    def __new__(cls, value: int) -> Self:
        if value < 0 or value > 0xFF:
            raise ASMValueError(f"{cls.__name__} must be within 0 and 255")
        return super().__new__(cls, value)

    def __str__(self) -> str:
        return f"0x{self:02X}"

    def __bytes__(self):
        return self.to_bytes(1, "little", signed=False)


class Instruction(NamedTuple):
    op: OpCode
    operands: bytes = b""

    def __len__(self):
        return 1 + len(self.operands)

    def __str__(self):
        return f"{self.op.name:9s} {' '.join(hex(o) for o in self.operands)}"

    def __bytes__(self):
        return bytes([self.op, *self.operands])


class Assembler:
    def __init__(self, *, base_address: int = 0x00):
        self.instructions = []
        self.labels = {}
        self._base_addr = base_address
        self._offset = base_address

    def __str__(self) -> str:
        def _instructions():
            idx = self._base_addr
            for inst in self.instructions:
                yield f"{idx:04X}: {inst}"
                idx += len(inst)

        return "\n".join(_instructions())

    def __bytes__(self) -> bytes:
        # def _instructions():
        #     for op, *operands in self.instructions:
        #         yield bytes([op, *operands])
        return b"".join(bytes(inst) for inst in self.instructions)

    def _append(self, op: OpCode, opr: int | None = None):
        instr = Instruction(op, b'' if opr is None else bytes(opr))
        self.instructions.append(instr)
        self._offset += len(instr)
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
            raise ASMValueError(f"Label '{label}' must be within 127 (0x7F) instruction bytes")

        return RelAddress(rel_addr)

    def label_addr_absolute(self, label: str):
        """Absolute address of a label."""
        try:
            addr = self.labels[label]
        except KeyError as e:
            raise ASMLabelNotFound(label) from e

        return _Abs(addr)

    # <editor-fold desc="Transfer Instructions">

    def lda(self, opr: Val | _Abs | _Ind):
        """Load Accumulator with Memory"""
        if isinstance(opr, Val):
            self._append(OpCode.LDA_imm, opr)
        elif isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "LDA",
                    OpCode.LDA_abs,
                    OpCode.LDA_abs_X,
                    OpCode.LDA_abs_Y,
                    # Zero page
                    OpCode.LDA_zpg,
                    OpCode.LDA_zpg_X,
                )
            )
        elif isinstance(opr, _Ind):
            self._append(
                *opr.map_instruction(
                    "LDA",
                    None,
                    OpCode.LDA_X_ind,
                    OpCode.LDA_ind_Y,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def ldx(self, opr: Val | _Abs):
        """Load Index X with Memory"""
        if isinstance(opr, Val):
            self._append(OpCode.LDX_imm, opr)
        elif isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
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
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def ldy(self, opr: Val | _Abs):
        """Load Index Y with Memory"""
        if isinstance(opr, Val):
            self._append(OpCode.LDY_imm, opr)
        elif isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "LDY",
                    OpCode.LDY_abs,
                    OpCode.LDY_abs_X,
                    None,
                    # Zero page
                    OpCode.LDY_zpg,
                    OpCode.LDY_zpg_X,
                    None,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def sta(self, opr: _Abs | _Ind):
        """Store Accumulator"""
        if isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "STA",
                    OpCode.STA_abs,
                    OpCode.STA_abs_X,
                    OpCode.STA_abs_Y,
                    # Zero page
                    OpCode.STA_zpg,
                    OpCode.STA_zpg_X,
                )
            )
        elif isinstance(opr, _Ind):
            self._append(
                *opr.map_instruction(
                    "STA",
                    None,
                    OpCode.STA_X_ind,
                    OpCode.STA_ind_Y,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def stx(self, opr: _Abs):
        """Store X Register"""
        if isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
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
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def sty(self, opr: _Abs):
        """Store Y Register"""
        if isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
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
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

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

    # <editor-fold desc="Stack Instructions">

    def pha(self):
        """Push accumulator register onto the stack."""
        self._append(OpCode.PHA, None)

    def php(self):
        """Push processor status register (with the break flag set)."""
        self._append(OpCode.PHP, None)

    def pla(self):
        """Pull accumulator from the stack."""
        self._append(OpCode.PLA, None)

    def plp(self):
        """Pull processor status register from the stack."""
        self._append(OpCode.PLP, None)

    # </editor-fold>

    # <editor-fold desc="Decrements & Increments">

    def dec(self, opr: _Abs):
        """Decrement (memory)."""
        if isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "DEC",
                    OpCode.DEC_abs,
                    OpCode.DEC_abs_X,
                    None,
                    OpCode.DEC_zpg,
                    OpCode.DEC_zpg_X,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def dex(self):
        """Decrement X."""
        self._append(OpCode.DEX, None)

    def dey(self):
        """Decrement Y."""
        self._append(OpCode.DEY, None)

    def inc(self, opr: _Abs):
        """Increment (memory)."""
        if isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "INC",
                    OpCode.INC_abs,
                    OpCode.INC_abs_X,
                    None,
                    OpCode.INC_zpg,
                    OpCode.INC_zpg_X,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def inx(self):
        """Increment X."""
        self._append(OpCode.INX, None)

    def iny(self):
        """Increment Y."""
        self._append(OpCode.INY, None)

    # </editor-fold>

    # <editor-fold desc="Arithmetic Operations">

    def adc(self, opr: Val | _Abs | _Ind):
        """Add with carry (prepare by CLC)"""
        if isinstance(opr, Val):
            self._append(OpCode.ADC_imm, opr)
        elif isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "ADC",
                    OpCode.ADC_abs,
                    OpCode.ADC_abs_X,
                    OpCode.ADC_abs_Y,
                    OpCode.ADC_zpg,
                    OpCode.ADC_zpg_X,
                )
            )
        elif isinstance(opr, _Ind):
            self._append(
                *opr.map_instruction(
                    "ADC",
                    None,
                    OpCode.ADC_X_ind,
                    OpCode.ADC_ind_Y,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def sbc(self, opr: Val | _Abs | _Ind):
        """Subtract with carry (prepare by SEC)"""
        if isinstance(opr, Val):
            self._append(OpCode.SBC_imm, opr)
        elif isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "SBC",
                    OpCode.SBC_abs,
                    OpCode.SBC_abs_X,
                    OpCode.SBC_abs_Y,
                    OpCode.SBC_zpg,
                    OpCode.SBC_zpg_X,
                )
            )
        elif isinstance(opr, _Ind):
            self._append(
                *opr.map_instruction(
                    "SBC",
                    None,
                    OpCode.SBC_X_ind,
                    OpCode.SBC_ind_Y,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    # </editor-fold>

    # <editor-fold desc="Logical Operations">

    def and_(self, opr: Val | _Abs | _Ind):
        """AND Memory with Accumulator"""
        if isinstance(opr, Val):
            self._append(OpCode.AND_imm, opr)
        elif isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "AND",
                    OpCode.AND_abs,
                    OpCode.AND_abs_X,
                    OpCode.AND_abs_Y,
                    OpCode.AND_zpg,
                    OpCode.AND_zpg_X,
                )
            )
        elif isinstance(opr, _Ind):
            self._append(
                *opr.map_instruction(
                    "AND",
                    None,
                    OpCode.AND_X_ind,
                    OpCode.AND_ind_Y,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def eor(self, opr: Val | _Abs | _Ind):
        """Exclusive Or with Accumulator"""

        if isinstance(opr, Val):
            self._append(OpCode.EOR_imm, opr)
        elif isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "EOR",
                    OpCode.EOR_abs,
                    OpCode.EOR_abs_X,
                    OpCode.EOR_abs_Y,
                    OpCode.EOR_zpg,
                    OpCode.EOR_zpg_X,
                )
            )
        elif isinstance(opr, _Ind):
            self._append(
                *opr.map_instruction(
                    "EOR",
                    None,
                    OpCode.EOR_X_ind,
                    OpCode.EOR_ind_Y,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def ora(self, opr: Val | _Abs | _Ind):
        """Inclusive Or with Accumulator"""

        if isinstance(opr, Val):
            self._append(OpCode.ORA_imm, opr)
        elif isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "ORA",
                    OpCode.ORA_abs,
                    OpCode.ORA_abs_X,
                    OpCode.ORA_abs_Y,
                    OpCode.ORA_zpg,
                    OpCode.ORA_zpg_X,
                )
            )
        elif isinstance(opr, _Ind):
            self._append(
                *opr.map_instruction(
                    "ORA",
                    None,
                    OpCode.ORA_X_ind,
                    OpCode.ORA_ind_Y,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    # </editor-fold>

    # <editor-fold desc="Shift & Rotate Instructions">

    def asl(self, opr: _Abs | None = None):
        """Arithmetic shift left (shifts in a zero bit on the right)"""
        if opr is None:
            return self._append(OpCode.ASL)
        elif isinstance(opr, _Abs):
            return self._append(
                *opr.map_instruction(
                    "ASL",
                    OpCode.ASL_abs,
                    OpCode.ASL_abs_X,
                    None,
                    OpCode.ASL_zpg,
                    OpCode.ASL_zpg_X,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def lsr(self, opr: _Abs | None = None):
        """Logical shift right (shifts in a zero bit on the left)"""
        if opr is None:
            return self._append(OpCode.LSR)
        elif isinstance(opr, _Abs):
            return self._append(
                *opr.map_instruction(
                    "LSR",
                    OpCode.LSR_abs,
                    OpCode.LSR_abs_X,
                    None,
                    OpCode.LSR_zpg,
                    OpCode.LSR_zpg_X,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def rol(self, opr: _Abs | None = None):
        """Rotate left (shifts in carry bit on the right)"""
        if opr is None:
            return self._append(OpCode.ROL)
        elif isinstance(opr, _Abs):
            return self._append(
                *opr.map_instruction(
                    "ROL",
                    OpCode.ROL_abs,
                    OpCode.ROL_abs_X,
                    None,
                    OpCode.ROL_zpg,
                    OpCode.ROL_zpg_X,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def ror(self, opr: _Abs | None = None):
        """Rotate right (shifts in carry bit on the left)"""
        if opr is None:
            return self._append(OpCode.ROR)
        elif isinstance(opr, _Abs):
            return self._append(
                *opr.map_instruction(
                    "ROR",
                    OpCode.ROR_abs,
                    OpCode.ROR_abs_X,
                    None,
                    OpCode.ROR_zpg,
                    OpCode.ROR_zpg_X,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    # </editor-fold>

    # <editor-fold desc="Flag Instructions">

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

    # <editor-fold desc="Comparisons">

    def cmp(self, opr: Val | _Abs | _Ind):
        """Compare (with accumulator)"""
        if isinstance(opr, Val):
            return self._append(OpCode.CMP_imm, opr)
        elif isinstance(opr, _Abs):
            return self._append(
                *opr.map_instruction(
                    "CMP",
                    OpCode.CMP_abs,
                    OpCode.CMP_abs_X,
                    OpCode.CMP_abs_Y,
                    OpCode.CMP_zpg,
                    OpCode.CMP_zpg_X,
                )
            )
        elif isinstance(opr, _Ind):
            return self._append(
                *opr.map_instruction(
                    "CMP",
                    None,
                    OpCode.CMP_X_ind,
                    OpCode.CMP_ind_Y,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def cpx(self, opr: Val | _Abs):
        """Compare with X"""
        if isinstance(opr, Val):
            self._append(OpCode.CPX_imm, opr)
        elif isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "CPX",
                    OpCode.CPX_abs,
                    None,
                    None,
                    OpCode.CPX_zpg,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def cpy(self, opr: Val | _Abs):
        """Compare with Y"""
        if isinstance(opr, Val):
            self._append(OpCode.CPY_imm, opr)
        elif isinstance(opr, _Abs):
            self._append(
                *opr.map_instruction(
                    "CPY",
                    OpCode.CPY_abs,
                    None,
                    None,
                    OpCode.CPY_zpg,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    # </editor-fold>

    # <editor-fold desc="Bit Test">

    def bit(self, opr: _Abs):
        """Test Bits in Memory with Accumulator."""
        if isinstance(opr, _Abs):
            return self._append(
                *opr.map_instruction(
                    "BIT",
                    OpCode.BIT_abs,
                    None,
                    None,
                    OpCode.BIT_zpg,
                )
            )
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    # </editor-fold>

    # <editor-fold desc="Conditional Branch Instructions">

    def _branch(self, op: OpCode, opr: str | RelAddress | int):
        if isinstance(opr, str):
            opr = self.label_addr_relative(opr)
        elif isinstance(opr, int):
            opr = RelAddress(opr)
        if isinstance(opr, RelAddress):
            self._append(op, opr)
        else:
            raise ASMValueError(f"Invalid branch target: {opr}")

    def bcc(self, opr: str | RelAddress | int):
        """Branch if carry flag clear"""
        self._branch(OpCode.BCC_rel, opr)

    def bcs(self, opr: str | RelAddress | int):
        """Branch if carry flag set"""
        self._branch(OpCode.BCS_rel, opr)

    def beq(self, opr: str | RelAddress | int):
        """Branch if zero flag set"""
        self._branch(OpCode.BEQ_rel, opr)

    def bmi(self, opr: str | RelAddress | int):
        """Branch if negative flag set"""
        self._branch(OpCode.BMI_rel, opr)

    def bne(self, opr: str | RelAddress | int):
        """Branch if zero flag clear"""
        self._branch(OpCode.BNE_rel, opr)

    def bpl(self, opr: str | RelAddress | int):
        """Branch if negative flag clear"""
        self._branch(OpCode.BPL_rel, opr)

    def bvc(self, opr: str | RelAddress | int):
        """Branch if overflow flag clear"""
        self._branch(OpCode.BVC_rel, opr)

    def bvs(self, opr: str | RelAddress | int):
        """Branch if overflow flag set"""
        self._branch(OpCode.BVS_rel, opr)

    # </editor-fold>

    # <editor-fold desc="Jumps & Subroutines">

    def jmp(self, opr: _Abs | _Ind | str):
        """Jump to address"""
        if isinstance(opr, str):
            opr = self.label_addr_absolute(opr)

        if isinstance(opr, _Abs):
            self._append(*opr.map_instruction("JMP", OpCode.JMP_abs))
        elif isinstance(opr, _Ind):
            self._append(*opr.map_instruction("JMP", OpCode.JMP_ind))
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def jsr(self, opr: _Abs | str):
        """Jump to subroutine"""
        if isinstance(opr, str):
            opr = self.label_addr_absolute(opr)

        if isinstance(opr, _Abs):
            return self._append(*opr.map_instruction("JSR", OpCode.JSR_abs))
        else:
            raise ASMValueError(f"Invalid operand type: {type(opr)}")

    def rts(self):
        """Return from subroutine"""
        return self._append(OpCode.RTS)

    # </editor-fold>

    # <editor-fold desc="Interrupts">

    def brk(self):
        """Force an interrupt"""
        return self._append(OpCode.BRK)

    def rti(self):
        """Return from Interrupt"""
        return self._append(OpCode.RTI)

    # </editor-fold>

    # <editor-fold desc="Other">

    def nop(self):
        """No operation."""
        self._append(OpCode.NOP)

    # </editor-fold>


if __name__ == "__main__":
    a = Assembler(base_address=0xff00)

    a.label("reset")
    a.cld()
    a.cli()
    a.label("halt")
    a.jmp("halt")

    print(a)

    # a.adc(Val(0x42))
    # a.adc(Abs[0x32])
    # a.adc(Abs[0x4323])
    # a.adc(Abs[0x4323:X])
    # a.adc(Abs[0x4323:Y])
    # a.adc(Ind[0x23:X])
    Path("test-sample.bin").write_bytes(a.__bytes__())
