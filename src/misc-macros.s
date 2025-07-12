; print a simple message, or a whole screen for that matter.
; enter with .X/.Y = address of message, .A = 0 if message is null-
; terminated, else it must be the message length (max 255 chars either way)

!macro CHECK_COLOR_FLAG {
		bit print_msg_colors_flag
		bpl .sc
		rts

	.sc
		ldx #15
	-	cmp COLORS_TABLE,x
		beq .np
		dex
		bpl -
		rts

	.np	lda #0
	.ep
}

; if print_msg_colors_flag is clear and the current char is found in the
; KERNAL's color codes table, replace it with an unprintable null.

!macro PRINT_MSG {
	php
	sta print_msg_char_limit

	lda #0
	ror
	sta print_msg_colors_flag

	dec print_msg_char_limit
	stx print_msg_addr
	sty print_msg_addr+1
	ldy #0
-	lda (print_msg_addr),y
	beq +

	jsr check_color_flag
	jsr CHROUT
	cpy print_msg_char_limit
	beq +
	iny
	bne -
+	plp
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
	php
	lda #0
	ror
	sta print_msg_colors_flag

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

.pr
	jsr check_color_flag
	jsr CHROUT

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
	plp
}

!macro DISABLE_VIC_SCREEN {
	lda VIC_CONTROL_A
	and #%11101111
	sta VIC_CONTROL_A
}

!macro ENABLE_VIC_SCREEN {
	lda VIC_CONTROL_A
	ora #%00010000
	sta VIC_CONTROL_A
}

!ifndef c128 {
	!macro C64_NORMAL_SCREEN {
		lda CIA2_PORT_A
		and #$fc
		sta CIA2_PORT_A
		lda #$37
		sta VIC_MEM_CTRL
		lda #>VIC_SCREEN			; and point the KERNAL appropriately, for
		sta HIBASE					; screen editor/CHROUT/etc.
	}
}

!macro ENABLE_KERNAL_ONLY {
	!ifdef c128 {
		lda #%00001110
		sta MMU_CR1
	} else {
		lda #$36
		sta $01
	}
}

!macro ENABLE_ALL_ROMS {
	!ifdef c128 {
		lda #0
		sta MMU_CR1
	} else {
		lda #$37
		sta $01
	}
}

!ifndef c128 {
	!macro C64_ENABLE_CHAR_ROM_ONLY { ; really the only purpose is to bank-out I/O
		lda #$31
		sta $01
	}
}

!ifdef c128 {
	!macro VDC_RAM_ACC_SETUP {
	-	bit VDC_ADDR
		bpl -

		lda #18
		sta VDC_ADDR
		lda fill_copy_target+1
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda fill_copy_target
		sta VDC_DATA

	-	bit VDC_ADDR
		bpl -
	}

	!macro VDC_RAM_RW_SETUP {
		+VDC_RAM_ACC_SETUP
		lda #31
		sta VDC_ADDR
	}

	!macro VDC_WRITE_RAM {
	-	bit VDC_ADDR
		bpl -

		sta VDC_DATA
	}

	!macro VDC_READ_RAM {
	-	bit VDC_ADDR
		bpl -

		lda VDC_DATA
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
