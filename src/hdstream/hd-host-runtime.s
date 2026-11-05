; The C64's half of the HD streamer, the part that is used while a file is read:  the
; RamLink's hardware, in and out, and the sectors.  See hd-host-install.s for what it
; is, and hd-defs.s for what is needed.

!zone hd_runtime {

; waits for the HD to answer the KERNAL, up to a few seconds.  returns .C = 1 if it
; didn't.  this is for after hd_stop or hd_release, because the HD's DOS isn't
; listening before it's back.  needs the KERNAL on.

hd_wait_dos
	ldy #$60			; the number of tries
.try
	lda #0
	sta hd_k_status
	lda hd_k_device
	jsr hd_k_listen
	lda #($60 | 15)
	jsr hd_k_second
	lda hd_k_status
	bmi .failed
	jsr hd_k_unlsn
	clc
	rts
.failed
	jsr hd_k_unlsn
	ldx #0				; (about 25 ms between the tries)
.pause
	lda #$0d
-	sec
	sbc #1
	bne -
	dex
	bne .pause
	dey
	bne .try
	sec
	rts

; ---------------------------------------------------------------------------------
; the RamLink's hardware, in and out.  in:  the parallel bus is set to input, and
; the KERNAL's ROM is the RamLink's.  the patched values are what is written to
; $DD00 to let go of the clock (hd_rb2, hd_rb5, hd_rb7) and to pull it down (hd_rb4,
; hd_rb6, hd_rb8, hd_rb9), with the C64's own low bits as they were.

hd_open_port
	sei
	!ifndef c128 {
		lda hd_cpu_port
		pha
		lda #hd_krnl_io_in
		sta hd_cpu_port
	}
	lda hd_cia2
	and #%00001111
	sta hd_rb2+1
	sta hd_rb5+1
	sta hd_rb7+1
	ora #%00010000
	sta hd_rb4+1
	sta hd_rb6+1
	sta hd_rb8+1
	sta hd_rb9+1
	!ifndef c128 {
		jsr hd_rl_on		; (the RamLink's hardware)
	} else {
		sta hd_rl_on_reg
	}
	jsr hd_par_to_input
	!ifndef c128 {
		pla
		sta hd_cpu_port
	}
	rts

hd_close_port
	!ifndef c128 {
		lda hd_cpu_port
		pha
		lda #hd_krnl_io_in
		sta hd_cpu_port
	}
	jsr hd_par_to_input
	!ifndef c128 {
		jsr hd_rl_off		; (this leaves interrupts off)
		pla
		sta hd_cpu_port
	} else {
		sta hd_rl_off_reg	; (interrupts are off, as they were)
	}
	rts

; the parallel port is to be an input.  the 8255 doesn't like to be written to while
; the VIC is taking the bus, so it's done in a part of the screen where that
; doesn't happen.

hd_par_to_input
	ldx #%10011000
	sei
	sec
-	lda hd_rasterline
	sbc #49
	bcc +
	and #%00000110
	beq -
+	lda hd_pb8255			; (port B is kept)
	pha
	lda hd_pc8255
	stx hd_cr8255
	sta hd_pc8255
	pla
	sta hd_pb8255
	rts

; ---------------------------------------------------------------------------------
; reads a sector.  the HD has to be waiting for it (after hd_start, or the last
; sector), and the port open.
;
; returns .Y = the number of bytes of the file that are in hd_blk_buffer+2, which
; is 254 for all but the last sector of the file, the number that are left for that
; one, and 0 if there is no file (or nothing is left).  hd_blk_buffer and
; hd_blk_buffer+1 are the link:  a track of 0 says that this is the last sector.
; .Y isn't 254 only in the last sector, so that is what ends the file.

hd_read_block
hd_rb2	lda #%00000111			; (patched)
	sta hd_cia2			; let go of the clock line
-	bit hd_cia2			; the HD lets go of the data line
	bpl -
hd_rb4	ldx #%00010111			; (patched)
	stx hd_cia2			; the clock line down
-	bit hd_cia2			; the HD pulls the data line down
	bmi -
	lda hd_pa8255			; a byte
hd_rb5	ldx #%00000111			; (patched)
	stx hd_cia2			; the clock line up
	sta hd_blk_buffer+0
-	bit hd_cia2
	bpl -
	lda hd_pa8255
	sta hd_blk_buffer+1
	tay
	ora hd_blk_buffer+0
	beq hd_rb8			; two zeros:  nothing here
	lda hd_blk_buffer+0
	bne .full
	dey				; the last sector:  .Y is the index of its last byte
	beq hd_rb8			; (and none of the file is in it)
	!byte $2c			; (skips the next instruction)
.full	ldy #254
	sty hd_bytes_to_fetch
	ldy #0

hd_rb6	ldx #%00010111			; (patched)
	stx hd_cia2
-	bit hd_cia2
	bmi -
	lda hd_pa8255
hd_rb7	ldx #%00000111			; (patched)
	stx hd_cia2
	sta hd_blk_buffer+2,y
	iny
	cpy hd_bytes_to_fetch
	beq hd_rb9			; (the last byte was the first of a pair)
-	bit hd_cia2
	bpl -
	lda hd_pa8255
	sta hd_blk_buffer+2,y
	iny
	cpy hd_bytes_to_fetch
	bne hd_rb6

hd_rb8	ldx #%00010111			; (patched)
	stx hd_cia2			; the clock line down, to say that this is done
-	bit hd_cia2			; the HD pulls the data line down
	bmi -
	rts

; the end when the last byte was the first of a pair.  the HD doesn't wait for the
; clock line to be let go of and pulled down again, if it looks at it before the C64
; has let go of it (which a quick HD does, and a slow one doesn't), so it has seen the
; clock line down already, and the pulse on the data line that hd_rb8 waits for may be
; over by now.  what is always so is that it ends with the HD letting go of the
; data line (or has done so), which is what is waited for here.

hd_rb9	ldx #%00010111			; (patched)
	stx hd_cia2			; the clock line down
-	bit hd_cia2			; wait for the HD to let go of the data line
	bpl -
	rts

hd_bytes_to_fetch
	!byte 0

; ---------------------------------------------------------------------------------
; hd_stop:  quits the HD's program before the end of the file (the HD has to be
; waiting for the next sector, as it is between hd_read_block calls).  the data line
; is pulled down, which the HD sees when the clock line is let go of, and it answers
; by pulling the clock line down, and waiting for the data line to be let go of.
; there is a limit to how long this waits for the HD, because there is no answer if
; the program has ended already.  returns .C = 1 if the HD didn't answer.  the HD
; is back in its DOS some time after this, which hd_wait_dos waits for.

hd_stop
	lda hd_cia2
	and #%00001111
	ora #%00100000
	sta hd_cia2			; the data line down, and the clock line up
	ldx #0
	ldy #0
-	bit hd_cia2			; the HD pulls the clock line down
	bvc +
	dex
	bne -
	dey
	bne -
	jmp hd_release			; (it didn't)
+	and #%00001111
	sta hd_cia2			; let go of both
	ldy #0
	ldx #0
-	bit hd_cia2			; and the HD lets go of the clock line
	bvs +
	dex
	bne -
	dey
	bne -
	sec
	rts
+	clc
	rts

; lets go of the clock line and the data line, which is all there is to do after
; the last sector (the HD has gone back to its DOS, by itself).  returns .C = 1.

hd_release
	lda hd_cia2
	and #%00001111
	sta hd_cia2
	sec
	rts

}
