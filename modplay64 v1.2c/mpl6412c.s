;---------------------------------
; iAN CooG/HokutoForce
;---------------------------------
; ModPlay 1.2c patch

        *=$0800
        byte 0

        incprg  original\MP64.MAIN.fix.out.prg
        incprg  original\mp64.signed.prg,l
        incprg  original\mp64.ascii.prg,l
        incprg  original\mp64.loaders.o.prg,l
        incprg  original\mp64.c64player.o.prg,l
        incprg  original\mp64.volumetab.prg,l
        incprg  original\mp64.tempotab.prg,l
        incprg  original\mp64.division.prg,l

;-----------------------------------------------------------------------
; include arp+vib as a relocating routine
        *=$8d90
        ldx #$3f
tr
        lda arptable,x
        sta $0360,x
        dex
        bpl tr
        lda #$1
        sta 2024
        rts
arptable
        incprg "original\MP64.ARP+VIB.prg"
;-----------------------------------------------------------------------
; prints directory, wait 4 key, exits

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

dirname byte "$"
;-----------------------------------------------------------------------
; patch for 2nd SID base address low byte
        *=$6190
        lda $02     ; 00/20/40/60/80/a0/c0/e0
        sta patch1+1
        lda #$63
        sta $04
        ldy #$00
        ldx #[addrtablh-addrtabll-1]
lp1
     	lda addrtabll,x
     	sta $03
pt   	lda ($03),y
        and #$1f
        ora $02
        sta ($03),y
        dex
        bpl lp1
	    rts

    	*=$61b0
patch1
        lda #$00
        sta $fe
        lda $03ec
        rts

addrtabll
        byte <[$630C+1]
        byte <[$6310+1]
        byte <[$6314+1]
        byte <[$6318+1]
        byte <[$631C+1]
addrtablh

        *=$72BC
        jsr patch1
        STA $FF
        LDA #$00
        bit $FE

        *=$62FD
        jsr patch1
;-----------------------------------------------------------------------
