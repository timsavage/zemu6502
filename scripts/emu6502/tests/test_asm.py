import pytest
from emu6502.asm import Assembler, Abs, Ind, X, Y, Val
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
