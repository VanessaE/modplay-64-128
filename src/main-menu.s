; display the main menu

!text "main menu",0

show_main_menu
	!ifdef c128 {				; restore screen/window dimensions
		jsr FULLW
		bit clear_menu_screen_flag
		bpl +
		lda #CLR
		jsr CHROUT
	+	lda #$80
		sta clear_menu_screen_flag
	}

	; draw the main menu's outlines/boxes and title line

	lda #0
	ldx #<program_title
	ldy #>program_title
	sec
	jsr print_msg

	lda #0
	ldx #<program_version
	ldy #>program_version
	sec
	jsr print_msg

	lda #0
	ldx #<program_title_b
	ldy #>program_title_b
	sec
	jsr print_msg

	ldy #0
	sty temp_abs_y
-	ldy temp_abs_y
	cpy #23
	beq +
	ldx mm_lo,y
	lda mm_hi,y
	tay
	lda #0
	sec
	jsr print_msg_rle
	inc temp_abs_y
	bne -

+	!ifndef c128 { ; restore the screen line links to 40 chars apiece.
		ldx #24
	-	lda screen_line_link_table,x
		sta LDTB1,x
		dex
		bpl -
	}

	jsr populate_info_box

	jsr display_disk_name
	jsr erase_playlist_pane
	jsr prefill_playlist_colors
	jsr display_playlist

redraw_menu
	!ifdef c128 {
		jsr set_window_menu_pane
		lda #CLR
		jsr CHROUT

	} else {
		ldy #0
		lda #$20
	-	!for .row, 2, 16 {
			sta VIC_SCREEN+.row*40+18,y
		}
		iny
		cpy #21
		bne -
	}

	lda current_menu_page
	bne +
	jsr draw_menu_page_a
	jmp finish_menu

+	cmp #1
	bne +
	jsr draw_menu_page_b
	jmp finish_menu

+	jsr draw_menu_page_c

finish_menu
	!ifdef c128 {
		jsr set_window_playlist_pane
	}

	bit initial_playlist_loaded
	bmi main_loop
	jsr load_directory
	lda #$80
	sta initial_playlist_loaded
	jmp show_main_menu

main_loop
-	jsr GETIN	; debounce in case of player exit via any key
	bne -		; common between both player UI and main menu

	jsr get_menu_key
	; exit status: .A = 0, do nothing; $80=just re-print/redraw
	; the menu text, anything else = show main menu from start

	beq main_loop
	bmi redraw_menu
	jmp show_main_menu

rp_start = VIC_SCREEN+(2*40)+19

switch_pages
	inc current_menu_page
	lda current_menu_page
	cmp #3
	bne +
	lda #0
	sta current_menu_page
+ rts

draw_menu_page_a
	!ifndef c128 {
		lda #0
		ldx #<prepend_top_margin
		ldy #>prepend_top_margin
		sec
		jsr print_msg
	}

	lda playlist_length ; 2 or more items required
	cmp #2
	; the carry will be clear if there's less than 2 items,
	; which is also the print-in-color (or not) flag.

	ldx #<menu_text_up_down
	ldy #>menu_text_up_down
	jsr print_menu_line
	jmp ++

++	clc
	lda playlist_length ; 1 or more items required
	beq +

	sec
+	ldx #<menu_text_load_and_play
	ldy #>menu_text_load_and_play
	jsr print_menu_line

++	clc
	lda current_file_type ; type 0 means nothing is loaded.
	beq +

	sec
+	ldx #<menu_text_play_loaded
	ldy #>menu_text_play_loaded
	jsr print_menu_line

	!ifndef c128 {
		ldx #<menu_text_play_loaded_b
		ldy #>menu_text_play_loaded_b
		jsr print_menu_line
	}

	lda playlist_length ; 1 or more items required
	cmp #1

	ldx #<menu_text_add_to_list
	ldy #>menu_text_add_to_list
	jsr print_menu_line

	ldx #<menu_text_play_list
	ldy #>menu_text_play_list
	jsr print_menu_line

	ldx #<menu_text_play_all
	ldy #>menu_text_play_all
	jsr print_menu_line

	sec
	ldx #<menu_text_repeat
	ldy #>menu_text_repeat
	jsr print_menu_line

	ldx #<menu_text_read_dir
	ldy #>menu_text_read_dir
	sec
	jsr print_menu_line

	!ifndef c128 {
		ldx #<menu_text_read_dir_b
		ldy #>menu_text_read_dir_b
		jsr print_menu_line
	}

	clc
	lda playlist_length ; 1 or more items required
	beq +

	sec
