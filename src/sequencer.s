; This file is the actual music sequencer
; Originally I was gonna just port the old Modplay 64 v1.2 sequencer since
; it works pretty well, but that code is an absolute mess.

!text "sequencer",0

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

	sta seq_pitch_slide_target_period_lows,x
	sta seq_pitch_slide_target_period_highs,x

	sta fine_tune_values,x
	sta retrigger_rates,x
	sta cut_sample_ticks,x
	sta delay_sample_ticks,x
	sta track_current_loop_flags,x
	sta vibrato_rates,x
	sta tremolo_rates,x
	sta volume_slide_rates,x
	sta seq_commands,x
	sta seq_prev_commands,x
	sta seq_command_arguments,x
	sta seq_prev_command_arguments,x

	sta current_note_periods_lows,x
	sta current_note_periods_highs,x

	sta current_steprates_fracts,x
	sta current_steprates_ints,x

	sta sample_pointers_fracts,x
	sta sample_pointers_lows,x
	sta sample_pointers_mids,x
	sta sample_pointers_highs,x

	sta current_sample_end_addr_lows,x
	sta current_sample_end_addr_highs,x

	dex
	bpl -

	ldx #7
	lda #1
-	sta current_sample_end_addr_mids,x
	dex
	bpl -

	lda #$80
	ldx #7
-	sta track_current_enable_flags,x
	dex
	bpl -

; caution:  do not init more than 4 tracks here until the fetch and mixer
; loops have been expanded to handle it, will cause mem corruption

	lda #3
	sta seq_current_track
-	+JSR_INDIRECT (do_selfmod_pitch_vec)
	+JSR_INDIRECT (do_selfmod_instrument_vec)
	dec seq_current_track
	bpl -

	ldy #3
-	lda #64
	jsr set_volume
	dey
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

	jsr print_num_song_pos

	lda #0
	beq nple

next_pattern
	inc current_song_pos
	lda current_song_pos
	cmp number_of_song_positions
	bne nple

	jmp stop_song

nple
	tax
	lda pattern_table,x
	sta seq_current_pattern_number
	tay

	jsr print_song_pos_pat_num

	lda visualizer_mode
	bne next_row

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
	beq +
	and #$7f
	sta seq_current_row
	lda #0
	sta pattern_break_target_row

+	lda visualizer_mode
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
	stx sequencer_temp_x

; split each row, each track's four data bytes into their different components

get_command								; ...and its parameters.
	lda seq_current_row_data+3,x
	sta seq_command_arguments,y
	lda seq_current_row_data+1,x
	lsr
	lsr
	lsr
	lsr
	sta seq_commands,y

get_sample_number
	ldx sequencer_temp_x
	lda seq_current_row_data,x			; if sample number is 0, keep using
	beq +								; the previous sample number

	sta current_sample_numbers,y

	tax									; only change the channel's volume if
	lda sample_default_volume_levels,x	; the sample number changes.
	jsr set_volume
	ldx sequencer_temp_x

+	lda seq_current_row_data+1,x		; if period is 0, don't restart
	and #$0f							; the sample
	ora seq_current_row_data+2,x
	beq run_command

	lda seq_commands,y					; if slide-to-note is in effect, just
	cmp #3								; ignore the sample number and don't
	beq get_note_period					; re-start the sample
	cmp #5								; ditto for pitch slide + volume slide
	beq get_note_period

	lda current_sample_numbers,y
	jsr start_sample
	ldx sequencer_temp_x
	ldy seq_current_track

get_note_period
	lda seq_current_row_data+1,x
	and #$0f
	ora seq_current_row_data+2,x		; if period is 0, keep using the
	beq run_command						; previous note/pitch

	lda seq_commands,y					; for commands 3 and 5, the given
	cmp #3								; period is a parameter to the
	beq run_command						; command, to be used later.
	cmp #5
	beq run_command

	lda seq_current_row_data+1,x
	and #$0f
	sta current_note_periods_highs,y
	lda seq_current_row_data+2,x
	sta current_note_periods_lows,y
	jsr set_pitch
	ldx sequencer_temp_x
	ldy seq_current_track

run_command

	; if the command number is > 15 or the command is unimplemented, don't
	; try to run anything.

	lda seq_commands,y
	cmp #16
	bcs no_command_this_row_this_track

	asl
	tax								; we need command no. * 2
	lda start_effect_command_jump_table+1,x
	beq no_command_this_row_this_track
	sta start_command_vec+2
	lda start_effect_command_jump_table,x
	sta start_command_vec+1

start_command_vec					; start or initialize an effect command
	jsr $1234						; (also for stuff that just runs once)
	ldy seq_current_track

no_command_this_row_this_track
	iny
	sty seq_current_track
	cpy #4
	beq +
	jmp next_track_this_row

+	lda seq_ticks_per_division
	sta seq_ticks_counter

next_tick
	!ifndef c128 {
		bit enable_screen_on_playback
		bpl +
	}
	lda CIA1_TOD_SECONDS
	cmp last_seconds
	beq +
	sta last_seconds
	jsr print_elapsed_time

+	jsr seq_check_keyboard
	beq +
	jmp stop_song

+	ldy #0
	sty seq_current_track

next_track_pre_tick
	ldy seq_current_track
	lda seq_commands,y					; commands 0-3, and 5 need to be run
	cmp #5								; after the fetch/mixer routine, not
	beq dont_run_pre_tick_command		; before.
	cmp #4
	bcc dont_run_pre_tick_command
	cmp #16
	bcs dont_run_pre_tick_command

pre_tick_command
	asl
	tax
	lda run_effect_command_jump_table+1,x
	beq dont_run_pre_tick_command

	sta run_command_pre_tick_vec+2
	lda run_effect_command_jump_table,x
	sta run_command_pre_tick_vec+1

