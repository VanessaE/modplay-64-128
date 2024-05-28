; display the main menu

!text "main menu",0

show_main_menu
	!ifdef c128 {				; restore screen/window dimensions
		jsr set_window_full_screen
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
	jsr print_msg

	+PRINT_MSG_BATCH_RLE 23, mm_lo, mm_hi

	!ifndef c128 { ; restore the screen line links to 40 chars apiece.
		ldx #24
	-	lda screen_line_link_table,x
		sta LDTB1,x
		dex
		bpl -
	}

	jsr populate_info_box
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

main_loop
	jsr GETIN	; returns $0 if nothing is pressed/buf empty
	bne chk_key_up

	jsr check_com_key
	beq main_loop ; a zero exit means the C= key was not pressed

	jsr switch_pages
	!ifdef c128 {
		jsr set_window_playlist_pane
	}
	jmp redraw_menu

chk_key_up
	cmp #$91
	bne chk_key_down
	lda playlist_length
	beq chk_key_down
	jsr playlist_scroll_up
	jmp main_loop

chk_key_down
	cmp #$11
	bne chk_key_p
	lda playlist_length
	beq chk_key_p
	jsr playlist_scroll_down
	jmp main_loop

chk_key_p
	cmp #$50
	bne chk_key_return
	lda current_file_type
	beq chk_key_return
	jsr start_main_player
+	jmp show_main_menu

chk_key_return
	cmp #$0d
	bne chk_key_f4
	lda playlist_length
	beq chk_key_f4
	jsr enqueue_file
	jmp main_loop

chk_key_f4
	cmp #$8a
	bne chk_key_f5
	lda playlist_length
	beq chk_key_f5
	!ifdef c128 {
		jsr set_window_menu_pane
	}
	jsr toggle_repeat
	jmp main_loop

chk_key_f5
	cmp #$87
	bne chk_key_home
	jsr load_directory
	jmp show_main_menu

; keys for page B start here

chk_key_home
	cmp #$13
	bne chk_key_clr
	lda playlist_length
	beq chk_key_clr
	lda playlist_scroll_pos
	beq chk_key_clr
	lda #0
	sta playlist_scroll_pos
	jsr display_playlist
	jmp main_loop

chk_key_clr
	cmp #$93
	bne chk_key_minus
	lda playlist_length
	beq chk_key_minus
	sec
	lda playlist_length
	sbc #1
	cmp playlist_scroll_pos
	beq chk_key_minus
	sta playlist_scroll_pos
	jsr display_playlist
	jmp main_loop

chk_key_minus
	cmp #$2d
	bne chk_key_plus
	lda playlist_length
	beq chk_key_plus
	jsr playlist_page_up
	jmp main_loop

chk_key_plus
	cmp #$2b
	bne chk_key_shift_p
	lda playlist_length
	beq chk_key_shift_p
	jsr playlist_page_down
	jmp main_loop

chk_key_shift_p
	cmp #$70
	beq +
	cmp #$d0
	bne chk_key_l

+	lda current_file_type
	beq chk_key_l
	jsr single_sample_player
	jmp show_main_menu

chk_key_l
	cmp #$4c
	bne chk_key_shf_l
	lda playlist_length
	beq chk_key_shf_l
	clc
	jsr load_file_to_expansion
	jmp show_main_menu

chk_key_shf_l
	cmp #$6c
	beq +
	cmp #$cc
	bne chk_key_number

+	jsr request_filename
	beq + ; if zero length filename, just abort
	sec
	jsr load_file_to_expansion
+	jmp show_main_menu

chk_key_number
	cmp #$23
	bne chk_key_dollar
	!ifdef c128 {
		jsr set_window_menu_pane
	}
	jsr change_input_device
	jmp main_loop

chk_key_dollar
	cmp #$24
	bne chk_key_d
	jsr show_directory
	jmp show_main_menu


; keys for page C start here

chk_key_d
	cmp #$44
	bne chk_key_m
	jsr choose_audio_driver
	jmp show_main_menu

chk_key_m
	cmp #$4d
	bne chk_key_s
	jsr choose_memory_driver
	jmp show_main_menu

chk_key_s
	cmp #$53
	bne chk_key_a
	!ifdef c128 {
		jsr set_window_menu_pane
	}
	jsr toggle_stereo_mode

	lda audio_driver
	cmp #5
	beq +
	cmp #6
	beq +
	jmp redraw_menu

+	jsr show_stereo_mode
	jmp main_loop

chk_key_a
	cmp #$41
	bne chk_key_f
	jsr change_audio_addr
	jmp main_loop

chk_key_f
	cmp #$46
	bne chk_key_r
	!ifdef c128 {
		jsr set_window_menu_pane
	}
	jsr change_filter_setting
	jmp main_loop

chk_key_r
	cmp #$52
	bne chk_key_e
	!ifdef c128 {
		jsr set_window_menu_pane
	}
	jsr change_resonance_setting
	jmp main_loop

chk_key_e
	!ifndef c128 {
		cmp #$45
		bne chk_key_leftarrow
		jsr toggle_screen_enable
		jmp main_loop
	}

chk_key_leftarrow
	cmp #$5f
	bne chk_key_at
	jsr save_config
	jmp show_main_menu

chk_key_at
	cmp #$40
	bne invalid_key
	jsr request_dos_command
	jmp show_main_menu

invalid_key
	jmp main_loop

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
		jsr print_msg
	}

	lda playlist_length ; 2 or more items required
	sec
	cmp #2
	bcc +

	ldx #<menu_text_up_down
	ldy #>menu_text_up_down
	jsr print_menu_line
	jmp ++

