; This file is the actual music sequencer
; Originally I was gonna just port the old Modplay 64 v1.2 sequencer since
; it works pretty well, but that code is an absolute mess.

!text "sequencer",0

start_sequencer
	lda #<volume_tables_low
	sta volume_table_vectors
	sta volume_table_vectors+2
	sta volume_table_vectors+4
	sta volume_table_vectors+6
	lda #>volume_tables_low
	sta volume_table_vectors+1
	sta volume_table_vectors+3
	sta volume_table_vectors+5
	sta volume_table_vectors+7

	lda #0
	sta seq_abort_flag
	sta glissando_flag
	sta vibrato_waveform
	sta tremolo_waveform
	sta delay_pattern_divisions
	sta pattern_break_target_row

	ldx #7
-	sta current_sample_volume_levels,x
	sta current_sample_numbers,x

	sta track_current_enable_flags,x

	sta current_pitch_slide_flags,x
	sta pitch_slide_up_rates,x
	sta pitch_slide_down_rates,x
	sta pitch_slide_to_note_rates,x

	sta seq_pitch_slide_stop_point_lows,x
	sta seq_pitch_slide_stop_point_highs,x

	sta fine_tune_values,x
	sta retrigger_rates,x
	sta cut_sample_ticks,x
	sta delay_sample_ticks,x
	sta track_current_loop_flags,x
	sta vibrato_rates,x
	sta tremolo_rates,x
	sta volume_slide_rates,x
	sta current_note_periods_lows,x
	sta current_note_periods_highs,x
	sta current_node_period_offsets,x
	sta current_steprates_fract,x
	sta current_steprates_lows,x
	sta sample_pointers_fract,x
	sta sample_pointers_lows,x
	sta sample_pointers_mids,x
	sta sample_pointers_highs,x
	sta current_sample_end_addr_lows,x
	sta current_sample_end_addr_mids,x
	sta current_sample_end_addr_highs,x

	sta seq_commands,x
	sta seq_prev_commands,x
	sta seq_command_arguments,x
	sta seq_prev_command_arguments,x

	dex
	bpl -

	lda #$80
	ldx #7
-	sta track_current_enable_flags,x
	dex
	bpl -

	; pre-calculate the dividends for the mixer loops per tick and
	; the period-to-steppers divisions

	; for both of these, we divide the ISR interval by 2 to make sure that it
	; can't possibly be > 8 bits, and compensate for that by using constants
	; that are twice as high.  We lose a tiny bit of precision from the ISR
	; timer, but that's okay, it'll be imperceptible.

	; mod speed is [divisions per minute] = (24 * bpm)/[ticks per div]
	;
	; at a default of 125 bpm and 6 tpd, that's 500 div/min or 8.3/sec
	; giving ~50 ticks/sec, or 20454 cycles/tick (NTSC)
	;
	; with an ISR of 195 cycles (i.e. every 3 rasters), that's 20454/195 =
	; 104.895 samples per tick, or ideally ~13.112 runs of the mixer loop

	lda isr_trigger_interval+1
	lsr
	lda isr_trigger_interval
	ror
	ldx tempo_fine_adjust_constant
	jsr multiply_8x8

	lda product
	sta mixer_loops_dividend_precalc
	lda product+1
	sta mixer_loops_dividend_precalc+1

	lda isr_trigger_interval+1
	lsr
	lda isr_trigger_interval
	ror
	ldx pitch_fine_adjust_constant
	jsr multiply_8x8

	lda product
	sta stepper_dividend_precalc
	lda product+1
	sta stepper_dividend_precalc+1

	lda #125
	sta seq_tempo_bpm
	lda #6
	sta seq_ticks_per_division
	jsr set_mixer_loops_per_tick

	lda #0
	sta current_song_pos
	sta seq_current_row
	beq +

next_pattern

	inc current_song_pos
	lda current_song_pos
	cmp number_of_song_positions
	bne +

	jmp stop_song

