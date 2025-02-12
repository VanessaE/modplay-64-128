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

; Relay the RAM driver's index table address from outside of the ZP backup

fetch_routine_table_lsb
	lda #0
	sta ram_drv_fetch_addr_table_pointer
fetch_routine_table_msb
	lda #0
	sta ram_drv_fetch_addr_table_pointer+1

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

+	ldx seq_current_row
	cpx #61
	bcs +

	lda #<visualizer_line_6
	sta utility_pointer 
	lda #>visualizer_line_6
	sta utility_pointer+1

	inx
	inx
	inx
	jsr viz_row_data_fetch_and_print

	ldx seq_current_row

+	jsr fetch_row_data

	jsr print_row_num

	ldy #0
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
	tax ; .X will need command no. * 2
	lsr
	sta seq_commands,y

	; initialize/start the appropriate effect for this track

	lda start_effect_command_jump_table,x
	sta start_command_vec+1
	lda start_effect_command_jump_table+1,x
	sta start_command_vec+2

get_sample_number
	ldx sequencer_temp_x
	lda seq_current_row_data,x			; if sample number is 0, keep using
	beq get_note_period					; the previous sample number

	ldx seq_commands,y					; if slide-to-note is in effect, just
	cpx #3								; ignore the sample number and don't
	beq get_note_period					; re-trigger the sample
	cpx #5								; ditto for pitch slide + volume slide
	beq get_note_period

	sta current_sample_numbers,y

	jsr start_sample
	ldy seq_current_track

get_note_period
	ldx sequencer_temp_x
	lda seq_current_row_data+1,x
	and #$0f
	ora seq_current_row_data+2,x		; if period is 0, keep using the
	beq run_command						; previous note/pitch

	lda seq_commands,y					; for commands 3 and 5, the given
	cmp #3								; period is a parameter to the
	beq set_target_period				; command, to be used later.
	cmp #5
	beq set_target_period
	jmp use_given_period

set_target_period
	lda seq_current_row_data+1,x
	and #$0f
	sta seq_pitch_slide_target_period_highs,y
	lda seq_current_row_data+2,x
	sta seq_pitch_slide_target_period_lows,y
	jmp run_command

use_given_period
	lda seq_current_row_data+1,x
	and #$0f
	sta current_note_periods_highs,y
	lda seq_current_row_data+2,x
	sta current_note_periods_lows,y

run_command
	jsr set_pitch
	ldx sequencer_temp_x
	ldy seq_current_track

	; if the command number is > 15 or the command is unimplemented, don't
	; try to run anything.

	lda seq_commands,y
	cmp #16
	bcs no_command_this_row_this_track
	lda start_command_vec+2
	beq no_command_this_row_this_track

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
	lda run_effect_command_jump_table,x
	sta run_command_pre_tick_vec+1
	lda run_effect_command_jump_table+1,x
	sta run_command_pre_tick_vec+2
	beq dont_run_pre_tick_command

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

	ldy #0
	sty seq_current_track

next_track_post_tick
	ldy seq_current_track
	lda seq_commands,y					; commands 0-3, and 5 need to be run here.
	cmp #5
	beq run_post_tick_command
	cmp #4
	bcs dont_run_post_tick_command
	cmp #16
	bcs dont_run_post_tick_command

run_post_tick_command
	ldx seq_ticks_counter				; post-tick commands only run N-1 times
	cpx #1								; per row/division
	beq dont_run_post_tick_command

	asl
	tax
	lda run_effect_command_jump_table,x
	sta run_command_post_tick_vec+1
	lda run_effect_command_jump_table+1,x
	sta run_command_post_tick_vec+2
	beq dont_run_post_tick_command

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

	; add the $0400 offset since the pattern data sits 4 pages up from the start

	clc
	lda utility_pointer_b+1
	adc #4
	sta utility_pointer_b+1

	fetch_row_expansion_vec
		jmp $1234 ; just exit back to the caller via the fetch routine

; [re-]start a new sample
; enter with .A = sample number, .Y = track number

start_sample
	tax
	lda #0
	sta vibrato_rates,y
	sta tremolo_rates,y
	sta volume_slide_rates,y
	sta current_pitch_slide_rates,y

	sta sample_pointers_fracts,y
	lda #0
	sta sample_pointers_lows,y
	lda sample_start_addresses_mids,x
	sta sample_pointers_mids,y
	lda sample_start_addresses_highs,x
	sta sample_pointers_highs,y

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
	lda sample_default_volume_levels,x
	jmp set_volume  ; just exit from there

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

