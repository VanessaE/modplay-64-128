; iAN CooG/HokutoForce
    *=$8d90
    ldx #$3f
tr
    lda arptable,x
    sta $360,x
    dex
    bpl tr
    lda #$1
    sta 2024
    rts
arptable
    incprg "original\MP64.ARP+VIB.prg"
