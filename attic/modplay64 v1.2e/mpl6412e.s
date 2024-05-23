;---------------------------------
; iAN CooG/HokutoForce
;---------------------------------
; ModPlay 1.2e patch
; added precalculated pitch tables
; main.prg can be compiled with austrospeed
; this build source is onefiled too

        *=$0800
        byte 0
startprg
        incprg  original\MP64.MAIN.fix.out.prg
endprg
        incprg  original\mp64.signed.prg,l
        incprg  original\mp64.ascii.prg,l
        incprg  original\mp64.loaders.o.prg,l
        incprg  original\mp64.c64player.o.prg,l
        incprg  original\mp64.volumetab.prg,l
        incprg  original\mp64.tempotab.prg,l
        incprg  original\mp64.division.prg,l
;-----------------------------------------------------------------------
        *=$d000
t0      incprg   original\c\mem_e600_pm1sp0di0.exo
t1      incprg   original\c\mem_e600_pm1sp0di1.exo
t2      incprg   original\c\mem_e600_pm1sp1di1.exo
t3
        *=$ee10
        incprg   original\c\mem_e600_pm3sp0di0.exo
t4      incprg   original\c\mem_e600_pm3sp1di0.exo
t5
;-----------------------------------------------------------------------
        *=$3500
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

        ldx #[endptrs-memptrs-1]
setptrs
        lda memptrs,x
        sta $2b,x
        dex
        bpl setptrs

        jsr $a659
        jsr $a533
        jmp $a7ae

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
;---------------------------------
topofmem=$5500
memptrs
        word  startprg
        word  endprg
        word  endprg
        word  endprg
        word  topofmem
        word  topofmem
        word  topofmem
endptrs
;---------------------------------

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
pt      lda ($03),y
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
; include arp+vib as a relocating routine
        *=$8d90
        ldx #$3f
tr
        lda arptable,x
        sta $0360,x
        dex
        bpl tr
        ;lda #$1  ; 1mhz/20mhz marker, useless in onefiled version
        ;sta 2024
        rts
arptable
        incprg "original\MP64.ARP+VIB.prg"

;-----------------------------------------------------------------------
tablel
 byte <t1    ;pm1sp0di0
 byte <t2    ;pm1sp0di1
 byte <t2    ;pm1sp1di0 = pm1sp0di1
 byte <t3    ;pm1sp1di1
 byte <t4    ;pm3sp0di0
 byte <t4    ;pm3sp0di1 = pm3sp0di0
 byte <t5    ;pm3sp1di0
 byte <t5    ;pm3sp1di1 = pm3sp1di0
tableh
 byte >t1
 byte >t2
 byte >t2
 byte >t3
 byte >t4
 byte >t4
 byte >t5
 byte >t5
;-----------------------------------------------------------------------
        *=$8e00
        ldy $02
        lda tablel,y
        ldx tableh,y

;
; Copyright (c) 2002, 2003 Magnus Lind.
;
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from
; the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
;   1. The origin of this software must not be misrepresented; you must not
;   claim that you wrote the original software. If you use this software in a
;   product, an acknowledgment in the product documentation would be
;   appreciated but is not required.
;
;   2. Altered source versions must be plainly marked as such, and must not
;   be misrepresented as being the original software.
;
;   3. This notice may not be removed or altered from any distribution.
;
;   4. The names of this software and/or it's copyright holders may not be
;   used to endorse or promote products derived from this software without
;   specific prior written permission.
;
; -------------------------------------------------------------------
; The decruncher jsr:s to the get_crunched_byte address when it wants to
; read a crunched byte. This subroutine has to preserve x and y register
; and must not modify the state of the carry flag.
; -------------------------------------------------------------------
;.import get_crunched_byte
; -------------------------------------------------------------------
; this function is the heart of the decruncher.
; It initializes the decruncher zeropage locations and precalculates the
; decrunch tables and decrunches the data
; This function will not change the interrupt status bit and it will not
; modify the memory configuration.
; -------------------------------------------------------------------
;.export decrunch