start_effect_command_jump_table
	!word start_effect_arpeggio
	!word start_effect_pitch_slide
	!word start_effect_pitch_slide
	!word start_effect_pitch_slide_to_note
	!word 0 ; start_effect_vibrato
	!word start_effect_pitch_slide_plus_volume_slide
	!word 0 ; start_effect_vibrato_plus_volume_slide
	!word 0
	!word 0
	!word 0 ; run_effect_set_sample_offset
	!word start_effect_volume_slide
	!word 0 ; run_effect_position_jump
	!word run_effect_set_volume
	!word run_effect_pattern_break
	!word 0
	!word run_effect_set_speed

run_effect_command_jump_table
	!word run_effect_arpeggio
	!word run_effect_pitch_slide_up
	!word run_effect_pitch_slide_down
	!word run_effect_pitch_slide_to_note
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

; effect command decoders -- start-of-row/init routines
; enter each one with .Y = track number

; #### ARPEGGIO

start_effect_arpeggio
	lda seq_command_arguments,y
	bne +
	rts

+	tya
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
	sta multiplicand_a
	iny
	lda (utility_pointer),y
	sta multiplicand_a+1

	ldy seq_current_track

	lda seq_command_arguments,y
	lsr
	lsr
	lsr
	and #$0e ; we want the note offset * 2
	tax
	lda semitones_table,x
	sta multiplicand_b
	inx
	lda semitones_table,x
	sta multiplicand_b+1

	sec
	jsr multiply_16x16

	; for precision sake, the semitones table is 256x higher than "normal", so
	; use the middle two bytes of the product to divide it back down.

	lda product+1
	sta arpeggio_extra_note_first_fracts,y
	lda product+2
	sta arpeggio_extra_note_first_ints,y

	lda seq_command_arguments,y
	and #$0f
	asl
	tax
	lda semitones_table,x
	sta multiplicand_b
	inx
	lda semitones_table,x
	sta multiplicand_b+1

	clc ; reuse the previous multiplicand_a preset
	jsr multiply_16x16

	lda product+1
	sta arpeggio_extra_note_second_fracts,y
	lda product+2
	sta arpeggio_extra_note_second_ints,y

	lda #2
	sta arpeggio_counters,y
rts

run_effect_arpeggio
	lda seq_command_arguments,y
	bne +
	rts

+	stx sequencer_temp_x
	ldx arpeggio_counters,y
	inx

	cpx #1
	bne +

	lda arpeggio_extra_note_first_fracts,y
	sta current_steprates_fracts,y
	lda arpeggio_extra_note_first_ints,y
	sta current_steprates_ints,y
	jmp set_arp_pitch_2_3

+	cpx #2
	bne +
	lda arpeggio_extra_note_second_fracts,y
	sta current_steprates_fracts,y
	lda arpeggio_extra_note_second_ints,y
	sta current_steprates_ints,y
	jmp set_arp_pitch_2_3

+	ldx #0
	stx arpeggio_counters,y
	jsr set_pitch

	ldx sequencer_temp_x
	rts

set_arp_pitch_2_3
	stx arpeggio_counters,y
	+JSR_INDIRECT (do_selfmod_pitch_vec)

	ldx sequencer_temp_x
rts

; #### PITCH SLIDING

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
	bcc stop_porta_up

	lda current_note_periods_lows,y
	cmp seq_pitch_slide_target_period_lows,y
	lda current_note_periods_highs,y
	sbc seq_pitch_slide_target_period_highs,y
	bcs +

stop_porta_up
	lda seq_pitch_slide_target_period_lows,y
	sta current_note_periods_lows,y
	lda seq_pitch_slide_target_period_highs,y
	sta current_note_periods_highs,y
	lda #0
	sta current_pitch_slide_rates,y

+	jmp set_pitch

slide_to_lower_note
	clc
	lda current_note_periods_lows,y
	adc current_pitch_slide_rates,y
	sta current_note_periods_lows,y
	lda current_note_periods_highs,y
	adc #0
	sta current_note_periods_highs,y
	bcs stop_porta_down

	lda seq_pitch_slide_target_period_lows,y
	cmp current_note_periods_lows,y
	lda seq_pitch_slide_target_period_highs,y
	sbc current_note_periods_highs,y
	bcs +

