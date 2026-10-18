; miscellanious functions

;#################
;# ROM SWITCHING #
;#################

; see also misc-macros.s near line 140

!ifdef c128 {
	disable_roms
		sei
		lda #%00111110
		sta MMU_CR1
	rts
} else {
	disable_roms
		sei
		lda #$35
		sta $01
	rts
}

enable_kernal_only
	+ENABLE_KERNAL_ONLY
rts

;#####################
;# STRING OPERATIONS #
;#####################

; this simply translates an ASCII string into somewhat-close PETSCII and
; prints the result.  Color/cursor/control codes are not supported.

print_msg_ascii
	sta print_msg_char_limit

	dec print_msg_char_limit
	stx print_msg_addr
	sty print_msg_addr+1
	ldy #0
-	lda (print_msg_addr),y
	beq +

	tax
	lda ascii_to_petscii_table,x
	jsr CHROUT
	cpy print_msg_char_limit
	beq +
	iny
	bne -
  +
rts

get_string_length
	stx utility_pointer_b
	sty utility_pointer_b+1
	ldy #0
-	lda (utility_pointer_b),y
	beq +
	iny
	bne -
  +
rts

; call with .X/.Y = address of string
; .A = width of area to display in
; prints as many cursor-RIGHTS as needed

center_string
	pha
	jsr get_string_length
	pla

center_string_by_len_val	; or enter here with known string length in .Y
	sty temp_abs_a			; and width of the area in .A
	sec
	sbc temp_abs_a
	lsr
	beq +
	tay
	dey
	beq +
	lda #RIGHT
-	jsr CHROUT
	dey
	bne -
  +
rts

strip_trailing_spaces
	ldx #0
-	lda string_buffer,x
	beq +
	inx
	cpx #48
	bne -
	rts

+
-	dex
	lda string_buffer,x
	cmp #$20
	beq -

	lda #0
-	inx
	sta string_buffer,x
	cpx #47
	bne -
rts


;########################
;# ZERO-PAGE OPERATIONS #
;########################

; Always call the swap in pairs, once to "back-up" KERNAL/system zero page
; and then again later to restore it

swap_zero_page
	ldx #2
-	lda $00,x
	pha
	lda zero_page_swap_area,x
	sta $00,x
	pla
	sta zero_page_swap_area,x
	inx
	bne -
rts

; this should only be used at player start, after swapping-out the
; KERNAL/system zero page contents.

erase_zero_page
	lda #0
	ldx #2
-	sta $00,x
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
	sec
	jmp print_msg

+	lda #0
	ldx #<uint16_string_buffer
	ldy #>uint16_string_buffer
	sec
jmp print_msg


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
+	iny
rts


;###################
;# MATH OPERATIONS #
;###################

; Multiply routines by JackAsser (reformatted for Acme and my code style)
; https://codebase64.org/doku.php?id=base:seriously_fast_multiplication

; Unsigned 8-bit multiplication with unsigned 16-bit result
;
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


; Unsigned 16-bit multiplication with unsigned 32-bit result
;
; Input: 16-bit unsigned value in multiplicand_a
;        16-bit unsigned value in multiplicand_b
;        Carry=0: Re-use multiplicand_a from previous multiplication (faster)
;        Carry=1: Set multiplicand_a (slower)
;
; Output: 32-bit unsigned value in product
;
; Clobbered: product, .X, .A, .C
;
; Allocation setup: multiplicand_a, multiplicand_b, and product
;                   multablo, multabhi, multab2lo, multab2hi must be
;                   page aligned. Each table are 512 bytes. Total 2kb.
;
; Table generation: I:0..511
;                   multablo = <((I*I)/4)
;                   multabhi = >((I*I)/4)
;                   multab2lo = <(((I-255)*(I-255))/4)
;                   multab2hi = >(((I-255)*(I-255))/4)