; -------------------------------------------------------------------
; if literal sequences is not used (the data was crunched with the -c
; flag) then the following line can be uncommented for shorter code.
LITERAL_SEQUENCES_NOT_USED = 1
;LITERAL_SEQUENCES_NOT_USED = 0
; -------------------------------------------------------------------
; zero page addresses used
; -------------------------------------------------------------------
zp_len_lo = $a7

zp_src_lo  = $ae
zp_src_hi  = zp_src_lo + 1

zp_bits_hi = $fc

zp_bitbuf  = $fd
zp_dest_lo = zp_bitbuf + 1  ; dest addr lo
zp_dest_hi = zp_bitbuf + 2  ; dest addr hi

decrunch_table = $8f00
tabl_bi = decrunch_table
tabl_lo = decrunch_table + 52
tabl_hi = decrunch_table + 104

; -------------------------------------------------------------------
; no code below this comment has to be modified in order to generate
; a working decruncher of this source file.
; However, you may want to relocate the tables last in the file to a
; more suitable address.
; -------------------------------------------------------------------
; stub by -=[iAN CooG/HokutoForce]=-
; example:
;  lda #<endaddr
;  ldx #>endaddr
;  jsr exodecruncher
; -------------------------------------------------------------------
   ;org $0900
exodecruncher
   sta _byte_lo
   stx _byte_hi
   sei
   inc $01
   jsr decrunch
   dec $01
   ;cli
   rts
; -------------------------------------------------------------------
; jsr this label to decrunch, it will in turn init the tables and
; call the decruncher
; no constraints on register content, however the
; decimal flag has to be #0 (it almost always is, otherwise do a cld)
   ;org $c000
decrunch:
; -------------------------------------------------------------------
; init zeropage, x and y regs. (12 bytes)
;
    ldy #0
    ldx #3
init_zp:
    jsr get_crunched_byte
    sta zp_bitbuf - 1,x
    dex
    bne init_zp
; -------------------------------------------------------------------
; calculate tables (50 bytes)
; x and y must be #0 when entering
;
nextone:
    inx
    tya
    and #$0f
    beq shortcut        ; starta på ny sekvens

    txa         ; this clears reg a
    lsr a           ; and sets the carry flag
    ldx tabl_bi-1,y
rolle:
    rol a
    rol zp_bits_hi
    dex
    bpl rolle       ; c = 0 after this (rol zp_bits_hi)

    adc tabl_lo-1,y
    tax

    lda zp_bits_hi
    adc tabl_hi-1,y
shortcut:
    sta tabl_hi,y
    txa
    sta tabl_lo,y

    ldx #4
    jsr get_bits        ; clears x-reg.
    sta tabl_bi,y
    iny
    cpy #52
    bne nextone
    ldy #0
    beq begin
; -------------------------------------------------------------------
; get bits (29 bytes)
;
; args:
;   x = number of bits to get
; returns:
;   a = #bits_lo
;   x = #0
;   c = 0
;   z = 1
;   zp_bits_hi = #bits_hi
; notes:
;   y is untouched
; -------------------------------------------------------------------
get_bits:
    lda #$00
    sta zp_bits_hi
    cpx #$01
    bcc bits_done
bits_next:
    lsr zp_bitbuf
    bne ok
    pha
literal_get_byte:
    jsr get_crunched_byte
    bcc literal_byte_gotten
    ror a
    sta zp_bitbuf
    pla
ok:
    rol a
    rol zp_bits_hi
    dex
    bne bits_next
bits_done:
    rts
; -------------------------------------------------------------------
get_crunched_byte:
        lda _byte_lo
        bne _byte_skip_hi
        dec _byte_hi
_byte_skip_hi:
        dec _byte_lo
_byte_lo = * + 1
_byte_hi = * + 2
        lda $FFFF ;end_of_data
        rts
; -------------------------------------------------------------------
; main copy loop (18(16) bytes)
;
copy_next_hi:
    dex
    dec zp_dest_hi
    dec zp_src_hi
copy_next:
    dey
IF 0 == LITERAL_SEQUENCES_NOT_USED
    bcc literal_get_byte
ENDIF
    lda (zp_src_lo),y
literal_byte_gotten:
    sta (zp_dest_lo),y
