; VIBRATO 
;
; The format doc says:
;
; "oscillate the sample pitch using a particular waveform with amplitude
; y/16 semitones, such that (x * ticks)/64 cycles occur in the division"
;
; Where "ticks" is the number of ticks per division (row)
;
; Therefore:
;
; one_semitone					= 1.059463094 ; 2^(1/12)
; one_sixteenth_semitone		= 1.003616666 ; 2^(1/(12*16))
;
; sixteenth_semitone_table[y] = one_sixteenth_semitone ^ (-y)
;
; (negative y in the table exponent because we're working with note periods,
; which are analogous to wavelengths, rather than using frequencies)
;
; amplitude = sixteenth_semitone_table[y] * period
; period step amount = (x * amplitude) / 64
;
; The step value needs to be double that amount when doing a triangle wave,
; so divide by 32 instead in that case.
;
; do one such step per tick
;
; Test cases include "Into the Hypercube" and "Bodveizer".

; expects a track number in .Y


start_effect_vibrato
	; if the fundamental pitch is zero, this must be a new vibrato run, so
	; pick up a new fundamental period, reset the period stepping direction,
	; and calculate a new top point and step size against that.

	lda current_vibrato_fundamental_periods_lows,y
	ora current_vibrato_fundamental_periods_highs,y
	bne +

	lda current_note_periods_lows,y
	sta current_vibrato_fundamental_periods_lows,y
	lda current_note_periods_highs,y
	sta current_vibrato_fundamental_periods_highs,y

	lda #0
	sta current_note_periods_fracts,y

	lda #$80
	sta current_pitch_bend_dirs,y

+	lda seq_commands,y					; if we got here via command #6, then
	cmp #6								; we *must* use the previous
	beq +								; amplitude value

	lda seq_command_arguments,y			; ditto if the amplitude value is 0
	and #$0f							; and this is a normal vibrato
	bne ++

+	lda last_vibrato_amplitudes,y

++	sta last_vibrato_amplitudes,y
	tax
	lda sixteenth_semitones_table_lows,x
	sta multiplicand_a
	lda sixteenth_semitones_table_highs,x
	sta multiplicand_a+1

	lda current_vibrato_fundamental_periods_lows,y
	sta multiplicand_b
	lda current_vibrato_fundamental_periods_highs,y
	sta multiplicand_b+1

	sec
	jsr multiply_16x16
	ldy seq_current_track

	; multiplying the upper three bytes by 2 and then using the highest two
	; bytes is the same as dividing the entire four-byte result by 32768

	asl product+1
	rol product+2
	lda product+3
	rol 

	sta current_vibrato_top_periods_highs,y
	lda product+2
	sta current_vibrato_top_periods_lows,y

	; if the requested amplitude would put the top period at less than 57,
	; cap it.

	cmp #57
	lda current_vibrato_top_periods_highs,y
	sbc #0
	bcs +

	lda #57
	sta current_vibrato_top_periods_lows,y

+	lda seq_commands,y					; if we got here via command #6, then
	cmp #6								; we *must* use the previous rate
	beq +								; value

	ldx seq_command_arguments,y			; ditto if the rate value is 0 and
	lda divide_by_16_table,x			; this is a normal vibrato command.
	bne ++

+	lda last_vibrato_rates,y

++	sta last_vibrato_rates,y
	tax

	; since the "top" of a vibrato is its highest pitch, that will be a
	; shorter period value than its fundamental period, so subtract the top
	; from the fundamental to get the real amplitude.

	sec
	lda current_vibrato_fundamental_periods_lows,y
	sbc current_vibrato_top_periods_lows,y

	; Since the highest amplitude value represents almost one full semitone,
	; and the longest period in the table is 1712, the maximum possible
	; difference would 1712 - 1616 = 96 if the max were exactly one semitone.

	; the upper byte of the subtract will thus always be zero, and since the
	; rate value maxes-out at 15, we can just do an 8x8 multiply now.

	jsr multiply_8x8
	ldy seq_current_track

	; now divide the roughly-11-bit result by 32.  That's the same as
	; multiplying by 2 and then treating the high byte as the integer part
	; of a fixed-point 8.8 value (it's okay that this discards the low two
	; bits of the result, the diff is infinitesimal and inaudible).

	asl product
	lda product+1
	rol
	sta current_vibrato_step_sizes_ints,y

	lda product
	sta current_vibrato_step_sizes_fracts,y
