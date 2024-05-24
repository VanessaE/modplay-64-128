; this file will hold the outline of the actual player

start_main_player
; ---------------
	php
	sei

	!ifdef c128 {
		jsr gray_out_blur_out
		jsr switch_to_secondary_screen

		clc
		jsr draw_medium_popup
		lda #0
		ldx #<music_player_msg
		ldy #>music_player_msg
		jsr print_msg

		clc
		jsr draw_mini_popup
		lda #0
		ldx #<between_songs_msg
		ldy #>between_songs_msg
		jsr print_msg_rle
	} else {
		bit enable_screen_on_playback
		bmi +
		jsr disable_screen

		clc
		jsr draw_mini_popup
		lda #0
		ldx #<between_songs_msg
		ldy #>between_songs_msg
		jsr print_msg_rle
		jmp ++

	+	jsr gray_out_blur_out
		jsr switch_to_secondary_screen

		sec
		jsr draw_medium_popup
		lda #0
		ldx #<music_player_msg_ascii
		ldy #>music_player_msg_ascii
		jsr print_msg_ascii

		sec
		jsr draw_mini_popup
		lda #0
		ldx #<between_songs_msg_ascii
		ldy #>between_songs_msg_ascii
		jsr print_msg_ascii
	}

	; ask audio driver for its ISR timing and volume table output resolution

++	+JSR_INDIRECT (audio_timing_res_vec)
	stx .isr_interval+1
	jsr generate_volume_tables ; will only regenerate if needed

	jsr disable_roms
	jsr backup_zero_page

	ldy #0
	lda #$80
-	sta audio_buffer_left,y
	sta audio_buffer_right,y
	iny
	bne -

.isr_interval
	ldx #0
	jsr isr_startup

;	jsr start_sequencer

	; check for spacebar
	lda #$7f		; column 7 low
	sta CIA1

	lda #$ef		; look for row 4
-	cmp CIA1+$01
	bne -

	jsr isr_shutdown
	jsr restore_zero_page
	jsr enable_kernal_only
	plp

	!ifndef c128 {
		bit enable_screen_on_playback
		bmi +
		jsr switch_to_primary_screen
		jsr enable_screen
		rts
	}

+	jsr clear_primary_screen_early
	jsr switch_to_primary_screen
rts

single_sample_player
	php
	sei
	jsr gray_out_blur_out
	jsr switch_to_secondary_screen

	!ifdef c128 {
		clc
	} else {
		sec
	}

	jsr draw_medium_popup

	!ifndef c128 {
		lda #0
		ldx #<sample_player_msg_ascii
		ldy #>sample_player_msg_ascii
		jsr print_msg_ascii
		jsr press_any_key_ascii
	} else {
		lda #0
		ldx #<sample_player_msg
		ldy #>sample_player_msg
		jsr print_msg
		jsr press_any_key
	}

	jsr clear_primary_screen_early
	jsr switch_to_primary_screen
	plp
rts

; generate volume scaler tables... enter with .A = desired output resolution

generate_volume_tables
	cmp volume_tables_resolution
	bne +
	rts

+	sta volume_tables_resolution
	lda #<volume_tables_low
	sta tempzp_d
	lda #>volume_tables_low
	sta tempzp_d+1
	lda #0
	sta bval_cnt			; byte value counter
	sta vol_cnt				; volume counter

	--	ldx vol_cnt
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
; only 4 or 8 bits allowed

		ldx volume_tables_resolution
		cpx #4
		bne .nd

		lsr
		lsr
		lsr
		lsr

	.nd	sta (tempzp_d),y
		inc bval_cnt
		bne --
		inc tempzp_d+1
		inc vol_cnt
		lda vol_cnt
		cmp #34		; the first 33 pages can fit below the screens at $c800...
		bne +
		lda #>volume_tables_high	; ...while the rest goes under the KERNAL.
		sta tempzp_d+1
		bne -
	+	cmp #65
		bne -
rts