multiply_16x16

		; <multiplicand_a * <multiplicand_b = AAaa
		; <multiplicand_a * >multiplicand_b = BBbb
		; >multiplicand_a * <multiplicand_b = CCcc
		; >multiplicand_a * >multiplicand_b = DDdd
		;
		;       AAaa
		;     BBbb
		;     CCcc
		; + DDdd
		; ----------
		;   product!

		; Setup multiplicand_a if changed

		bcc +
		lda multiplicand_a+0
		sta sm1a+1
		sta sm3a+1
		sta sm5a+1
		sta sm7a+1
		eor #$ff
		sta sm2a+1
		sta sm4a+1
		sta sm6a+1
		sta sm8a+1
		lda multiplicand_a+1
		sta sm1b+1
		sta sm3b+1
		sta sm5b+1
		sta sm7b+1
		eor #$ff
		sta sm2b+1
		sta sm4b+1
		sta sm6b+1
		sta sm8b+1

+		; Perform <multiplicand_a * <multiplicand_b = AAaa
		ldx multiplicand_b+0
		sec
sm1a	lda multablo,x
sm2a	sbc multab2lo,x
		sta product+0
sm3a	lda multabhi,x
sm4a	sbc multab2hi,x
		sta _AA+1

		; Perform >multiplicand_a_hi * <multiplicand_b = CCcc
		sec
sm1b	lda multablo,x
sm2b	sbc multab2lo,x
		sta _cc+1
sm3b	lda multabhi,x
sm4b	sbc multab2hi,x
		sta _CC+1

		; Perform <multiplicand_a * >multiplicand_b = BBbb
		ldx multiplicand_b+1
		sec
sm5a	lda multablo,x
sm6a	sbc multab2lo,x
		sta _bb+1
sm7a	lda multabhi,x
sm8a	sbc multab2hi,x
		sta _BB+1

		; Perform >multiplicand_a * >multiplicand_b = DDdd
		sec
sm5b	lda multablo,x
sm6b	sbc multab2lo,x
		sta _dd+1
sm7b	lda multabhi,x
sm8b	sbc multab2hi,x
		sta product+3

		; Add the separate multiplications together
		clc
_AA		lda #0
_bb		adc #0
		sta product+1
_BB		lda #0
_CC		adc #0
		sta product+2
		bcc +
		inc product+3
		clc
	  +
_cc		lda #0
		adc product+1
		sta product+1
_dd		lda #0
		adc product+2
		sta product+2
		bcc +
		inc product+3
	  +
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
	sta divide_tmp
	lda remainder+2
	sbc divisor+2
	bcc +				;if carry=0 then divisor didn't fit in yet

	sta remainder+2		;else save substraction result as new remainder,
	lda divide_tmp
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
	asl dividend		;dividend lb & hb*3, msb -> Carry
	rol dividend+1
	rol dividend+2
	rol dividend+3
	rol remainder		;remainder lb & hb * 2 + msb from carry
	rol remainder+1
	lda remainder
	sec
	sbc divisor		;sustract divisor to see if it fits in
	tay					;lb quotient -> Y, for we may need it later
	lda remainder+1
	sbc divisor+1
	bcc +				;if carry=0 then divisor didn't fit in yet

	sta remainder+1		;else save substraction quotient as new remainder,
	sty remainder
	inc quotient		;and INCrement quotient cause divisor fit in 1 times

+	dex
	bne .lp3
rts


divide_32by24
	lda #0				;preset remainder to 0
	sta remainder
	sta remainder+1
	sta remainder+2
	ldx #32				;repeat for each bit: ...

.lp4
	asl dividend		;dividend lb & hb*2, msb -> Carry
	rol dividend+1
	rol dividend+2
	rol dividend+3
	rol remainder		;remainder lb & hb * 2 + msb from carry
	rol remainder+1
	rol remainder+2
	lda remainder
	sec
	sbc divisor			;subtract divisor to see if it fits in
	tay					;LSB result -> Y, for we may need it later
	lda remainder+1
	sbc divisor+1
	sta divide_tmp
	lda remainder+2
	sbc divisor+2
	bcc +				;if carry=0 then divisor didn't fit in yet

	sta remainder+2		;else save substraction result as new remainder,
	lda divide_tmp
	sta remainder+1
	sty remainder
	inc quotient		;and INCrement result cause divisor fit in 1 times

