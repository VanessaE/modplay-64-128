; print a simple message, or a whole screen for that matter.
; enter with .X/.Y = address of message, .A = 0 if message is null-
; terminated, else it must be the message length (max 255 chars either way)

!macro PRINT_MSG {
	print_msg
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
	+	rts
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
	print_msg_rle
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
rts
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
