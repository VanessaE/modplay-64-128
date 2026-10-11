; This file is the actual music sequencer
; Originally I was gonna just port the old Modplay 64 v1.2 sequencer since
; it works pretty well, but that code is an absolute mess.

start_sequencer
	lda #0
	sta seq_abort_flag
	sta glissando_flag
	sta vibrato_waveform
	sta tremolo_waveform
	sta delay_pattern_divisions
	sta pattern_break_target_row
	sta seq_key_debounce

	ldx #7
-	sta current_sample_numbers,x
	sta enqueued_sample_numbers,x

	sta current_pitch_slide_target_lows,x
	sta current_pitch_slide_target_highs,x

	sta current_retrigger_rates,x
	sta current_cut_sample_ticks,x
	sta current_delay_sample_ticks,x
	sta current_track_loop_flags,x
	sta current_track_gate_flags,x

	sta current_vibrato_step_sizes_ints,x
	sta current_vibrato_step_sizes_fracts,x
	sta current_vibrato_fundamental_periods_lows,x
	sta current_vibrato_fundamental_periods_highs,x
	sta last_vibrato_rates,x
	sta last_vibrato_amplitudes,x

	sta current_tremolo_step_sizes,x
	sta current_volume_slide_rates,x
	sta seq_commands,x
	sta seq_prev_commands,x
	sta seq_command_arguments,x

	sta current_note_periods_fracts,x
	sta current_note_periods_lows,x
	sta current_note_periods_highs,x

	sta current_fine_tune_values,x

	sta current_steprates_fracts,x
	sta current_steprates_ints,x

	sta current_sample_pointers_fracts,x
	sta current_sample_pointers_lows,x
	sta current_sample_pointers_mids,x
	sta current_sample_pointers_highs,x

	sta current_sample_end_addr_lows,x
	sta current_sample_end_addr_highs,x

	sta current_fetch_loop_ofl_amounts,x

	dex
	bpl -

	ldx #7
	lda #1
-	sta current_sample_end_addr_mids,x
	dex
	bpl -

	lda #2
	sta do_viz_plot

	lda #$ff
	sta pos_jump_target_pattern

; caution:  do not init more than 4 tracks in the selfmod and volume loops
; below until the fetch and mixer loops have been expanded to handle it, will
; cause mem corruption.

	lda #3 ; see above
	sta seq_current_track
-	+JSR_INDIRECT (do_selfmod_pitch_vec)
	+JSR_INDIRECT (do_selfmod_instrument_vec)
	dec seq_current_track
	bpl -

	; enable flags need to be set before the volume loop is run, otherwise
	; the set-volume call will just exit out without doing anything

	lda #$80
	ldx #7
-	sta track_current_enable_flags,x
	dex
	bpl -

	ldy #3 ; see above
-	lda #64
	jsr set_volume
	dey
	bpl -

	; and then disable them again

	lda #0
	ldx #7
-	sta track_current_enable_flags,x
	dex
	bpl -

	lda #125
	sta seq_tempo_bpm
	lda #6
	sta seq_ticks_per_division
	jsr set_mixer_loops_per_tick

	lda #0
	sta mixer_countdown_fract
	sta current_song_pos
	sta seq_current_row
	sta current_active_tracks_count

	lda CIA1_CRB	; ensure that the next few STA's reset the TOD clock
	and #$7f
	sta CIA1_CRB

	lda #0
	sta CIA1_TOD_HOURS
	sta CIA1_TOD_MINUTES
	sta CIA1_TOD_SECONDS
	sta CIA1_TOD_TENTHS

	ldx number_of_song_positions
	dex

	!ifndef use_profiler {
		jsr print_num_song_pos
	}

	lda #0
	beq nple

next_pattern
	lda pos_jump_target_pattern
	cmp #$ff
	beq +
	sta current_song_pos
	lda #$ff
	sta pos_jump_target_pattern
	bne ++

+	inc current_song_pos
++	lda current_song_pos
	cmp number_of_song_positions
	bne nple
	jmp stop_song

