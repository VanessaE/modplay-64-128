; generate volume scaler tables
; these tables scale the amplitude of the sample data according to the volume
; the mod asks for, converts the signed samples to unsigned, and downscales
; the resolution of the final numbers according to the needs of the audio
; driver.

; enter with .A = desired output resolution

!text "tables",0

generate_volume_tables
	lda #0
	sta fill_copy_target
	sta vol_cnt							; volume counter

	next_vol_val
		lda vol_cnt
		cmp #16
		bcs +
		adc #>volume_table_lower		; the first 16 pages fit below $c800...
		jmp ++

	+	clc
		adc #(>volume_table_upper)-16	; ...while the rest goes under the KERNAL.

	++	sta fill_copy_target+1

		lda #0
		sta bval_cnt					; byte value counter

	next_byte_val
		lda bval_cnt

		; MOD samples are 2's-compliment signed
		; this will translate the value to unsigned.
		clc
		adc #$80

		ldx vol_cnt
		jsr multiply_8x8				; on exit, product MSB is in .A

		lsr								; divide by 32 since that's our max volume
		ror product
		lsr
		ror product
		lsr
		ror product
		lsr
		ror product
		lsr
		ror product

; re-center the amplitude range to keep the middle sample value at $7f/80.

		sec
		lda #32
		sbc vol_cnt
		asl
		asl
		clc
		adc product

; divide the final value down to the resolution the audio driver needs
; only 4 or 8 bits allowed

		ldx volume_tables_resolution
		cpx #4
		bne .nd

		lsr
		lsr
		lsr
		lsr

	.nd	ldy bval_cnt
		sta (fill_copy_target),y
		inc bval_cnt
		bne next_byte_val

		inc vol_cnt
		lda vol_cnt
		cmp #33
		bne next_vol_val
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
	sei
	jsr disable_roms

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

	dex
	lda quotient
	sta steprate_table,x
	inx
	lda quotient+1
	sta steprate_table,x

+	inx
	cpx #120
	bne -

	jsr enable_kernal_only
	cli
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
