; ===========================
; === In-player UI stuff  ===
; ===========================

!ifndef c128 {
	print_nsp_target = VIC_SCREEN + 9*40 + 16
} else {
	print_nsp_target = VDC_SCREEN + 9*80 + 34
}

print_num_song_pos
	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bpl .no_print_num_pos
	}

	lda #<print_nsp_target
	sta utility_pointer
	lda #>print_nsp_target
	sta utility_pointer+1
	ldx number_of_song_positions
	dex
	txa
	jsr display_byte_hex_direct

.no_print_num_pos
rts

!ifndef c128 {
	print_sp_target = VIC_SCREEN + 9*40 + 13
	print_pn_target = VIC_SCREEN + 9*40 + 25
} else {
	print_sp_target = VDC_SCREEN + 9*80 + 31
	print_pn_target = VDC_SCREEN + 9*80 + 44
}

print_song_pos_pat_num ; enter with .X = song position
	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bpl .no_print_pat_pos
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

.no_print_pat_pos
rts

!ifndef c128 {
	print_rn_target = VIC_SCREEN + 10*40 + 7
} else {
	print_rn_target = VDC_SCREEN + 10*80 + 27
}

print_row_num
	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bpl .no_print_row_num
	}

	lda #<print_rn_target
	sta utility_pointer
	lda #>print_rn_target
	sta utility_pointer+1
	lda seq_current_row
	jsr display_byte_hex_direct

.no_print_row_num
rts

!ifndef c128 {
	print_sst_target = VIC_SCREEN + 10*40 + 19
	print_ssb_target = VIC_SCREEN + 10*40 + 22
} else {
	print_sst_target = VDC_SCREEN + 10*80 + 39
	print_ssb_target = VDC_SCREEN + 10*80 + 42
}

print_song_speed
	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bpl .no_print_speed
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

.no_print_speed
rts

print_elapsed_time
	bit CIA1_TOD_HOURS; read hours to latch the time

	!ifndef c128 {

		print_et_target = VIC_SCREEN + 10*40 + 33

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
		print_et_target = VDC_SCREEN + 10*80 + 53

		+VDC_UPD_RDY_WAIT

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
		jsr vdc_write_ram

		txa
		and #$0f
		ora #$30
		jsr vdc_write_ram

		lda #":"
		jsr vdc_write_ram

		ldx CIA1_TOD_SECONDS
		lda divide_by_16_table,x
		ora #$30
		jsr vdc_write_ram

		txa
		and #$0f
		ora #$30
		jsr vdc_write_ram
	}

	bit CIA1_TOD_TENTHS; read tenths to un-latch the time
rts

!ifndef c128 {
	print_trks_target = VIC_SCREEN + 9*40 + 34
} else {
	print_trks_target = VDC_SCREEN + 9*80 + 56
}

print_track_count
	!ifndef c128 {
		lda current_active_tracks_count
		clc
		adc #$30
		sta print_trks_target
	} else {
		+VDC_UPD_RDY_WAIT

		lda #18
		sta VDC_ADDR
		lda #>print_trks_target
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<print_trks_target
		sta VDC_DATA

		lda #31
		sta VDC_ADDR

		lda current_active_tracks_count
		clc
		adc #$30

		jsr vdc_write_ram
	}
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

	!ifdef c128 {
		lda #%11111111		; all of columns K2-K0 high
		sta C128_EXTRA_KEYS
	}

	lda #%11110111			; column 3 low
	sta CIA1_PORT_A
	lda CIA1_PORT_B
	cmp #%01111111			; Look for row 7, the "V" key
	bne +
	lda visualizer_mode
	eor #$01
	sta visualizer_mode
	lda #$7f						; disable timer A interrupt, but leave the
	sta CIA2_ICR					; timer itself running, so that IT stays
									; in sync with the raster (if applicable)

	jsr player_ui_re_init

	lda #$81						; re-nable timer A interrupt
	sta CIA2_ICR

	jmp exit_player_keyscan

+	lda #%11011111			; column 5 low
	sta CIA1_PORT_A
	lda CIA1_PORT_B
	cmp #%11111101			; Look for row 1, the "P" key
	bne ++

	ldx current_song_pos
	beq +
	dex
	stx pos_jump_target_pattern
	pla						; discard return address
	pla
	jmp next_pattern

+	pla
	pla
	jmp start_sequencer		; special case: if already song pos 0, restart song

++	lda #%11101111			; column 4 low
	sta CIA1_PORT_A
	lda CIA1_PORT_B
	cmp #%01111111			; Look for row 7, the "N" key
	bne +

	lda #$ff
	sta pos_jump_target_pattern
	pla
	pla
	jmp next_pattern

