; generate volume scaler tables
; these tables scale the amplitude of the sample data according to the volume
; the mod asks for, converts the signed samples to unsigned, and downscales
; the resolution of the final numbers according to the needs of the audio
; driver.

; enter with .A = desired output resolution

!text "tables",0

generate_volume_tables
	lda #<volume_table_lower
	sta fill_copy_target
	lda #>volume_table_lower
	sta fill_copy_target+1
	lda #0
	sta bval_cnt			; byte value counter
	sta vol_cnt				; volume counter

	--	lda vol_cnt
		asl
		tax
	-	lda bval_cnt
		jsr multiply_8x8 	; returns 14 bit value in 'product' (top 2 bits are
							; always 0 here) MSB is also in .A at exit.

		asl product			; multiply by 4 then displace downward by one byte
		rol					; is identical to dividing by 64 (14 --> 8 bit),
		asl product			; but is considerably faster.
		rol
		sta product

; MOD samples are 2's-compliment signed, this will offset where the data
; is stored in the page, so that the output from the table is unsigned.

		lda bval_cnt
		clc
		adc #$80
		tay

; re-center the amplitude range to keep the middle sample value at $7f/80.

		sec
		lda #64
		sbc vol_cnt
		asl
		clc
		adc product

; divide the final value down to the resolution the audio driver needs
; only 4 or 8 bits allowed -- note that we actually shift one extra step
; so the volume tables actually output 3-bit or 7-bit values to avoid the
; mixer needing to do that shift in realtime.

		ldx volume_tables_resolution
		cpx #4
		bne .nd

		lsr
		lsr
		lsr
		lsr

	.nd	lsr
		sta (fill_copy_target),y
		inc bval_cnt
		bne --
		inc fill_copy_target+1
		inc vol_cnt
		lda vol_cnt
		cmp #16		; the first 16 pages fit below $c800...
		bne +
		lda #>volume_table_upper	; ...while the rest goes under the KERNAL.
		sta fill_copy_target+1
		bne -
	+	cmp #32
		bne -
rts

generate_tempo_table
	lda #0
	ldy #31
-	sta tempo_table_fracts,y
	sta tempo_table_lows,y
	dey
	bpl -

	ldx #32 ; entries 0-31 are unused.

-	stx temp_abs_x
	lda isr_trigger_interval
	jsr multiply_8x8

	lda #0
	sta dividend32
	lda #<tempo_fine_adjust_constant
	sta dividend32+1
	lda #>tempo_fine_adjust_constant
	sta dividend32+2
	lda #^tempo_fine_adjust_constant ; "^" means "bank" e.g. bits 16-23
	sta dividend32+3

	lda product
	sta divisor16
	lda product+1
	sta divisor16+1

	jsr divide_32by16

	ldx temp_abs_x
	lda quotient
	sta tempo_table_fracts,x
	lda quotient+1
	sta tempo_table_lows,x
	inx
	bne -
rts

generate_steprate_table

	lda isr_trigger_interval
	ldx #pitch_fine_adjust_constant
	jsr multiply_8x8

	ldx #0

-	lda #0
	sta dividend
	sta divisor+2

	lda product
	sta dividend+1
	lda product+1
	sta dividend+2

	lda note_period_table,x
	sta divisor
	inx
	lda note_period_table,x
	sta divisor+1

	stx temp_abs_x
	jsr divide_24by24
	ldx temp_abs_x

	lda quotient
	lsr quotient+1
	ror
	lsr quotient+1
	ror
	lsr quotient+1
	ror
	lsr quotient+1
	ror

	dex
	sta steprate_table,x
	inx
	lda quotient+1
	sta steprate_table,x

+	inx
	cpx #120
	bne -
rts

regen_all_tables
	lda isr_trigger_interval
	cmp last_isr_trigger_interval
	bne +
	lda volume_tables_resolution
	cmp last_volume_tables_resolution 
	bne +
	rts

+	bit allow_regen_msg
	bpl no_msgs1

	!ifndef c128 {
		bit enable_screen_on_playback ; because if it's enabled, the display will
		bmi +						; have switched to ASCII mode by this point.

		jsr gray_out
		jsr draw_short_popup
		lda #0
		ldx #<main_player_regen_tables_msg
		ldy #>main_player_regen_tables_msg
		jsr print_msg
		jmp ++

	+	lda #0
		ldx #<main_player_regen_tables_msg_ascii
		ldy #>main_player_regen_tables_msg_ascii
		jsr print_msg_ascii
	 ++
	} else {
		lda #0
		ldx #<main_player_regen_tables_msg
		ldy #>main_player_regen_tables_msg
		jsr print_msg
	}

no_msgs1
	lda volume_tables_resolution
	cmp last_volume_tables_resolution
	beq +
	sta last_volume_tables_resolution

	jsr generate_volume_tables

+	lda isr_trigger_interval
	cmp last_isr_trigger_interval
	beq +
	sta last_isr_trigger_interval

	jsr generate_tempo_table
	jsr generate_steprate_table

+	bit allow_regen_msg
	bpl no_msgs2

	!ifndef c128 {
		bit enable_screen_on_playback
		bpl no_msgs2

		lda #0
		ldx #<main_player_regen_erase_tables_msg_ascii
		ldy #>main_player_regen_erase_tables_msg_ascii
		jsr print_msg_ascii
	} else {
		lda #0
		ldx #<main_player_regen_erase_tables_msg
		ldy #>main_player_regen_erase_tables_msg
		jsr print_msg
	}

  no_msgs2
rts

vol_cnt		!byte 0
bval_cnt	!byte 0