+	tax
	lda pattern_table,x
	sta seq_current_pattern_number

	stx $c800
	sta $c801

; row format
;
;   byte 0    byte 1    byte 2    byte 3
; 7654-3210 7654-3210 7654-3210 7654-3210
; aaaa pppp pppp pppp bbbb eeee xxxx yyyy
;
;     aaaabbbb (8 bits) is the sample for this channel/division
; pppppppppppp (12 bits) is the sample's period
; eeeexxxxyyyy (12 bits) e is the effect number, x/y are the parameters (or one param)
;
; repeat for as many channels as the mod has

next_row
	lda seq_current_row
	sta $c802

	+JSR_INDIRECT (fetch_row_vec)
	ldy #0

next_track_this_row
	tya
	asl
	asl
	tax

	; get sample number
	lda seq_current_row_data,x
	and #$f0
	sta sequencer_temp_a
	lda seq_current_row_data+2,x
	lsr
	lsr
	lsr
	lsr
	ora sequencer_temp_a			; if sample number is 0, keep using the
	beq +							; previous sample number
	sta current_sample_numbers,y

	; get sample period
+	lda seq_current_row_data,x		; if period is 0, keep using the
	and #$0f						; previous period value
	ora seq_current_row_data+1
	bne +
	jmp getcmd

+	lda seq_current_row_data,x
	and #$0f
	sta current_note_periods_highs,y
	tax
	lda seq_current_row_data+1,x
	sta current_note_periods_lows,y

	stx sequencer_temp_x
	sty sequencer_temp_y

	jsr get_stepper_value

	ldy sequencer_temp_y
	sta current_steprates_fract,y
	sta sequencer_temp_b
	stx current_steprates_lows,y
	stx sequencer_temp_b+1

	tya
	asl
	asl
	asl
	tax ; .X = track number times 8

	!for .idx, 1, 7 {
		lda sequencer_temp_b
		adc current_steprates_fract,y
		sta sequencer_temp_b
		lda sequencer_temp_b+1
		adc current_steprates_lows,y
		lda sequencer_temp_b+1
		sta sample_data_lookahead_indexes + .idx,x
	}

	; get effect command and its parameters
