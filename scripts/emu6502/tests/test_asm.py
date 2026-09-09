import pytest
from emu6502.asm import Assembler, Abs, Ind, X, Y, Val
from emu6502.errors import ASMValueError, ASMLabelNotFound
from emu6502.address import RelAddress
from emu6502.opcodes import OpCode


class TestAssembler:
    # Transfer instructions

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), [OpCode.LDA_imm, 0x42]),
            (Abs[0x42], [OpCode.LDA_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.LDA_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.LDA_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.LDA_abs_X, 0x34, 0x12]),
            (Abs[0x1234:Y], [OpCode.LDA_abs_Y, 0x34, 0x12]),
            (Ind[0x42:X], [OpCode.LDA_X_ind, 0x42]),
            (Ind[0x42:Y], [OpCode.LDA_ind_Y, 0x42]),
        ],
    )
    def test_lda(self, val, expected):
        target = Assembler()

        target.lda(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), [OpCode.LDX_imm, 0x42]),
            (Abs[0x42], [OpCode.LDX_zpg, 0x42]),
            (Abs[0x42:Y], [OpCode.LDX_zpg_Y, 0x42]),
            (Abs[0x1234], [OpCode.LDX_abs, 0x34, 0x12]),
            (Abs[0x1234:Y], [OpCode.LDX_abs_Y, 0x34, 0x12]),
        ],
    )
    def test_ldx(self, val, expected):
        target = Assembler()

        target.ldx(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), [OpCode.LDY_imm, 0x42]),
            (Abs[0x42], [OpCode.LDY_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.LDY_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.LDY_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.LDY_abs_X, 0x34, 0x12]),
        ],
    )
    def test_ldy(self, val, expected):
        target = Assembler()

        target.ldy(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], [OpCode.STA_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.STA_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.STA_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.STA_abs_X, 0x34, 0x12]),
            (Abs[0x1234:Y], [OpCode.STA_abs_Y, 0x34, 0x12]),
            (Ind[0x42:X], [OpCode.STA_X_ind, 0x42]),
            (Ind[0x42:Y], [OpCode.STA_ind_Y, 0x42]),
        ],
    )
    def test_sta(self, val, expected):
        target = Assembler()

        target.sta(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], [OpCode.STX_zpg, 0x42]),
            (Abs[0x42:Y], [OpCode.STX_zpg_Y, 0x42]),
            (Abs[0x1234], [OpCode.STX_abs, 0x34, 0x12]),
        ],
    )
    def test_stx(self, val, expected):
        target = Assembler()

        target.stx(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], [OpCode.STY_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.STY_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.STY_abs, 0x34, 0x12]),
        ],
    )
    def test_sty(self, val, expected):
        target = Assembler()

        target.sty(val)

        assert target.instructions == [expected]

    def test_tax(self):
        target = Assembler()

        target.tax()

        assert target.instructions == [[OpCode.TAX]]

    def test_tay(self):
        target = Assembler()

        target.tay()

        assert target.instructions == [[OpCode.TAY]]

    def test_tsx(self):
        target = Assembler()

        target.tsx()

        assert target.instructions == [[OpCode.TSX]]

    def test_txa(self):
        target = Assembler()

        target.txa()

        assert target.instructions == [[OpCode.TXA]]

    def test_txs(self):
        target = Assembler()

        target.txs()

        assert target.instructions == [[OpCode.TXS]]

    def test_tya(self):
        target = Assembler()

        target.tya()

        assert target.instructions == [[OpCode.TYA]]

    # Stack Operations

    def test_pha(self):
        target = Assembler()
        target.pha()
        assert target.instructions == [[OpCode.PHA]]

    def test_php(self):
        target = Assembler()
        target.php()
        assert target.instructions == [[OpCode.PHP]]

    def test_pla(self):
        target = Assembler()
        target.pla()
        assert target.instructions == [[OpCode.PLA]]

    def test_plp(self):
        target = Assembler()
        target.plp()
        assert target.instructions == [[OpCode.PLP]]

    # Decrements & Increments

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], [OpCode.DEC_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.DEC_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.DEC_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.DEC_abs_X, 0x34, 0x12]),
        ],
    )
    def test_dec(self, val, expected):
        target = Assembler()
        target.dec(val)
        assert target.instructions == [expected]

    def test_dex(self):
        target = Assembler()
        target.dex()
        assert target.instructions == [[OpCode.DEX]]

    def test_dey(self):
        target = Assembler()
        target.dey()
        assert target.instructions == [[OpCode.DEY]]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], [OpCode.INC_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.INC_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.INC_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.INC_abs_X, 0x34, 0x12]),
        ],
    )
    def test_inc(self, val, expected):
        target = Assembler()
        target.inc(val)
        assert target.instructions == [expected]

    def test_inx(self):
        target = Assembler()
        target.inx()
        assert target.instructions == [[OpCode.INX]]

    def test_iny(self):
        target = Assembler()
        target.iny()
        assert target.instructions == [[OpCode.INY]]

    # Arithmetic Operations

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), [OpCode.ADC_imm, 0x42]),
            (Abs[0x42], [OpCode.ADC_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.ADC_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.ADC_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.ADC_abs_X, 0x34, 0x12]),
            (Abs[0x1234:Y], [OpCode.ADC_abs_Y, 0x34, 0x12]),
            (Ind[0x42:X], [OpCode.ADC_X_ind, 0x42]),
            (Ind[0x42:Y], [OpCode.ADC_ind_Y, 0x42]),
        ],
    )
    def test_adc(self, val, expected):
        target = Assembler()

        target.adc(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), [OpCode.SBC_imm, 0x42]),
            (Abs[0x42], [OpCode.SBC_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.SBC_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.SBC_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.SBC_abs_X, 0x34, 0x12]),
            (Abs[0x1234:Y], [OpCode.SBC_abs_Y, 0x34, 0x12]),
            (Ind[0x42:X], [OpCode.SBC_X_ind, 0x42]),
            (Ind[0x42:Y], [OpCode.SBC_ind_Y, 0x42]),
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
            (Val(0x42), [OpCode.AND_imm, 0x42]),
            (Abs[0x42], [OpCode.AND_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.AND_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.AND_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.AND_abs_X, 0x34, 0x12]),
            (Abs[0x1234:Y], [OpCode.AND_abs_Y, 0x34, 0x12]),
            (Ind[0x42:X], [OpCode.AND_X_ind, 0x42]),
            (Ind[0x42:Y], [OpCode.AND_ind_Y, 0x42]),
        ],
    )
    def test_and(self, val, expected):
        target = Assembler()

        target.and_(val)

        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), [OpCode.EOR_imm, 0x42]),
            (Abs[0x42], [OpCode.EOR_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.EOR_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.EOR_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.EOR_abs_X, 0x34, 0x12]),
            (Abs[0x1234:Y], [OpCode.EOR_abs_Y, 0x34, 0x12]),
            (Ind[0x42:X], [OpCode.EOR_X_ind, 0x42]),
            (Ind[0x42:Y], [OpCode.EOR_ind_Y, 0x42]),
        ],
    )
    def test_eor(self, val, expected):
        target = Assembler()
        target.eor(val)
        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), [OpCode.ORA_imm, 0x42]),
            (Abs[0x42], [OpCode.ORA_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.ORA_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.ORA_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.ORA_abs_X, 0x34, 0x12]),
            (Abs[0x1234:Y], [OpCode.ORA_abs_Y, 0x34, 0x12]),
            (Ind[0x42:X], [OpCode.ORA_X_ind, 0x42]),
            (Ind[0x42:Y], [OpCode.ORA_ind_Y, 0x42]),
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
            (None, [OpCode.ASL]),
            (Abs[0x42], [OpCode.ASL_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.ASL_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.ASL_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.ASL_abs_X, 0x34, 0x12]),
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
            (None, [OpCode.LSR]),
            (Abs[0x42], [OpCode.LSR_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.LSR_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.LSR_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.LSR_abs_X, 0x34, 0x12]),
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
            (None, [OpCode.ROL]),
            (Abs[0x42], [OpCode.ROL_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.ROL_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.ROL_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.ROL_abs_X, 0x34, 0x12]),
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
            (None, [OpCode.ROR]),
            (Abs[0x42], [OpCode.ROR_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.ROR_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.ROR_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.ROR_abs_X, 0x34, 0x12]),
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
        assert target.instructions == [[OpCode.CLC]]

    def test_cld(self):
        target = Assembler()
        target.cld()
        assert target.instructions == [[OpCode.CLD]]

    def test_cli(self):
        target = Assembler()
        target.cli()
        assert target.instructions == [[OpCode.CLI]]

    def test_clv(self):
        target = Assembler()
        target.clv()
        assert target.instructions == [[OpCode.CLV]]

    def test_sec(self):
        target = Assembler()
        target.sec()
        assert target.instructions == [[OpCode.SEC]]

    def test_sed(self):
        target = Assembler()
        target.sed()
        assert target.instructions == [[OpCode.SED]]

    def test_sei(self):
        target = Assembler()
        target.sei()
        assert target.instructions == [[OpCode.SEI]]

    # Comparisons

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), [OpCode.CMP_imm, 0x42]),
            (Abs[0x42], [OpCode.CMP_zpg, 0x42]),
            (Abs[0x42:X], [OpCode.CMP_zpg_X, 0x42]),
            (Abs[0x1234], [OpCode.CMP_abs, 0x34, 0x12]),
            (Abs[0x1234:X], [OpCode.CMP_abs_X, 0x34, 0x12]),
            (Abs[0x1234:Y], [OpCode.CMP_abs_Y, 0x34, 0x12]),
            (Ind[0x42:X], [OpCode.CMP_X_ind, 0x42]),
            (Ind[0x42:Y], [OpCode.CMP_ind_Y, 0x42]),
        ],
    )
    def test_cmp(self, val, expected):
        target = Assembler()
        target.cmp(val)
        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), [OpCode.CPX_imm, 0x42]),
            (Abs[0x42], [OpCode.CPX_zpg, 0x42]),
            (Abs[0x1234], [OpCode.CPX_abs, 0x34, 0x12]),
        ],
    )
    def test_cpx(self, val, expected):
        target = Assembler()
        target.cpx(val)
        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Val(0x42), [OpCode.CPY_imm, 0x42]),
            (Abs[0x42], [OpCode.CPY_zpg, 0x42]),
            (Abs[0x1234], [OpCode.CPY_abs, 0x34, 0x12]),
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
            (Abs[0x42], [OpCode.BIT_zpg, 0x42]),
            (Abs[0x1234], [OpCode.BIT_abs, 0x34, 0x12]),
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
        assert target.instructions == [[OpCode.NOP], [opcode, 0xFF]]

        # Test with RelAddress
        target2 = Assembler()
        method2 = getattr(target2, branch_method)
        method2(RelAddress(10))
        assert target2.instructions == [[opcode, 0x0A]]

        # Test with int
        target3 = Assembler()
        method3 = getattr(target3, branch_method)
        method3(10)
        assert target3.instructions == [[opcode, 0x0A]]

    # Jumps & Subroutines

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x1234], [OpCode.JMP_abs, 0x34, 0x12]),
            (Ind[0x42], [OpCode.JMP_ind, 0x42]),
        ],
    )
    def test_jmp(self, val, expected):
        target = Assembler()
        target.jmp(val)
        assert target.instructions == [expected]

    @pytest.mark.parametrize(
        "val, expected",
        [
            (Abs[0x42], [OpCode.JSR_abs, 0x42, 0x00]),
            (Abs[0x1234], [OpCode.JSR_abs, 0x34, 0x12]),
        ],
    )
    def test_jsr(self, val, expected):
        target = Assembler()
        target.jsr(val)
        assert target.instructions == [expected]

    def test_rts(self):
        target = Assembler()
        target.rts()
        assert target.instructions == [[OpCode.RTS]]

    # Interrupts & System

    def test_brk(self):
        target = Assembler()
        target.brk()
        assert target.instructions == [[OpCode.BRK]]

    def test_rti(self):
        target = Assembler()
        target.rti()
        assert target.instructions == [[OpCode.RTI]]

    def test_nop(self):
        target = Assembler()
        target.nop()
        assert target.instructions == [[OpCode.NOP]]

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
            "asl",
            "lsr",
            "rol",
            "ror",
            "bit",
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

    @pytest.mark.parametrize(
        "method_name",
        ["cpx", "cpy", "jmp"],
    )
    def test_invalid_operand_type_value_error(self, method_name):
        target = Assembler()
        method = getattr(target, method_name)
        with pytest.raises(ValueError):
            method("invalid")

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