+	ldx #<menu_text_clear_playlist
	ldy #>menu_text_clear_playlist
	jsr print_menu_line

	lda playlist_length ; 1 or more items required
	cmp #1

	ldx #<menu_text_play_from_here
	ldy #>menu_text_play_from_here
	jsr print_menu_line

	!ifndef c128 {
		ldx #<menu_text_play_from_here_b
		ldy #>menu_text_play_from_here_b
		jsr print_menu_line
	}

	ldx #<menu_text_exit
	ldy #>menu_text_exit
	sec
	jsr print_menu_line

	jsr show_repeat_mode
rts

draw_menu_page_b
	!ifndef c128 {
		lda #0
		ldx #<prepend_top_margin
		ldy #>prepend_top_margin
		sec
		jsr print_msg
	}

	lda playlist_length ; 2 or more items required
	cmp #2

	ldx #<menu_txt_home_clr
	ldy #>menu_txt_home_clr
	jsr print_menu_line

	clc
	lda playlist_length ; 1 or more items required
	beq +

	sec
+	ldx #<menu_text_page_up_down
	ldy #>menu_text_page_up_down
	jsr print_menu_line

	clc
	lda playlist_length ; 1 or more items required
	beq +

	sec
+	ldx #<menu_text_load_only
	ldy #>menu_text_load_only
	jsr print_menu_line

	ldx #<menu_text_load_filename
	ldy #>menu_text_load_filename
	sec
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_load_filename_b
		ldy #>menu_text_load_filename_b
		jsr print_menu_line
	}

	ldx #<menu_text_device_number
	ldy #>menu_text_device_number
	sec
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_device_number_b
		ldy #>menu_text_device_number_b
		jsr print_menu_line
	}

	ldx #<menu_text_view_dir
	ldy #>menu_text_view_dir
	sec
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_view_dir_b
		ldy #>menu_text_view_dir_b
		jsr print_menu_line
	}

	ldx #<menu_text_dos_cmd
	ldy #>menu_text_dos_cmd
	sec
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_dos_cmd_b
		ldy #>menu_text_dos_cmd_b
		jsr print_menu_line
	}

	ldx #<menu_text_info_popup
	ldy #>menu_text_info_popup
	sec
	jsr print_menu_line

	jsr show_input_device
rts

draw_menu_page_c
	!ifndef c128 {
		lda #0
		ldx #<prepend_top_margin
		ldy #>prepend_top_margin
		sec
		jsr print_msg
	}

	ldx #<menu_text_audio_driver
	ldy #>menu_text_audio_driver
	sec
	jsr print_menu_line

	; display stereo mode
	ldx #<menu_text_stereo
	ldy #>menu_text_stereo
	sec
	jsr print_menu_line

	; display either SID or DAC address, if SID addr, only if stereo is on.
	lda audio_driver
	cmp #3
	beq not_sid_menu

	lda stereo_enable
	rol

	ldx #<menu_text_sid_addr
	ldy #>menu_text_sid_addr
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_sid_addr_b
		ldy #>menu_text_sid_addr_b
		jsr print_menu_line
	}
	jmp ++

not_sid_menu
	ldx #<menu_text_dac_addr
	ldy #>menu_text_dac_addr
	sec
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_dac_addr_b
		ldy #>menu_text_dac_addr_b
		jsr print_menu_line
	}

++	lda audio_driver
	cmp #1
	bne +

	ldx #<menu_text_dithering
	ldy #>menu_text_dithering
	sec
	jsr print_menu_line

+	!ifndef c128 {
		ldx #<menu_text_enable_screen
		ldy #>menu_text_enable_screen
		sec
		jsr print_menu_line

		ldx #<menu_text_enable_screen_b
		ldy #>menu_text_enable_screen_b
		jsr print_menu_line
	}

	ldx #<menu_text_enable_filter
	ldy #>menu_text_enable_filter
	sec
	jsr print_menu_line

	ldx #<menu_text_save_config
	ldy #>menu_text_save_config
	sec
	jsr print_menu_line

	jsr show_audio_driver
	jsr show_sid_addr
	jsr show_dac_addr
	jsr show_stereo_mode
	jsr show_filter_setting
	jsr show_dithering_setting
	!ifndef c128 {
		jsr show_screen_enable
	}
rts

print_menu_line
	php

	lda #DGRY
	jsr CHROUT

	plp

	!ifndef c128 {
		stx temp_abs_x
		sty temp_abs_y
		lda #0
		ldx #<prepend_right_margin
		ldy #>prepend_right_margin
		jsr print_msg_rle
		ldx temp_abs_x
		ldy temp_abs_y
	}
	jsr print_msg
rts

