; print a simple message, or a whole screen for that matter.
; enter with .X/.Y = address of message, .A = 0 if message is null-
; terminated, else it must be the message length (max 255 chars either way)

!macro PRINT_MSG {
	sta print_msg_char_limit
	dec print_msg_char_limit
	stx print_msg_addr
	sty print_msg_addr+1
	ldy #0
-	lda (print_msg_addr),y
	beq +
	jsr CHROUT
	cpy print_msg_char_limit
	beq +
	iny
	bne -
	inc print_msg_addr+1
	bne -
  +
}

	; print an RLE_encoded message
	; enter with .X/.Y = address of message
	; (useful for big PETSCII dumps like the splash)

	; example encoded message:
	;
	;	!byte $81, "6"
	;	!text $82, "4 "
	;	!byte $05, $ff
	;	!byte $81, " "
	;	!text $8b, "hello world"
	;	!byte $81, " "
	;	!byte $06, "A"
	;	!byte $09, "B"
	;	!byte $81, " "
	;	!text $85, "yeah!"
	;	!byte 0
	;
	; which will render as:
	;
	; "64 🮖🮖🮖🮖🮖 hello world AAAAAABBBBBBBBB yeah!"

!macro PRINT_MSG_RLE {
	stx print_msg_addr
	sty print_msg_addr+1

	ldy #0
	sty rle_byte_count

.lp	lda (print_msg_addr),y
	beq .done			; a null is always the end of the msg

	ldx rle_byte_count	; if count is non-zero, just print what's in .A
	bne .pr

	sta rle_mode_flag	; else .A is a command
	and #$7f
	sta rle_byte_count	; so set the new count
	bne .next_byte

.pr	jsr CHROUT

	dec rle_byte_count

	ldx rle_mode_flag	; if it's a data block, continue through stream
	bmi .next_byte
	ldx rle_byte_count	; if it's a run, keep looping back to reprint
	bne .pr				; until count runs out.

.next_byte
	iny
	bne .lp
	inc print_msg_addr+1
	bne .lp
.done
}

!macro PRINT_MSG_BATCH_RLE .lines, .lows, .highs {
		ldy #0
		sty tempzp_d
	-	ldy tempzp_d
		cpy #.lines
		beq +
		ldx .lows,y
		lda .highs,y
		tay
		lda #0
		jsr print_msg_rle
		inc tempzp_d
		bne -
	+
}

!macro VDC_BLOCK_COPY_INIT .src, .dst {
	lda #<.src
	sta tempzp_d
	lda #>.src
	sta tempzp_d+1

	lda #<.dst
	sta tempzp_e
	lda #>.dst
	sta tempzp_e+1
}

!macro VDC_BLOCK_FILL .dst, .len, .fill {
-	bit VDC
	bpl -

	lda #18
	sta VDC
	lda #>.dst
	sta VDC+1

	lda #19
	sta VDC
	lda #<.dst
	sta VDC+1

	lda #31
	sta VDC
	lda #.fill
	sta VDC+1

	lda #24
	sta VDC
	lda #$20
	sta VDC+1

	lda #30
	sta VDC
	lda #.len
	sta VDC+1
}

!macro VDC_BLOCK_FILL_CONT .len2, .fill2 {
-	bit VDC
	bpl -

	lda #31
	sta VDC
	lda #.fill2
	sta VDC+1

	lda #24
	sta VDC
	lda #$20
	sta VDC+1

	lda #30
	sta VDC
	lda #.len2
	sta VDC+1
}

!macro SCREEN_ONOFF {
	disable_screen
		lda VIC+$11
		and #%11101111
		sta VIC+$11
	rts

	enable_screen
		lda VIC+$11
		ora #%00010000
		sta VIC+$11
	rts
}

!macro CPU_FREQ {
	c128_set_1mhz_mode
		lda #$00
		sta VIC+$30
	rts

	c128_set_2mhz_mode
		lda #$01
		sta VIC+$30
	rts
}

;#################
;# ROM SWITCHING #
;#################

!macro ROM_SWITCHING {
	!ifdef c128 {
		disable_roms
			lda #%00111110
			sta MMU
		rts

		enable_kernal_only
			lda #%00001110
			sta MMU
		rts

		enable_roms
			lda #0
			sta MMU
		rts

	} else {
		disable_roms
			lda #$35
			sta $01
		rts

		enable_char_rom_only ; really the only purpose is to bank-out I/O
			lda #$31
			sta $01
		rts

		enable_kernal_only
			lda #$36
			sta $01
		rts

		enable_roms
			lda #$37
			sta $01
		rts
	}
}

!macro JSR_INDIRECT .vec {
	sta .reload_a+1
	lda #>.ra
	pha
	lda #<.ra
	pha
.reload_a
	lda #00
	jmp (.vec)
	.ra = * - 1
}
