; this file will hold the outline of the actual player

!text "player",0

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
		jsr print_msg

	-	bit SCPU_JD_TURBO_SWITCH
		bvs -

		lda #$80
		sta supercpu_turbo_available
	  +
	}

	!ifdef c128 {
		jsr gray_out

		clc
		jsr draw_medium_popup

		lda #0
		ldx #<main_player_now_playing_msg
		ldy #>main_player_now_playing_msg
		jsr print_msg

		lda #0
		ldx #<main_player_file_msg
		ldy #>main_player_file_msg
		jsr print_msg

		lda #0
		ldx #<current_file_name
		ldy #>current_file_name
		jsr print_msg

		lda #RETURN
		jsr CHROUT

		lda #0
		ldx #<main_player_title_msg
		ldy #>main_player_title_msg
		jsr print_msg

		lda #UPPER
		jsr CHROUT

		lda #0
		ldx #<current_file_title
		ldy #>current_file_title
		jsr print_msg_ascii

		lda #RETURN
		jsr CHROUT
		lda #LOWER
		jsr CHROUT

		jsr print_filetype

		lda #0
		ldx #<main_player_hline
		ldy #>main_player_hline
		jsr print_msg_rle

		lda #0
		ldx #<main_player_song_pos_pat_msg
		ldy #>main_player_song_pos_pat_msg
		jsr print_msg

		lda #0
		ldx #<main_player_row_speed_time
		ldy #>main_player_row_speed_time
		jsr print_msg

		lda #0
		ldx #<main_player_hline
		ldy #>main_player_hline
		jsr print_msg_rle

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
		jsr print_msg_rle

		lda #0
		ldx #<main_player_keys_msg
		ldy #>main_player_keys_msg
		jsr print_msg

	} else {
		bit enable_screen_on_playback
		bmi +
		jmp no_player_ui

	+	jsr gray_out_blur_out
		sec
		jsr draw_medium_popup
		lda #0
		ldx #<main_player_now_playing_msg_ascii
		ldy #>main_player_now_playing_msg_ascii
		jsr print_msg_ascii

		lda #0
		ldx #<main_player_file_msg_ascii
		ldy #>main_player_file_msg_ascii
		jsr print_msg_ascii

		lda #0
		ldx #<current_file_name
		ldy #>current_file_name
		jsr print_msg_ascii

		lda #RETURN
		jsr CHROUT

		lda #0
		ldx #<main_player_title_msg_ascii
		ldy #>main_player_title_msg_ascii
		jsr print_msg_ascii

		lda #0
		ldx #<current_file_title
		ldy #>current_file_title
		jsr print_msg_ascii

		lda #RETURN
		jsr CHROUT

		jsr print_filetype_ascii

		lda #0
		ldx #<main_player_hline_ascii
		ldy #>main_player_hline_ascii
		jsr print_msg_ascii

		lda #0
		ldx #<main_player_song_pos_pat_msg_ascii
		ldy #>main_player_song_pos_pat_msg_ascii
		jsr print_msg_ascii

		lda #0
		ldx #<main_player_row_speed_time_ascii
		ldy #>main_player_row_speed_time_ascii
		jsr print_msg_ascii

		lda #0
		ldx #<main_player_hline_ascii
		ldy #>main_player_hline_ascii
		jsr print_msg_ascii

		lda #DOWN
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT

		lda #0
		ldx #<main_player_hline_ascii
		ldy #>main_player_hline_ascii
		jsr print_msg_ascii

		lda #0
		ldx #<main_player_keys_msg_ascii
		ldy #>main_player_keys_msg_ascii
		jsr print_msg_ascii
	}

no_player_ui
	bit stereo_enable
	bpl +

	!ifdef scpu {
		sta SCPU_TURBO_OFF
	}

	!ifdef c128 {
		lda #0
		sta VIC_2_MHZ
	}

	jsr check_sid_type_right

	!ifdef scpu {
		sta SCPU_TURBO_ON
	}

	!ifdef c128 {
		inc VIC_2_MHZ
	}

+	lda audio_driver
	cmp #1
	bne ns4ip

	bit dither_enable
	bpl +

	jsr sid_4bit_dithered_driver_init
	jmp player_gen_tables

+	jsr sid_4bit_driver_init
	jmp player_gen_tables

ns4ip
	cmp #2
	bne nsmah
	jsr sid_mahoney_driver_init
	jmp player_gen_tables

nsmah
	jsr dac_driver_init

player_gen_tables
	+JSR_INDIRECT (ram_driver_set_cycle_counts_vec)
	+JSR_INDIRECT (audio_driver_set_cycle_count_vec)
	+JSR_INDIRECT (audio_set_resolution_vec)
	jsr isr_set_interval
	lda #$80
	sta allow_regen_msg

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
		}
	}

	jsr regen_all_tables

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
		jsr disable_screen
		jmp ++
	}

+	clc
	ldx #visualizer_screen_row
	ldy #visualizer_screen_column
	jsr PLOT

	jsr viz_row_data_init

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
		bit enable_screen_on_playback
		bmi +
		jsr set_normal_screen
		jsr enable_screen
		rts
	}

+	jsr clear_screen_early
	jsr set_normal_screen
rts

single_sample_player
	!ifndef c128 {
		jsr gray_out_blur_out
		sec
	} else {
		jsr gray_out
		clc
	}

	jsr draw_medium_popup

	!ifndef c128 {
		lda #0
		ldx #<sample_player_msg_ascii
		ldy #>sample_player_msg_ascii
		jsr print_msg_ascii
		jsr press_any_key_ascii
	} else {
		lda #0
		ldx #<sample_player_msg
		ldy #>sample_player_msg
		jsr print_msg
		jsr press_any_key
	}

	jsr clear_screen_early
	jsr set_normal_screen
rts
