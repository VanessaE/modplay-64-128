; prints directory, wait 4 key, exits
; iAN CooG/HokutoForce
        *= $6140

        ;JSR $E544      ;clear screen
        LDA #$01
        LDX #<dirname
        LDY #>dirname
        JSR $FFBD      ; set filename "$"
        LDA #$08
        CMP $BA
        BCC lab1
        STA $BA
lab1
        LDA #$60
        STA $B9        ; secondary chn
        JSR $F3D5      ; open for serial bus devices
        JSR $F219      ; set input device
        LDY #$04
labl1   JSR $EE13      ; input byte on serial bus
        DEY
        BNE labl1      ; get rid of Y bytes
        LDA $C6        ; key pressed?
        ORA $90        ; or EOF?
        BNE labl2      ; if yes exit
        JSR $EE13      ; now get in AX the dimension
        TAX            ; of the file
        JSR $EE13
        JSR $BDCD      ; print number from AX
labl3   JSR $EE13      ; now the filename
        JSR $E716      ; put a character to screen
        BNE labl3      ; while not 0 encountered
        JSR $AAD7      ; put a CR , end line
        LDY #$02       ; set 2 bytes to skip
        BNE labl1      ; repeat
labl2   JSR $F642      ; close serial bus device
        JSR $F6F3      ; restore I/O devices to default
;labl4   JSR $F142      ; w8 a key
        ;BEQ labl4
        RTS

dirname .byte "$"
