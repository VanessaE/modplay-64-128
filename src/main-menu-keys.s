get_menu_key
	jsr GETIN	; returns $0 if nothing is pressed/buf empty
	bne check_menu_key_up

	jsr check_com_key
	beq get_menu_key ; a zero exit means the C= key was not pressed

	jsr switch_pages
	!ifdef c128 {
		jsr set_window_playlist_pane
	}
		lda #$80
	rts

check_menu_key_up
	cmp #$91
	bne check_menu_key_down
	lda playlist_length
	beq check_menu_key_down
	jsr playlist_scroll_up
	lda #0
	rts

check_menu_key_down
	cmp #$11
	bne check_menu_key_p
	lda playlist_length
	beq check_menu_key_p
	jsr playlist_scroll_down
	lda #0
	rts

check_menu_key_p
	cmp #$50
	bne check_menu_key_return
	lda current_file_type
	beq check_menu_key_return
	jsr start_main_player
+	lda #1
	rts

check_menu_key_return
	cmp #$0d
	bne check_menu_key_f1
	lda playlist_length
	beq check_menu_key_f1
	jsr enqueue_file
	lda #0
	rts

check_menu_key_f1
	cmp #$85
	bne check_menu_key_f2
	lda playlist_length
	beq check_menu_key_f2
	clc
	jsr load_file_to_expansion
	lda current_file_type
	beq +
	jsr start_main_player
+	lda #1
	rts

check_menu_key_f2
	cmp #$89
	bne check_menu_key_f3
	lda playlist_length
	beq check_menu_key_f3
	clc
	lda #$80
	sta playlist_iterate_mode
	jsr playlist_iterate
+	lda #1
	rts

check_menu_key_f3
	cmp #$86
	bne check_menu_key_f4
	lda playlist_length
	beq check_menu_key_f4
	clc
	lda #0
	sta playlist_scroll_pos
	sta playlist_iterate_mode
	jsr playlist_iterate
+	lda #1
	rts

check_menu_key_f4
	cmp #$8a
	bne check_menu_key_f5
	!ifdef c128 {
		jsr set_window_menu_pane
	}
	jsr toggle_repeat
	lda #0
	rts

check_menu_key_f5
	cmp #$87
	bne check_menu_key_f6
	jsr load_directory
	lda #1
	rts

check_menu_key_f6
	cmp #$8b
	bne check_menu_key_f7
	lda #0
	ldx #0
-	sta playlist_file_flags,x
	inx
	cpx #192
	bne -
	jsr display_playlist
	lda #0
	rts

check_menu_key_f7
	cmp #$88
	bne check_menu_key_f8
	lda playlist_length
	beq check_menu_key_f8
	clc
	lda #0
	sta playlist_iterate_mode
	jsr playlist_iterate
+	lda #1
	rts

check_menu_key_f8
	cmp #$8c
	bne check_menu_key_home
	jmp RESET

; keys for page B start here

check_menu_key_home
	cmp #$13
	bne check_menu_key_clr
	lda playlist_length
	beq check_menu_key_clr
	lda playlist_scroll_pos
	beq check_menu_key_clr
	lda #0
	sta playlist_scroll_pos
	jsr display_playlist
	lda #0
	rts

check_menu_key_clr
	cmp #$93
	bne check_menu_key_minus
	lda playlist_length
	beq check_menu_key_minus
	sec
	lda playlist_length
	sbc #1
	cmp playlist_scroll_pos
	beq check_menu_key_minus
	sta playlist_scroll_pos
	jsr display_playlist
	lda #0
	rts

check_menu_key_minus
	cmp #$2d
	bne check_menu_key_plus
	lda playlist_length
	beq check_menu_key_plus
	jsr playlist_page_up
	lda #0
	rts

check_menu_key_plus
	cmp #$2b
	bne check_menu_key_l
	lda playlist_length
	beq check_menu_key_l
	jsr playlist_page_down
	lda #0
	rts

;check_menu_key_shift_p
;	cmp #$70
;	beq +
;	cmp #$d0
;	bne check_menu_key_l
;
;+	lda current_file_type
;	beq check_menu_key_l
;	jsr single_sample_player
;	lda #1
;	rts

check_menu_key_l
	cmp #$4c
	bne check_menu_key_shf_l
	lda playlist_length
	beq check_menu_key_shf_l
	clc
	jsr load_file_to_expansion
	lda #1
	rts

check_menu_key_shf_l
	cmp #$6c
	beq +
	cmp #$cc
	bne check_menu_key_number

+	jsr request_filename
	beq + ; if zero length filename, just abort
	sec
	jsr load_file_to_expansion
+	lda #1
	rts

check_menu_key_number
	cmp #$23
	bne check_menu_key_dollar
	!ifdef c128 {
		jsr set_window_menu_pane
	}
	jsr change_input_device
	lda #0
	rts

check_menu_key_dollar
	cmp #$24
	bne check_menu_key_at
	jsr show_directory
	lda #1
	rts

check_menu_key_at
	cmp #$40
	bne check_menu_key_i
	jsr request_dos_command
	lda #1
	rts

check_menu_key_i
	cmp #$49
	bne check_menu_key_d
	jsr show_system_info_popup
	lda #1
	rts

; keys for page C start here

check_menu_key_d
	cmp #$44
	bne check_menu_key_s
	jsr choose_audio_driver
	lda #1
	rts

check_menu_key_s
	cmp #$53
	bne check_menu_key_a
	!ifdef c128 {
		jsr set_window_menu_pane
	}

	jsr toggle_stereo_mode
	jsr show_stereo_mode

	lda current_menu_page
	cmp #2
	beq +
	lda #0
	rts
+	lda #$80
	rts

check_menu_key_a
	cmp #$41
	bne check_menu_key_f

	bit stereo_enable
	bpl +
	jsr change_audio_addr
+	lda #0
	rts

check_menu_key_f
	cmp #$46
	bne check_menu_key_t
	!ifdef c128 {
		jsr set_window_menu_pane
	}
	jsr change_filter_setting
	lda #0
	rts

check_menu_key_t
	cmp #$54
	bne check_menu_key_e

	!ifdef c128 {
		jsr set_window_menu_pane
	}

	lda audio_driver
	cmp #1
	bne +
	jsr change_dithering_setting
+	lda #0
	rts

check_menu_key_e
	!ifndef c128 {
		cmp #$45
		bne check_menu_key_leftarrow
		jsr toggle_screen_enable
		lda #$80
		rts
	}

check_menu_key_leftarrow
	cmp #$5f
	bne +
	jsr save_config
	lda #1
	rts

+	lda #0
rts
