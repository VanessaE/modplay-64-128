; miscellanious functions

!text "misc functions",0

;#####################
;# STRING OPERATIONS #
;#####################

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
	beq +
	tay
	dey
	beq +
	lda #RIGHT
-	jsr CHROUT
	dey
	bne -
+ rts

; converts a 0-15 value in .A into printable "0" to "F", returns it in .A
to_hex
	sec
	cmp #10
	bcs +
	adc #$30
rts

+	clc
	adc #$37
rts

;########################
;# ZERO-PAGE OPERATIONS #
;########################

 backup_zero_page
	ldx #2
-	lda $00,x
	sta zp_backup,x
	inx
	bne -

	lda #0
	ldx #2
-	sta $00,x
	inx
	bne -
rts

restore_zero_page
	ldx #2
-	lda zp_backup,x
	sta $00,x
	inx
	bne -
rts

;######################
;# NUMERIC_OPERATIONS #
;######################

; enter with carry set to strip leading 0's

print_uint16
	jsr uint16_to_string
	bcc +

	jsr trim_num
	lda #0
	ldx #<uint16_string_buf_trim
	ldy #>uint16_string_buf_trim
	jsr print_msg
	rts

+	lda #0
	ldx #<uint16_string_buffer
	ldy #>uint16_string_buffer
	jsr print_msg
rts

; from Codebase64:
; https://codebase64.org/doku.php?id=base:int16_and_uint16_conversion_to_string
; enter with carry set to strip leading 0's

uint16_to_string
	php
	stx int16
	sty int16+1

	ldy #6
	lda #0
-	sta uint16_string_buffer,y
	sta uint16_string_buf_trim,y
	dey
	bpl -

	ldy int16+1
	jsr bin_to_bcd_16		; converts the number to BCD
	;lda bcd+2
	and #$0f				; extracts every byte and adds $30
	ora #$30
	sta uint16_string_buffer+1

	lda bcd+1
	and #$0f
	ora #$30
	sta uint16_string_buffer+3
	lda bcd+1
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta uint16_string_buffer+2

	lda bcd+0
	and #$0f
	ora #$30
	sta uint16_string_buffer+5
	lda bcd+0
	lsr
	lsr
	lsr
	lsr
	ora #$30
	sta uint16_string_buffer+4
	lda #$20
	sta uint16_string_buffer+0
	plp						; recall the carry
	bcs +
	rts

+	php
	ldx #1					; remove 0s at beginning
.rem0
	lda uint16_string_buffer,x
	cmp #$30				; if it's a '0'
	bne ++
	lda #$20				; put a space instead
	sta uint16_string_buffer,x
	inx
	cpx #5					; exits before last digit
	bne .rem0
++	plp
rts

trim_num
	ldy #0
	cpx #0
	beq .tndone
.trmlp
	lda uint16_string_buffer,x
	sta uint16_string_buf_trim,y
	beq .tndone
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
.tndone
	cld						; back to binary
rts

; similar to get_string_length
; enter with .X/.Y = the number to check
; returns number of digits in .Y
; set the carry to look for 0-led numbers

get_num_length
	jsr uint16_to_string
	bcc +

	jsr trim_num

+	ldy #6
-	lda uint16_string_buf_trim,y
	bne +
	dey
	bne -
+ rts


;###################
;# MATH OPERATIONS #
;###################


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
; reminder:  quotient+remainder = dividend ÷ divisor  😛

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
	sbc divisor			;sustract divisor to see if it fits in
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

.lp2
	asl dividend		;dividend lb & hb*2, msb -> Carry
	rol dividend+1
	rol dividend+2
	rol remainder		;remainder lb & hb * 2 + msb from carry
	rol remainder+1
	rol remainder+2
	lda remainder
	sec
	sbc divisor			;subtract divisor to see if it fits in
	tay					;LSB result -> Y, for we may need it later
	lda remainder+1
	sbc divisor+1
	sta divide24_tmp
	lda remainder+2
	sbc divisor+2
	bcc +				;if carry=0 then divisor didn't fit in yet

	sta remainder+2		;else save substraction result as new remainder,
	lda divide24_tmp
	sta remainder+1
	sty remainder
	inc dividend		;and INCrement result cause divisor fit in 1 times

