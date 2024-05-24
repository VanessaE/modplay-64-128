; print a simple message or a whole screen for that matter.
; enter with .X/.Y = address of message

!macro PRINT_MSG {
	print_msg
		stx print_msg_addr
		sty print_msg_addr+1
		ldy #0
	-	lda (print_msg_addr),y
		beq +
		jsr CHROUT
		iny
		bne -
		inc print_msg_addr+1
		bne -
	+ rts
}

; Inline delay of ( (.count - 1)*5 + 4 ) cycles
!macro DELAY_LOOP .index, .count { 
	!if .index == "X" {
		ldx #.count		; 2 cycles
	-	dex				; 2 cycles
		bne -			; 3 or 2 cycles
	} else {
		ldy #.count
	-	dey
		bne -
	}
}

!macro VDC_OPS {
	vdc_read_reg
		stx VDC_C128
	-	bit VDC_C128
		bpl -
		lda VDC_C128+1
	rts

	vdc_write_reg
		stx VDC_C128
	-	bit VDC_C128
		bpl -
		sta VDC_C128+1
	rts

	regs		!byte   0,  1,   2,  22, 27, 25, 255
	vals_40		!byte  63, 40,  55, 137, 40, 87
	vals_80		!byte 126, 80, 102, 120,  0, 71

	!macro LOOP_REG .r , .v {
		ldy #0
	-	ldx .r,y
		bmi +		; if it hits that 255, bail out
		lda .v,y
		jsr vdc_write_reg
		iny
		bne -
		+
	}

	vdc_set_double_pix_width
		+LOOP_REG regs, vals_40
		lda #39
		sta COLUMNS
	rts

	vdc_set_single_pix_width
		+LOOP_REG regs, vals_80
		lda #79
		sta COLUMNS
+	rts
}

; Description: Unsigned 8-bit multiplication with unsigned 16-bit result.
; Code by JackAsser (reformatted for Acme and my code style)
; https://codebase64.org/doku.php?id=base:seriously_fast_multiplication

; Input: 8-bit unsigned values in .A and .X
;
; Output: 16-bit unsigned value in product
;
; Clobbered: product, X, A, C
;
; Allocation setup: product preferably on Zero-page.
;                   multablo, multabhi, multab2lo, multab2hi must be
;                   page aligned. Each table are 512 bytes. Total 2kb.
;
; Table generation: I:0..511
;                   multablo = <((I*I)/4)
;                   multabhi = >((I*I)/4)
;                   multab2lo = <(((I-255)*(I-255))/4)
;                   multab2hi = >(((I-255)*(I-255))/4)

!macro MULTIPLY {
	multiply_8x8
		sta sm1+1
		sta sm3+1
		eor #$ff
		sta sm2+1
		sta sm4+1

		sec
	sm1	lda multablo,x
	sm2	sbc multab2lo,x
		sta product
	sm3	lda multabhi,x
	sm4	sbc multab2hi,x
		sta product+1

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

!macro ROM_SWITCHING {
	!ifdef c128 {
		disable_roms ; bank-out BASIC and KERNAL ROMs and disable IRQ's
			lda #%00111110
			sta MMU_C128+$0
		rts

		enable_roms ; bank the BASIC and KERNAL ROMs back in and enable IRQ's.
			lda #0
			sta MMU_C128+$0
		rts

	} else {
		disable_roms
			lda #$35
			sta $01
		rts

		enable_roms
			lda #$37
			sta $01
		rts
	}
}

!macro C128_CPU_FREQ {
	c128_set_1mhz_mode
		lda #$00
		sta VIC+$30
	rts
	
	c128_set_2mhz_mode
		lda #$01
		sta VIC+$30
	rts
}

; Enter with .A = the byte to decode.
;
; Returns:
;
; * .A = the decoded byte
; * .X = $80 if routine has more data for the caller to store.
; * carry set if the routine needs another new byte from the input stream.

!macro RLE_DECODE {
	rle_decode
		sta $0400,y

		clc
		ldx rle_byte_count	; if the count is zero, .A must be a command byte
		beq .new_chunk

		dec rle_byte_count
		ldx rle_mode_flag	; otherwise it's an ongoing chunk.  if mode is $80+
		bpl .perform_fill_run
	rts						; ...it's a data chunk, so just return the byte.

	.perform_fill_run
		bit rle_fill_byte_is_set ; check if fill byte has been set yet (duh :P )
		bmi +
		sta rle_fill_byte
		ldx #$80
		stx rle_fill_byte_is_set
	+ rts						; otherwise just use what's in .A

	.new_chunk
		tax						; .A still holds the command byte
		and #$80				; set data-or-run mode
		sta rle_mode_flag
		and #$7f				; and get the count
		sta rle_byte_count
		lda #0
		sta rle_fill_byte_is_set
		sec						; tell caller routine we need another byte
	rts
}

; print an RLE_encoded message
; enter with .X/.Y = address of message
; (useful for a full-screen PETSCII dump like the splash or main UI screen)

!macro PRINT_MSG_RLE {
	print_msg_rle
		stx print_msg_addr
		sty print_msg_addr+1

		ldy #0
		sty rle_byte_count
		sty rle_fill_byte
		sty rle_mode_flag
		sty is_rle_encoded

	.lp	lda (print_msg_addr),y
		beq +

	.more
		jsr rle_decode
		sta $0428,y
		bcs .next_byte
		jsr CHROUT

		ldx rle_byte_count
		bne .more

	.next_byte
		iny
		bne .lp
		inc print_msg_addr+1
		bne .lp
	+ rts
}



























; generate_pitch_table
	; dim lt(1023)
	; lt(0-31) = 0
	; C64 BASIC LOG() is "natural log" e.g. base 'e'
	; this translates it into a table of log base 2
	; lg=log(2) : for x = 32 to 1023: lt(x)=log(x)/lg : next

; load_file_long
	;	[ loader start ]
	;		[ bank-in the KERNAL and BASIC ]
	;		[ set filename ]
	;		[ set addresses ]
	;		[ setup STOP wedge ]
	;		[ call KERNAL LOAD routine ]
	;
	;		[ when STOP trap triggers, check file load vector ]
	;			[ if file load vector < buf start + 2k ]
	;				[ just let KERNAL continue ]
	;			[ else ]
	;				[ call RAM driver to stash this block of data ]
	;				[ increment expanded memory pointers for next cycle ]
	;				[ if new value exceeds RAM limit, bail out ]
	;				[ reset file load address vector ]
	;				[ let KERNAL continue ]
	;			[ endif ]
	;			[ stash the last block of data -- jump here to finish cleanly ]
	;		[ undo STOP wedge --- jump here to bail-out ]
	;
	;	[ bank-out KERNAL/BASIC ]
	;	[ exit from loader ]

