; This file is the actual music sequencer
; Originally I was gonna just port the old Modplay 64 v1.2 sequencer since
; it works pretty well, but that code is an absolute mess.

start_sequencer
	lda #>volume_tables_low
	sta volume_table_vectors+1
	sta volume_table_vectors+3
	sta volume_table_vectors+5
	sta volume_table_vectors+7
	lda #0
	sta volume_table_vectors
	sta volume_table_vectors+2
	sta volume_table_vectors+4
	sta volume_table_vectors+6

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
-	sta track_current_enable_flags
	dex
	bpl -

	lda #125
	sta seq_tempo_bpm
	lda #6
	sta seq_tempo_ticks_per_div
	jsr calculate_mixer_loops_per_tick

	lda #0
	sta current_song_pos
	sta seq_current_row
	jmp +

next_pattern

	inc current_song_pos
	lda current_song_pos
	cmp number_of_song_positions
	bne +

	jmp stop_song

+	tax
	lda pattern_table,x
	sta seq_current_pattern_number

	bit seq_debug_mode
	bpl next_row
	jsr debug_print_new_pattern_mark

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
	bit seq_debug_mode
	bpl +
	jsr debug_print_new_row_mark

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
	tax
	lda start_effect_command_jump_table,x
	sta .sc+1
	lda start_effect_command_jump_table+1,x
	sta .sc+2

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

+	bit seq_debug_mode
	bpl +
	jsr debug_print_new_tick_mark

+	ldy #0
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
++	jsr calculate_mixer_loops_per_tick

	lda mixer_loops_per_tick_fract
	sta seq_ticks_counter_fract
	lda mixer_loops_per_tick
	sta seq_ticks_counter
rts

;==================
; auxillary routines

debug_print_new_pattern_mark
	sei
	jsr enable_kernal_only
	lda #RETURN
	jsr CHROUT
	jsr CHROUT
	lda #"p"
	jsr CHROUT
	lda #RETURN
	jsr CHROUT
	jsr disable_roms
	cli
rts

debug_print_new_row_mark
	sei
	jsr enable_kernal_only
	lda #RETURN
	jsr CHROUT
	lda #"r"
	jsr CHROUT
	jsr disable_roms
	cli
rts

debug_print_new_tick_mark
	sei
	jsr enable_kernal_only
	lda #"t"
	jsr CHROUT
	jsr disable_roms
	cli
rts

; mod speed is [divisions per minute] = (24 * bpm)/[ticks per div]
;
; at a default of 125 bpm and 6 tpd, that's 500 div/min or 8.3/sec
; and ~50 ticks/sec or 20454 cycles/tick (NTSC)
;
; with an ISR of every 3rd raster (24), that's 20454/(65*3) = ~105 samples
; per tick, or 13 28/256 runs of the mixer loop
;
; a scaler of 69 would give (24*69)/125 = 13.248 == 13 63/256 runs of the loop

tick_sample_count_scaler = 69

calculate_mixer_loops_per_tick
	lda isr_trigger_interval
	ldx tick_sample_count_scaler
	jsr multiply_8x8

	lda product
	sta dividend
	lda product+1
	sta dividend+1
	lda seq_tempo_bpm
	sta divisor
	lda #0
	sta divisor+1
	jsr divide_16by16

	lda remainder
	sta mixer_loops_per_tick_fract
	lda quotient
	lsr
	lsr
	lsr
	sta mixer_loops_per_tick
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

seq_tempo_bpm				!byte 0
seq_tempo_ticks_per_div		!byte 0

seq_ticks_counter_fract		!byte 0
seq_ticks_counter			!byte 0

mixer_loops_per_tick_fract	!byte 0
mixer_loops_per_tick		!byte 0

seq_current_track			!byte 0

seq_current_row				!byte 0
seq_current_pattern			!byte 0

seq_abort_flag				!byte 0
seq_debug_mode				!byte $80
