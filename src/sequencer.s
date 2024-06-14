; This file is the actual music sequencer
; Originally I was gonna just port the old Modplay 64 v1.2 sequencer since
; it works pretty well, but that code is an absolute mess.

!text "sequencer",0

start_sequencer
	lda #64
	ldx #7
-	sta current_sample_volume_levels,x
	dex
	bpl -

	ldx #14
	lda #<volume_tables_high
-	sta volume_table_vectors,x
	dex
	dex
	bpl -

	ldx #15
	lda #>(volume_tables_high+$1e00)
-	sta volume_table_vectors,x
	dex
	dex
	bpl -

	lda #0
	sta seq_abort_flag
	sta glissando_flag
	sta vibrato_waveform
	sta tremolo_waveform
	sta delay_pattern_divisions
	sta pattern_break_target_row

	ldx #7
-	sta current_sample_numbers,x

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
	sta seq_ticks_per_division
	jsr set_mixer_loops_per_tick

	lda #0
	sta mixer_countdown_fract

	sta current_song_pos
	sta seq_current_row

	ldx number_of_song_positions
	dex

	!ifndef c128 {
		bit enable_screen_on_playback
		bpl nple
		lda divide_by_16_table,x
		jsr to_hex
		sta secondary_screen + 11*40 + 18
		txa
		and #$0f
		jsr to_hex
		sta secondary_screen + 11*40 + 19
	} else {
		!addr {
			vdc_target = (VDC_SCREEN + 12*80 + 38)
		}

		lda #18
		sta VDC
		lda #>vdc_target
		sta VDC+1

		lda #19
		sta VDC
		lda #<vdc_target
		sta VDC+1

		lda #31
		sta VDC

		lda divide_by_16_table,x
		jsr to_hex
		sta VDC+1

		txa
		and #$0f
		jsr to_hex
		sta VDC+1
	}

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

	!ifndef c128 {
		bit enable_screen_on_playback
		bpl next_row
		lda divide_by_16_table,x
		jsr to_hex
		sta secondary_screen + 11*40 + 15
		txa
		and #$0f
		jsr to_hex
		sta secondary_screen + 11*40 + 16

		ldx seq_current_pattern_number
		lda divide_by_16_table,x
		jsr to_hex
		sta secondary_screen + 11*40 + 33
		txa
		and #$0f
		jsr to_hex
		sta secondary_screen + 11*40 + 34
	} else {
		!addr {
			vdc_target2 = (VDC_SCREEN + 12*80 + 35)
			vdc_target3 = (VDC_SCREEN + 12*80 + 53)
		}

		lda #18
		sta VDC
		lda #>vdc_target2
		sta VDC+1

		lda #19
		sta VDC
		lda #<vdc_target2
		sta VDC+1

		lda #31
		sta VDC

		lda divide_by_16_table,x
		jsr to_hex
		sta VDC+1

		txa
		and #$0f
		jsr to_hex
		sta VDC+1


		lda #18
		sta VDC
		lda #>vdc_target3
		sta VDC+1

		lda #19
		sta VDC
		lda #<vdc_target3
		sta VDC+1

		lda #31
		sta VDC

		ldx seq_current_pattern_number
		lda divide_by_16_table,x
		jsr to_hex
		sta VDC+1

		txa
		and #$0f
		jsr to_hex
		sta VDC+1

	}

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
	ldx seq_current_row

	!ifndef c128 {
		bit enable_screen_on_playback
		bpl fetch_row_vec
		lda divide_by_16_table,x
		jsr to_hex
		sta secondary_screen + 12*40 + 13
		lda seq_current_row
		and #$0f
		jsr to_hex
		sta secondary_screen + 12*40 + 14
	}  else {
		!addr {
			vdc_target4 = (VDC_SCREEN + 13*80 + 34)
		}

		lda #18
		sta VDC
		lda #>vdc_target4
		sta VDC+1

		lda #19
		sta VDC
		lda #<vdc_target4
		sta VDC+1

		lda #31
		sta VDC

		lda divide_by_16_table,x
		jsr to_hex
		sta VDC+1

		txa
		and #$0f
		jsr to_hex
		sta VDC+1
	}

fetch_row_vec			; fetch the next row from expansion RAM
	jsr $1234
	ldy #0
	sty seq_current_track

next_track_this_row
	tya
	asl
	asl					; .X = track number x 4
	tax

; get sample number
	lda seq_current_row_data,x
	and #$f0
	sta tempzpbk_g
	lda seq_current_row_data+2,x
	lsr
	lsr
	lsr
	lsr
	ora tempzpbk_g					; if sample number is 0, keep using the
	beq get_period					; previous sample number
	sta current_sample_numbers,y

	jsr start_sample

get_period
	lda seq_current_row_data,x		; if period is 0, keep using the
	and #$0f						; previous period value
	ora seq_current_row_data+1,x
	beq get_command

	lda seq_current_row_data,x
	and #$0f
	sta current_note_periods_highs,y
	lda seq_current_row_data+1,x
	sta current_note_periods_lows,y

	jsr set_pitch