run_command_pre_tick_vec			; run effect command if it needs tick-interval timing
	jsr $1234

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

	clc
	lda mixer_countdown_fract
	adc mixer_loops_per_tick_fract
	sta mixer_countdown_fract
	lda mixer_loops_per_tick
	adc #0
	sta mixer_countdown

run_fetch_and_mixer_vec
	jsr $1234

	!ifndef c128 {
		bit enable_screen_on_playback
		bpl +
	}
	lda visualizer_mode
	beq +
	lda do_viz_plot
	eor #$80
	sta do_viz_plot
	bpl +
	jsr viz_waveform_plot

+	ldy #0
	sty seq_current_track

next_track_post_tick
	ldy seq_current_track
	lda seq_commands,y					; commands 0-3, and 5 need to be run here.
	cmp #5
	beq run_post_tick_command
	cmp #4
	bcc run_post_tick_command
	cmp #16
	bcs dont_run_post_tick_command

run_post_tick_command
	ldx seq_ticks_counter				; post-tick commands only run N-1 times
	cpx #1								; per row/division
	beq dont_run_post_tick_command

	asl
	tax

	lda run_effect_command_jump_table+1,x
	beq dont_run_post_tick_command
	sta run_command_post_tick_vec+2

	lda run_effect_command_jump_table,x
	sta run_command_post_tick_vec+1

run_command_post_tick_vec
	jsr $1234

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

;==================
; auxillary routines

; fetch the row indicated by .X, from pattern indicated by .Y, from expansion
; RAM into the row data buffer.  

fetch_row_data
	lda #0
	sta utility_pointer_b+2

	tya						; pattern number -> offset:  N*1024
	asl
	rol utility_pointer_b+2
	asl
	rol utility_pointer_b+2
	sta utility_pointer_b+1

	txa						; use LSB to multiply row no. x16
	sta utility_pointer_b
	lda #0
	asl utility_pointer_b
	rol
	asl utility_pointer_b
	rol
	asl utility_pointer_b
	rol
	asl utility_pointer_b
	rol

	adc utility_pointer_b+1		; finish the addition, now we have a relative
	sta utility_pointer_b+1		; offset from the first pattern byte
	lda utility_pointer_b+2
	adc #0
	sta utility_pointer_b+2

	; add exp_file_data_start_page*256 offsets since the pattern
	; data sits quite some ways up from the start of exp RAM

	clc
	lda utility_pointer_b+1
	adc exp_file_data_start_page
	sta utility_pointer_b+1

	fetch_row_expansion_vec
		jmp $1234 ; just exit back to the caller via the fetch routine

; [re-]start a new sample
; enter with .A = sample number, .Y = track number

start_sample
	tax

	lda seq_commands,y
	cmp #9	; let the set-sample-offset cmd handle the pointer, if applicable
	beq +

	lda sample_start_addresses_mids,x
	sta sample_pointers_mids,y
	lda sample_start_addresses_highs,x
	sta sample_pointers_highs,y

+	lda #0
	sta vibrato_rates,y
	sta tremolo_rates,y
	sta volume_slide_rates,y
	sta current_pitch_slide_rates,y
	sta sample_pointers_fracts,y
	sta sample_pointers_lows,y

	lda sample_end_addresses_lows,x
	sta current_sample_end_addr_lows,y
	lda sample_end_addresses_mids,x
	sta current_sample_end_addr_mids,y
	lda sample_end_addresses_highs,x
	sta current_sample_end_addr_highs,y

	lda sample_default_loop_flags,x
	sta track_current_loop_flags,y

	+JSR_INDIRECT (do_selfmod_instrument_vec)

	ldy seq_current_track
	ldx current_sample_numbers,y
rts

; convert a note period into a sample stepper value
; enter with .Y = track number

set_pitch
	tya
	tax

	lda current_note_periods_lows,x
	sta utility_pointer
	lda current_note_periods_highs,x
	asl utility_pointer
	rol
	sta utility_pointer+1

	clc
	lda utility_pointer
	adc #<steprate_lookup_table
	sta utility_pointer
	lda utility_pointer+1
	adc #>steprate_lookup_table
	sta utility_pointer+1

	ldy #0
	lda (utility_pointer),y
	sta current_steprates_fracts,x
	iny
	lda (utility_pointer),y
	sta current_steprates_ints,x

	+JSR_INDIRECT (do_selfmod_pitch_vec)
rts

; #############################
; EFFECT COMMAND ADDRESS TABLES
;
; enter each command with .Y = track number
; The actual commands are in fxcmd-*.s, linked into modplay.s

start_effect_command_jump_table
	!word start_effect_arpeggio
	!word start_effect_pitch_slide ; up
	!word start_effect_pitch_slide ; down
	!word start_effect_pitch_slide ; portamento to note
	!word 0 ; start_effect_vibrato
	!word start_effect_pitch_slide_plus_volume_slide
	!word 0 ; start_effect_vibrato_plus_volume_slide
	!word 0
	!word 0
	!word run_effect_set_sample_offset
	!word start_effect_volume_slide
	!word 0 ; run_effect_position_jump
	!word run_effect_set_volume
	!word run_effect_pattern_break
	!word 0
	!word run_effect_set_speed

run_effect_command_jump_table
	!word run_effect_arpeggio
	!word run_effect_pitch_slide
	!word run_effect_pitch_slide
	!word run_effect_pitch_slide
	!word 0 ; run_effect_vibrato
	!word run_effect_pitch_slide_plus_volume_slide
	!word 0 ; run_effect_vibrato_plus_volume_slide
	!word 0
	!word 0
	!word 0
	!word run_effect_volume_slide
	!word 0
	!word 0
	!word 0
	!word 0
	!word 0
