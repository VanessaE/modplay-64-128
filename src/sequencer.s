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
-	jsr do_realtime_selfmods_for_pitch_change
	jsr do_realtime_selfmods_for_instrument_change
	dec seq_current_track
	bpl -

	ldy #3
-	sec
	lda #64
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

	; the last write to register $0f before this point already sets the TOD
	; flag such that writes to $08-0b set the time, not the alarm

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

	adc utility_pointer_b+1		; finish the addition, now we have an offset into
	sta utility_pointer_b+1		; the pattern data
	lda utility_pointer_b+2
	adc #0
	sta utility_pointer_b+2

	lda current_file_type
	cmp #1
	bne +

; add the header length and now we have the real address of the desired row

	clc
	lda utility_pointer_b
	adc #<header15_seek_to_pat_data
	sta utility_pointer_b

	lda utility_pointer_b+1
	adc #>header15_seek_to_pat_data
	jmp ++

+	clc
	lda utility_pointer_b
	adc #<header31_seek_to_pat_data
	sta utility_pointer_b

	lda utility_pointer_b+1
	adc #>header31_seek_to_pat_data
++	sta utility_pointer_b+1

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

	jsr do_realtime_selfmods_for_instrument_change

	ldy seq_current_track
	ldx current_sample_numbers,y
	lda sample_default_volume_levels,x
	sec
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

	jsr do_realtime_selfmods_for_pitch_change
rts

; set the sample's volume, and set the address targets in the mixer

; enter with .A = volume, .Y = track, and carry set to store that setting as
; the "current" volume level, or carry clear just to set the volume table
; addresses e.g. if coming from the keyboard's 1-4 keys.

set_volume
	bcc +
	sta current_sample_volume_levels,y
+	lda current_sample_volume_levels,y
	ldx track_current_enable_flags,y
	bne +
	lda #>volume_table_lower
	jmp set_vol_direct

+	lsr
	cmp #16
	bcs +

	adc #>volume_table_lower
	jmp set_vol_direct

+	clc
	adc #(>volume_table_upper)-16

set_vol_direct
	ldx lookahead_code_volume_addr_idx,y

	!zone lookahead_idx_set {
		!for .idx4, 0, 15 {
			sta vol_addr_1 + mixer_loop_segment_length*.idx4 + 2,x
		}
	}
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
	cmp #65
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


; #### SET VOLUME

run_effect_set_volume
	lda seq_command_arguments,y
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
	jmp toggle_enable

+	cmp #%11110111			; row 3, the "2" key
	bne +
	ldy #1
	jmp toggle_enable

+	lda #%11111101			; column 1 low
	sta CIA1
	lda CIA1+$01

	cmp #%11111110			; row 0, the "3" key
	bne +
	ldy #2
	jmp toggle_enable

+	cmp #%11110111			; row 3, the "4" key
	bne no_valid_key
	ldy #3

toggle_enable
	lda track_current_enable_flags,y
	eor #$80
	sta track_current_enable_flags,y

	!ifndef c128 {
		bit enable_screen_on_playback
		bpl no_mute_ui
	}

	jsr viz_show_track_mute

no_mute_ui
	clc
	jsr set_volume

no_valid_key
	lda #0
rts


; =========================================================
; === fetch loop and mixer loop self-mod setup routines ===
; =========================================================

mixer_loop_segment_length = mixer_loop_close - mixer_loop_open

; SET-UP LOOKAHEAD INDEXES/ADDRESSES

; This routine just sets up where in the fetch loop the changes will be made

fetch_selfmods_init
	ldx seq_current_track

	ldy #8
	lda (ram_drv_fetch_addr_table_pointer),y ; fetch loop code segment length
	jsr multiply_8x8

	ldy #0
	lda (ram_drv_fetch_addr_table_pointer),y ; fetch loop open code address LSB
	clc
	adc product
	sta utility_pointer

	iny
	lda (ram_drv_fetch_addr_table_pointer),y ; MSB
	adc product+1
	sta utility_pointer+1
rts


; This sets the self-mod steprate adds in the fetch routine, which control
; each track's frequency, and sets the associated self-mods in the mixer so
; that the lookahead finds the right data.
;
; Always operates on the track number specified by seq_current_track