+	dex
	bne .lp4
rts

; this expects the file entry number in the list in .X
; set the carry to get the address of the PETSCII filename
; or clear to get the address of the screen code version

calc_filename_address
	lda #0
	sta temp_abs_a
	ror
	sta temp_abs_b

	txa
	asl
	rol temp_abs_a
	asl
	rol temp_abs_a
	asl
	rol temp_abs_a
	asl
	rol temp_abs_a
	tax

	clc
	lda temp_abs_a
	bit temp_abs_b
	bmi +

	!ifndef c128 {
		adc exp_screencode_filenames_start_page
	} else {
		adc #>VDC_filename_cache
	}

	tay
	rts

+	clc
	lda temp_abs_a
	adc exp_petscii_filenames_start_page
	tay
rts

; enter with .X = the file entry number in the playlist
; set carry for PETSCII filename, clear for screen code 
; returns it in the string buffer

get_filename_from_exp_ram
	jsr calc_filename_address
	stx expansion_memory_target_pointer
	sty expansion_memory_target_pointer+1
	lda #0
	sta expansion_memory_target_pointer+2

	sta stash_size+1
	lda #16
	sta stash_size

	lda #<string_buffer
	sta expansion_transfer_local_addr
	lda #>string_buffer
	sta expansion_transfer_local_addr+1

	+JSR_INDIRECT (fetch_block_vec)
rts

; check if C= key is pressed, wait for release

check_com_key
	!ifdef c128 {
		lda #%11111111			; make sure extra columns K0-2 are high
		sta C128_EXTRA_KEYS
	}

	lda #%01111111 ; column 7 low
	sta CIA1_PORT_A
	lda #%11011111 ; look for row 5
	cmp CIA1_PORT_B
	bne .ck_out

	lda #$ff
-	cmp CIA1_PORT_B
	bne -
	lda #0
.ck_out
	eor #$df
rts

press_any_key ; display "press key" message and wait for keypress
	lda #0
	ldx #<press_key_msg
	ldy #>press_key_msg
	sec
	jsr print_msg

wait_key
-	jsr GETIN
	beq -
rts

clear_string_buffer
	ldy #47
	lda #0
-	sta string_buffer,y
	dey
	bpl -
rts

; enter with .Y = allowed string length (up to 48 chars max)
; returns the string in the string buffer, and its length in .Y

; the last instruction when the routine exits is a load of that value,
; so the caller can just immediately bne/beq after calling this.
; returns .C set if the user hit Run/Stop or Esc, else .C will be clear.

get_text_input
	sty temp_abs_a ; temp_abs_a is the limit, temp_abs_b is the current count

	jsr clear_string_buffer
	ldy #0
	sty temp_abs_b
	jsr upd_cursor

.nxt
	!ifndef c128 {
		lda TIME+2		; low byte
		and #$20		; toggle every 32 jiffies, roughly half a second
		cmp temp_abs_c
		beq +
		sta temp_abs_c
		jsr upd_cursor
	  +
	}

	jsr GETIN
	beq .nxt

	!ifdef c128 {
		cmp #$1b ; Esc
		bne .get_input_ck_stop
		beq .get_input_exit_empty
	}

.get_input_ck_stop
	pha
	jsr STOP ; check for Run/Stop
	bne .get_input_ck_return
	pla

.get_input_exit_empty
	jsr clear_string_buffer
	ldy #0
	sec
	rts

.get_input_ck_return
	pla
	cmp #$0d
	bne .get_input_ck_del
	ldy temp_abs_b
	clc
	rts

.get_input_ck_del
	cmp #$14
	bne .get_input_ck_printable
	ldy temp_abs_b
	beq .nxt
	lda #0
	dey
	sta string_buffer,y
	sty temp_abs_b
	lda #" "
	jsr CHROUT
	lda #LEFT
	jsr CHROUT
	jsr CHROUT
	jsr upd_cursor
	jmp .nxt

.get_input_ck_printable
	cmp #$20
	bcc .nxt
	cmp #$80
	bcc .st
	cmp #$a0
	bcc .nxt

