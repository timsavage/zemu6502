import pytest
from emu6502.address import RelAddress
from emu6502.asm import Abs, Assembler, Ind, Instruction, Val, X, Y
from emu6502.errors import ASMLabelNotFound, ASMValueError
from emu6502.opcodes import OpCode


class TestInstruction:
    def test_instruction_implicit(self):
        inst = Instruction(OpCode.NOP)
        assert inst.op == OpCode.NOP
        assert inst.operands == b""
        assert len(inst) == 1
        assert bytes(inst) == b"\xea"
        assert str(inst) == "NOP       "

    def test_instruction_single_byte_operand(self):
        inst = Instruction(OpCode.LDA_imm, b"\x42")
        assert inst.op == OpCode.LDA_imm
        assert inst.operands == b"\x42"
        assert len(inst) == 2
        assert bytes(inst) == b"\xa9\x42"
        assert str(inst) == "LDA_imm   0x42"

    def test_instruction_two_byte_operands(self):
        inst = Instruction(OpCode.LDA_abs, b"\x34\x12")
        assert inst.op == OpCode.LDA_abs
        assert inst.operands == b"\x34\x12"
        assert len(inst) == 3
        assert bytes(inst) == b"\xad\x34\x12"
        assert str(inst) == "LDA_abs   0x34 0x12"

    def test_instruction_namedtuple_unpacking(self):
        op, operands = Instruction(OpCode.TAX)
        assert op == OpCode.TAX
        assert operands == b""

    def test_instruction_equality(self):
        inst1 = Instruction(OpCode.BRK)
        inst2 = Instruction(OpCode.BRK, b"")
        assert inst1 == inst2