+	ldx #<menu_text_up_down_gray
	ldy #>menu_text_up_down_gray
	jsr print_menu_line

++	lda playlist_length ; 1 or more items required
	beq +

	ldx #<menu_text_load_and_play
	ldy #>menu_text_load_and_play
	jsr print_menu_line
	jmp ++

+	ldx #<menu_text_load_gray
	ldy #>menu_text_load_gray
	jsr print_menu_line

++	lda current_file_type ; type 0 means nothing is loaded.
	beq +

	ldx #<menu_text_play_loaded
	ldy #>menu_text_play_loaded
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_play_loaded_b
		ldy #>menu_text_play_loaded_b
		jsr print_menu_line
	}
	jmp ++

+	ldx #<menu_text_play_loaded_gray
	ldy #>menu_text_play_loaded_gray
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_play_loaded_gray_b
		ldy #>menu_text_play_loaded_gray_b
		jsr print_menu_line
	}

++	lda playlist_length ; 1 or more items required
	beq +

	ldx #<menu_text_add_to_list
	ldy #>menu_text_add_to_list
	jsr print_menu_line

	ldx #<menu_text_play_list
	ldy #>menu_text_play_list
	jsr print_menu_line

	ldx #<menu_text_play_all
	ldy #>menu_text_play_all
	jsr print_menu_line
	jmp ++

+	ldx #<menu_text_add_to_list_gray
	ldy #>menu_text_add_to_list_gray
	jsr print_menu_line

	ldx #<menu_text_play_list_gray
	ldy #>menu_text_play_list_gray
	jsr print_menu_line

	ldx #<menu_text_play_all_gray
	ldy #>menu_text_play_all_gray
	jsr print_menu_line

++	lda playlist_length ; 1 or more items required
	beq +

	ldx #<menu_text_repeat
	ldy #>menu_text_repeat
	jsr print_menu_line
	jmp ++

+	ldx #<menu_text_repeat_gray
	ldy #>menu_text_repeat_gray
	jsr print_menu_line

++	ldx #<menu_text_read_dir
	ldy #>menu_text_read_dir
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_read_dir_b
		ldy #>menu_text_read_dir_b
		jsr print_menu_line
	}

	lda playlist_length ; 1 or more items required
	beq +

	ldx #<menu_text_clear_playlist
	ldy #>menu_text_clear_playlist
	jsr print_menu_line
	jmp ++

+	ldx #<menu_text_clear_playlist_gray
	ldy #>menu_text_clear_playlist_gray
	jsr print_menu_line

++	lda playlist_length ;  2 or more items required
	sec
	cmp #2
	bcc +

	ldx #<menu_text_play_from_here
	ldy #>menu_text_play_from_here
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_play_from_here_b
		ldy #>menu_text_play_from_here_b
		jsr print_menu_line
	}
	jmp ++

+	ldx #<menu_text_play_from_here_gray
	ldy #>menu_text_play_from_here_gray
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_play_from_here_gray_b
		ldy #>menu_text_play_from_here_gray_b
		jsr print_menu_line
	}

++	ldx #<menu_text_exit
	ldy #>menu_text_exit
	jsr print_menu_line

	jsr show_repeat_mode
rts

draw_menu_page_b
	!ifndef c128 {
		lda #0
		ldx #<prepend_top_margin
		ldy #>prepend_top_margin
		jsr print_msg
	}

	lda playlist_length ; 2 or more items required
	sec
	cmp #2
	bcc +

	ldx #<menu_txt_home_clr
	ldy #>menu_txt_home_clr
	jsr print_menu_line
	jmp ++

+	ldx #<menu_txt_home_clr_gray
	ldy #>menu_txt_home_clr_gray
	jsr print_menu_line

++	lda playlist_length ; 1 or more items required
	beq +

	ldx #<menu_text_page_up_down
	ldy #>menu_text_page_up_down
	jsr print_menu_line
	jmp ++

+	ldx #<menu_text_page_up_down_gray
	ldy #>menu_text_page_up_down_gray
	jsr print_menu_line

++	lda playlist_length ; 1 or more items required
	beq +

	ldx #<menu_text_load_only
	ldy #>menu_text_load_only
	jsr print_menu_line
	jmp ++

+	ldx #<menu_text_load_only_gray
	ldy #>menu_text_load_only_gray
	jsr print_menu_line

