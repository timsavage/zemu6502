; Can be compiled with https://www.masswerk.at/6502/assembler.html
  .org $FF00

reset_handler:
  ; Reset stack pointer
  LDX #$ff
  TXS
  LDY #10
hello_loop:
  DEY
  BEQ hello_done
  LDX #0
hello_char_loop:
  LDA hello_message,x
  BEQ hello_loop
  JSR print_char
  INX
  JMP hello_char_loop
hello_done:
  BRK
  LDY #10
  JMP hello_loop

irq_handler:
  LDX #0
irq_char_loop:
  LDA irq_message,x
  BEQ irq_return
  JSR print_char
  INX
  JMP irq_char_loop
irq_return:
  RTI

; Print Char sub-routine
print_char:
  STA $8000   ; Print to terminal
  RTS

; String table
.org $FFA0
hello_message:
  .text "Hello World!"
  .word $000A
irq_message:
  .text "Lets do it again!"
  .word $000A

; Reset Vectors
  .org $FFFA
  .word $0000         ; NMI
  .word reset_handler ; Reset
  .word irq_handler   ; IRQ
