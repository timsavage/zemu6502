XAML = $24                              ; Last "opened" location Low
XAMH = $25                              ; Last "opened" location High
STL  = $26                              ; Store address Low
STH  = $27                              ; Store address High
L    = $28                              ; Hex value parsing Low
H    = $29                              ; Hex value parsing High
YSAV = $2A                              ; Used to see if hex value is given
MODE = $2B                              ; $00=XAM, $7F=STOR, $AE=BLOCK XAM

IN   = $0200                            ; Input text buffer

TERMINAL = $D012                        ; Terminal output peripheral
KEYBOARD = $D010                        ; Keyboard input peripheral

                .ORG $FF00

RESET:
                CLD                     ; Clear decimal mode.
                CLI
                LDA     #$1B            ; Begin with escape.

NOTCR:
                CMP     #$08            ; Backspace key
                BEQ     BACKSPACE       ; Yes
                CMP     #$1B            ; ESC? / ~
                BEQ     ESCAPE          ; Yes
                INY                     ; Advance text index
                BPL     NEXTCHAR        ;

ESCAPE:
                LDA     #$5C            ; "\"
                JSR     ECHO

GETLINE:
                LDA     #$0A            ; Send NL
                JSR     ECHO

                LDY     #$01            ; Init text index
BACKSPACE:
                DEY                     ; Backup text index
                BMI     GETLINE         ; Beyond start of line

NEXTCHAR:
                LDA     KEYBOARD
                BEQ     NEXTCHAR        ; Loop until a key is ready
                STA     IN,Y            ; Store in buffer
                JSR     ECHO
                CMP     #$0A            ; NL?
                BNE     NOTCR

                LDY     #$FF            ; Reset text input
                LDA     #$00
                TAX
SETBLOCK:
                ASL
SETSTORE:
                ASL
                STA     MODE
BLSKIP:
                INY
NEXTITEM:
                LDA     IN,Y
                CMP     #$0A            ; NL?
                BEQ     GETLINE
                CMP     #$2E            ; "."?
                BCC     BLSKIP          ; Skip delimiter
                BEQ     SETBLOCK        ; Set BLOCK XAM mode.
                CMP     #$3A            ; ":"?
                BEQ     SETSTORE        ; Set STOR mode.
                CMP     #$52            ; "R"?
                BEQ     RUN
                STX     L
                STX     H
                STY     YSAV            ; Save Y for comparison

NEXTHEX:
                LDA     IN,Y            ; Get character for hex test.
                EOR     #$30            ; Map digits 0-9
                CMP     #$0A            ; Digit?
                BCC     DIG             ; Yes
                ADC     #$88            ; Map letter A-F to FA-FF
                CMP     #$FA            ; Hex letter
                BCC     NOTHEX          ; No, character not hex
DIG:
                ASL
                ASL
                ASL
                ASL

                LDX     #$04           ; Shift count.
HEXSHIFT:
                ASL                    ; Hex digit left, MSB to carry.
                ROL     L              ; Rotate into LSD.
                ROL     H              ; Rotate into MSD's.
                DEX                    ; Done 4 shifts?
                BNE     HEXSHIFT       ; No, loop.
                INY                    ; Advance text index.
                BNE     NEXTHEX        ; Always taken. Check next character for hex.

NOTHEX:
                CPY     YSAV           ; Check if L, H empty (no hex digits).
                BEQ     ESCAPE         ; Yes, generate ESC sequence.

                BIT     MODE           ; Test MODE byte.
                BVC     NOTSTOR        ; B6=0 is STOR, 1 is XAM and BLOCK XAM.

                LDA     L              ; LSD's of hex data.
                STA     (STL,X)        ; Store current 'store index'.
                INC     STL            ; Increment store index.
                BNE     NEXTITEM       ; Get next item (no carry).
                INC     STH            ; Add carry to 'store index' high order.
TONEXTITEM:     JMP     NEXTITEM       ; Get next command item.

RUN:
                JMP     (XAML)         ; Run at current XAM index.

NOTSTOR:
                BMI     XAMNEXT        ; B7 = 0 for XAM, 1 for BLOCK XAM.

                LDX     #$02           ; Byte count.
SETADR:         LDA     L-1,X          ; Copy hex data to
                STA     STL-1,X        ;  'store index'.
                STA     XAML-1,X       ; And to 'XAM index'.
                DEX                    ; Next of 2 bytes.
                BNE     SETADR         ; Loop unless X = 0.

NXTPRNT:
                BNE     PRDATA         ; NE means no address to print.
                LDA     #$0A           ; NL.
                JSR     ECHO           ; Output it.
                LDA     XAMH           ; 'Examine index' high-order byte.
                JSR     PRBYTE         ; Output it in hex format.
                LDA     XAML           ; Low-order 'examine index' byte.
                JSR     PRBYTE         ; Output it in hex format.
                LDA     #$3A           ; ":".
                JSR     ECHO           ; Output it.

PRDATA:
                LDA     #$20           ; Blank.
                JSR     ECHO           ; Output it.
                LDA     (XAML,X)       ; Get data byte at 'examine index'.
                JSR     PRBYTE         ; Output it in hex format.
XAMNEXT:        STX     MODE           ; 0 -> MODE (XAM mode).
                LDA     XAML
                CMP     L              ; Compare 'examine index' to hex data.
                LDA     XAMH
                SBC     H
                BCS     TONEXTITEM     ; Not less, so no more data to output.

                INC     XAML
                BNE     MOD8CHK        ; Increment 'examine index'.
                INC     XAMH

MOD8CHK:
                LDA     XAML           ; Check low-order 'examine index' byte
                AND     #$07           ; For MOD 8 = 0
                BPL     NXTPRNT        ; Always taken.

PRBYTE:
                PHA                    ; Save A for LSD.
                LSR
                LSR
                LSR                    ; MSD to LSD position.
                LSR
                JSR     PRHEX          ; Output hex digit.
                PLA                    ; Restore A.

PRHEX:
                AND     #$0F           ; Mask LSD for hex print.
                ORA     #$30           ; Add "0".
                CMP     #$3A           ; Digit?
                BCC     ECHO           ; Yes, output it.
                ADC     #$06           ; Add offset for letter.

ECHO:
                STA     TERMINAL       ; Output to terminal
                RTS

                ; Reset Vectors
                .ORG $FFFA
                .WORD   $0000                   ; NMI
                .WORD   RESET                   ; Reset
                .WORD   $0000                   ; IRQ

.END
