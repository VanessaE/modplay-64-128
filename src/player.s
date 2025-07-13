; this file will hold the outline of the actual player

start_main_player
	!ifdef scpu {
		lda #0
		sta supercpu_turbo_available

		bit supercpu_detected
		bpl +

		bit SCPU_JD_TURBO_SWITCH
		bvc +

		clc
		jsr draw_mini_popup

		lda #0
		ldx #<turn_turbo_on_msg
		ldy #>turn_turbo_on_msg
		sec
		jsr print_msg

	-	bit SCPU_JD_TURBO_SWITCH
		bvs -

		lda #$80
		sta supercpu_turbo_available
	  +
	}

	!ifndef c128 {
		bit enable_screen_on_playback
		bmi +
		jmp no_player_ui

	+	jsr set_alt_charset
	}

	lda #CLR
	jsr CHROUT

	jsr retrieve_player_bg

	!ifndef c128 {
		lda #0
		ldx #<medium_popup_top_line
		ldy #>medium_popup_top_line
		sec
		jsr print_msg_rle

		lda #0
		ldx #<medium_popup_next_line
		ldy #>medium_popup_next_line
		jsr print_msg_rle
	} else {
		jsr set_window_medium_popup
		clc
		ldx #0
		ldy #0
		jsr PLOT
	}

	lda #0
	ldx #<main_player_now_playing_msg
	ldy #>main_player_now_playing_msg
	sec
	jsr print_msg

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
	!ifndef c128 {
		!ifdef scpu {
			bit SCPU_PRESENT
			bmi +

			sta SCPU_TURBO_ON
			sta SCPU_ENABLE_HW_REGS
			lda #%10000100					; disable all local RAM echoing
			sta SCPU_OPTIMIZATION_MODE
			sta SCPU_DISABLE_HW_REGS
		  +
		} else {
			lda #$80
			sta allow_regen_msg
		}
	}

	jsr init_audio_driver
	jsr reu_set_selfmod_and_mixer_vectors
	jsr regenerate_tables_if_needed

	!ifndef c128 {
		!ifdef scpu {
			bit SCPU_PRESENT
			bmi +

			sta SCPU_TURBO_ON
			sta SCPU_ENABLE_HW_REGS
			lda #%01000100				; optimize:  only echo $c000-$ffff to
			sta SCPU_OPTIMIZATION_MODE	; local RAM
			sta SCPU_DISABLE_HW_REGS
		  +
		}
	}

	!ifndef c128 {
		bit enable_screen_on_playback
		bmi +
		jsr disable_vic_screen
		jmp ++
	}

+	clc
	ldx #visualizer_screen_row
	ldy #visualizer_screen_column
	jsr PLOT

	lda visualizer_mode
	bne +

	jsr viz_row_data_init
	jmp ++

+	jsr viz_waveform_init

++	php
	sei
	jsr disable_roms

	jsr backup_zero_page

	+JSR_INDIRECT (audio_start_vec)
	jsr isr_startup

	jsr start_sequencer

	jsr isr_shutdown
	+JSR_INDIRECT (audio_stop_vec)

	jsr restore_zero_page
	jsr enable_kernal_only
	plp

	!ifndef c128 {
		jsr set_standard_charset
		bit enable_screen_on_playback
		bmi +
		jsr enable_vic_screen
	  +
	}
rts

init_audio_driver
	lda audio_driver
	cmp #3
	bne +
	jsr dac_driver_init
	rts

+	cmp #2
	bne +
	jsr sid_mahoney_driver_init
	rts

+	bit dither_enable
	bpl +

	jsr sid_4bit_dithered_driver_init
	rts

+	jsr sid_4bit_driver_init
rts