.st
	ldy temp_abs_b
	cpy temp_abs_a
	beq .nxt
	sta string_buffer,y
	iny
	sty temp_abs_b
	cmp #$22 ; quote
	bne .get_input_print_char
	jsr CHROUT
	jsr CHROUT
	lda #LEFT

.get_input_print_char
	jsr CHROUT
	jsr upd_cursor
	jmp .nxt

upd_cursor
	!ifndef c128 {
		lda temp_abs_c
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

; Binary search routine written by "atolle" on 6502 forums, reformatted to fit
; my code style.  Source: http://forum.6502.org/viewtopic.php?f=2&t=1199

; Searches a sorted table of 16-bit values.  Table entries must be in
; ascending order, and aligned to a two-byte boundary.

binsearch_size     = 2				; element size (must be power of 2)

binary_search
.bns_loop
	sec								; calculate high - low
	lda binsearch_high
	sbc binsearch_low
	tax								; preserve lsb of difference in x
	lda binsearch_high+1
	sbc binsearch_low+1
	bcc .bns_done					; if low > high, not found
	lsr								; calculate (high - low) / 2
	tay
	txa
	ror								; carry cleared because multiple of 2
	and #$100 - binsearch_size		; align to element size
	adc binsearch_low				; mid = low + ((high - low) / 2)
	sta binsearch_mid
	tya
	adc binsearch_low+1
	sta binsearch_mid+1
	lda binsearch_value+1			; load target value msb
	ldy #1							; load index to msb
	cmp (binsearch_mid),y			; compare msb
	beq .bns_chklsb
	bcc .bns_modhigh				; a[mid] > value
.bns_modlow								; a[mid] < value
	lda binsearch_mid				; low = mid + element size
	adc #binsearch_size - 1			; carry always set
	sta binsearch_low
	lda binsearch_mid+1
	adc #0
	sta binsearch_low+1
	jmp .bns_loop
.bns_chklsb
	lda binsearch_value				; load target value lsb
	dey								; set index to lsb
	cmp (binsearch_mid),y			; compare lsb
	beq .bns_done
	bcs .bns_modlow					; a[mid] < value
.bns_modhigh							; a[mid] > value
	lda binsearch_mid				; high = mid - element size
	sbc #binsearch_size - 1			; carry always clear
	sta binsearch_high
	lda binsearch_mid+1
	sbc #0
	sta binsearch_high+1
	jmp .bns_loop
.bns_done
	rts

; how to perform a binary search using that code:
;
; prior to entry,
;     binsearch_low should point to first entry in the table.
;     binsearch_high should point to last entry in the table.
;     binsearch_value should contain the search target.
;
;	lda #<search_value
;	sta binsearch_value
;	lda #>search_value
;	stx binsearch_value+1
;
;	lda #<note_period_table
;	sta binsearch_low
;	lda #>note_period_table
;	sta binsearch_low+1
;
;	lda #<(note_period_table+118)
;	sta binsearch_high
;	lda #>(note_period_table+118)
;	sta binsearch_high+1
;
;	jsr binary_search
;
; if .C = 1, the value in binsearch_mid is the address of the exact match
; if .C = 0, the value in binsearch_low is the address of the closest entry 


;##########
;#  MISC  #
;##########

; enter with fill_copy_target set to the start address of the block to
; be filled, .A holds the fill byte, .X holds the block length.

local_ram_block_fill
	sta temp_abs_a
	stx temp_abs_x
	sty temp_abs_y

	ldy #0
-	sta (fill_copy_target),y
	iny
	dex
	bne -

	clc
	lda fill_copy_target
	adc temp_abs_x
	sta fill_copy_target
	bcc +
	inc fill_copy_target+1

+	lda temp_abs_a
	ldx temp_abs_x
	ldy temp_abs_y
rts

; enter with fill_copy_source and fill_copy_target set to the source and
; target addresses of the area to be copied, .X is the copy length

local_ram_block_copy
	stx temp_abs_x
	sty temp_abs_y

	ldy #0
-	lda (fill_copy_source),y
	sta (fill_copy_target),y
	iny
	dex
	bne -

	clc
	lda fill_copy_source
	adc temp_abs_x
	sta fill_copy_source
	bcc +
	inc fill_copy_source+1
	clc

+	lda fill_copy_target
	adc temp_abs_x
	sta fill_copy_target
	bcc +
	inc fill_copy_target+1

+	ldx temp_abs_x
	ldy temp_abs_y
rts

;#######################
;# C128 VDC OPERATIONS #
;#######################

; enter with fill_copy_source set to the source address,
; fill_copy_target is the target, and .X is the copy length

!ifdef c128 {
	vdc_block_copy
		+VDC_RAM_ACC_SETUP

		lda #24
		sta VDC_ADDR
		lda #$a0
		sta VDC_DATA

		lda #32
		sta VDC_ADDR
		lda fill_copy_source+1
		sta VDC_DATA

		lda #33
		sta VDC_ADDR
		lda fill_copy_source
		sta VDC_DATA

		lda #30
		sta VDC_ADDR
		stx VDC_DATA
	rts

	vdc_block_copy_extend
		+VDC_UPD_RDY_WAIT
		lda #30
		sta VDC_ADDR
		stx VDC_DATA
	rts

	; enter with fill_copy_target = start address, .A = fill byte,
	; .X = fill length

	vdc_block_fill
		sta temp_abs_a

		+VDC_RAM_ACC_SETUP

		lda #31
		sta VDC_ADDR
		lda temp_abs_a
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #24
		sta VDC_ADDR
		lda #$20
		sta VDC_DATA

		lda #30
		sta VDC_ADDR
		dex
		stx VDC_DATA

		lda temp_abs_a
	rts

	; this extends the previous block fill, .A = fill byte, .X = fill length

	vdc_block_fill_extend
		sta temp_abs_a
		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR
		lda temp_abs_a
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #24
		sta VDC_ADDR
		lda #$20
		sta VDC_DATA

		lda #30
		sta VDC_ADDR
		stx VDC_DATA
		lda temp_abs_a
	rts

	vdc_ram_rw_setup
		+VDC_RAM_RW_SETUP
	rts

	vdc_write_ram
		+VDC_WRITE_RAM
	rts

	vdc_read_ram
		+VDC_READ_RAM
	rts
}

; translates a 0-15 value in .A into printable "0" to "f", returned in .A
to_hex
	and #$0f
	cmp #10
	bcs +
	adc #$30
	rts

+	clc
	adc #$37
rts

; Same thing but with "A" through "F" capitalized.
to_hex_caps
	and #$0f
	cmp #10
	bcs +
	adc #$30
	rts

+	clc
	adc #$57
rts


; directly stores to the screen starting at the address in utility_pointer to
; "print" the two-digit hex value in .A

display_byte_hex_direct
	sta temp_abs_a
	sty temp_abs_y

	!ifndef c128 {
		lsr
		lsr
		lsr
		lsr
		jsr to_hex
		ldy #0
		sta (utility_pointer),y
		lda temp_abs_a
		jsr to_hex
		iny
		sta (utility_pointer),y
	} else {
		lda utility_pointer
		sta fill_copy_target
		lda utility_pointer+1
		sta fill_copy_target+1
		lda temp_abs_a
		lsr
		lsr
		lsr
		lsr
		jsr to_hex
		pha
		jsr vdc_ram_rw_setup
		pla
		jsr vdc_write_ram

		lda temp_abs_a
		jsr to_hex
		jsr vdc_write_ram
	}

	ldy temp_abs_y
rts

; enter with .A = byte to fill with
fill_audio_buffers
	ldy #0
-	sta audio_buffer_left,y
	sta audio_buffer_right,y
	iny
	bne -
rts

keyboard_debounce
	lda #0						; drive all columns low on CIA
	sta CIA1_PORT_A
	!ifdef c128 {
		sta C128_EXTRA_KEYS		; and on C128 extra keys
	}
	lda #$ff
-	cmp CIA1_PORT_B				; is any row low?
	bne -						; if so, a key of some kind was pressed

	lda #0						; make sure we exit with a "no key" status
rts

press_key_msg
	!text "Press any key",0