class TestAssembler:
    # Transfer instructions

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.LDA_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.LDA_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.LDA_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.LDA_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.LDA_abs_X, b"\x34\x12")),
            (Abs[0x1234:Y], Instruction(OpCode.LDA_abs_Y, b"\x34\x12")),
            (Ind[0x42:X], Instruction(OpCode.LDA_X_ind, b"\x42")),
            (Ind[0x42:Y], Instruction(OpCode.LDA_ind_Y, b"\x42")),
        ],
    )
    def test_lda(self, val, expected):
        target = Assembler()

        target.lda(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.LDX_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.LDX_zpg, b"\x42")),
            (Abs[0x42:Y], Instruction(OpCode.LDX_zpg_Y, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.LDX_abs, b"\x34\x12")),
            (Abs[0x1234:Y], Instruction(OpCode.LDX_abs_Y, b"\x34\x12")),
        ],
    )
    def test_ldx(self, val, expected):
        target = Assembler()

        target.ldx(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.LDY_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.LDY_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.LDY_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.LDY_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.LDY_abs_X, b"\x34\x12")),
        ],
    )
    def test_ldy(self, val, expected):
        target = Assembler()

        target.ldy(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], Instruction(OpCode.STA_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.STA_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.STA_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.STA_abs_X, b"\x34\x12")),
            (Abs[0x1234:Y], Instruction(OpCode.STA_abs_Y, b"\x34\x12")),
            (Ind[0x42:X], Instruction(OpCode.STA_X_ind, b"\x42")),
            (Ind[0x42:Y], Instruction(OpCode.STA_ind_Y, b"\x42")),
        ],
    )
    def test_sta(self, val, expected):
        target = Assembler()

        target.sta(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], Instruction(OpCode.STX_zpg, b"\x42")),
            (Abs[0x42:Y], Instruction(OpCode.STX_zpg_Y, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.STX_abs, b"\x34\x12")),
        ],
    )
    def test_stx(self, val, expected):
        target = Assembler()

        target.stx(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], Instruction(OpCode.STY_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.STY_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.STY_abs, b"\x34\x12")),
        ],
    )
    def test_sty(self, val, expected):
        target = Assembler()

        target.sty(val)

        assert target.instructions == [expected]

    def test_tax(self):
        target = Assembler()

        target.tax()

        assert target.instructions == [Instruction(OpCode.TAX)]

    def test_tay(self):
        target = Assembler()

        target.tay()

        assert target.instructions == [Instruction(OpCode.TAY)]

    def test_tsx(self):
        target = Assembler()

        target.tsx()

        assert target.instructions == [Instruction(OpCode.TSX)]

    def test_txa(self):
        target = Assembler()

        target.txa()

        assert target.instructions == [Instruction(OpCode.TXA)]

    def test_txs(self):
        target = Assembler()

        target.txs()

        assert target.instructions == [Instruction(OpCode.TXS)]

    def test_tya(self):
        target = Assembler()

        target.tya()

        assert target.instructions == [Instruction(OpCode.TYA)]

    # Stack Operations

    def test_pha(self):
        target = Assembler()
        target.pha()
        assert target.instructions == [Instruction(OpCode.PHA)]

    def test_php(self):
        target = Assembler()
        target.php()
        assert target.instructions == [Instruction(OpCode.PHP)]

    def test_pla(self):
        target = Assembler()
        target.pla()
        assert target.instructions == [Instruction(OpCode.PLA)]

    def test_plp(self):
        target = Assembler()
        target.plp()
        assert target.instructions == [Instruction(OpCode.PLP)]

    # Decrements & Increments

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], Instruction(OpCode.DEC_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.DEC_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.DEC_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.DEC_abs_X, b"\x34\x12")),
        ],
    )
    def test_dec(self, val, expected):
        target = Assembler()
        target.dec(val)
        assert target.instructions == [expected]

    def test_dex(self):
        target = Assembler()
        target.dex()
        assert target.instructions == [Instruction(OpCode.DEX)]

    def test_dey(self):
        target = Assembler()
        target.dey()
        assert target.instructions == [Instruction(OpCode.DEY)]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], Instruction(OpCode.INC_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.INC_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.INC_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.INC_abs_X, b"\x34\x12")),
        ],
    )
    def test_inc(self, val, expected):
        target = Assembler()
        target.inc(val)
        assert target.instructions == [expected]

    def test_inx(self):
        target = Assembler()
        target.inx()
        assert target.instructions == [Instruction(OpCode.INX)]

    def test_iny(self):
        target = Assembler()
        target.iny()
        assert target.instructions == [Instruction(OpCode.INY)]

    # Arithmetic Operations

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.ADC_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.ADC_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.ADC_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.ADC_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.ADC_abs_X, b"\x34\x12")),
            (Abs[0x1234:Y], Instruction(OpCode.ADC_abs_Y, b"\x34\x12")),
            (Ind[0x42:X], Instruction(OpCode.ADC_X_ind, b"\x42")),
            (Ind[0x42:Y], Instruction(OpCode.ADC_ind_Y, b"\x42")),
        ],
    )
    def test_adc(self, val, expected):
        target = Assembler()

        target.adc(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.SBC_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.SBC_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.SBC_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.SBC_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.SBC_abs_X, b"\x34\x12")),
            (Abs[0x1234:Y], Instruction(OpCode.SBC_abs_Y, b"\x34\x12")),
            (Ind[0x42:X], Instruction(OpCode.SBC_X_ind, b"\x42")),
            (Ind[0x42:Y], Instruction(OpCode.SBC_ind_Y, b"\x42")),
        ],
    )
    def test_sbc(self, val, expected):
        target = Assembler()
        target.sbc(val)
        assert target.instructions == [expected]

    # Logic Operations

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.AND_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.AND_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.AND_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.AND_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.AND_abs_X, b"\x34\x12")),
            (Abs[0x1234:Y], Instruction(OpCode.AND_abs_Y, b"\x34\x12")),
            (Ind[0x42:X], Instruction(OpCode.AND_X_ind, b"\x42")),
            (Ind[0x42:Y], Instruction(OpCode.AND_ind_Y, b"\x42")),
        ],
    )
    def test_and(self, val, expected):
        target = Assembler()

        target.and_(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.EOR_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.EOR_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.EOR_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.EOR_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.EOR_abs_X, b"\x34\x12")),
            (Abs[0x1234:Y], Instruction(OpCode.EOR_abs_Y, b"\x34\x12")),
            (Ind[0x42:X], Instruction(OpCode.EOR_X_ind, b"\x42")),
            (Ind[0x42:Y], Instruction(OpCode.EOR_ind_Y, b"\x42")),
        ],
    )
    def test_eor(self, val, expected):
        target = Assembler()
        target.eor(val)
        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.ORA_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.ORA_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.ORA_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.ORA_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.ORA_abs_X, b"\x34\x12")),
            (Abs[0x1234:Y], Instruction(OpCode.ORA_abs_Y, b"\x34\x12")),
            (Ind[0x42:X], Instruction(OpCode.ORA_X_ind, b"\x42")),
            (Ind[0x42:Y], Instruction(OpCode.ORA_ind_Y, b"\x42")),
        ],
    )
    def test_ora(self, val, expected):
        target = Assembler()
        target.ora(val)
        assert target.instructions == [expected]

    # Shift & Rotate Instructions

    @pytest.mark.parametrize(
        "val, expected",
        [
            (None, Instruction(OpCode.ASL)),
            (Abs[0x42], Instruction(OpCode.ASL_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.ASL_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.ASL_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.ASL_abs_X, b"\x34\x12")),
        ],
    )
    def test_asl(self, val, expected):
        target = Assembler()
        if val is None:
            target.asl()
        else:
            target.asl(val)
        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (None, Instruction(OpCode.LSR)),
            (Abs[0x42], Instruction(OpCode.LSR_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.LSR_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.LSR_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.LSR_abs_X, b"\x34\x12")),
        ],
    )
    def test_lsr(self, val, expected):
        target = Assembler()
        if val is None:
            target.lsr()
        else:
            target.lsr(val)
        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (None, Instruction(OpCode.ROL)),
            (Abs[0x42], Instruction(OpCode.ROL_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.ROL_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.ROL_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.ROL_abs_X, b"\x34\x12")),
        ],
    )
    def test_rol(self, val, expected):
        target = Assembler()
        if val is None:
            target.rol()
        else:
            target.rol(val)
        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (None, Instruction(OpCode.ROR)),
            (Abs[0x42], Instruction(OpCode.ROR_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.ROR_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.ROR_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.ROR_abs_X, b"\x34\x12")),
        ],
    )
    def test_ror(self, val, expected):
        target = Assembler()
        if val is None:
            target.ror()
        else:
            target.ror(val)
        assert target.instructions == [expected]

    # Flag Instructions

    def test_clc(self):
        target = Assembler()
        target.clc()
        assert target.instructions == [Instruction(OpCode.CLC)]

    def test_cld(self):
        target = Assembler()
        target.cld()
        assert target.instructions == [Instruction(OpCode.CLD)]

    def test_cli(self):
        target = Assembler()
        target.cli()
        assert target.instructions == [Instruction(OpCode.CLI)]

    def test_clv(self):
        target = Assembler()
        target.clv()
        assert target.instructions == [Instruction(OpCode.CLV)]

    def test_sec(self):
        target = Assembler()
        target.sec()
        assert target.instructions == [Instruction(OpCode.SEC)]

    def test_sed(self):
        target = Assembler()
        target.sed()
        assert target.instructions == [Instruction(OpCode.SED)]

    def test_sei(self):
        target = Assembler()
        target.sei()
        assert target.instructions == [Instruction(OpCode.SEI)]

    # Comparisons

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.CMP_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.CMP_zpg, b"\x42")),
            (Abs[0x42:X], Instruction(OpCode.CMP_zpg_X, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.CMP_abs, b"\x34\x12")),
            (Abs[0x1234:X], Instruction(OpCode.CMP_abs_X, b"\x34\x12")),
            (Abs[0x1234:Y], Instruction(OpCode.CMP_abs_Y, b"\x34\x12")),
            (Ind[0x42:X], Instruction(OpCode.CMP_X_ind, b"\x42")),
            (Ind[0x42:Y], Instruction(OpCode.CMP_ind_Y, b"\x42")),
        ],
    )
    def test_cmp(self, val, expected):
        target = Assembler()
        target.cmp(val)
        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.CPX_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.CPX_zpg, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.CPX_abs, b"\x34\x12")),
        ],
    )
    def test_cpx(self, val, expected):
        target = Assembler()
        target.cpx(val)
        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), Instruction(OpCode.CPY_imm, b"\x42")),
            (Abs[0x42], Instruction(OpCode.CPY_zpg, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.CPY_abs, b"\x34\x12")),
        ],
    )
    def test_cpy(self, val, expected):
        target = Assembler()
        target.cpy(val)
        assert target.instructions == [expected]

    # Bit Test

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], Instruction(OpCode.BIT_zpg, b"\x42")),
            (Abs[0x1234], Instruction(OpCode.BIT_abs, b"\x34\x12")),
        ],
    )
    def test_bit(self, val, expected):
        target = Assembler()
        target.bit(val)
        assert target.instructions == [expected]

    # Conditional Branch Instructions

    @pytest.mark.parametrize(
        "branch_method, opcode",
        [
            ("bcc", OpCode.BCC_rel),
            ("bcs", OpCode.BCS_rel),
            ("beq", OpCode.BEQ_rel),
            ("bmi", OpCode.BMI_rel),
            ("bne", OpCode.BNE_rel),
            ("bpl", OpCode.BPL_rel),
            ("bvc", OpCode.BVC_rel),
            ("bvs", OpCode.BVS_rel),
        ],
    )
    def test_branches(self, branch_method, opcode):
        # Test with label
        target = Assembler()
        target.label("start")
        target.nop()
        method = getattr(target, branch_method)
        method("start")
        # Offset was 1 when branch was evaluated, target is 0 -> rel = -1 (0xFF)
        assert target.instructions == [Instruction(OpCode.NOP), Instruction(opcode, b"\xff")]

        # Test with RelAddress
        target2 = Assembler()
        method2 = getattr(target2, branch_method)
        method2(RelAddress(10))
        assert target2.instructions == [Instruction(opcode, b"\x0a")]

        # Test with int
        target3 = Assembler()
        method3 = getattr(target3, branch_method)
        method3(10)
        assert target3.instructions == [Instruction(opcode, b"\x0a")]

    # Jumps & Subroutines

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x1234], Instruction(OpCode.JMP_abs, b"\x34\x12")),
            (Ind[0x42], Instruction(OpCode.JMP_ind, b"\x42")),
        ],
    )
    def test_jmp(self, val, expected):
        target = Assembler()
        target.jmp(val)
        assert target.instructions == [expected]

    def test_jmp_label(self):
        target = Assembler()
        target.label("start")
        target.jmp("start")
        assert target.instructions == [Instruction(OpCode.JMP_abs, b"\x00\x00")]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], Instruction(OpCode.JSR_abs, b"\x42\x00")),
            (Abs[0x1234], Instruction(OpCode.JSR_abs, b"\x34\x12")),
        ],
    )
    def test_jsr(self, val, expected):
        target = Assembler()
        target.jsr(val)
        assert target.instructions == [expected]

    def test_jsr_label(self):
        target = Assembler()
        target.label("sub")
        target.jsr("sub")
        assert target.instructions == [Instruction(OpCode.JSR_abs, b"\x00\x00")]

    def test_rts(self):
        target = Assembler()
        target.rts()
        assert target.instructions == [Instruction(OpCode.RTS)]

    # Interrupts & System

    def test_brk(self):
        target = Assembler()
        target.brk()
        assert target.instructions == [Instruction(OpCode.BRK)]

    def test_rti(self):
        target = Assembler()
        target.rti()
        assert target.instructions == [Instruction(OpCode.RTI)]

    def test_nop(self):
        target = Assembler()
        target.nop()
        assert target.instructions == [Instruction(OpCode.NOP)]

    # Labels and relative addresses

    def test_labels_and_relative_addressing(self):
        target = Assembler()
        target.nop()
        target.label("loop")
        target.lda(Val(0x10))
        target.label("after")

        assert target.labels == {"loop": 1, "after": 3}
        rel = target.label_addr_relative("loop")
        assert isinstance(rel, RelAddress)
        assert rel == 1 - 3  # -2

    def test_label_not_found(self):
        target = Assembler()
        with pytest.raises(ASMLabelNotFound):
            target.label_addr_relative("missing")

    def test_label_out_of_range(self):
        target = Assembler()
        target.label("start")
        # Offset exceeds 127 bytes
        target._offset = 200
        with pytest.raises(ASMValueError, match="must be within 127"):
            target.label_addr_relative("start")

    # Error handling for invalid operand types

    @pytest.mark.parametrize(
        "method_name",
        [
            "lda",
            "ldx",
            "ldy",
            "sta",
            "stx",
            "sty",
            "adc",
            "sbc",
            "and_",
            "eor",
            "ora",
            "dec",
            "inc",
            "cmp",
            "cpx",
            "cpy",
            "asl",
            "lsr",
            "rol",
            "ror",
            "bit",
            "jmp",
            "jsr",
            "bcc",
            "bcs",
            "beq",
            "bmi",
            "bne",
            "bpl",
            "bvc",
            "bvs",
        ],
    )
    def test_invalid_operand_type_asm_value_error(self, method_name):
        target = Assembler()
        method = getattr(target, method_name)
        with pytest.raises(ASMValueError):
            method(object())

    # String representation

    def test_str_representation(self):
        target = Assembler()
        target.lda(Val(0x42))
        target.sta(Abs[0x1234])
        target.nop()
        rendered = str(target)
        assert "0000: LDA_imm   0x42" in rendered
        assert "0002: STA_abs   0x34 0x12" in rendered
        assert "0005: NOP" in rendered
