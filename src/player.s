; this file will hold the outline of the actual player

!text "player",0

start_main_player
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
		ldx #<main_player_row
		ldy #>main_player_row
		jsr print_msg

		lda #0
		ldx #<main_player_speed_msg
		ldy #>main_player_speed_msg
		jsr print_msg

		lda #0
		ldx #<main_player_hline
		ldy #>main_player_hline
		jsr print_msg_rle

	} else {
		bit enable_screen_on_playback
		bpl ++

		jsr gray_out_blur_out
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
		ldx #<main_player_row_ascii
		ldy #>main_player_row_ascii
		jsr print_msg_ascii

		lda #0
		ldx #<main_player_speed_msg_ascii
		ldy #>main_player_speed_msg_ascii
		jsr print_msg_ascii

		lda #0
		ldx #<main_player_hline_ascii
		ldy #>main_player_hline_ascii
		jsr print_msg_ascii
}

++	+JSR_INDIRECT (ram_driver_set_cycle_counts_vec)
	+JSR_INDIRECT (audio_driver_set_cycle_count_vec)
	+JSR_INDIRECT (audio_set_resolution_vec)
	jsr isr_set_interval
	lda #$80
	sta allow_regen_msg
	jsr regen_all_tables

	!ifndef c128 {
		bit enable_screen_on_playback
		bmi +
		jsr disable_screen
	}

+	php
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
		jsr switch_to_primary_screen
		jsr enable_screen
		rts
	}

+	jsr clear_primary_screen_early
	jsr switch_to_primary_screen
rts

single_sample_player
	php
	sei

	!ifdef c128 {
		jsr gray_out
		clc
	} else {
		jsr gray_out_blur_out
		sec
		jsr switch_to_secondary_screen
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

	jsr clear_primary_screen_early
	jsr switch_to_primary_screen
	plp
rts