copy_start:
    tya
    bne copy_next
begin:
    txa
    bne copy_next_hi
; -------------------------------------------------------------------
; decruncher entry point, needs calculated tables (21(13) bytes)
; x and y must be #0 when entering
;
IF 0 == LITERAL_SEQUENCES_NOT_USED
    inx
    jsr get_bits
    tay
    bne literal_start1
ELSE
    dey
ENDIF
begin2:
    inx
    jsr bits_next
    lsr a
    iny
    bcc begin2
IF 1 == LITERAL_SEQUENCES_NOT_USED
    beq literal_start
ENDIF
    cpy #$11
IF 0 == LITERAL_SEQUENCES_NOT_USED
    bcc sequence_start
    bne bits_done
; -------------------------------------------------------------------
; literal sequence handling (13(2) bytes)
;
    ldx #$10
    jsr get_bits
literal_start1:
    sta <zp_len_lo
    ldx <zp_bits_hi
    ldy #0
    bcc literal_start
sequence_start:
ELSE
    bcs bits_done
ENDIF
; -------------------------------------------------------------------
; calulate length of sequence (zp_len) (11 bytes)
;
    ldx tabl_bi - 1,y
    jsr get_bits
    adc tabl_lo - 1,y   ; we have now calculated zp_len_lo
    sta zp_len_lo
; -------------------------------------------------------------------
; now do the hibyte of the sequence length calculation (6 bytes)
    lda zp_bits_hi
    adc tabl_hi - 1,y   ; c = 0 after this.
    pha
; -------------------------------------------------------------------
; here we decide what offset table to use (20 bytes)
; x is 0 here
;
    bne nots123
    ldy zp_len_lo
    cpy #$04
    bcc size123
nots123:
    ldy #$03
size123:
    ldx tabl_bit - 1,y
    jsr get_bits
    adc tabl_off - 1,y  ; c = 0 after this.
    tay         ; 1 <= y <= 52 here
; -------------------------------------------------------------------
; Here we do the dest_lo -= len_lo subtraction to prepare zp_dest
; but we do it backwards:   a - b == (b - a - 1) ^ ~0 (C-syntax)
; (16(16) bytes)
    lda zp_len_lo
literal_start:          ; literal enters here with y = 0, c = 1
    sbc zp_dest_lo
    bcc noborrow
    dec zp_dest_hi
noborrow:
    eor #$ff
    sta zp_dest_lo
    cpy #$01        ; y < 1 then literal
IF 0 == LITERAL_SEQUENCES_NOT_USED
    bcc pre_copy
ELSE
    bcc literal_get_byte
ENDIF
; -------------------------------------------------------------------
; calulate absolute offset (zp_src) (27 bytes)
;
    ldx tabl_bi,y
    jsr get_bits;
    adc tabl_lo,y
    bcc skipcarry
    inc zp_bits_hi
    clc
skipcarry:
    adc zp_dest_lo
    sta zp_src_lo
    lda zp_bits_hi
    adc tabl_hi,y
    adc zp_dest_hi
    sta zp_src_hi
; -------------------------------------------------------------------
; prepare for copy loop (8(6) bytes)
;
    pla
    tax
IF 0 == LITERAL_SEQUENCES_NOT_USED
    sec
pre_copy:
    ldy <zp_len_lo
    jmp copy_start
ELSE
    ldy <zp_len_lo
    bcc copy_start
ENDIF
; -------------------------------------------------------------------
; two small static tables (6(6) bytes)
;
tabl_bit:
    .byte 2,4,4
tabl_off:
    .byte 48,32,16
; -------------------------------------------------------------------
; end of decruncher
; -------------------------------------------------------------------

; -------------------------------------------------------------------
; this 156 byte table area may be relocated. It may also be clobbered
; by other data between decrunches.
; -------------------------------------------------------------------
;decrunch_table:
    ;.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ;.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ;.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ;.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ;.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ;.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ;.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ;.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ;.byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ;.byte 0,0,0,0,0,0,0,0,0,0,0,0
; -------------------------------------------------------------------
; end of decruncher
; -------------------------------------------------------------------