stop_porta_down
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

; #### SET VOLUME

; sets a sample's volume, either by way of an effect command, or by a new
; sample being started, or by unmuting a track.  sets the address targets in
; the mixer also.

; enter run_effect_set_volume with .Y = track, the latter set_volume needs
; that along with .A = new volume level.

run_effect_set_volume
	lda seq_command_arguments,y

set_volume
	sta current_sample_volume_levels,y
	ldx track_current_enable_flags,y
	bmi +
	rts

+	cmp #64
	bcc +
	lda #63
	bne voltab_use_upper

+	cmp #38
	bcs voltab_use_upper

	adc #>volume_table_lower
	jmp set_vol_addrs_only

voltab_use_upper
	clc
	adc #(>volume_table_upper)-38

set_vol_addrs_only
	jmp mixer_set_lookahead_vol_addrs

; #### VOLUME SLIDE

start_effect_volume_slide
	lda seq_command_arguments,y
	sta volume_slide_rates,y
rts

run_effect_volume_slide
	lda volume_slide_rates,y
	and #$f0
	beq vsdown
	lsr
	lsr
	lsr
	lsr
	clc
	adc current_sample_volume_levels,y
	cmp #64
	bcc +
	lda #64
+	sta current_sample_volume_levels,y
	jmp set_volume


vsdown
	lda volume_slide_rates,y
	and #$0f
	bne +
	rts

+	sta temp_zpbk_a
	sec
	lda current_sample_volume_levels,y
	sbc temp_zpbk_a
	bcs +
	lda #0
+	sta current_sample_volume_levels,y
	jmp set_volume

; #### PATTERN BREAK

run_effect_pattern_break
	stx temp_zpbk_a+1

	lda seq_command_arguments,y
	and #$0f
	sta temp_zpbk_a
	lda seq_command_arguments,y
	lsr
	lsr
	lsr
	lsr
	clc
	tax
	lda nybble_x10,x
	adc temp_zpbk_a
	ora #$80
	sta pattern_break_target_row

	ldx temp_zpbk_a+1
rts

; #### SET SPEED

; Note we're setting the values to 256x the actual amounts temporarily, so
; that the quotient low byte can act as a fraction.

run_effect_set_speed
	lda seq_command_arguments,y
	cmp #33
	bcc +
	sta seq_tempo_bpm
	bcs set_mixer_loops_per_tick

+	sta seq_ticks_per_division

set_mixer_loops_per_tick
	ldx seq_tempo_bpm
	lda tempo_table_fracts,x
	sta mixer_loops_per_tick_fract
	lda tempo_table_lows,x
	sta mixer_loops_per_tick

	jsr print_song_speed

	elpt
rts

; ================================
; === Mixer/lookahead routines ===
; ================================

; this is the average mixer run time, in cycles, per output sample pair
; see full details in doc/timing-info.txt.

!ifndef scpu {
	!ifndef c128 {
		mixer_cycle_count = 47
	} else {
		mixer_cycle_count = 48 / 2
	}
} else {
	mixer_cycle_count = 3
}

; Must enter with .X = the most recent 16-byte offset into the audio input
; buffer, which will be updated here

run_mixer_lookahead											; 6 to enter
	txa														; 2
	adc #16													; 2

-	ldy audio_out_buf_index									; 3
	cmp and_f0_table,y										; 4
	beq -													; 3/2

	clc														; 2

	mixer_loop_open
	  !for .idx2, 0, 15 {

		; the various `LDY $nnnn` below will have their addresses re-written
		; by the mixer_do_selfmods_for_pitch_change routine below.
		; Similarly, each corresponding `LDA/ADC $nnnn,Y` will
		; have its high byte re-written by the set_volume routine.
		;
		; the addresses below are arbitrary, chosen only so that they're
		; definitely in absolute mode when assembled, and so that failure
		; to alter one of them is easy to spot in the ML monitor at runtime.

		!if .idx2 = 0 { mixer_rd_la_track_1 = * }
		ldy $6100											; 4
		!if .idx2 = 0 { mixer_vol_addr_1 = * }
		lda $8100,y											; 4

		!if .idx2 = 0 { mixer_rd_la_track_4 = *}
		ldy $6400											; 4
		!if .idx2 = 0 { mixer_vol_addr_4 = *}
		adc $8400,y											; 4

		sta audio_buffer_left,x								; 5

		!if .idx2 = 0 { mixer_rd_la_track_2 = * }
		ldy $6200											; 4
		!if .idx2 = 0 { mixer_vol_addr_2 = * }
		lda $8200,y											; 4

		!if .idx2 = 0 { mixer_rd_la_track_3 = * }
		ldy $6300											; 4
		!if .idx2 = 0 { mixer_vol_addr_3 = * }
		adc $8300,y											; 4

		sta audio_buffer_right,x							; 5

		inx													; 2
	  !if .idx2 = 0 { !set mixer_loop_close = * }
	}
