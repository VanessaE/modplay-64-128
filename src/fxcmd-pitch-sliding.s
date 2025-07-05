; PITCH SLIDING

start_effect_pitch_slide
	lda seq_command_arguments,y
	sta current_pitch_slide_rates,y

	lda seq_commands,y
	cmp #1 ; is it a slide up?
	beq set_slide_up
	cmp #2 ; or a slide down?
	beq set_slide_down
	cmp #3 ; is it a slide-to-note?
	beq set_slide_to_note
	cmp #5 ; then maybe it's slide-to-note plus volume slide?
	beq set_slide_to_note

	lda #0 ; if we get here and it's none of those, bail out
	sta current_pitch_slide_rates,y
	rts

set_slide_up ; that is, decreasing the note period
	lda #$80
	sta current_pitch_slide_dirs,y
	lda #57
	sta seq_pitch_slide_target_period_lows,y
	lda #0
	sta seq_pitch_slide_target_period_highs,y
	rts

set_slide_down ; increase the note period
	lda #0
	sta current_pitch_slide_dirs,y
	lda #<1712
	sta seq_pitch_slide_target_period_lows,y
	lda #>1712
	sta seq_pitch_slide_target_period_highs,y
	rts

set_slide_to_note
	tya
	asl
	asl
	tax
	lda seq_current_row_data+1,x
	and #$0f
	sta seq_pitch_slide_target_period_highs,y
	lda seq_current_row_data+2,x
	sta seq_pitch_slide_target_period_lows,y

	lda current_note_periods_lows,y
	cmp seq_pitch_slide_target_period_lows,y
	lda current_note_periods_highs,y
	sbc seq_pitch_slide_target_period_highs,y
	lda #0
	ror
	sta current_pitch_slide_dirs,y
rts

run_effect_pitch_slide
	lda current_pitch_slide_rates,y
	bne +
	rts

+	lda current_pitch_slide_dirs,y
	bpl slide_pitch_down ; to higher period value

	; slide pitch up, to lower period value
	sec
	lda current_note_periods_lows,y
	sbc current_pitch_slide_rates,y
	sta current_note_periods_lows,y
	lda current_note_periods_highs,y
	sbc #0
	bcc stop_pitch_slide				; a really fast slide-up from a high
	sta current_note_periods_highs,y	; pitch could underflow the period
										; st 0, breaking the limit check below

	lda seq_pitch_slide_target_period_lows,y
	cmp current_note_periods_lows,y
	lda seq_pitch_slide_target_period_highs,y
	sbc current_note_periods_highs,y
	bcs stop_pitch_slide
	jmp set_pitch

slide_pitch_down
	clc
	lda current_note_periods_lows,y
	adc current_pitch_slide_rates,y
	sta current_note_periods_lows,y
	lda current_note_periods_highs,y
	adc #0
	sta current_note_periods_highs,y

	lda current_note_periods_lows,y
	cmp seq_pitch_slide_target_period_lows,y
	lda current_note_periods_highs,y
	sbc seq_pitch_slide_target_period_highs,y
	bcs stop_pitch_slide
	jmp set_pitch

stop_pitch_slide
	lda seq_pitch_slide_target_period_lows,y
	sta current_note_periods_lows,y
	lda seq_pitch_slide_target_period_highs,y
	sta current_note_periods_highs,y
	lda #0
	sta current_pitch_slide_rates,y
	jmp set_pitch

; continue pitch slide and add volume slide

start_effect_pitch_slide_plus_volume_slide
	jsr start_effect_pitch_slide
	jsr start_effect_volume_slide
rts

run_effect_pitch_slide_plus_volume_slide
	jsr run_effect_pitch_slide
	jsr run_effect_volume_slide
rts
