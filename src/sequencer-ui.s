; ===========================
; === In-player UI stuff  ===
; ===========================

!ifndef c128 {
	print_nsp_target = VIC_SCREEN + 10*40 + 18
} else {
	print_nsp_target = VDC_SCREEN + 9*80 + 38
}

print_num_song_pos
	!ifdef badlines_exist {
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
	print_sp_target = VDC_SCREEN + 9*80 + 35
	print_pn_target = VDC_SCREEN + 9*80 + 53
}

print_song_pos_pat_num ; enter with .X = song position
	!ifdef badlines_exist {
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
	print_rn_target = VDC_SCREEN + 10*80 + 27
}

print_row_num
	!ifdef badlines_exist {
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
	print_sst_target = VDC_SCREEN + 10*80 + 39
	print_ssb_target = VDC_SCREEN + 10*80 + 42
}

print_song_speed
	!ifdef badlines_exist {
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

	lda #%11111110			; column 0 low
	sta CIA1_PORT_A
	lda CIA1_PORT_B
	cmp #%11110111			; look for row 3, F7 key
	bne +

.pui_abort_list
	lda #$80
	sta seq_abort_flag
	rts

+	lda #%01111111			; column 7 low
	sta CIA1_PORT_A
	lda CIA1_PORT_B
	cmp #%01111111			; loop for row 7, Run/Stop
	beq .pui_abort_list

	cmp #%11101111			; look for row 4, spacebar
	bne +
	lda #1
	sta seq_abort_flag
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
	!ifndef c128 {
		bne exit_player_keyscan
		ldy #3
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
		bne exit_player_keyscan
		jmp .pui_abort_list
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
		bpl exit_player_keyscan
	}

	lda visualizer_mode
	bne exit_player_keyscan
	jsr viz_row_data_show_track_mute

exit_player_keyscan
	lda #0
rts