rts

; this routine is very similar to pitch sliding, it just uses a different
; set of variables, and puts the current period fraction value to use

run_effect_vibrato
	lda current_vibrato_fundamental_periods_lows,y
	ora current_vibrato_fundamental_periods_highs,y
	bne +
	rts

+	lda current_pitch_bend_dirs,y
	bpl vibrato_pitching_down

vibrato_pitching_up
	sec
	lda current_note_periods_fracts,y
	sbc current_vibrato_step_sizes_fracts,y
	sta current_note_periods_fracts,y
	lda current_note_periods_lows,y
	sbc current_vibrato_step_sizes_ints,y
	sta current_note_periods_lows,y
	lda current_note_periods_highs,y
	sbc #0
	sta current_note_periods_highs,y

	lda current_note_periods_lows,y
	cmp current_vibrato_top_periods_lows,y
	lda current_note_periods_highs,y
	sbc current_vibrato_top_periods_highs,y
	bcs +

	lda #0
	sta current_pitch_bend_dirs,y

	sta current_note_periods_fracts,y
	lda current_vibrato_top_periods_lows,y
	sta current_note_periods_lows,y
	lda current_vibrato_top_periods_highs,y
	sta current_note_periods_highs,y

+	jmp set_pitch_by_table_lookup

vibrato_pitching_down
	clc
	lda current_note_periods_fracts,y
	adc current_vibrato_step_sizes_fracts,y
	sta current_note_periods_fracts,y
	lda current_note_periods_lows,y
	adc current_vibrato_step_sizes_ints,y
	sta current_note_periods_lows,y
	lda current_note_periods_highs,y
	adc #0
	sta current_note_periods_highs,y

	lda current_note_periods_lows,y
	cmp current_vibrato_fundamental_periods_lows,y
	lda current_note_periods_highs,y
	sbc current_vibrato_fundamental_periods_highs,y
	bcc +

	lda #$80
	sta current_pitch_bend_dirs,y

	lda #0
	sta current_note_periods_fracts,y
	lda current_vibrato_fundamental_periods_lows,y
	sta current_note_periods_lows,y
	lda current_vibrato_fundamental_periods_highs,y
	sta current_note_periods_highs,y

+	jmp set_pitch_by_table_lookup

start_effect_vibrato_plus_volume_slide
	jsr start_effect_vibrato
	jsr start_effect_volume_slide
rts

run_effect_vibrato_plus_volume_slide
	jsr run_effect_vibrato
	jsr run_effect_volume_slide
rts


; if there is a command, and isn't one of the two vibrato variants, but
; the previous command was, this signals the end of a vibrato, so we'll need
; to either reset the current note back to now-ending vibrato's fundamental
; period, or if a new period was given in this row, use that, and then in
; either case zero-out the old fundamental so that the next time either
; command is run, it'll signal a new vibrato.

; enter with .X = current command number and .Y = track number

stop_vibrato_check
	cpx #4
	beq vib_do_nothing
	cpx #6
	beq vib_do_nothing

	lda seq_prev_commands,y

	cmp #4
	beq vib_stop
	cmp #6
	bne vib_do_nothing

vib_stop
	ldx seq_cur_track_data_offset
	lda seq_current_row_data+1,x
	and #$0f
	ora seq_current_row_data+2,x
	bne vib_dont_reset_current_period

	lda current_vibrato_fundamental_periods_lows,y
	sta current_note_periods_lows,y
	lda current_vibrato_fundamental_periods_highs,y
	sta current_note_periods_highs,y

vib_dont_reset_current_period
	lda #0
	sta current_vibrato_fundamental_periods_lows,y
	sta current_vibrato_fundamental_periods_highs,y

	jsr set_pitch_by_table_lookup
	ldy seq_current_track
	ldx seq_commands,y

vib_do_nothing
rts
