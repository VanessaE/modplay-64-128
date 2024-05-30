; this file will hold the outline of the actual player

!text "player",0

start_main_player
	!ifdef c128 {
		jsr gray_out_blur_out

		clc
		jsr draw_medium_popup
		lda #0
		ldx #<music_player_msg
		ldy #>music_player_msg
		jsr print_msg

	} else {
		bit enable_screen_on_playback
		bmi +
		jsr disable_screen

		clc
		jsr draw_mini_popup
		lda #0
		ldx #<between_songs_msg
		ldy #>between_songs_msg
		jsr print_msg_rle
		jmp ++

	+	jsr gray_out_blur_out

		sec
		jsr draw_medium_popup
	}

++	php
	sei
	jsr disable_roms
	jsr backup_zero_page

	ldy #0
	lda #$80
-	sta audio_buffer_left,y
	sta audio_buffer_right,y
	iny
	bne -

	+JSR_INDIRECT (mixer_set_timings_vec)
	+JSR_INDIRECT (audio_resolution_vec)
	jsr generate_volume_tables ; will only regenerate if needed

	jsr isr_startup

	jsr start_sequencer

	jsr isr_shutdown
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
	jsr gray_out_blur_out
	jsr switch_to_secondary_screen

	!ifdef c128 {
		clc
	} else {
		sec
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