++	ldx #<menu_text_load_filename
	ldy #>menu_text_load_filename
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_load_filename_b
		ldy #>menu_text_load_filename_b
		jsr print_menu_line
	}

	lda current_file_type ; type 0 means nothing is loaded.
	beq +

	ldx #<menu_text_sample_mode
	ldy #>menu_text_sample_mode
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_sample_mode_b
		ldy #>menu_text_sample_mode_b
		jsr print_menu_line
	}
	jmp ++

+	ldx #<menu_text_sample_mode_gray
	ldy #>menu_text_sample_mode_gray
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_sample_mode_gray_b
		ldy #>menu_text_sample_mode_gray_b
		jsr print_menu_line
	}

++	ldx #<menu_text_device_number
	ldy #>menu_text_device_number
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_device_number_b
		ldy #>menu_text_device_number_b
		jsr print_menu_line
	}

	ldx #<menu_text_view_dir
	ldy #>menu_text_view_dir
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_view_dir_b
		ldy #>menu_text_view_dir_b
		jsr print_menu_line
	}

	ldx #<menu_text_dos_cmd
	ldy #>menu_text_dos_cmd
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_dos_cmd_b
		ldy #>menu_text_dos_cmd_b
		jsr print_menu_line
	}

	jsr show_input_device
rts

draw_menu_page_c
	!ifndef c128 {
		lda #0
		ldx #<prepend_top_margin
		ldy #>prepend_top_margin
		jsr print_msg
	}

	ldx #<menu_text_audio_driver
	ldy #>menu_text_audio_driver
	jsr print_menu_line

	ldx #<menu_text_ram_driver
	ldy #>menu_text_ram_driver
	jsr print_menu_line

	; display stereo mode
	ldx #<menu_text_stereo
	ldy #>menu_text_stereo
	jsr print_menu_line

	; display either SID or DAC address, if SID addr, only if stereo is on.
	sec
	lda audio_driver
	cmp #5
	bpl .not_sid_menu

	bit stereo_enable
	bpl +

	ldx #<menu_text_sid_addr
	ldy #>menu_text_sid_addr
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_sid_addr_b
		ldy #>menu_text_sid_addr_b
		jsr print_menu_line
	}
	jmp ++

+	ldx #<menu_text_sid_addr_gray
	ldy #>menu_text_sid_addr_gray
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_sid_addr_gray_b
		ldy #>menu_text_sid_addr_gray_b
		jsr print_menu_line
	}
	jmp ++

.not_sid_menu
	cmp #5
	beq +
	cmp #6
	beq +
	jmp ++

+	ldx #<menu_text_dac_addr
	ldy #>menu_text_dac_addr
	jsr print_menu_line
	!ifndef c128 {
		ldx #<menu_text_dac_addr_b
		ldy #>menu_text_dac_addr_b
		jsr print_menu_line
	}

	; display filter and resonance or not
++	lda audio_driver
	cmp #3
	beq +
	cmp #4
	beq +
	jmp ++

+	ldx #<menu_text_filter
	ldy #>menu_text_filter
	jsr print_menu_line

	ldx #<menu_text_resonance
	ldy #>menu_text_resonance
	jsr print_menu_line

	!ifndef c128 {
	++	ldx #<menu_text_enable_screen
		ldy #>menu_text_enable_screen
		jsr print_menu_line
		
		ldx #<menu_text_enable_screen_b
		ldy #>menu_text_enable_screen_b
		jsr print_menu_line
	}

	; display "save config"
++	ldx #<menu_text_save_config
	ldy #>menu_text_save_config
	jsr print_menu_line

	jsr show_audio_driver
	jsr show_ram_driver
	jsr show_sid_addr
	jsr show_dac_addr
	jsr show_stereo_mode
	jsr show_filter_setting
	jsr show_resonance_setting
	!ifndef c128 {
		jsr show_screen_enable
	}
rts

print_menu_line
	!ifndef c128 {
		stx tempzp_d
		sty tempzp_d+1
		lda #0
		ldx #<prepend_right_margin
		ldy #>prepend_right_margin
		jsr print_msg_rle
		ldx tempzp_d
		ldy tempzp_d+1
	}
	lda #0
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

		sec
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

		ldx #<tracker_name_msg_fasttracker
		ldy #>tracker_name_msg_fasttracker

	++	lda #0
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
		sta tempzp_c
		sec
		lda #41
		sbc tempzp_c
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
		jsr print_msg

		ldx #<current_file_patterns_msg
		ldy #>current_file_patterns_msg
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
	jsr print_msg

	lda #0
	ldx #<current_file_song_pos_msg
	ldy #>current_file_song_pos_msg
	jsr print_msg

	sec
	ldx current_file_size_in_kb
	ldy current_file_size_in_kb+1
	jsr print_uint16

	!ifndef c128 { ; check if the number is 4 digits i.e. 1000+
		sec
		lda current_file_size_in_kb
		cmp #232
		lda current_file_size_in_kb+1
		cmp #3
		bcs +
		lda #" "
		jsr CHROUT
	}

+	lda #LBLU
	jsr CHROUT
	lda #0
	ldx #<kb_msg
	ldy #>kb_msg
	jsr print_msg
rts
