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

	sta current_pitch_slide_flags,x
	sta pitch_slide_rates,x

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
	sta seq_commands,x
	sta seq_prev_commands,x
	sta seq_command_arguments,x
	sta seq_prev_command_arguments,x

	sta current_note_periods_lows,x
	sta current_note_periods_highs,x
	sta current_note_numbers,x

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

	lda CIA1+$0f	; ensure that the next few STA's reset the TOD clock
	and #$7f
	sta CIA1+$0f

	lda #0
	sta CIA1+$0b
	sta CIA1+$0a
	sta CIA1+$09
	sta CIA1+$08

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
;   byte 0   byte 1    byte 2    byte 3
; 76543210 76543210 7654-3210 76543210
; xxxxxxxx wwwwyyyy 0000-cccc zzzzzzzz
;
; where:
;      xxxxxxxx (now 8 bits) is the note number, 0 - 60 (see init.s)
;      wwwwyyyy     (8 bits) is the sample number
; cccc-zzzzzzzz   (4+8 bits) is the effect and its parameters

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

	lda #<viz_line_6
	sta utility_pointer 
	lda #>viz_line_6
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

; get sample number
	lda seq_current_row_data+1,x		; if sample number is 0, keep using
	beq get_note_number					; the previous sample number
	sta current_sample_numbers,y

	stx sequencer_temp_x
	jsr start_sample
	ldx sequencer_temp_x
	ldy seq_current_track

get_note_number
	lda seq_current_row_data,x			; if note number is 0, keep using the
	beq get_command						; previous note/pitch

	; .A holds the note number 1-60
	stx sequencer_temp_x
	sta current_note_numbers,y
	jsr set_pitch
	ldx sequencer_temp_x
	ldy seq_current_track

get_command								; ...and its parameters.
	lda seq_current_row_data+3,x
	sta seq_command_arguments,y
	lda seq_current_row_data+2,x
	sta seq_commands,y
	asl
	tax

	; initialize/start the appropriate effect for this track

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
	!ifndef c128 {
		bit enable_screen_on_playback
		bpl +
	}
	lda CIA1+$09
	cmp last_seconds
	beq +
	sta last_seconds
	jsr print_elapsed_time

+	jsr seq_check_keyboard
	beq +
	jmp stop_song

+	ldy #0
	sty seq_current_track

next_track_this_tick
	lda seq_commands,y				; if command and its params are both 0,
	ora seq_command_arguments,y		; then there's no command at all (whereas
	beq no_cmd_this_tick			; command #0 + nonzero args = arpeggio)

	lda seq_commands,y
	asl
	tax
	lda run_effect_command_jump_table,x
	sta run_command_vec+1
	lda run_effect_command_jump_table+1,x
	sta run_command_vec+2

run_command_vec			; run effect command if it needs tick-interval timing
	jsr $1234

no_cmd_this_tick
	inc seq_current_track
	ldy seq_current_track
	cpy #4
	bne next_track_this_tick

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
	; run the sample data fetch and mix routines

	run_fetch_and_mixer_vec
		jsr $1234
	ldy seq_current_track
	; ----------------------------------

	dec seq_ticks_counter
	bne next_tick

	lda pattern_break_target_row
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

; add the $0200 offset since the pattern data sits 2 pages up from the start

	clc
	lda utility_pointer_b+1
	adc #2
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
	sta pitch_slide_rates,y

	sta sample_pointers_fracts,y
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

	lda sample_default_loop_flags,x
	sta track_current_loop_flags,y

	+JSR_INDIRECT (do_selfmod_instrument_vec)

	ldy seq_current_track
	ldx current_sample_numbers,y
	lda sample_default_volume_levels,x
	jmp set_volume  ; just exit from there

; convert a note period into a sample stepper value
;
; enter with .A = note number 1-60 to set, .Y = track number

set_pitch
	stx sequencer_temp_x

	sec
	sbc #1	; subtract 1, then double it = 1-61 --> 0-59 --> 0-118
	asl
	tax

	lda note_period_table,x
	sta current_note_periods_lows,y
	lda steprate_table,x
	sta current_steprates_fracts,y
	inx
	lda note_period_table,x
	sta current_note_periods_highs,y
	lda steprate_table,x
	sta current_steprates_ints,y

	+JSR_INDIRECT (do_selfmod_pitch_vec)
rts

unused
rts