nple
	tax
	lda pattern_table,x
	sta seq_current_pattern_number
	tay

	!ifndef use_profiler {
		jsr print_song_pos_pat_num
	}

	lda visualizer_mode
	bne next_row_no_scroll

	lda pattern_break_target_row
	bne apply_pat_break

	jsr viz_row_data_pattern_preload
	jmp next_row_no_scroll

; row format (after processing by the loader)
;
;  byte 0    byte 1   byte 2   byte 3
; 76543210 7654-3210 76543210 76543210
; wwwwyyyy cccc xxxx-xxxxxxxx zzzzzzzz
;
; where:
;       wwwwyyyy (8 bits) is the sample number
;  xxxx-xxxxxxxx (12 bits) is the note period
;           cccc (4 bits) is the effect number
;       zzzzzzzz (8 bits) is the effect parameter(s)


next_row
	lda visualizer_mode
	bne next_row_no_scroll
	jsr viz_row_data_scroll

next_row_no_scroll
	ldx current_song_pos
	ldy pattern_table,x

	lda pattern_break_target_row
	beq ++

apply_pat_break
	and #$7f
	sta seq_current_row

	lda visualizer_mode
	bne +
	jsr viz_row_data_pattern_preload

+	lda #0
	sta pattern_break_target_row

++	lda visualizer_mode
	bne seq_fetch_row_data

	ldx seq_current_row
	cpx #61
	bcs seq_fetch_row_data

	lda #<visualizer_line_6
	sta utility_pointer
	lda #>visualizer_line_6
	sta utility_pointer+1

	inx
	inx
	inx
	jsr viz_row_data_fetch_and_print

seq_fetch_row_data
	ldx seq_current_row
	jsr fetch_row_data

	jsr print_row_num

+	ldy #0
	sty seq_current_track

next_track_this_row
	tya
	asl
	asl					; .X = track number x 4
	tax
	stx seq_cur_track_data_offset

; split each row, each track's four data bytes into their different components

get_command								; ...and its parameters.
	lda seq_commands,y
	sta seq_prev_commands,y

	lda seq_current_row_data+3,x
	sta seq_command_arguments,y
	lda seq_current_row_data+1,x
	lsr
	lsr
	lsr
	lsr
	sta seq_commands,y

get_sample_number_and_period
	ldx seq_cur_track_data_offset
	lda seq_current_row_data,x			; if sample number is 0, keep using
	beq +								; the previous sample number

	sta enqueued_sample_numbers,y
    
+	lda seq_commands,y					; if slide-to-note is in effect, just
	cmp #3								; ignore the given period and don't
	beq slide_or_no_period_set_vol		; re-start the sample
	cmp #5								; ditto for pitch slide + volume slide
	beq slide_or_no_period_set_vol

	lda seq_current_row_data+1,x		; in any other case, if period is 0
	and #$0f							; don't restart the sample
	ora seq_current_row_data+2,x
	beq slide_or_no_period_set_vol

	lda enqueued_sample_numbers,y		; new sample number? gate it...
	jsr start_sample

	ldx current_sample_numbers,y
	lda sample_default_volume_levels,x
	jsr set_volume

	ldx seq_cur_track_data_offset

	lda current_fine_tune_values,y
	bne +

	lda seq_current_row_data+1,x		; ...and apply the note period...
	and #$0f
	sta current_note_periods_highs,y
	lda seq_current_row_data+2,x
	sta current_note_periods_lows,y
	jmp ++

+	jsr calculate_fine_tuning			; ...with fine-tuning, if necessary.

	lda product+2
	sta current_note_periods_lows,y
	lda product+3
	sta current_note_periods_highs,y

++	jsr set_pitch_by_table_lookup
	ldx seq_cur_track_data_offset
	ldy seq_current_track
	jmp run_command

slide_or_no_period_set_vol
	ldx seq_cur_track_data_offset
	lda seq_current_row_data,x
	beq run_command

	ldx current_sample_numbers,y
	beq run_command
	lda sample_default_volume_levels,x
	jsr set_volume