do_realtime_selfmods_for_pitch_change
	jsr fetch_selfmods_init

	ldx seq_current_track
	ldy #2
	lda (ram_drv_fetch_addr_table_pointer),y ; current steprate fract offs
	tay
	lda current_steprates_fracts,x
	sta (utility_pointer),y

	ldy #3
	lda (ram_drv_fetch_addr_table_pointer),y ; current steprate int offs
	tay
	lda current_steprates_ints,x
	sta (utility_pointer),y

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

		ldx lookahead_code_read_byte_addr_idx,y

		clc
		lda seq_current_track
		adc #>sample_data_buffer

		!for .idx4, 0, 15 {
			!set la_rd_addr_st = rd_la_track_1 + mixer_loop_segment_length * .idx4
			sta la_rd_addr_st + 2,x
		}

		!for .idx5, 0, 15 {

			!set la_rd_addr_st = rd_la_track_1 + mixer_loop_segment_length * .idx5

			lda utility_zpbk_counter+2
			sta la_rd_addr_st + 1,x

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

+	pha
	ldy #7
	lda (ram_drv_fetch_addr_table_pointer),y ; fetch length addr
	tay
	pla
	sta (utility_pointer),y

	!ifndef scpu {
		; it takes 4, 1 MHz cycles to start a fetch.
		; on C128, add 13, 1 MHz cycles to that for clock switching
		; (SEI:DEC $D030 + STY $D030:CLI)

		; we'll allow up to 20 cycles' ISR delay before the mixer has to stop
		; and wait.  too much more and it'll be audible.

		sec

		!ifndef c128 {
			sbc #16		; that is, add 4 cycles and subtract 20
		} else {
			sbc #3		; that is, add 17 and subtract 20
		}

		bcs +
		lda #1	; if the time is short enough, limit the timer check to one loop
	  +	sta isr_minimum_times_before_fetch,x
	}
rts


; This simply sets the three self-mod immediate compares that look for the
; end of the sample, in the fetch routine.
;
; Always operates on the track number specified by seq_current_track

do_realtime_selfmods_for_instrument_change
	jsr fetch_selfmods_init

	ldx seq_current_track
	ldy #4
	lda (ram_drv_fetch_addr_table_pointer),y ; sample pointer LSB end-check offs
	tay
	lda current_sample_end_addr_lows,x
	sta (utility_pointer),y

	ldy #5
	lda (ram_drv_fetch_addr_table_pointer),y ; end-check mid byte
	tay
	lda current_sample_end_addr_mids,x
	sta (utility_pointer),y

	ldy #6
	lda (ram_drv_fetch_addr_table_pointer),y ; end-check MSB
	tay
	lda current_sample_end_addr_highs,x
	sta (utility_pointer),y
rts

; the actual mixer and lookahead routine
; this is run just after each pass through the RAM driver's fetch routine

!ifndef scpu {
	mixer_cycle_count = 54
} else {
	mixer_cycle_count = 3
}

run_lookahead_and_mixer
	txa													; 2
	adc #16												; 2

-	ldy audio_out_buf_index								; 3
	cmp and_f0_table,y									; 4
	beq -												; 3/2

	mixer_loop_open
	  !for .idx2, 0, 15 {

		; the various `LDY $nnnn` below will have their addresses
		; re-written by the above set_lookahead_addrs routine.
		; Similarly, each corresponding `LDA/ADC $nnnn,Y` will
		; have its high byte re-written by the set_volume routine.
		;
		; the addresses below are arbitrary, chosen only so that they're
		; definitely in absolute mode when assembled, and so that failure
		; to alter one of them is easy to spot in the ML monitor at runtime.

		clc												; 2

		!if .idx2 = 0 { rd_la_track_1 = * }
		ldy $6100										; 4
		!if .idx2 = 0 { vol_addr_1 = * }
		lda $8100,y										; 4

		!if .idx2 = 0 { rd_la_track_4 = *}
		ldy $6400										; 4
		!if .idx2 = 0 { vol_addr_4 = *}
		adc $8400,y										; 4

		ror												; 2
		sta audio_buffer_left,x							; 5

		clc												; 2

		!if .idx2 = 0 { rd_la_track_2 = * }
		ldy $6200										; 4
		!if .idx2 = 0 { vol_addr_2 = * }
		lda $8200,y										; 4

		!if .idx2 = 0 { rd_la_track_3 = * }
		ldy $6300										; 4
		!if .idx2 = 0 { vol_addr_3 = * }
		adc $8300,y										; 4

		ror												; 2
		sta audio_buffer_right,x						; 5

		inx												; 2
	!if .idx2 = 0 { !set mixer_loop_close = * }
	}
rts

lookahead_code_read_byte_addr_idx
	!byte 0
	!byte rd_la_track_2 - rd_la_track_1
	!byte rd_la_track_3 - rd_la_track_1
	!byte rd_la_track_4 - rd_la_track_1

lookahead_code_volume_addr_idx
	!byte 0
	!byte vol_addr_2 - vol_addr_1
	!byte vol_addr_3 - vol_addr_1
	!byte vol_addr_4 - vol_addr_1