rts															; 6

; Mixer self-mod stuff

mixer_loop_segment_length = mixer_loop_close - mixer_loop_open

mixer_set_lookahead_vol_addrs
	ldx mixer_lookahead_code_volume_addr_idx,y

	!zone lookahead_idx_set {
		!for .idx6, 0, 15 {
			sta mixer_vol_addr_1 + mixer_loop_segment_length * .idx6 + 2,x
		}
	}
rts

mixer_do_selfmods_for_pitch_change
  !zone lookahead_idx_set {
	ldy seq_current_track

	lda #0
	sta utility_zpbk_counter
	sta utility_zpbk_counter+1
	sta utility_zpbk_counter+2

	sta temp_zpbk_a
	lda current_steprates_fracts,y
	sta temp_zpbk_a+1

	lda current_steprates_ints,y
	lsr
	ror temp_zpbk_a+1
	ror temp_zpbk_a
	lsr
	ror temp_zpbk_a+1
	ror temp_zpbk_a
	lsr
	ror temp_zpbk_a+1
	ror temp_zpbk_a
	lsr
	ror temp_zpbk_a+1
	ror temp_zpbk_a
	sta temp_zpbk_a+2

	ldx mixer_lookahead_code_read_byte_addr_idx,y

	clc
	lda seq_current_track
	adc #>sample_data_buffer

	!for .idx4, 0, 15 {
		!set .mixer_la_rd_addr_st = mixer_rd_la_track_1 + mixer_loop_segment_length * .idx4
		sta .mixer_la_rd_addr_st + 2,x
	}

	!for .idx5, 0, 15 {

		!set .mixer_la_rd_addr_st = mixer_rd_la_track_1 + mixer_loop_segment_length * .idx5

		lda utility_zpbk_counter+2
		sta .mixer_la_rd_addr_st + 1,x

		lda utility_zpbk_counter
		adc temp_zpbk_a
		sta utility_zpbk_counter

		lda utility_zpbk_counter+1
		adc temp_zpbk_a+1
		sta utility_zpbk_counter+1

		lda utility_zpbk_counter+2
		adc temp_zpbk_a+2
		sta utility_zpbk_counter+2
	  }
	}

	!ifdef scpu {
		lsr
		lsr
	}

	adc #1
rts

; ===========================
; === In-player UI stuff  ===
; ===========================

!ifndef c128 {
	print_nsp_target = VIC_SCREEN + 10*40 + 18
} else {
	print_nsp_target = VDC_SCREEN + 10*80 + 38
}

print_num_song_pos
	!ifndef c128 {
		bit enable_screen_on_playback
		bpl +
	}

	lda #<print_nsp_target
	sta utility_pointer
	lda #>print_nsp_target
	sta utility_pointer+1
	ldx number_of_song_positions
	dex
	txa
	jsr display_byte_hex_direct
  +
rts

!ifndef c128 {
	print_sp_target = VIC_SCREEN + 10*40 + 15
	print_pn_target = VIC_SCREEN + 10*40 + 33
} else {
	print_sp_target = VDC_SCREEN + 10*80 + 35
	print_pn_target = VDC_SCREEN + 10*80 + 53
}

print_song_pos_pat_num ; enter with .X = song position
	!ifndef c128 {
		bit enable_screen_on_playback
		bpl +
	}

	lda #<print_sp_target
	sta utility_pointer
	lda #>print_sp_target
	sta utility_pointer+1
	txa
	jsr display_byte_hex_direct

	lda #<print_pn_target
	sta utility_pointer
	lda #>print_pn_target
	sta utility_pointer+1
	lda seq_current_pattern_number
	jsr display_byte_hex_direct
  +
rts

!ifndef c128 {
	print_rn_target = VIC_SCREEN + 11*40 + 7
} else {
	print_rn_target = VDC_SCREEN + 11*80 + 27
}

