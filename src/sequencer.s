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

	lda #125
	sta seq_tempo_bpm
	lda #6
	sta seq_tempo_ticks_per_div
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

+	+JSR_INDIRECT (fetch_row_vec)
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
	ora sequencer_temp_a
	beq +
	sta current_sample_numbers,y

	; get sample period
+	lda seq_current_row_data,x
	and #$0f
	sta sequencer_temp_a
	ora seq_current_row_data+1,x
	beq +

	lda sequencer_temp_a
	sta current_note_periods_highs,y
	lda seq_current_row_data+1,x
	sta current_note_periods_highs,y

	; get effect command and its parameters
+	lda seq_commands,y
	sta seq_prev_commands,y
	lda seq_command_arguments,y
	lda seq_prev_command_arguments,y

	lda seq_current_row_data+3,x
	sta seq_command_arguments,y
	lda seq_current_row_data+2,x
	lsr
	lsr
	lsr
	lsr
	sta seq_commands,y

	; initialize/start the appropriate effect for this track
	asl
	tax
	lda start_effect_command_jump_table,x
	sta .sc+1
	lda start_effect_command_jump_table+1,x
	sta .sc+2




jam ; #### done for the night, jump table seems correct now, need to fix the
	; 		mixer loop countdown calc


.sc jsr $1234

	iny
	cpy #4
	bne next_track_this_row

	clc								; by adding like this, we allow the mixer
	lda mixer_loops_per_tick_fract	; count to vary slightly so that a tick
	adc seq_ticks_counter_fract		; will get one more loop than normal every
	sta seq_ticks_counter_fract		; so often, for precise speed control
	lda mixer_loops_per_tick
	adc #0
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

+	sta seq_tempo_ticks_per_div
++	jsr set_mixer_loops_per_tick

rts

;==================
; auxillary routines


; this routine converts the current "bpm" setting into a mixer loops per tick
; value

; mod speed is [divisions per minute] = (24 * bpm)/[ticks per div]
;
; at a default of 125 bpm and 6 tpd, that's 500 div/min or 8.3/sec
; and ~50 ticks/sec or 20454 cycles/tick (NTSC)
;
; with an ISR of 195 cycles (i.e. every 3 rasters), that's 20454/195 = 104.895
; samples per tick, or ~13.112 runs of the mixer loop
;
; a scaler of 68.5 would give (24*68.5)/125 = 13.152 == 13 & 39/256 runs of
; the loop

tempo_fine_adjust_constant = 137

set_mixer_loops_per_tick
	lda isr_trigger_interval+1		; we divide the ISR interval by 2 to make
	lsr								; sure that it can't possibly be > 8 bits,
	lda isr_trigger_interval		; and compensate for that by using a fine
	ror								; adjust constant that's twice as high.  We
	ldx #tempo_fine_adjust_constant	; lose a tiny bit of precision from the
	jsr multiply_8x8				; ISR timer, but gain it back in the mixer
									; loop counter.
	lda product
	sta dividend
	lda product+1
	sta dividend+1
	lda seq_tempo_bpm
	sta divisor
	lda #0
	sta divisor+1
	jsr divide_16by16

	lda quotient
	sta mixer_loops_per_tick_fract
	sta seq_ticks_counter_fract
	lda quotient+1
	sta mixer_loops_per_tick
	sta seq_ticks_counter

rts

; this routine converts a note period into a sample stepper value: audio
; driver timer multiplied by a constant, and then divided by the note period.
; enter with .A/.X set to the desired note period
; returns the stepper value in .A/.X

pitch_fine_adjust_constant = 80

calculate_stepper_value
	sta tempzp_d
	stx tempzp_d+1
	lda isr_trigger_interval+1	; as before, divide the ISR interval by 2 to
	lsr							; make sure that it can't be > 8 bits, then
	lda isr_trigger_interval	; compensate by doubling the constant.
	ror
	ldx #pitch_fine_adjust_constant
	jsr multiply_8x8

	lda product
	sta dividend
	lda product+1
	sta dividend+1
	lda tempzp_d
	sta divisor
	lda tempzp_d+1
	sta divisor+1
	jsr divide_16by16
	lda quotient
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