+	dex
	bne .lp2
rts


divide_32by16
	lda #0				; preset remainder to 0
	sta remainder
	sta remainder+1
	ldx #32				;repeat for each bit: ...

.lp3
	asl dividend32		;dividend lb & hb*3, msb -> Carry
	rol dividend32+1
	rol dividend32+2
	rol dividend32+3
	rol remainder		;remainder lb & hb * 2 + msb from carry
	rol remainder+1
	lda remainder
	sec
	sbc divisor16		;sustract divisor to see if it fits in
	tay					;lb quotient -> Y, for we may need it later
	lda remainder+1
	sbc divisor16+1
	bcc +				;if carry=0 then divisor didn't fit in yet

	sta remainder+1		;else save substraction quotient as new remainder,
	sty remainder
	inc quotient32		;and INCrement quotient cause divisor fit in 1 times

+	dex
	bne .lp3
rts


calc_filename_address ; expects .X to be a list scroll position
	lda #0
	sta tempzp_c

	txa
	asl
	rol tempzp_c
	asl
	rol tempzp_c
	asl
	rol tempzp_c
	asl
	rol tempzp_c

	clc
	adc #<playlist_filenames
	tax
	lda tempzp_c
	adc #>playlist_filenames
	tay
rts

check_com_key ; check if C= key is pressed, wait for release
	lda #$7f ; column 7 low
	sta CIA1
	lda #$df ; look for row 5
	cmp CIA1+$01
	bne .ck_out

	lda #$ff
-	cmp CIA1+$01
	bne -
	lda #0
.ck_out
	eor #$df
rts

press_any_key ; display "press key" message and wait for keypress
	lda #0
	ldx #<press_key_msg
	ldy #>press_key_msg
	jsr print_msg

-	jsr GETIN
	beq -
rts

!ifndef c128 {
	press_any_key_ascii ; display "press key" message and wait for keypress
		lda #0
		ldx #<press_key_msg_ascii
		ldy #>press_key_msg_ascii
		jsr print_msg_ascii

	-	jsr GETIN
		beq -
	rts
}

clear_string_buffer
	ldy #47
	lda #0
-	sta string_buffer,y
	dey
	bpl -
rts

; enter with .Y = allowed string length (up to 48 chars max)
; returns the string in the string buffer, and its length in .Y

get_text_input
	sty tempzp_d ; so _d is the limit, _d+1 is the current count

	jsr clear_string_buffer
	ldy #0
	sty tempzp_d+1
	jsr upd_cursor

.nxt
	!ifndef c128 {
		lda TIME+2		; low byte
		and #$20		; toggle every 32 jiffies, roughly half a second
		cmp tempzp_c
		beq +
		sta tempzp_c
		jsr upd_cursor
	}
+	jsr GETIN
	beq .nxt

	!ifdef c128 {
		cmp #$1b ; Esc
		bne +
		beq ++
	}

+	pha
	jsr STOP ; check for Run/Stop
	bne +
	pla

++	jsr clear_string_buffer
	ldy #0
	rts

+	pla
	cmp #$0d ; return
	bne +
	ldy tempzp_d+1
	rts

+	cmp #$14 ; delete
	bne +
	ldy tempzp_d+1
	beq .nxt
	lda #0
	dey
	sta string_buffer,y
	sty tempzp_d+1
	lda #" "
	jsr CHROUT
	lda #LEFT
	jsr CHROUT
	jsr CHROUT
	jsr upd_cursor
	jmp .nxt

+	sec
	cmp #$20
	bcc .nxt
	cmp #$80
	bcc .st
	cmp #$a0
	bcc .nxt

.st
	ldy tempzp_d+1
	cpy tempzp_d
	beq .nxt
	sta string_buffer,y
	iny
	sty tempzp_d+1
	cmp #$22 ; quote
	bne +
	jsr CHROUT
	jsr CHROUT
	lda #LEFT
