; PITCH SLIDING

start_effect_pitch_slide
	lda seq_command_arguments,y
	sta current_pitch_slide_rates,y
rts

; slide up

run_effect_pitch_slide_up
	lda current_pitch_slide_rates,y
	bne +
	rts

+	sec
	lda current_note_periods_lows,y
	sbc current_pitch_slide_rates,y
	sta current_note_periods_lows,y
	lda current_note_periods_highs,y
	sbc #0
	sta current_note_periods_highs,y
	bcc stop_slide_up

	lda current_note_periods_lows,y
	cmp #57
	lda current_note_periods_highs,y
	sbc #0
	bcs +

stop_slide_up
	lda #57
	sta current_note_periods_lows,y
	lda #0
	sta current_note_periods_highs,y
	sta current_pitch_slide_rates,y

+	jmp set_pitch

; slide down

run_effect_pitch_slide_down
	lda current_pitch_slide_rates,y
	bne +
	rts

+	clc
	lda current_note_periods_lows,y
	adc current_pitch_slide_rates,y
	sta current_note_periods_lows,y
	lda current_note_periods_highs,y
	adc #0
	sta current_note_periods_highs,y
	bcs stop_slide_down

	lda current_note_periods_lows,y
	cmp #<1712
	lda current_note_periods_highs,y
	sbc #>1712
	bcc +

stop_slide_down
	lda #<1712
	sta current_note_periods_lows,y
	lda #>1712
	sta current_note_periods_highs,y
	lda #0
	sta current_pitch_slide_rates,y

+	jmp set_pitch

; slide/portamento to note

start_effect_pitch_slide_to_note
	lda seq_command_arguments,y
	sta current_pitch_slide_rates,y

	lda current_note_periods_lows,y
	cmp seq_pitch_slide_target_period_lows,y
	lda current_note_periods_highs,y
	sbc seq_pitch_slide_target_period_highs,y
	bcs +
	lda #0
	sta current_slide_to_note_dir,y
	rts

+	lda #$80
	sta current_slide_to_note_dir,y
rts

run_effect_pitch_slide_to_note
	lda current_pitch_slide_rates,y
	bne +
	rts

+	lda current_slide_to_note_dir,y
	bpl slide_to_lower_note

	sec
	lda current_note_periods_lows,y
	sbc current_pitch_slide_rates,y
	sta current_note_periods_lows,y
	lda current_note_periods_highs,y
	sbc #0
	sta current_note_periods_highs,y

	lda current_note_periods_lows,y
	cmp seq_pitch_slide_target_period_lows,y
	lda current_note_periods_highs,y
	sbc seq_pitch_slide_target_period_highs,y
	bcc stop_porta

	jmp set_pitch

slide_to_lower_note
	clc
	lda current_note_periods_lows,y
	adc current_pitch_slide_rates,y
	sta current_note_periods_lows,y
	lda current_note_periods_highs,y
	adc #0
	sta current_note_periods_highs,y

	lda seq_pitch_slide_target_period_lows,y
	cmp current_note_periods_lows,y
	lda seq_pitch_slide_target_period_highs,y
	sbc current_note_periods_highs,y
	bcs +

stop_porta
	lda seq_pitch_slide_target_period_lows,y
	sta current_note_periods_lows,y
	lda seq_pitch_slide_target_period_highs,y
	sta current_note_periods_highs,y
	lda #0
	sta current_pitch_slide_rates,y

+	jmp set_pitch

; continue pitch slide and add volume slide

start_effect_pitch_slide_plus_volume_slide
	jsr start_effect_pitch_slide_to_note
	jsr start_effect_volume_slide
rts

run_effect_pitch_slide_plus_volume_slide
	jsr run_effect_pitch_slide_to_note
	jsr run_effect_volume_slide
rts
