;---------------------------------
; iAN CooG/HokutoForce
;---------------------------------
        ;crunched main prog
        *=$0801
realentry
        incprg modplay12.prg
endprg
;---------------------------------
        ;entry point
        *=$3c00
entry
        lda #$00
        sta $d020
        sta $d021
        sta $d011
        lda #$16
        sta $d018
        lda #0
        sta $02
tragain
        ldx $02
        lda tablesrc,x
        sta trloop+2
        lda tabledst,x
        sta trloop+5

        ldx #0
        ldy #$04
trloop
        lda $1000,x
        sta $0400,x
        inx
        bne trloop
        inc trloop+2
        inc trloop+5
        dey
        bne trloop

        inc $02
        lda $02
        and #$01
        bne nokeynow
        lda #$1b
        sta $d011
        jsr w8k
nokeynow
        lda $02
        cmp #[tabledst-tablesrc]
        bne tragain
        lda #1
        jsr $e536
        lda #0
        sta $c6
        lda #225
        sta 808
        ;sei
        ;inc $01
        jsr reudetect
        lda #0
        jsr $e536
        jmp realentry

;---------------------------------
w8k
        jsr sensek
        bne w8k
debounce
        jsr sensek
        beq debounce
        rts
sensek  lda $dc01
        and $dc00
        and #$10
        rts
;---------------------------------
reudetect

        lda #$55
        sta $df02 ; here MUST stay like this
        nop
        cmp $df02
        bne noreu
        sta $df00 ; here MUST NOT stay, $00 and $10 only on read
        cmp $df00
        beq noreu
        lda $df00
        beq reu1700
        cmp #$10
        bne noreu

        lda #<mreu17xx
        ldy #>mreu17xx
        bne npr
reu1700

        lda #<mreu1700
        ldy #>mreu1700
npr
        jsr $ab1e
        ldx #$2
pr      lda $a2
        bne pr
        dex
        bne pr
        rts

noreu
        lda #<noreumsg
        ldy #>noreumsg
        jsr $ab1e
        jmp w8k

noreumsg petc "*WARNING* REU not found!",0
mreu1700 petc "REU 128k found",0
mreu17xx petc "REU 256k+ found",0
;---------------------------------
        ;info pages
        align $100
col1
        incprg "original\mp64.scrn color.prg"
        align $100
scr1
        incprg "original\mp64.screen.prg"
        align $100


tablesrc
        byte >col1
        byte >scr1
tabledst
        byte $d8
        byte $04
