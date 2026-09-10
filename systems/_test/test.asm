;  Simple Test Program for external testing of programs using the debug interface
;  Written by Tim Savage

               .org $FF00

RESET:          CLD             ; Clear decimal arithmetic mode.
                CLI
HALT:
                JMP HALT

                .org $FFFA

; Interrupt Vectors

                .WORD $1234     ; NMI
                .WORD RESET     ; RESET
                .WORD $1234     ; BRK/IRQ