+	lda #%11111110			; column 0 low
	sta CIA1_PORT_A
	lda CIA1_PORT_B
	cmp #%11110111			; look for row 3, F7 key (skip this song)
	bne +
	lda #1
	sta seq_abort_flag
	rts

+	lda #%01111111			; column 7 low
	sta CIA1_PORT_A
	lda CIA1_PORT_B
	cmp #%01111111			; loop for row 7, Run/Stop (abort whole playlist)
	bne +

.pui_abort_list
	lda #$80
	sta seq_abort_flag
	rts

+	cmp #%11101111			; look for row 4, spacebar (pause)
	bne +
	jmp pause_player

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
	!ifndef c128 {
		beq +
		jmp exit_player_keyscan

	+	ldy #3
		jmp toggle_enable_track
	} else {
		bne +
		ldy #3
		jmp toggle_enable_track

	+	lda #%11111111			; all regular columns high
		sta CIA1_PORT_A
		lda #%11111101			; column K1 low
		sta C128_EXTRA_KEYS
		lda CIA1_PORT_B
		cmp #%11111110			; Row 0, the "Esc" key
		beq .pui_abort_list
		jmp exit_player_keyscan
	}

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

++	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bmi +
		jmp exit_player_keyscan
	  +
	}

	lda visualizer_mode
	beq +
	jmp exit_player_keyscan

+	jsr viz_row_data_show_track_mute
	jmp exit_player_keyscan


pause_player
	lda #$7f						; disable timer A interrupt
	sta CIA2_ICR

	bit CIA1_TOD_HOURS				; we can't stop the TOD, so just save
	lda CIA1_TOD_MINUTES			; the elapsed M:S.t and restore it later
	sta TOD_clock_temps+2
	lda CIA1_TOD_SECONDS
	sta TOD_clock_temps+1
	lda CIA1_TOD_TENTHS
	sta TOD_clock_temps

	lda #0
	sta CIA1_TOD_HOURS
	sta CIA1_TOD_MINUTES
	sta CIA1_TOD_SECONDS
	sta CIA1_TOD_TENTHS

	lda #$80
	jsr fill_audio_buffers

	+JSR_INDIRECT (audio_stop_vec)

	jsr swap_zero_page				; KERNAL swap -> active, player -> swap
	jsr enable_kernal_only

	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bmi +
		lda #CLR
		jsr CHROUT
 		jsr enable_vic_screen
 	  +
	}

	sec
	lda #0
	ldx #<paused_msg
	ldy #>paused_msg
	jsr print_msg_rle

	jsr disable_roms
	jsr swap_zero_page				; player swap -> active, KERNAL -> swap

	lda #%11101111
-	cmp CIA1_PORT_B					; wait for user to release the spacebar
	beq -

	lda #2							; wait 0.2s, to debounce spacebar
-	cmp CIA1_TOD_TENTHS
	bne -

	lda #%11101111					; wait for user to tap the spacebar again
-	cmp CIA1_PORT_B
	bne -

-	cmp CIA1_PORT_B
	beq -

	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bmi +
 		jsr disable_vic_screen
 		jmp .pause_noviz2
 	  +
	}

	jsr player_ui_re_init

.pause_noviz2
	+JSR_INDIRECT (audio_start_vec)

	lda #$81						; enable timer A interrupt
	sta CIA2_ICR

	lda #0
	sta CIA1_TOD_HOURS
	lda TOD_clock_temps+2
	sta CIA1_TOD_MINUTES
	lda TOD_clock_temps+1
	sta CIA1_TOD_SECONDS
	lda TOD_clock_temps
	sta CIA1_TOD_TENTHS

exit_player_keyscan
	lda #0
rts

player_ui_re_init
	jsr visualizer_clear_area

	lda visualizer_mode
	beq +
	jsr viz_waveform_init
	jmp .player_ui_re_init_exit

+	jsr swap_zero_page				; KERNAL swap -> active, player -> swap
	jsr enable_kernal_only

	clc
	ldx #visualizer_screen_row
	ldy #visualizer_screen_column
	jsr PLOT

	jsr viz_row_data_init

	jsr disable_roms
	jsr swap_zero_page				; player swap -> active, KERNAL -> swap

	ldx current_song_pos
	ldy pattern_table,x

	ldx seq_current_row
	jsr viz_row_data_pattern_preload

	lda #<visualizer_line_6
	sta utility_pointer
	lda #>visualizer_line_6
	sta utility_pointer+1

	inx
	inx
	inx
	jsr viz_row_data_fetch_and_print
  .player_ui_re_init_exit
rts