populate_info_box
	!ifndef c128 {
		ibr1col = 18
		ibr2col = 18
		ibrow = 20
		nfcol = 19
	} else {
		jsr set_window_infobox
		ibr1col = 6
		ibr2col = 4
		ibrow = 0
		nfcol = 6
	}

	lda current_file_type
	bne +

	ldx #ibrow+1
	ldy #nfcol
	clc
	jsr PLOT

	lda #0
	ldx #<no_file_loaded_msg
	ldy #>no_file_loaded_msg

	sec
	!ifndef c128 {
		jsr print_msg_rle
	} else {
		jsr print_msg
	}
	rts

+	clc
	ldx #ibrow
	ldy #ibr1col
	jsr PLOT

	!ifdef c128 {
		ldx #<current_file_msg
		ldy #>current_file_msg
		sec
		jsr print_msg
	}

	lda #CYAN
	jsr CHROUT

	lda #21
	ldx #<current_file_name
	ldy #>current_file_name
	jsr center_string

	lda #$22 ; quote
	jsr CHROUT

	lda #16
	ldx #<current_file_name
	ldy #>current_file_name
	sec
	jsr print_msg

	lda #$22 ; quote
	jsr CHROUT
	lda #$0d
	jsr CHROUT

	clc
	ldx #ibrow+1
	ldy #ibr2col
	jsr PLOT

	!ifdef c128 {
		lda #DCYN
		jsr CHROUT

		jsr print_filetype

		lda #0
		sec
		jsr print_msg
		lda #","
		jsr CHROUT
		lda #" "
		jsr CHROUT
	}

	lda #CYAN
	jsr CHROUT

	lda current_file_tracks
	jsr to_hex
	jsr CHROUT

	lda #0
	ldx #<current_file_tracks_msg
	ldy #>current_file_tracks_msg
	sec
	jsr print_msg

	lda current_file_type
	cmp #1
	bne +
	ldx #15
	bne ++

+	ldx #31
++	ldy #0
	sec
	jsr print_uint16

	lda #0
	ldx #<current_file_samples_msg
	ldy #>current_file_samples_msg
	sec
	jsr print_msg

	lda #CYAN
	jsr CHROUT

	!ifdef c128 {
		ldx current_file_size_in_kb
		ldy current_file_size_in_kb+1
		jsr get_num_length
		tya
		clc
		adc #33
		sta temp_abs_a
		sec
		lda #41
		sbc temp_abs_a
		lsr
		tay
		ldx #ibrow+2
		clc
		jsr PLOT

		clc
		ldx number_of_patterns
		ldy #0
		jsr uint16_to_string

		lda #0
		ldx #<(uint16_string_buffer+3) ; +3 to skip the empty sign byte
		ldy #>(uint16_string_buffer+3) ; and two of the leading zeroes
		sec
		jsr print_msg

		ldx #<current_file_patterns_msg
		ldy #>current_file_patterns_msg
		sec
		jsr print_msg
	} else {
		clc
		ldx #ibrow+2
		ldy #18 ; "ibr3col"
		jsr PLOT
	}

	lda #CYAN
	jsr CHROUT

	clc
	ldx number_of_song_positions
	ldy #0
	jsr uint16_to_string

	lda #0
	ldx #<(uint16_string_buffer+3) ; +3 to skip the empty sign byte
	ldy #>(uint16_string_buffer+3) ; and two of the leading zeroes
	sec
	jsr print_msg

	lda #0
	ldx #<current_file_song_pos_msg
	ldy #>current_file_song_pos_msg
	sec
	jsr print_msg

	sec
	ldx current_file_size_in_kb
	ldy current_file_size_in_kb+1
	jsr print_uint16

	!ifndef c128 { ; check if the number is 4 digits i.e. 1000+
		lda current_file_size_in_kb
		cmp #232
		lda current_file_size_in_kb+1
		sbc #3
		bcs +
		lda #" "
		jsr CHROUT
	}

+	lda #LBLU
	jsr CHROUT
	lda #0
	ldx #<kb_msg
	ldy #>kb_msg
	sec
	jsr print_msg
rts

print_filetype
	lda current_file_type
	cmp #1
	bne +
	ldx #<tracker_name_msg_soundtracker
	ldy #>tracker_name_msg_soundtracker
	jmp ++

+	cmp #4
	bcs +
	ldx #<tracker_name_msg_protracker
	ldy #>tracker_name_msg_protracker
	jmp ++

+	cmp #6
	bcs +
	ldx #<tracker_name_msg_startrekker
	ldy #>tracker_name_msg_startrekker
	jmp ++

+	ldx #<tracker_name_msg_fasttracker
	ldy #>tracker_name_msg_fasttracker
++ rts