getcmd
	ldx sequencer_temp_x
	lda seq_commands,y
	sta seq_prev_commands,y
	lda seq_command_arguments,y
	lda seq_prev_command_arguments,y

	lda seq_current_row_data+3,x
	sta seq_command_arguments,y
	lda seq_current_row_data+2,x
	lsr
	lsr
	lsr
	tax
	lsr
	sta seq_commands,y

	; initialize/start the appropriate effect for this track

	lda seq_command_arguments,y		; if both the command and its args are 0
	ora seq_commands,y				; then there's no command
	beq +							; (command #0 + nonzero args = arpeggio)

	lda start_effect_command_jump_table,x
	sta .sc+1
	lda start_effect_command_jump_table+1,x
	sta .sc+2

.sc jsr $1234

+	iny
	cpy #4
	beq +
	jmp next_track_this_row

+	lda seq_ticks_per_division
	sta seq_ticks_counter

next_tick

	; check for spacebar
	lda #$7f		; column 7 low
	sta CIA1

	lda #$ef		; look for row 4
	cmp CIA1+$01
	bne +
	jmp stop_song

+	lda seq_ticks_counter
	sta $c803
	ldy #0
	sty seq_current_track

next_track_this_tick
	ldy seq_current_track
	lda seq_commands,y
	asl
	tax
	lda run_effect_command_jump_table,x
	sta .rc+1
	lda run_effect_command_jump_table+1,x
	sta .rc+2

.rc jsr $1234

	inc seq_current_track
	lda seq_current_track
	cmp #4
	bne next_track_this_tick

	; By adding the loops per tick with a fract byte, rather than just
	; resetting the count to zero, the mixer will occasionally add one extra
	; loop, for precise speed control.

	clc
	lda mixer_output_countdown_fract
	adc mixer_loops_per_tick_fract
	sta mixer_output_countdown_fract
	lda #0
	adc mixer_loops_per_tick
	sta mixer_output_countdown

	+JSR_INDIRECT (run_mixer_vec)

	dec seq_ticks_counter
	lda seq_ticks_counter
	cmp #$ff
	bne next_tick

	inc seq_current_row
	lda seq_current_row
	cmp #64
	beq +
	jmp next_row

+	lda #0
	sta seq_current_row
	jmp next_pattern

stop_song
rts

; effect command decoders -- start-of-row/init routines
; enter each one with .Y = track number

run_effect_set_speed
	sec
	lda seq_command_arguments,y
	cmp #32
	bcc +
	sta seq_tempo_bpm
	bcs ++

+	sta seq_ticks_per_division
++	jsr set_mixer_loops_per_tick

rts

;==================
; auxillary routines


; convert the current "bpm" setting into a mixer loops per tick value
; and set the speed that value.  Note we're setting the values to 256x the
; actual amounts, so that quotient low byte can act as a fraction.

set_mixer_loops_per_tick
	lda #0
	sta dividend
	sta divisor+1
	sta divisor+2

	lda mixer_loops_dividend_precalc
	sta dividend+1
	lda mixer_loops_dividend_precalc+1
	sta dividend+2
	lda seq_tempo_bpm
	sta divisor

	jsr divide_24by24

	lda #0
	ldx mixer_count_shifts
-	lsr
	ror quotient+1
	ror quotient+2
	dex
	bne -

	lda quotient
	sta mixer_loops_per_tick_fract
	lda quotient+1
	sta mixer_loops_per_tick
rts

; convert a note period into a sample stepper value
;
; enter with .A/.X set to the desired note period
; returns the stepper value in .A/.X (.A will be the fraction)

get_stepper_value
	sta divisor
	stx divisor+1
	lda stepper_dividend_precalc
	sta dividend
	lda stepper_dividend_precalc+1
	sta dividend+1
	jsr divide_16by16

	lda quotient

	ldx mixer_count_shifts
-	lsr quotient+1
	ror
	dex
	bne -

	ldx quotient+1
rts

get_row_address
rts

unused
rts

start_effect_command_jump_table
	!word unused ; start_effect_arpeggio
	!word unused ; start_effect_pitch_slide_up
	!word unused ; start_effect_pitch_slide_down
	!word unused ; start_effect_pitch_slide_to_note
	!word unused ; start_effect_vibrato
	!word unused ; start_effect_pitch_slide_plus_volume_slide
	!word unused ; start_effect_vibrato_plus_volume_slide
	!word unused
	!word unused
	!word unused ; run_effect_set_sample_offset
	!word unused ; start_effect_volume_slide
	!word unused ; run_effect_position_jump
	!word unused ; run_effect_set_volume
	!word unused ; run_effect_pattern_break
	!word unused
	!word unused ; run_effect_set_speed

run_effect_command_jump_table
	!word unused ; run_effect_arpeggio
	!word unused ; run_effect_pitch_slide_up
	!word unused ; run_effect_pitch_slide_down
	!word unused ; run_effect_pitch_slide_to_note
	!word unused ; run_effect_vibrato
	!word unused ; run_effect_pitch_slide_plus_volume_slide
	!word unused ; run_effect_vibrato_plus_volume_slide
	!word unused
	!word unused
	!word unused
	!word unused ; run_effect_volume_slide
	!word unused
	!word unused
	!word unused
	!word unused
	!word unused

sequencer_temp_a			!fill 4,0
sequencer_temp_b			!fill 4,0
sequencer_temp_c			!fill 4,0
sequencer_temp_d			!fill 4,0
sequencer_temp_x			!byte 0
sequencer_temp_y			!byte 0

seq_abort_flag				!byte 0
seq_debug_mode				!byte $80
