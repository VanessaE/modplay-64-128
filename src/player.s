; this file holds the "outline" of the actual player

start_main_player
	!ifdef scpu {
		bit SCPU_JD_TURBO_SWITCH
		bvc .scpu_turbo_sw_is_on

		clc
		jsr draw_mini_popup

		lda #0
		ldx #<turn_turbo_on_msg
		ldy #>turn_turbo_on_msg
		sec
		jsr print_msg

	-	bit SCPU_JD_TURBO_SWITCH
		bvs -

	.scpu_turbo_sw_is_on
		sta SCPU_TURBO_ON
		sta SCPU_ENABLE_HW_REGS

		!ifdef c128 {
			lda #%10000100				; disable all local RAM echoing
		} else {
			lda #%01000100				; optimize:  only echo $c000-$ffff to
		}

		sta SCPU_OPTIMIZATION_MODE	; local RAM
		sta SCPU_DISABLE_HW_REGS
	}

	jsr disable_roms

	jsr force_mono_if_no_second_sid
	jsr init_audio_driver
	jsr reu_set_selfmod_and_mixer_vectors

	!ifndef turbo_available {
		bit allow_regen_msg
		bpl +

		jsr enable_kernal_only
		jsr gray_out

		jsr draw_short_popup

		ldx #short_popup_top_row+1
		ldy #short_popup_left_column
		clc
		jsr PLOT

		lda #0
		ldx #<main_player_regen_tables_msg
		ldy #>main_player_regen_tables_msg
		sec
		jsr print_msg
	  +
	}

	jsr disable_roms
	jsr regenerate_tables_if_needed
	jsr enable_kernal_only

	!ifndef c128 {
		jsr set_alt_charset
	}

	lda #CLR
	jsr CHROUT

	!ifdef c128 {
		bit c128_vdc_has_64k
		bmi +
		jsr vdc_retrieve_player_bg_from_reu
		jmp .pnvdcc

	+	jsr vdc_copy_player_bg_from_cache

	  .pnvdcc
	} else {
		jsr vic_retrieve_player_bg_from_reu
	}

	!ifndef c128 {
		lda #0
		ldx #<player_popup_top_line
		ldy #>player_popup_top_line
		sec
		jsr print_msg_rle

		lda #0
		ldx #<player_popup_next_line
		ldy #>player_popup_next_line
		jsr print_msg_rle
	} else {
		jsr set_window_player_popup
		clc
		ldx #0
		ldy #0
		jsr PLOT
	}

	jsr print_now_playing_msg

	lda #0
	ldx #<main_player_file_msg
	ldy #>main_player_file_msg
	sec
	jsr print_msg

	lda #0
	ldx #<current_file_name
	ldy #>current_file_name
	sec
	jsr print_msg

	lda #RETURN
	jsr CHROUT

	lda #0
	ldx #<main_player_title_msg
	ldy #>main_player_title_msg
	sec
	jsr print_msg

	lda #0
	ldx #<current_file_title
	ldy #>current_file_title
	sec
	jsr print_msg_ascii

	lda #RETURN
	jsr CHROUT

	lda #0
	ldx #<main_player_hline
	ldy #>main_player_hline
	sec
	jsr print_msg

	lda #0
	ldx #<main_player_song_pos_pat_msg
	ldy #>main_player_song_pos_pat_msg
	sec
	jsr print_msg

	lda #0
	ldx #<main_player_row_speed_time
	ldy #>main_player_row_speed_time
	sec
	jsr print_msg

	lda #0
	ldx #<main_player_hline
	ldy #>main_player_hline
	sec
	jsr print_msg

	lda #DOWN
	jsr CHROUT
	jsr CHROUT
	jsr CHROUT
	jsr CHROUT
	jsr CHROUT
	jsr CHROUT

	lda #0
	ldx #<main_player_hline
	ldy #>main_player_hline
	sec
	jsr print_msg

	lda #0
	ldx #<main_player_keys_msg
	ldy #>main_player_keys_msg
	sec
	jsr print_msg

no_player_ui
	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bmi player_init_visualizer

		jsr disable_vic_screen
		jmp player_ui_finish
	}

player_init_visualizer
	!ifdef use_profiler {
		jsr profiler_setup
	}

	clc
	ldx #visualizer_screen_row
	ldy #visualizer_screen_column
	jsr PLOT

	lda visualizer_mode
	bne +

	jsr viz_row_data_init
	jmp player_ui_finish

+	jsr viz_waveform_init

player_ui_finish
	jsr isr_reset_timers_interrupts ; disables IRQ's and banks all ROMs out.

	jsr swap_zero_page				; KERNAL -> swap, don't care swap -> active
	jsr erase_zero_page				; wipe "active" ZP, hence don't care 😉

	jsr set_cia2_cra_default_val

	+JSR_INDIRECT (audio_start_vec)

	!ifndef use_profiler {
		jsr isr_startup
	}

	jsr start_sequencer

	!ifndef use_profiler {
		jsr isr_reset_timers_interrupts
	}

	!ifdef c128 {
		lda #36
		sta VDC_ADDR
		lda #0
		sta VDC_DATA
	}

	+JSR_INDIRECT (audio_stop_vec)

	jsr enable_kernal_only
	cli

	jsr keyboard_debounce
	jsr swap_zero_page ; KERNAL swap -> active, player/don't care -> swap

	jsr restore_stereo_enable

	; restore keyboard interrupt

+	sei
	!ifndef c128 {
		jsr enable_kernal_only
		jsr IOINIT
		jsr enable_kernal_only
	} else {
		lda #255
		sta VIC_RASTER_LOW
		lda VIC_CONTROL_A
		and #$7f
		sta VIC_CONTROL_A
		lda #$01
		sta VIC_IRQ_MASK
		jsr enable_kernal_only
	}
	cli

	jsr set_standard_charset

	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bmi +
		jsr enable_vic_screen
	 +
	}
rts