start_effect_command_jump_table
	!word start_effect_arpeggio
	!word unused ; start_effect_pitch_slide_up
	!word unused ; start_effect_pitch_slide_down
	!word unused ; start_effect_pitch_slide_to_note
	!word unused ; start_effect_vibrato
	!word unused ; start_effect_pitch_slide_plus_volume_slide
	!word unused ; start_effect_vibrato_plus_volume_slide
	!word unused
	!word unused
	!word unused ; run_effect_set_sample_offset
	!word start_effect_volume_slide
	!word unused ; run_effect_position_jump
	!word run_effect_set_volume
	!word run_effect_pattern_break
	!word unused
	!word run_effect_set_speed

run_effect_command_jump_table
	!word run_effect_arpeggio
	!word unused ; run_effect_pitch_slide_up
	!word unused ; run_effect_pitch_slide_down
	!word unused ; run_effect_pitch_slide_to_note
	!word unused ; run_effect_vibrato
	!word unused ; run_effect_pitch_slide_plus_volume_slide
	!word unused ; run_effect_vibrato_plus_volume_slide
	!word unused
	!word unused
	!word unused
	!word run_effect_volume_slide
	!word unused
	!word unused
	!word unused
	!word unused
	!word unused

; effect command decoders -- start-of-row/init routines
; enter each one with .Y = track number
;
; note that since note numbers are in reverse order (60 = lowest pitch),
; commands which change a note have to decrease the note number if they're
; supposed to increase the pitch.


; #### ARPEGGIO

start_effect_arpeggio
	lda seq_command_arguments,y
	lsr
	lsr
	lsr
	lsr
	sta arpeggio_extra_note_first,y

	lda seq_command_arguments,y
	and #$0f
	sta arpeggio_extra_note_second,y
rts

run_effect_arpeggio
	clc
	lda arpeggio_counters,y
	adc #1
	cmp #3
	bne +
	lda #0
	sta arpeggio_counters,y
	jmp set_pitch

+	sta arpeggio_counters,y
	cmp #1
	bne +
	lda current_note_numbers,y
	sec
	sbc arpeggio_extra_note_first,y
	jmp set_pitch

+	cmp #2
	bne +
	lda current_note_numbers,y
	sec
	sbc arpeggio_extra_note_second,y
	jmp set_pitch
+ rts


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

+	cmp #47
	bcs voltab_use_upper

	adc #>volume_table_lower
	jmp set_vol_addrs_only

voltab_use_upper
	clc
	adc #(>volume_table_upper)-47

set_vol_addrs_only
	set_lookahead_vol_addrs_vec
	  jmp $1234


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


; ===========================
; === In-player UI stuff  ===
; ===========================

!ifndef c128 {
	print_nsp_target = secondary_screen + 10*40 + 18
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
	print_sp_target = secondary_screen + 10*40 + 15
	print_pn_target = secondary_screen + 10*40 + 33
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
	print_rn_target = secondary_screen + 11*40 + 7
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
	print_sst_target = secondary_screen + 11*40 + 19
	print_ssb_target = secondary_screen + 11*40 + 22
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
	bit CIA1+$0b; read hours to latch the time

	!ifndef c128 {

		print_et_target = secondary_screen + 11*40 + 33

		ldx CIA1+$0a ; minutes
		lda divide_by_16_table,x
		ora #$30
		sta print_et_target
		txa
		and #$0f
		ora #$30
		sta print_et_target+1

		ldx CIA1+$09 ; seconds
		lda divide_by_16_table,x
		ora #$30
		sta print_et_target+3
		txa
		and #$0f
		ora #$30
		sta print_et_target+4
	} else {
		print_et_target = VDC_SCREEN + 11*80 + 53

	-	bit VDC
		bpl -

		lda #18
		sta VDC
		lda #>print_et_target
		sta VDC+1

		lda #19
		sta VDC
		lda #<print_et_target
		sta VDC+1

		lda #31
		sta VDC

		ldx CIA1+$0a
		lda divide_by_16_table,x
		ora #$30
		jsr vdc_continue_write_ram

		txa
		and #$0f
		ora #$30
		jsr vdc_continue_write_ram

		lda #":"
		jsr vdc_continue_write_ram

		ldx CIA1+$09
		lda divide_by_16_table,x
		ora #$30
		jsr vdc_continue_write_ram

		txa
		and #$0f
		ora #$30
		jsr vdc_continue_write_ram
	}

	bit CIA1+$08; read tenths to un-latch the time
rts

seq_check_keyboard
	lda #0					; drive all columns low
	sta CIA1
	lda CIA1+$01
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
	sta CIA1
	lda CIA1+$01
	cmp #%11110111			; look for row 3, F7 key
	bne +
	lda #1
	rts

+	lda #%01111111			; column 7 low
	sta CIA1
	lda CIA1+$01
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
	sta CIA1
	lda CIA1+$01

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

	jsr viz_show_track_mute

exit_player_keyscan
	lda #0
rts
