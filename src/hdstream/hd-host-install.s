; The C64's half of the HD streamer:  reads a file from a CMD HD that is on a
; RamLink, with the data going over the RamLink's parallel bus, and the serial bus
; lines (the clock, and the data) used for the handshake.  The HD's half is in
; hd-drive.s.  Both come from an earlier streamer program, which is credited in the
; notes, and is used here with permission.
;
; What is in this part is the start of it:  getting the HD's program in place and running.
; (The rest is in hd-host-runtime.s.)  A file is read like this:
;
;	hd_start	finds the HD, uploads hd-drive.s to it, starts it, and tests
;			the parallel bus, which leaves the HD waiting for the C64
;	hd_open_port	switches in the RamLink's hardware (the KERNAL isn't to be
;			called until hd_close_port)
;	hd_read_block	reads a sector (as often as it takes)
;	hd_close_port	switches it out again.  (hd_open_port and hd_close_port can
;			be called around every sector, which leaves the HD waiting)
;	hd_stop		quits the HD's program before the end of the file
;	hd_release	lets go of the bus after the end of the file
;
; Interrupts have to stay off from hd_open_port to hd_close_port, and the speed of a
; SuperCPU has to be 1 MHz, which is up to whoever includes this.  What the includer
; has to give:
;
;	hd_cmd_ptr	two bytes of zero page that are used while hd_start runs
;	hd_blk_buffer	256 bytes where a sector goes (the first two bytes are the
;			link of the sector, and then there are 254 of the file)
;	hd_image	where the bytes of hd-drive.s (the part that is the program
;			for the HD) are in the C64's memory, as they are uploaded
;
; and hd-drive.s has to come before this (for the labels of its bytes).

