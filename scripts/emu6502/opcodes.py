from enum import IntEnum


class OpCode(IntEnum):
    """All possible 6502 Opcodes"""

    BRK = 0x00
    ORA_X_ind = 0x01
    # Unused = 0x02
    # Unused = 0x03
    # Unused = 0x04
    ORA_zpg = 0x05
    ASL_zpg = 0x06
    # Unused = 0x07
    PHP = 0x08
    ORA_imm = 0x09
    ASL = 0x0A
    # Unused = 0x0B
    # Unused = 0x0C
    ORA_abs = 0x0D
    ASL_abs = 0x0E
    # Unused = 0x0F

    BPL_rel = 0x10
    ORA_ind_Y = 0x11
    # Unused = 0x12
    # Unused = 0x13
    # Unused = 0x14
    ORA_zpg_X = 0x15
    ASL_zpg_X = 0x16
    # Unused = 0x17
    CLC = 0x18
    ORA_abs_Y = 0x19
    # Unused = 0x1A
    # Unused = 0x1B
    # Unused = 0x1C
    ORA_abs_X = 0x1D
    ASL_abs_X = 0x1E
    # Unused = 0x1F

    JSR_abs = 0x20
    AND_X_ind = 0x21
    # Unused = 0x22
    # Unused = 0x23
    BIT_zpg = 0x24
    AND_zpg = 0x25
    ROL_zpg = 0x26
    # Unused = 0x27
    PLP = 0x28
    AND_imm = 0x29
    ROL_A = 0x2A
    # Unused = 0x2B
    BIT_abs = 0x2C
    AND_abs = 0x2D
    ROL_abs = 0x2E
    # Unused = 0x2F

    BMI_rel = 0x30
    AND_ind_Y = 0x31
    # Unused = 0x32
    # Unused = 0x33
    # Unused = 0x34
    AND_zpg_X = 0x35
    ROL_zpg_X = 0x36
    # Unused = 0x37
    SEC = 0x38
    AND_abs_Y = 0x39
    # Unused = 0x3A
    # Unused = 0x3B
    # Unused = 0x3C
    AND_abs_X = 0x3D
    ROL_abs_X = 0x3E
    # Unused = 0x3F

    RTI = 0x40
    EOR_X_ind = 0x41
    # Unused = 0x42
    # Unused = 0x43
    # Unused = 0x44
    EOR_zpg = 0x45
    LSR_zpg = 0x46
    # Unused = 0x47
    PHA_imp = 0x48
    EOR_imm = 0x49
    LSR = 0x4A
    # Unused = 0x4B
    JMP_abs = 0x4C
    EOR_abs = 0x4D
    LSR_abs = 0x4E
    # Unused = 0x4F

    BVC_rel = 0x50
    EOR_ind_Y = 0x51
    # Unused = 0x52
    # Unused = 0x53
    # Unused = 0x54
    EOR_zpg_X = 0x55
    LSR_zpg_X = 0x56
    # Unused = 0x57
    CLI_imp = 0x58
    EOR_abs_Y = 0x59
    # Unused = 0x5A
    # Unused = 0x5B
    # Unused = 0x5C
    EOR_abs_X = 0x5D
    LSR_abs_X = 0x5E
    # Unused = 0x5F

    RTS = 0x60
    ADC_X_ind = 0x61
    # Unused = 0x62
    # Unused = 0x63
    # Unused = 0x64
    ADC_zpg = 0x65
    ROR_zpg = 0x66
    # Unused = 0x67
    PLA = 0x68
    ADC_imm = 0x69
    ROR_A = 0x6A
    # Unused = 0x6B
    JMP_ind = 0x6C
    ADC_abs = 0x6D
    ROR_abs = 0x6E
    # Unused = 0x6F

    BVS_rel = 0x70
    ADC_ind_Y = 0x71
    # Unused = 0x72
    # Unused = 0x73
    # Unused = 0x74
    ADC_zpg_X = 0x75
    ROR_zpg_X = 0x76
    # Unused = 0x77
    SEI = 0x78
    ADC_abs_Y = 0x79
    # Unused = 0x7A
    # Unused = 0x7B
    # Unused = 0x7C
    ADC_abs_X = 0x7D
    ROR_abs_X = 0x7E
    # Unused = 0x7F

    # Unused = 0x80
    STA_X_ind = 0x81
    # Unused = 0x82
    # Unused = 0x83
    STY_zpg = 0x84
    STA_zpg = 0x85
    STX_zpg = 0x86
    # Unused = 0x87
    DEY = 0x88
    # Unused = 0x89
    TXA = 0x8A
    # Unused = 0x8B
    STY_abs = 0x8C
    STA_abs = 0x8D
    STX_abs = 0x8E
    # Unused = 0x8F

    BCC_rel = 0x90
    STA_ind_Y = 0x91
    # Unused = 0x92
    # Unused = 0x93
    STY_zpg_X = 0x94
    STA_zpg_X = 0x95
    STX_zpg_Y = 0x96
    # Unused = 0x97
    TYA = 0x98
    STA_abs_Y = 0x99
    TXS = 0x9A
    # Unused = 0x9B
    # Unused = 0x9C
    STA_abs_X = 0x9D
    # Unused = 0x9E
    # Unused = 0x9F

    LDY_imm = 0xA0
    LDA_X_ind = 0xA1
    LDX_imm = 0xA2
    # Unused = 0xA3
    LDY_zpg = 0xA4
    LDA_zpg = 0xA5
    LDX_zpg = 0xA6
    # Unused = 0xA7
    TAY = 0xA8
    LDA_ind = 0xA9
    TAX = 0xAA
    # Unused = 0xAB
    LDY_abs = 0xAC
    LDA_abs = 0xAD
    LDX_abs = 0xAE
    # Unused = 0xAF

    BCS_rel = 0xB0
    LDA_ind_Y = 0xB1
    # Unused = 0xB2
    # Unused = 0xB3
    LDY_zpg_X = 0xB4
    LDA_zpg_X = 0xB5
    LDX_zpg_Y = 0xB6
    # Unused = 0xB7
    CLV = 0xB8
    LDA_abs_Y = 0xB9
    TSX = 0xBA
    # Unused = 0xBB
    LDY_abs_X = 0xBC
    LDA_abs_X = 0xBD
    LDX_abs_Y = 0xBE
    # Unused = 0xBF

    CPY_imm = 0xC0
    CMP_X_ind = 0xC1
    # Unused = 0xC2
    # Unused = 0xC3
    CPY_zpg = 0xC4
    CMP_zpg = 0xC5
    DEV_zpg = 0xC6
    # Unused = 0xC7
    INY = 0xC8
    CMP_imm = 0xC9
    DEX = 0xCA
    # Unused = 0xCB
    CPY_abs = 0xCC
    CMP_abs = 0xCD
    DEC_abs = 0xCE
    # Unused = 0xCF

    BNE_rel = 0xD0
    CMP_ind_Y = 0xD1
    # Unused = 0xD2
    # Unused = 0xD3
    # Unused = 0xD4
    CMP_zpg_X = 0xD5
    DEC_zpg_X = 0xD6
    # Unused = 0xD7
    CLD = 0xD8
    CMP_abs_Y = 0xD9
    # Unused = 0xDA
    # Unused = 0xDB
    # Unused = 0xDC
    CMP_abs_X = 0xDD
    DEC_abs_X = 0xDE
    # Unused = 0xDF

    CPX_imm = 0xE0
    SBC_X_ind = 0xE1
    # Unused = 0xE2
    # Unused = 0xE3
    CPX_zpg = 0xE4
    SBC_zpg = 0xE5
    INC_zpg = 0xE6
    # Unused = 0xE7
    INX = 0xE8
    SBC_imm = 0xE9
    NOP = 0xEA
    # Unused = 0xEB
    CPX_abs = 0xEC
    SBC_abs = 0xED
    INC_abs = 0xEE
    # Unused = 0xEF

    BEQ_rel = 0xF0
    SBC_ind_Y = 0xF1
    # Unused = 0xF2
    # Unused = 0xF3
    # Unused = 0xF4
    SBC_zpg_X = 0xF5
    INC_zpg_X = 0xF6
    # Unused = 0xF7
    SED = 0xF8
    SBC_abs_Y = 0xF9
    # Unused = 0xFA
    # Unused = 0xFB
    # Unused = 0xFC
    SBC_abs_X = 0xFD
    INC_abs_X = 0xFE
    # Unused = 0xFF


def table():
    print(" Hi", *[f"{lo:^-9X}" for lo in range(0, 0x10)], "", sep=" | ")

    for hi in range(0, 0x10):
        print(f" {hi:X}- |", end="")
        for lo in range(0, 0x10):
            try:
                name = OpCode((hi << 4) | lo).name
            except ValueError:
                name = ""
            print(f" {name:9s} |", end="")
        print()


if __name__ == "__main__":
    table()
