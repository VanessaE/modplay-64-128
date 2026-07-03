; display the main menu

!ifndef c128 {
	menu_right_pane_base_addr = (VIC_SCREEN + 2*40 + 18)
	menu_right_pane_width = 21
	menu_right_pane_height = 15
}

show_main_menu
	lda #0
	sta playlist_iterate_mode
	sta playlist_pos_within_selection
	sta playlist_num_files_in_selection

	!ifdef c128 {
		jsr FULLW
	}

	lda #CLR
	jsr CHROUT

	!ifdef c128 {
		bit c128_vdc_has_64k
		bmi +
		jmp menu_full_redraw
	  +
	}

	bit main_menu_cache_is_valid
	bpl menu_full_redraw
	jsr retrieve_main_menu_from_cache_quick
	jmp main_loop

	; draw the main menu's outlines/boxes and title line

menu_full_redraw
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

	!ifdef c64u {
		lda #0
		bit c64u_detect
		bmi +

		ldx #<program_title_edition_u64
		ldy #>program_title_edition_u64
		jsr print_msg
		jmp ++

	+	lda #0
		ldx #<program_title_edition_c64u
		ldy #>program_title_edition_c64u
		jsr print_msg
	 ++
	}


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

	!ifndef c128 {
		ldy #0
		lda #$20
	-	!for .row, 2, 16 {
			sta VIC_SCREEN+.row*40+18,y
		}
		iny
		cpy #21
		bne -
	}

	jsr draw_menu_right_pane_contents

finish_menu
	bit initial_playlist_loaded
	bmi main_loop
	jsr load_directory
	lda #$80
	sta initial_playlist_loaded
	jmp show_main_menu

main_loop
	jsr get_menu_key
	; exit status:
	; .A = 0, do nothing
	;
	; otherwise, retrieve the cache and then....
	;
	; .A = 1, redraw the right pane
	; .A = 2, redraw the info box
	; .A = 3, redraw the playlist
	; .A = $80 or anything else = retrieve cache, use it immediately
	;
	; if no cache is available, all non-zero exits just trigger a fill redraw


	!ifndef c128 {
		beq main_loop
	} else {
		sta temp_abs_a
		bne +
		jsr set_window_menu_pane
		jmp main_loop

	+	jsr set_window_menu_pane
		bit c128_vdc_has_64k
		bmi +
		jmp show_main_menu
	+	lda temp_abs_a
	}

	cmp #1
	bne ++

	bit main_menu_cache_is_valid
	bpl +
	jmp main_loop

+	jsr retrieve_main_menu_from_cache_quick
	jsr draw_menu_right_pane_contents
	lda #0
	sta main_menu_cache_is_valid
	jmp main_loop

++	cmp #2
	bne ++

	jsr retrieve_main_menu_from_cache_quick
	jsr populate_info_box
	lda #0
	sta main_menu_cache_is_valid
	jmp main_loop

++	cmp #3
	bne ++

	jsr retrieve_main_menu_from_cache_quick
	jsr display_playlist
	lda #0
	sta main_menu_cache_is_valid
	jmp main_loop

++	jmp show_main_menu

rp_start = VIC_SCREEN+(2*40)+19

switch_pages
	inc current_menu_page
	lda current_menu_page
	cmp #3
	bne +
	lda #0
	sta current_menu_page
+	jsr draw_menu_right_pane_contents
	lda #0
	sta main_menu_cache_is_valid
rts

draw_menu_right_pane_contents
	!ifdef c128 {
		jsr set_window_menu_pane
	}

	jsr erase_menu_right_pane_contents

	lda current_menu_page
	bne +
	jsr draw_menu_page_a
	rts

+	cmp #1
	bne +
	jsr draw_menu_page_b
	rts

  +
jmp draw_menu_page_c


erase_menu_right_pane_contents
	!ifdef c128 {
		lda #CLR
		jsr CHROUT
	} else {
		ldx #<menu_right_pane_base_addr
		ldy #>menu_right_pane_base_addr
		lda #menu_right_pane_height
		sta erase_screen_area_row_count
		lda #menu_right_pane_width
		jsr vic_erase_screen_area
	}
rts

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

jmp show_repeat_mode

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

	!ifndef c128 {
		ldx #<menu_text_info_popup_b
		ldy #>menu_text_info_popup_b
		jsr print_menu_line
	}

jmp show_input_device


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

	lda #2
	cmp audio_driver	; carry will be clear if driver > 2

	ldx #<menu_text_stereo
	ldy #>menu_text_stereo
	jsr print_menu_line

	; display either SID or DAC address, if SID addr, only if stereo is on.
	lda audio_driver
	cmp #3
	bcs not_sid_menu

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

+	!ifdef badlines_exist {
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

	!ifdef badlines_exist {
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
jmp print_msg

!ifndef c128 {
	nfcol = 19

	ibr2col = 18

	ibtop = 20
	ibleft = 18
	ibwidth = 21
	ibheight = 3

	ib_top_left_addr = (VIC_SCREEN + ibtop*40 + ibleft)
} else {
	nfcol = 6

	ibr2col = 4

	ibtop = 0
	ibleft = 0
	ibwidth = 41
	ibheight = 3
}

populate_info_box
	!ifndef c128 {
		ldx #<ib_top_left_addr
		ldy #>ib_top_left_addr
		lda #ibheight
		sta erase_screen_area_row_count
		lda #ibwidth
		jsr vic_erase_screen_area
	} else {
		jsr set_window_infobox
		lda #CLR
		jsr CHROUT
	}

	lda current_file_type
	bne +

	ldx #ibtop+1
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
	ldx #ibtop
	ldy #ibleft
	jsr PLOT

	!ifdef c128 {
		ldx #<current_file_name
		ldy #>current_file_name
		jsr get_string_length

		tya
		clc
		adc #14 ; the length of the visible part of "Current file: "
		lsr
		sta temp_abs_a
		sec
		lda #ibwidth/2
		sbc temp_abs_a
		tay

		lda #RIGHT
	-	jsr CHROUT
		dey
		bne -

		lda #16
		ldx #<current_file_msg
		ldy #>current_file_msg
		sec
		jsr print_msg
	} else {
		lda #ibwidth
		ldx #<current_file_name
		ldy #>current_file_name
		jsr center_string
	}

	lda #CYAN
	jsr CHROUT

	lda #QUOTE
	jsr CHROUT

	lda #16
	ldx #<current_file_name
	ldy #>current_file_name
	sec
	jsr print_msg

	lda #QUOTE
	jsr CHROUT

	lda #RETURN
	jsr CHROUT

	clc
	ldx #ibtop+1
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
		ldx #ibtop+2
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
		ldx #ibtop+2
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
jmp print_msg

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