!zone hd_install {

; ---------------------------------------------------------------------------------
; hd_start:  finds the HD, and gets its program running.
;
; Enter with .A = the length of the name of the file (0 to 16), and .X/.Y = its
; address, with the name in PETSCII, as it is in the directory.  Only a PRG or SEQ
; file can be found.  The device that it is looked for in is the one in $BA.  The
; KERNAL has to be on, as it's called.
;
; Returns .X = 0 if the HD is waiting for hd_open_port, and the C64's I flag as it
; was.  Otherwise .X = HD_ERR_*, and the HD has been left alone.  (.Z doesn't say
; which.)  Trashes .A, .Y and hd_cmd_ptr.  Nothing is checked of the HD but that it is
; one:  the two bytes at $FEA4 of its ROM.  (The program for the HD has addresses of
; the HD's DOS in it, which are those of V1.92, the last one.)

hd_start
	php
	sei
	sta .len
	stx hd_cmd_ptr
	sty hd_cmd_ptr+1

	ldy #16				; the name goes in the program for the HD,
	lda #0				; with zeros after it
-	sta hd_image + (hdd_fName - hd_drive_start),y
	dey
	bpl -
	sta hd_image + (hdd_repeatFlag - hd_drive_start)	; (and the file is not to be repeated)
	ldy #0
-	cpy .len
	bcs +
	lda (hd_cmd_ptr),y
	sta hd_image + (hdd_fName - hd_drive_start),y
	iny
	cpy #16
	bcc -
+
	!ifndef c128 {
		lda hd_cpu_port		; (the KERNAL and the I/O in)
		pha
		lda #hd_krnl_io_in
		sta hd_cpu_port

		lda hd_rl_on		; the RamLink's KERNAL has a SEI here
		cmp #$78
		beq +
		ldx #HD_ERR_NO_RAMLINK
		bne .done		; (always)
+
	}
	jsr hd_check_hd
	bne .done
	jsr hd_ship_code
	bne .done
	lda #<hd_me_string		; and the program is started
	sta hd_cmd_ptr
	lda #>hd_me_string
	sta hd_cmd_ptr+1
	ldy #5
	jsr hd_send_command
	bne .done
	jsr hd_check_parallel

.done
	!ifndef c128 {
		pla
		sta hd_cpu_port
	}
	plp
	rts

.len	!byte 0

; the command that starts it

; (the letters of the commands are bytes, because !text would convert them, with
; some character tables)

hd_me_string
	!byte $4d, $2d, $45		; "M-E"
	!word $0400

; ---------------------------------------------------------------------------------
; checks that the device is an HD, by reading the two bytes at $FEA4 of its ROM.
; returns .X = 0, and .Z = 1, if it is.

hd_check_hd
	lda #<.read_cmd
	sta hd_cmd_ptr
	lda #>.read_cmd
	sta hd_cmd_ptr+1
	ldy #6
	jsr hd_send_command
	bne .not_hd
	jsr hd_talk_drive
	bmi .not_hd
	jsr hd_k_acptr
	pha
	jsr hd_k_acptr
	pha
	jsr hd_k_untalk
	pla
	tax
	pla
	cmp #$48			; "H"
	bne .not_hd
	cpx #$44			; "D"
	bne .not_hd
	ldx #0
	rts
.not_hd
	jsr hd_k_unlsn
	jsr hd_k_untalk
	ldx #HD_ERR_NOT_HD
	rts

.read_cmd
	!byte $4d, $2d, $52		; "M-R"
	!word $fea4
	!byte 2

; ---------------------------------------------------------------------------------
; uploads the program for the HD, to $0400, in pieces of 32 bytes (and the last
; piece, if it isn't a whole one).  returns .X = 0 if all went well.

hd_ship_code
	lda #<hd_image
	sta hd_cmd_ptr
	lda #>hd_image
	sta hd_cmd_ptr+1
	lda #<$0400
	sta hd_mw_string+3
	lda #>$0400
	sta hd_mw_string+4
	lda #<hd_drive_size
	sta .left
	lda #>hd_drive_size
	sta .left+1

.piece
	lda .left+1			; .A = 32 or the number of bytes that are left
	bne .whole
	lda .left
	cmp #32
	bcc .set
.whole
	lda #32
.set
	sta .count
	sta hd_mw_string+5

	jsr hd_listen_drive
	bmi .no_device
	ldy #0
-	lda hd_mw_string,y
	jsr hd_k_ciout
	iny
	cpy #6
	bcc -
	ldy #0
-	lda (hd_cmd_ptr),y
	jsr hd_k_ciout
	iny
	cpy .count
	bcc -
	lda #hd_CR
	jsr hd_k_ciout
	jsr hd_k_unlsn

	clc				; the next piece, to the next place, in the HD
	lda hd_mw_string+3
	adc .count
	sta hd_mw_string+3
	bcc +
	inc hd_mw_string+4
+	clc
	lda hd_cmd_ptr
	adc .count
	sta hd_cmd_ptr
	bcc +
	inc hd_cmd_ptr+1
+	sec
	lda .left
	sbc .count
	sta .left
	bcs +
	dec .left+1
+	lda .left
	ora .left+1
	bne .piece
	ldx #0
	rts

.no_device
	ldx #HD_ERR_DEV_NOT_FOUND
	rts

.left	!word 0
.count	!byte 0

hd_mw_string
	!byte $4d, $2d, $57		; "M-W"
	!word $0400
	!byte 32

; ---------------------------------------------------------------------------------
; the serial bus, with the KERNAL.  each returns with .N = 1 if the device didn't
; answer.

hd_listen_drive
	jsr hd_k_unlsn
	jsr hd_k_untalk
	lda #0
	sta hd_k_status
	lda hd_k_device
	jsr hd_k_listen
	bit hd_k_status
	bmi +
	lda #($60 | 15)
	jsr hd_k_second
	bit hd_k_status
+	rts

hd_talk_drive
	jsr hd_k_unlsn
	jsr hd_k_untalk
	lda #0
	sta hd_k_status
	lda hd_k_device
	jsr hd_k_talk
	bit hd_k_status
	bmi +
	lda #($60 | 15)
	jsr hd_k_tksa
	bit hd_k_status
+	rts

; sends the command that hd_cmd_ptr points to, .Y bytes of it, to the HD's command
; channel.  returns .X = 0 if it went, and .X = HD_ERR_DEV_NOT_FOUND if not.

hd_send_command
	sty .length
	jsr hd_listen_drive
	bmi .absent
	ldy #0
-	lda (hd_cmd_ptr),y
	jsr hd_k_ciout
	iny
	cpy .length
	bcc -
	lda #hd_CR
	jsr hd_k_ciout
	jsr hd_k_unlsn
	ldx #0
	rts
.absent
	ldx #HD_ERR_DEV_NOT_FOUND
	rts

.length	!byte 0

; ---------------------------------------------------------------------------------
; tests the parallel bus.  the HD sends $AA and then $55 (with the clock and data
; lines to say that each is there) and this has to read those.  returns .X = 0 if it
; did, and HD_ERR_NO_PARALLEL if not (and the HD is told to give up).  the parts
; that don't change the lines but the ones that are to change are patched, as the
; low bits of $DD00 are the C64's own:  the VIC's bank, and the others.

hd_check_parallel
	sei
	lda hd_cia2
	and #%00001111
	sta .cfp3+1
	sta .cfp6+1
	ora #%00010000
	sta .cfp2+1
	sta .cfp4+1
	sta .cfp7+1
	and #%00001111
	ora #%00100000
	sta .cfp8+1

	ldy #33				; a short pause
-	dey
	bne -
	jsr hd_open_port
	ldx #1
.cfp2	lda #%00010111			; (patched)
	sta hd_cia2			; the clock line down
-	bit hd_cia2			; wait for the HD to pull the data line down
	bmi -
.cfp3	lda #%00000111			; (patched)
	sta hd_cia2			; the clock line up
-	bit hd_cia2			; wait for the HD to let the data line go
	bpl -
	lda hd_pa8255
	cmp #$aa
	bne .cfp4
	dex
.cfp4	lda #%00010111			; (patched)
	sta hd_cia2
-	bit hd_cia2
	bmi -
	lda hd_pa8255
	cmp #$55
	bne .cfp5
	dex
.cfp5	txa
	pha
	jsr hd_close_port
	pla
	bpl .cfp8			; (.X was not 1 less than it was)
.cfp6	lda #%00000111			; (patched)
	sta hd_cia2
-	bit hd_cia2
	bpl -
.cfp7	lda #%00010111			; (patched)
	sta hd_cia2
-	bit hd_cia2
	bmi -
	ldx #0
	rts

.cfp8	lda #%00100111			; (patched):  data down, clock up:  the HD is to quit
	sta hd_cia2
	ldx #HD_ERR_NO_PARALLEL
	ldy #0				; (the HD looks at the data line once, a little while
-	dey				; after the clock line is let go of.  the original held it
	bne -				; for 24 cycles, which is too short for a slow HD, which
	and #%00001111			; would not quit.  this is 1.3 ms.)
	sta hd_cia2			; and everything is let go of
	rts

}