+	jsr CHROUT
	jsr upd_cursor
	jmp .nxt

upd_cursor
	!ifndef c128 {
		lda tempzp_c
		and #$20
		beq +
		lda #RVSON
		jsr CHROUT
	+	lda #" "
		jsr CHROUT
		lda #RVSOFF
		jsr CHROUT
		lda #LEFT
		jsr CHROUT
	} else {
		lda #FLASHON
		jsr CHROUT
		lda #RVSON
		jsr CHROUT
		lda #" "
		jsr CHROUT
		lda #RVSOFF
		jsr CHROUT
		lda #FLASHOFF
		jsr CHROUT
		lda #LEFT
		jsr CHROUT
	}
rts

; this function just uses DISPLY to print the char it's given, as ASCII, and
; uses CHROUT to handle control/color/cursor codes.  Call it just like CHROUT.
; it's .Y-safe, too.
 
chrout_ascii
	pha
	tax
	tya
	pha

	txa
	sec
	cmp #$20
	bcs +

	lda control_code_flags_table_low,x
	bne .pa
	txa
	jsr CHROUT
	jmp .nc

+	cmp #$80
	bcc .pa
	cmp #$a0
	bcs .pa

	lda control_code_flags_table_high-128,x
	bne .pa
	txa
	jsr CHROUT
	jmp .nc

.pa
	txa
	ldx CHAR_COLOR
	jsr DISPLY
	lda #RIGHT
	jsr CHROUT

.nc
	pla
	tay
	pla
rts

; this one uses the above function to print an ASCII string, and works like
; print_msg: .X/.Y holds the message address, .A = max length or 0, but
; with a variation.  Effectively it just prints the string raw, without the
; usual text-to-screen-codes translation.

print_msg_ascii
	sta print_msg_char_limit
	dec print_msg_char_limit
	stx print_msg_addr
	sty print_msg_addr+1
	ldy #0

-	lda (print_msg_addr),y
	bne +
	rts

+	jsr chrout_ascii
	cpy print_msg_char_limit
	beq +
	iny
	bne -
	inc print_msg_addr+1
	bne -
+ rts

print_filetype
	sec
	lda current_file_type

	cmp #1
	bne +
	ldx #<tracker_name_msg_soundtracker
	ldy #>tracker_name_msg_soundtracker
	jmp ++

+	cmp #4
	bcs +
	ldx #<tracker_name_msg_protracker
	ldy #>tracker_name_msg_protracker
	jmp ++

+	cmp #6
	bcs +
	ldx #<tracker_name_msg_startrekker
	ldy #>tracker_name_msg_startrekker
	jmp ++

+	ldx #<tracker_name_msg_fasttracker
	ldy #>tracker_name_msg_fasttracker
++ rts

!ifndef c128 {
	print_filetype_ascii
		sec
		lda current_file_type

		cmp #1
		bne +
		ldx #<tracker_name_msg_soundtracker_ascii
		ldy #>tracker_name_msg_soundtracker_ascii
		jmp ++

	+	cmp #4
		bcs +
		ldx #<tracker_name_msg_protracker_ascii
		ldy #>tracker_name_msg_protracker_ascii
		jmp ++

	+	cmp #6
		bcs +
		ldx #<tracker_name_msg_startrekker_ascii
		ldy #>tracker_name_msg_startrekker_ascii
		jmp ++

	+	ldx #<tracker_name_msg_fasttracker_ascii
		ldy #>tracker_name_msg_fasttracker_ascii
	++ rts
}

; if the byte equals its PETSCII value in that pos, it can hold a new char to
; print in ASCII mode.  If there's a 0, it's a control code that we need to
; pass to CHROUT, e.g. colors, cursor moves, etc.

control_code_flags_table_low
	!byte 0,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1
	!byte 1,0,1,0,0,1,1,1,1,1,1,1,0,0,0,0

control_code_flags_table_high
	!byte 1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