run_command

	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bpl dont_print_track_count
	}

	jsr print_track_count
	ldy seq_current_track

dont_print_track_count
	ldx seq_commands,y

	jsr stop_vibrato_check ; (.X and .Y are preserved)

	; if the current command is invalid, there's nothing to do. 😛

	cpx #16
	bcs no_command_this_row_this_track

	; if the command and its param is all 0's, there's nothing else to do.

	lda start_effect_command_jump_table_highs,x
	beq no_command_this_row_this_track
	sta start_command_vec+2
	lda start_effect_command_jump_table_lows,x
	sta start_command_vec+1

	!ifdef use_profiler {
		+SEQ_PROFILER_A
	}

start_command_vec					; start or initialize an effect command
	jsr $1234						; (also for stuff that just runs once)
	ldy seq_current_track

	!ifdef use_profiler {
		+SEQ_PROFILER_B 1
	}

no_command_this_row_this_track
	iny
	sty seq_current_track
	cpy #4
	beq +
	jmp next_track_this_row

+	lda seq_ticks_per_division
	sta seq_ticks_counter

next_tick
	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bpl .next_tick_no_ui
	}

	lda CIA1_TOD_SECONDS
	cmp last_seconds
	beq .next_tick_no_ui
	sta last_seconds
	jsr print_elapsed_time

.next_tick_no_ui
	jsr seq_check_keyboard
	beq +
	jmp stop_song

+	ldy #0
	sty seq_current_track

next_track_pre_tick
	ldy seq_current_track
	lda current_track_gate_flags,y
	bpl dont_run_pre_tick_command

	ldx seq_commands,y					; commands 0-3, 5, and A/10 need to 
	cpx #10								; run after the fetch/mixer routine,
	beq dont_run_pre_tick_command		; not before.
	cpx #5
	beq dont_run_pre_tick_command
	cpx #4
	bcc dont_run_pre_tick_command
	cpx #16
	bcs dont_run_pre_tick_command

	; run pre tick command
	lda run_effect_command_jump_table_highs,x
	beq dont_run_pre_tick_command

	sta run_command_pre_tick_vec+2
	lda run_effect_command_jump_table_lows,x
	sta run_command_pre_tick_vec+1

	!ifdef use_profiler {
		+SEQ_PROFILER_A
	}

run_command_pre_tick_vec			; run effect command if it needs tick-interval timing
	jsr $1234

	!ifdef use_profiler {
		+SEQ_PROFILER_B 3
	}

dont_run_pre_tick_command
	inc seq_current_track
	lda seq_current_track
	cmp #4
	bne next_track_pre_tick

; -----------------------------------------------------
; run the sample data fetch and mix routines... duh. 😉

	; resetting the countdown this way allows the mixer to run one extra loop
	; every so often, for more accurate timing control (even if the ISR were
	; run every 4 rasters, that's only 4 thousandths of a second variance per
	; song tick).

reset_mixer_loop_count
	clc
	lda mixer_countdown_fract
	adc mixer_loops_per_tick_fract
	sta mixer_countdown_fract
	lda mixer_loops_per_tick
	adc #0
	sta mixer_countdown

	run_fetch_and_mixer_vec
		jsr $1234

	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bpl no_wave_plot
	}

	lda visualizer_mode
	beq no_wave_plot

	!ifdef c64u {
		; no counter -- run it every tick
	} else ifdef c128 {
		dec do_viz_plot
		lda do_viz_plot
		bne no_wave_plot
		lda #2
		sta do_viz_plot
	} else {
		lda do_viz_plot
		eor #$80
		sta do_viz_plot
		bpl no_wave_plot
	}

	jsr viz_waveform_plot

no_wave_plot
	ldy #0
	sty seq_current_track

next_track_post_tick
	ldy seq_current_track

	lda current_track_gate_flags,y
	bpl dont_run_post_tick_command

	ldx seq_commands,y					; commands 0-3, 5, and A/10 need to
	cpx #10								; be run here.
	beq run_post_tick_command
	cpx #5
	beq run_post_tick_command
	cpx #4
	bcc run_post_tick_command
	jmp dont_run_post_tick_command