print_row_num
	!ifndef c128 {
		bit enable_screen_on_playback
		bpl +
	}

	lda #<print_rn_target
	sta utility_pointer
	lda #>print_rn_target
	sta utility_pointer+1
	lda seq_current_row
	jsr display_byte_hex_direct
  +
rts

!ifndef c128 {
	print_sst_target = VIC_SCREEN + 11*40 + 19
	print_ssb_target = VIC_SCREEN + 11*40 + 22
} else {
	print_sst_target = VDC_SCREEN + 11*80 + 39
	print_ssb_target = VDC_SCREEN + 11*80 + 42
}

print_song_speed
	!ifndef c128 {
		bit enable_screen_on_playback
		bpl +
	}

	lda #<print_sst_target
	sta utility_pointer
	lda #>print_sst_target
	sta utility_pointer+1
	lda seq_ticks_per_division
	jsr display_byte_hex_direct

	lda #<print_ssb_target
	sta utility_pointer
	lda #>print_ssb_target
	sta utility_pointer+1
	lda seq_tempo_bpm
	jsr display_byte_hex_direct
  +
rts

print_elapsed_time
	bit CIA1_TOD_HOURS; read hours to latch the time

	!ifndef c128 {

		print_et_target = VIC_SCREEN + 11*40 + 33

		ldx CIA1_TOD_MINUTES
		lda divide_by_16_table,x
		ora #$30
		sta print_et_target
		txa
		and #$0f
		ora #$30
		sta print_et_target+1

		ldx CIA1_TOD_SECONDS
		lda divide_by_16_table,x
		ora #$30
		sta print_et_target+3
		txa
		and #$0f
		ora #$30
		sta print_et_target+4
	} else {
		print_et_target = VDC_SCREEN + 11*80 + 53

	-	bit VDC_ADDR
		bpl -

		lda #18
		sta VDC_ADDR
		lda #>print_et_target
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<print_et_target
		sta VDC_DATA

		lda #31
		sta VDC_ADDR

		ldx CIA1_TOD_MINUTES
		lda divide_by_16_table,x
		ora #$30
		jsr vdc_continue_write_ram

		txa
		and #$0f
		ora #$30
		jsr vdc_continue_write_ram

		lda #":"
		jsr vdc_continue_write_ram

		ldx CIA1_TOD_SECONDS
		lda divide_by_16_table,x
		ora #$30
		jsr vdc_continue_write_ram

		txa
		and #$0f
		ora #$30
		jsr vdc_continue_write_ram
	}

	bit CIA1_TOD_TENTHS; read tenths to un-latch the time
rts

seq_check_keyboard
	lda #0					; drive all columns low
	sta CIA1_PORT_A
	lda CIA1_PORT_B
	cmp #$ff				; is any row low?
	bne key_pressed			; if so, a key was pressed

	lda #0
	sta seq_key_debounce
	rts

key_pressed
	lda seq_key_debounce
	beq +
	lda #0
	rts

+	dec seq_key_debounce

	lda #%11111110			; column 0 low
	sta CIA1_PORT_A
	lda CIA1_PORT_B
	cmp #%11110111			; look for row 3, F7 key
	bne +
	lda #1
	rts

+	lda #%01111111			; column 7 low
	sta CIA1_PORT_A
	lda CIA1_PORT_B
	cmp #%11101111			; look for row 4, spacebar
	bne +
	lda #1
	rts

+	cmp #%11111110			; row 0, the "1" key
	bne +
	ldy #0
	jmp toggle_enable_track

+	cmp #%11110111			; row 3, the "2" key
	bne +
	ldy #1
	jmp toggle_enable_track

+	lda #%11111101			; column 1 low
	sta CIA1_PORT_A
	lda CIA1_PORT_B

	cmp #%11111110			; row 0, the "3" key
	bne +
	ldy #2
	jmp toggle_enable_track

+	cmp #%11110111			; row 3, the "4" key
	bne exit_player_keyscan
	ldy #3

toggle_enable_track
	lda track_current_enable_flags,y
	eor #$80
	sta track_current_enable_flags,y
	bmi +

	lda #>volume_table_lower
	jsr set_vol_addrs_only
	jmp ++

+	lda current_sample_volume_levels,y
	jsr set_volume

++	!ifndef c128 {
		bit enable_screen_on_playback
		bpl exit_player_keyscan
	}

	jsr viz_row_data_show_track_mute

exit_player_keyscan
	lda #0
rts