get_command							; and its parameters
	lda seq_commands,y
	sta seq_prev_commands,y
	lda seq_command_arguments,y
	sta seq_prev_command_arguments,y

	lda seq_current_row_data+3,x
	sta seq_command_arguments,y
	lda seq_current_row_data+2,x
	and #$0f
	sta seq_commands,y
	asl
	tax

	; initialize/start the appropriate effect for this track

	lda seq_command_arguments,y		; if both the command and its args are 0
	ora seq_commands,y				; then there's no command
	beq +							; (command #0 + nonzero args = arpeggio)

	lda start_effect_command_jump_table,x
	sta start_command_vec+1
	lda start_effect_command_jump_table+1,x
	sta start_command_vec+2

start_command_vec					; start or initialize an effect command
	jsr $1234						; (also for stuff that just runs once)
	ldy seq_current_track

+	iny
	sty seq_current_track
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

+	ldy #0
	sty seq_current_track

next_track_this_tick
	lda seq_commands,y
	asl
	tax
	lda run_effect_command_jump_table,x
	sta run_command_vec+1
	lda run_effect_command_jump_table+1,x
	sta run_command_vec+2

run_command_vec					; run effect command if it needs tick-interval timing
	jsr $1234
	inc seq_current_track
	ldy seq_current_track
	cpy #4
	bne next_track_this_tick

	jsr set_lookahead_addrs

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

	; ----------------------------------
	; run the mixer!
	start_mixer_vec
		jsr $1234
	ldy seq_current_track
	; ----------------------------------

	dec seq_ticks_counter
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

; Note we're setting the values to 256x the actual amounts temporarily, so
; that the quotient low byte can act as a fraction.

run_effect_set_speed
	sec
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

	!ifndef c128 {
		bit enable_screen_on_playback
		bpl elpt

		ldx seq_ticks_per_division
		lda divide_by_16_table,x
		jsr to_hex
		sta secondary_screen + 12*40 + 27
		txa
		and #$0f
		jsr to_hex
		sta secondary_screen + 12*40 + 28

		ldx seq_tempo_bpm
		lda divide_by_16_table,x
		jsr to_hex
		sta secondary_screen + 12*40 + 30
		txa
		and #$0f
		jsr to_hex
		sta secondary_screen + 12*40 + 31
	} else {
		!addr {
			vdc_target5 = (VDC_SCREEN + 13*80 + 48)
			vdc_target6 = (VDC_SCREEN + 13*80 + 51)
		}

		lda #18
		sta VDC
		lda #>vdc_target5
		sta VDC+1

		lda #19
		sta VDC
		lda #<vdc_target5
		sta VDC+1

		lda #31
		sta VDC

		ldx seq_ticks_per_division
		lda divide_by_16_table,x
		jsr to_hex
		sta VDC+1

		txa
		and #$0f
		jsr to_hex
		sta VDC+1


		lda #18
		sta VDC
		lda #>vdc_target6
		sta VDC+1

		lda #19
		sta VDC
		lda #<vdc_target6
		sta VDC+1

		lda #31
		sta VDC

		ldx seq_tempo_bpm
		lda divide_by_16_table,x
		jsr to_hex
		sta VDC+1

		txa
		and #$0f
		jsr to_hex
		sta VDC+1
	}

  elpt
rts


;==================
; auxillary routines

; the actual mixer loop where the raltime stuff happens
; every cycle matters here.

; [re-]start a new sample
; enter with .A = sample number, .Y = track number
; .X/.Y-safe

start_sample
	stx sequencer_temp_x
	tax
	lda #0
	sta vibrato_rates,y
	sta tremolo_rates,y
	sta volume_slide_rates,y
	sta pitch_slide_up_rates,y
	sta pitch_slide_down_rates,y
	sta pitch_slide_to_note_rates,y

	sta sample_pointers_fract,y
	lda sample_start_addresses_lows,x
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

	lda sample_default_volume_levels,x

	ldx sequencer_temp_x

	; now just fall through into set_volume

; set the sample's volume
; enter with .A = volume level, .Y = track number
; .Y will be preserved

set_volume
	sta current_sample_volume_levels,y
	tya
	asl
	tay ; track number x2

	sec
	cmp #33
	bcc +

	clc
	adc #>volume_tables_low
	sta volume_table_vectors+1,y
	bcc ++

+	sec
	sbc #34
	clc
	adc #>volume_tables_high
	sta volume_table_vectors+1,y

++	lda #0
	sta volume_table_vectors,y
	ldy seq_current_track
rts

; convert a note period into a sample stepper value
;
; enter with .Y set to the track number whose period needs converted
; .Y will be preserved.

set_pitch
	tya
	tax

	lda #0
	sta tempzp_d
	sta tempzp_e

	clc
	lda #>pitch_table_fracts
	adc current_note_periods_highs,x
	sta tempzp_d+1

	lda #>pitch_table_lows
	adc current_note_periods_highs,x
	sta tempzp_e+1

	ldy current_note_periods_lows,x

	lda (tempzp_d),y
	sta current_steprates_fract,x

; the pitch table gen doesn't bother storing the highest 4 pages of the "lows"
; section (that is, the integers), because they will always return 0 no matter
; what, so we can just handle that here for note periods whose high byte is 3
; or more (e.g. 768 and above)

	sec
	lda current_note_periods_highs,x
	cmp #3
	bcs +
	lda (tempzp_e),y
	bcc ++

+	lda #0
++	sta current_steprates_lows,x

	ldy seq_current_track
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
	!word run_effect_set_speed

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

seq_abort_flag				!byte 0