run_post_tick_command
	lda seq_ticks_counter				; post-tick commands only run N-1 times
	cmp #1								; per row/division
	beq dont_run_post_tick_command

	lda run_effect_command_jump_table_highs,x
	beq dont_run_post_tick_command
	sta run_command_post_tick_vec+2

	lda run_effect_command_jump_table_lows,x
	sta run_command_post_tick_vec+1

	!ifdef use_profiler {
		+SEQ_PROFILER_A
	}

run_command_post_tick_vec
	jsr $1234

	!ifdef use_profiler {
		+SEQ_PROFILER_B 5
	}

dont_run_post_tick_command
	inc seq_current_track
	lda seq_current_track
	cmp #4
	bne next_track_post_tick

	dec seq_ticks_counter
	beq +
	jmp next_tick

+	lda pattern_break_target_row
	beq +
	jmp next_pattern

+	lda pos_jump_target_pattern
	cmp #$ff
	beq +
	lda #0
	sta seq_current_row
	jmp next_pattern

+	inc seq_current_row
	lda seq_current_row
	cmp #64
	beq +
	jmp next_row

+	lda #0
	sta seq_current_row
	jmp next_pattern

stop_song
rts

; #############################
; EFFECT COMMAND ADDRESS TABLES
;
; enter each command with .Y = track number
; The actual commands are in fxcmd-*.s, linked into modplay.s

start_effect_command_jump_table_lows
	!byte <start_effect_arpeggio
	!byte <start_effect_pitch_slide ; up
	!byte <start_effect_pitch_slide ; down
	!byte <start_effect_pitch_slide ; portamento to note
	!byte <start_effect_vibrato
	!byte <start_effect_pitch_slide_plus_volume_slide
	!byte <start_effect_vibrato_plus_volume_slide
	!byte 0
	!byte 0
	!byte <run_effect_set_sample_offset
	!byte <start_effect_volume_slide
	!byte <run_effect_position_jump
	!byte <run_effect_set_volume
	!byte <run_effect_pattern_break
	!byte <start_extended_effect
	!byte <run_effect_set_speed

start_effect_command_jump_table_highs
	!byte >start_effect_arpeggio
	!byte >start_effect_pitch_slide ; up
	!byte >start_effect_pitch_slide ; down
	!byte >start_effect_pitch_slide ; portamento to note
	!byte >start_effect_vibrato
	!byte >start_effect_pitch_slide_plus_volume_slide
	!byte >start_effect_vibrato_plus_volume_slide
	!byte 0
	!byte 0
	!byte >run_effect_set_sample_offset
	!byte >start_effect_volume_slide
	!byte >run_effect_position_jump
	!byte >run_effect_set_volume
	!byte >run_effect_pattern_break
	!byte >start_extended_effect
	!byte >run_effect_set_speed

run_effect_command_jump_table_lows
	!byte <run_effect_arpeggio
	!byte <run_effect_pitch_slide
	!byte <run_effect_pitch_slide
	!byte <run_effect_pitch_slide
	!byte <run_effect_vibrato
	!byte <run_effect_pitch_slide_plus_volume_slide
	!byte <run_effect_vibrato_plus_volume_slide
	!byte 0
	!byte 0
	!byte 0
	!byte <run_effect_volume_slide
	!byte 0
	!byte 0
	!byte 0
	!byte <run_extended_effect
	!byte 0

run_effect_command_jump_table_highs
	!byte >run_effect_arpeggio
	!byte >run_effect_pitch_slide
	!byte >run_effect_pitch_slide
	!byte >run_effect_pitch_slide
	!byte >run_effect_vibrato
	!byte >run_effect_pitch_slide_plus_volume_slide
	!byte >run_effect_vibrato_plus_volume_slide
	!byte 0
	!byte 0
	!byte 0
	!byte >run_effect_volume_slide
	!byte 0
	!byte 0
	!byte 0
	!byte >run_extended_effect
	!byte 0
