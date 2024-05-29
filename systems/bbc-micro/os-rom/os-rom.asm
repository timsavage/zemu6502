        .org    $C000
        include "characters.asm"
        include "reset.asm"
        include "interrupts.asm"

        .org    $FFFA
        ; Reset Vectors
        .word nmiEntryPoint     ; NMI
        .word resetEntryPoint   ; Reset
        .word irqEntryPoint     ; IRQ
