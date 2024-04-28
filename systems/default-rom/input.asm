KEYBOARD_ADDR = $8010
TERMINAL_ADDR = $8000

        .org $FF00

reset_handler:
        JMP     reset_handler

nmi_handler:
        LDA     KEYBOARD_ADDR
        BEQ     nmi_return
        STA     TERMINAL_ADDR
nmi_return:
        RTI

        ; Reset Vectors
        .org    $FFFA
        .word   nmi_handler     ; NMI
        .word   reset_handler   ; Reset
        .word   $0000           ; IRQ
