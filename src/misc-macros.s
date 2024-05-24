!macro STRING_OPS {

	; print a simple message, or a whole screen for that matter.
	; enter with .X/.Y = address of message

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

	; call with .X/.Y = string to check
	; returns the length in .Y

	get_string_length
		stx tempzp_e
		sty tempzp_e+1
		ldy #0
	-	lda (tempzp_e),y
		beq +
		iny
		bne -
	+ rts

	; call with .X/.Y = address of string
	; .A = width of area to display in
	; prints as many cursor-RIGHTS as needed

	center_string
		pha
		jsr get_string_length
		tya
		sta tempzp_c
		pla
		sec
		sbc tempzp_c
		lsr
		tay
		dey
		beq +
		lda #RIGHT
	-	jsr CHROUT
		dey
		bne -
	+ rts

	; converts a 0-15 value into printable "0" to "f" 
	to_hex
		clc
		adc #$30
		cmp #$39
		bmi +
		adc #38
	+ rts
}

!macro PRINT_MSG_BATCH .lines, .lows, .highs {
		ldy #0
		sty tempzp_d
	-	ldy tempzp_d
		cpy #.lines
		beq +
		ldx .lows,y
		lda .highs,y
		tay
		jsr print_msg
		inc tempzp_d
		bne -
	+
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

!macro ROM_SWITCHING {  ; only re-enables the KERNAL when switching-on
	!ifdef c128 {
		disable_roms
			lda #%00111110
			sta MMU_C128
		rts

		enable_kernal
			lda #%00001110
			sta MMU_C128
		rts

	} else {
		disable_roms
			lda #$35
			sta $01
		rts

		enable_kernal
			lda #$36
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

!macro ZERO_PAGE_OPS {
	backup_zero_page
		ldy #2
	-	lda $00,y
		sta zp_backup,y
		iny
		bne -
	rts

	restore_zero_page
		ldy #2
	-	lda zp_backup,y
		sta $00,y
		iny
		bne -
	rts
}

!macro NUMERIC_OPS {
	print_uint16
		jsr int16_to_string
		jsr trim_num

		ldx #<string_16_bit_trimmed
		ldy #>string_16_bit_trimmed
		jsr print_msg
	rts

; from Codebase64:
; https://codebase64.org/doku.php?id=base:int16_and_uint16_conversion_to_string

	int16_to_string
		stx int16
		sty int16+1

		ldy #6
		lda #0
	-	sta string_16_bit,y
		sta string_16_bit_trimmed,y
		dey
		bpl -

		ldy int16+1
		jsr bin_to_bcd_16		; converts the number to BCD
		;lda bcd+2
		and #$0f				; extracts every byte and adds $30
		ora #$30
		sta string_16_bit+1
 
		lda bcd+1
		and #$0f
		ora #$30
		sta string_16_bit+3
		lda bcd+1
		lsr
		lsr
		lsr
		lsr
		ora #$30
		sta string_16_bit+2
 
		lda bcd+0
		and #$0f
		ora #$30
		sta string_16_bit+5
		lda bcd+0
		lsr
		lsr
		lsr
		lsr
		ora #$30
		sta string_16_bit+4
		lda #$20
		sta string_16_bit+0
 
		ldx #1					; remove 0s at beginning
	.rem0
		lda string_16_bit,x
		cmp #$30				; if it's a '0'
		bne .done
		lda #$20				; put a space instead
		sta string_16_bit,x 
		inx
		cpx #$5					; exits before last digit
		bne .rem0
	.done
	rts

	trim_num
		ldy #0
		cpx #0
		beq .done
	.trmlp
		lda string_16_bit,x
		sta string_16_bit_trimmed,y
		beq .done
		inx
		iny
		jmp .trmlp

	bin_to_bcd_16
		sed						; switch to decimal mode
		lda #0					; ensure the result is clear
		sta bcd+0
		sta bcd+1
		sta bcd+2
 
	.cbit1
		asl int16				; shift out one bit
		rol int16+1
		;lda bcd+0
		adc bcd+0				; and add into result
		sta bcd+0
		asl int16
		rol int16+1
		adc bcd+0
		sta bcd+0
		asl int16
		rol int16+1
		adc bcd+0
		sta bcd+0
		asl int16
		rol int16+1
		adc bcd+0
		sta bcd+0
		asl int16
		rol int16+1
		adc bcd+0
		sta bcd+0
		asl int16
		rol int16+1
		adc bcd+0
		sta bcd+0
 
		ldx #7
	.cbit7
		asl int16				; shift out one bit
		rol int16+1
		lda bcd+0				; and add into result
		adc bcd+0
		sta bcd+0
		lda bcd+1				; propagating any carry
		adc bcd+1
		sta bcd+1
		dex						; and repeat for next bit
		bne .cbit7
 
		ldx #3
	.cbit13
		asl int16				; shift out one bit
		rol int16+1
		lda bcd+0				; and add into result
		adc bcd+0
		sta bcd+0
		lda bcd+1				; propagating any carry
		adc bcd+1
		sta bcd+1
		lda bcd+2				; ... thru whole result
		adc bcd+2
		sta bcd+2
		dex						; and repeat for next bit
		bne .cbit13
 
		cld						; back to binary
	rts

	; similar to get_string_length
	; enter with .X/.Y = the number to check
	; returns number of digits in .Y

	get_num_length
		jsr int16_to_string
		jsr trim_num
		ldy #6
	-	lda string_16_bit_trimmed,y
		bne +
		dey
		bne -
	+ rts
}

!macro MATH_OPS {

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

	; https://codebase64.org/doku.php?id=base:16bit_division_16-bit_result

	divide_16by16
		lda #0				; preset remainder to 0
		sta remainder
		sta remainder+1
		ldx #16				;repeat for each bit: ...

	.lp	asl dividend		;dividend lb & hb*2, msb -> Carry
		rol dividend+1
		rol remainder		;remainder lb & hb * 2 + msb from carry
		rol remainder+1
		lda remainder
		sec
		sbc divisor			;substract divisor to see if it fits in
		tay					;lb quotient -> Y, for we may need it later
		lda remainder+1
		sbc divisor+1
		bcc +				;if carry=0 then divisor didn't fit in yet

		sta remainder+1		;else save substraction quotient as new remainder,
		sty remainder
		inc quotient		;and INCrement quotient cause divisor fit in 1 times

	+	dex
		bne .lp
		rts


	divide_24by24
		lda #0				;preset remainder to 0
		sta remainder
		sta remainder+1
		sta remainder+2
		ldx #24				;repeat for each bit: ...

	divloop
		asl dividend		;dividend lb & hb*2, msb -> Carry
		rol dividend+1
		rol dividend+2
		rol remainder		;remainder lb & hb * 2 + msb from carry
		rol remainder+1
		rol remainder+2
		lda remainder
		sec
		sbc divisor			;substract divisor to see if it fits in
		tay					;LSB result -> Y, for we may need it later
		lda remainder+1
		sbc divisor+1
		sta tempzp_c
		lda remainder+2
		sbc divisor+2
		bcc +				;if carry=0 then divisor didn't fit in yet

		sta remainder+2		;else save substraction result as new remainder,
		lda tempzp_c
		sta remainder+1
		sty remainder
		inc dividend		;and INCrement result cause divisor fit in 1 times

	+	dex
		bne divloop	
	rts
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

