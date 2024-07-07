; this file loads the current directory into memory as a set of "arrays"
; for, and manages most aspects of the main menu playlist.

!text "playlist",0

!ifndef c128 {
	playlist_top_row			= 3
	playlist_bottom_row			= 19
	playlist_left_column		= 1
	playlist_width				= 16
	dirname_row					= 2
	dirname_col					= 1
	file_list_number_row		= 14
	file_list_number_column		= 22

	playlist_pane_base_addr = VIC_SCREEN + 3*40 + 1

} else {
	playlist_top_row			= 0
	playlist_bottom_row			= 18
	playlist_left_column		= 1
	playlist_width				= 26
	dirname_row					= 2
	dirname_col					= 9
	file_list_number_row		= 3
	file_list_number_column		= 17
	file_sizes_column			= 21

	playlist_pane_base_addr = VDC_SCREEN + 3*80 + 5

}

playlist_pane_height = playlist_bottom_row - playlist_top_row + 1
playlist_bottom_row_addr = playlist_pane_base_addr + (playlist_pane_height - 1)*screen_width

playlist_half_page_size = (playlist_pane_height - 1) / 2
playlist_middle_row = (playlist_bottom_row + playlist_top_row) / 2

load_directory
	lda #<playlist_filenames
	sta load_pointer
	lda #>playlist_filenames
	sta load_pointer+1

	lda #0
	sta playlist_length

	jsr dir_open
	jsr .err

	jsr gray_out
	clc
	jsr draw_mini_popup

	lda #0
	ldx #<scanning_dir_msg
	ldy #>scanning_dir_msg
	jsr print_msg

	jsr erase_file_list

	jsr CHRIN				; get/ignore the first six bytes
	jsr CHRIN
	jsr CHRIN
	jsr CHRIN
	jsr CHRIN
	jsr CHRIN

	jsr dir_read_line		; read dir name
	jsr dir_file_unquote

	ldy #32
+	ldx #0
-	lda string_buffer,y
	sta current_dir_name,x
	inx
	iny
	cpx #16
	bne -

	ldx #16					; zero-out the trailing spaces.
-	lda current_dir_name,x
	beq +
	cmp #$20
	bne .next_entry
	lda #0
	sta current_dir_name,x
+	dex
	bpl -

.next_entry
-	jsr CHRIN				; skip first two bytes of each dir entry
	jsr CHRIN
	jsr .err				; check for EOF/err

.read_size
	ldy playlist_length

	jsr CHRIN				; size LSB
	sta playlist_file_sizes_lows,y
	jsr CHRIN				; size MSB
	sta playlist_file_sizes_highs,y

.selected_flag				; always 1 to start :P
	lda #1
	sta playlist_file_flags,y

.filename
	jsr dir_read_line
	jsr dir_file_unquote
	bcs .next_entry			; carry set = no valid filename in the buffer

	ldx #32					; otherwise, accept it
	ldy #0
-	lda string_buffer,x
	sta (load_pointer),y
	inx
	iny
	cpy #16
	bne -

.more_files
	ldy playlist_length
	lda playlist_file_sizes_lows,y
	cmp #7					; discard any file less than 7 disk blocks long,
	bcc .next_entry			; it's all but impossible for a MOD to be that small.

	inc playlist_length
	lda playlist_length
	cmp #193				; end of list space?
	beq .fin

	clc
	lda load_pointer
	adc #16
	sta load_pointer
	bcc +
	inc load_pointer+1

+	clc
	ldx #file_list_number_row
	ldy #file_list_number_column
	jsr PLOT

	sec
	ldx playlist_length
	ldy #0
	jsr print_uint16
	jmp .next_entry

.err
	lda STATUS
	bne +
	rts
+	pla						; pull the last return, exit directly from here
	pla						; if there was an error

.fin
	jsr close_file

	!ifdef c128 {
		lda #0
		sta clear_menu_screen_flag
		ldx #mini_popup_height
		ldy #mini_popup_width
		jsr erase_popup
	}
rts

; display the loaded file list in the left pane

display_playlist
	lda playlist_length
	bne +

	!ifdef c128 {
		jsr set_window_playlist_pane
	}

	jsr erase_playlist_pane

	!ifdef c128 {
		clc
		ldx #playlist_middle_row
		ldy #playlist_left_column+2
		jsr PLOT
	}

	lda #0
	ldx #<no_list_loaded_msg
	ldy #>no_list_loaded_msg
	!ifndef c128 {
		jsr print_msg_rle
	} else {
		jsr print_msg
	}
	rts

+	!ifdef c128 {
		jsr set_window_full_screen
	}

	clc
	ldx #dirname_row
	ldy #dirname_col
	jsr PLOT

	lda #0
	ldx #<dirname_background
	ldy #>dirname_background
	jsr print_msg_rle

	lda #16
	ldx #<current_dir_name
	ldy #>current_dir_name
	jsr center_string

	lda #16
	ldx #<current_dir_name
	ldy #>current_dir_name
	jsr print_msg

	!ifdef c128 {
		jsr set_window_playlist_pane
	}

	jsr erase_playlist_pane

	lda #RVSOFF
	jsr CHROUT

	sec
	lda #playlist_half_page_size
	sbc playlist_scroll_pos
	bcc +
	lda #0
	sta playlist_print_file_counter
	lda #playlist_middle_row
	sbc playlist_scroll_pos
	bcs ++

+	sec
	lda playlist_scroll_pos
	sbc #playlist_half_page_size
	sta playlist_print_file_counter
	lda #playlist_top_row

++	sta screen_row_to_print_at
	lda #BLK	 ; hide the list initially, until the colors are painted in
	jsr CHROUT

.pl_print_lp
	ldx screen_row_to_print_at
	ldy #playlist_left_column
	clc
	jsr PLOT

	ldx playlist_print_file_counter
	lda playlist_file_flags,x
	bpl +

	lda #RVSON
	jsr CHROUT

	!ifdef c128 {
		lda #0
		ldx #<playlist_filename_background
		ldy #>playlist_filename_background
		jsr print_msg_rle
	}

+	ldx playlist_print_file_counter
	jsr calc_filename_address
	lda #16
	jsr print_msg

	!ifdef c128 {
		ldx playlist_print_file_counter
		ldy screen_row_to_print_at
		jsr append_file_size
	}

	lda #RVSOFF
	jsr CHROUT

	inc playlist_print_file_counter
	inc screen_row_to_print_at

	lda #playlist_bottom_row
	cmp screen_row_to_print_at
	bcc +

	lda playlist_length
	cmp playlist_print_file_counter
	beq +
	bne .pl_print_lp

+	!ifndef c128 {
		jsr show_file_size ; on C64 this prints the size at the bottom of the list
	}

	jsr fill_playlist_colors
rts

; NOTE:  "up" or "down" in these subroutines refer to the playlist pane's
; movement within the list, not the direction the text moves on the screen!
; (that is, the text shifts up to "scroll/page down", and vice versa)
;
; except for the calls to scroll_area_down/up -- those refer to the direction
; the text moves

playlist_scroll_up
	ldx playlist_scroll_pos
	dex
	cpx #255
	bne +
	rts

+	stx playlist_scroll_pos

	lda #$80
	sta scroll_area_blank_last_line_flag

	lda #<playlist_bottom_row_addr
	sta scroll_area_target_addr
	lda #>playlist_bottom_row_addr
	sta scroll_area_target_addr+1

	lda #playlist_width
	sta scroll_area_width
	lda #playlist_pane_height
	sta scroll_area_height

	jsr scroll_area_down

	ldx #playlist_top_row
	jmp scroll_add_row

playlist_scroll_down
	clc
	lda playlist_scroll_pos
	adc #1
	cmp playlist_length
	bne +
	rts

+	sta playlist_scroll_pos

	lda #$80
	sta scroll_area_blank_last_line_flag

	lda #<playlist_pane_base_addr
	sta scroll_area_target_addr
	lda #>playlist_pane_base_addr
	sta scroll_area_target_addr+1

	lda #playlist_width
	sta scroll_area_width
	lda #playlist_pane_height
	sta scroll_area_height

	jsr scroll_area_up
	ldx #playlist_bottom_row

scroll_add_row
	stx screen_row_to_print_at

	clc
	ldy #playlist_left_column
	jsr PLOT
	ldx screen_row_to_print_at
	cpx #playlist_top_row
	beq +

	clc
	lda playlist_scroll_pos
	adc #playlist_half_page_size
	cmp playlist_length
	bcc print_it
	rts

+	sec
	lda playlist_scroll_pos
	sbc #playlist_half_page_size
	bcs print_it
	rts

print_it
	sta playlist_print_file_counter
	tay
	lda #DGRY
	jsr CHROUT
	lda playlist_file_flags,y
	bpl +
	lda #RVSON
	jsr CHROUT

+	!ifdef c128 {
		lda #0
		ldx #<playlist_filename_background
		ldy #>playlist_filename_background
		jsr print_msg_rle
	}

	ldx playlist_print_file_counter
	jsr calc_filename_address
	lda #16
	jsr print_msg

	!ifdef c128 {
		ldx playlist_print_file_counter
		ldy screen_row_to_print_at
		jsr append_file_size
		lda #RVSOFF
		jsr CHROUT
	} else {
		lda #RVSOFF
		jsr CHROUT
		jsr show_file_size
	}
rts

erase_file_list
	lda #0
	ldy #0
-	sta playlist_file_sizes_lows,y
	sta playlist_file_sizes_highs,y
	sta playlist_file_flags,y
	iny
	bne -
	sta playlist_length
	lda #0
	sta playlist_scroll_pos

	lda #<playlist_filenames
	sta tempzp_d
	lda #>playlist_filenames
	sta tempzp_d+1

	ldy #0
-	lda #0
	sta (tempzp_d),y
	inc tempzp_d
	bne +
	inc tempzp_d+1

+	lda tempzp_d
	cmp #<playlist_filenames_end
	bne -
	lda tempzp_d+1
	cmp #>playlist_filenames_end
	bne -
rts

erase_playlist_pane
	!ifndef c128 {
		ldx #15
		lda #$20
	-	!for .row, 3, 19 {
			sta VIC_SCREEN+.row*40+1,x
		}
		dex
		bpl -
	} else {
		lda #CLR
		jsr CHROUT
	}

; manually fill the colors so that the scroll code doesn't have to mess with them

fill_playlist_colors
	!ifndef c128 {

		hl_color		= 1 ; white

		main_color		= 13  ; light green
		main_fade1		= 5   ; dark green
		main_fade2		= 11  ; dark gray

		ldx #15
		lda #main_color
	-	!for .row, 5, 17 {
			sta VIC_COLOR_RAM+.row*40+1,x
		}
		dex
		bpl -

		ldx #15
		lda #hl_color
	-	sta VIC_COLOR_RAM+11*40+1,x
		dex
		bpl -

		ldx #15
		lda #main_fade2
	-	sta VIC_COLOR_RAM+3*40+1,x
		sta VIC_COLOR_RAM+19*40+1,x
		dex
		bpl -

		ldx #15
		lda #main_fade1
	-	sta VIC_COLOR_RAM+4*40+1,x
		sta VIC_COLOR_RAM+18*40+1,x
		dex
		bpl -

	} else {
		; attribute codes also set lower/upper charset

		hl_color		= $8f ; white

		main_color		= $85 ; light green
		main_fade1		= $84 ; dark green
		main_fade2		= $81 ; dark gray

		num_color		= $87 ; (bright) cyan
		num_fade		= $83 ; light blue

		kb_color		= $86 ; dark cyan
		kb_fade			= $83 ; light blue

		lda #<(VDC_ATTRIBUTES+ 3*80+5)
		sta write_fill_copy_target
		lda #>(VDC_ATTRIBUTES+ 3*80+5)
		sta write_fill_copy_target+1
		lda #main_fade2
		ldx #25
		jsr vdc_block_fill

		lda #<(VDC_ATTRIBUTES+ 4*80+5)
		sta write_fill_copy_target
		lda #>(VDC_ATTRIBUTES+ 4*80+5)
		sta write_fill_copy_target+1
		lda #main_fade1
		ldx #17
		jsr vdc_block_fill

		ldx #4
		lda #num_fade
		jsr vdc_block_fill_extend
		ldx #2
		lda #kb_fade
		jsr vdc_block_fill_extend

		!for .row, 5, 11 {
			lda #<(VDC_ATTRIBUTES+.row*80+5)
			sta write_fill_copy_target
			lda #>(VDC_ATTRIBUTES+.row*80+5)
			sta write_fill_copy_target+1
			lda #main_color
			ldx #17
			jsr vdc_block_fill

			ldx #4
			lda #num_color
			jsr vdc_block_fill_extend
			ldx #2
			lda #kb_color
			jsr vdc_block_fill_extend
		}

		lda #<(VDC_ATTRIBUTES+12*80+5)
		sta write_fill_copy_target
		lda #>(VDC_ATTRIBUTES+12*80+5)
		sta write_fill_copy_target+1
		lda #hl_color
		ldx #25
		jsr vdc_block_fill

		!for .row, 13, 19 {
			lda #<(VDC_ATTRIBUTES+.row*80+5)
			sta write_fill_copy_target
			lda #>(VDC_ATTRIBUTES+.row*80+5)
			sta write_fill_copy_target+1
			lda #main_color
			ldx #17
			jsr vdc_block_fill

			ldx #4
			lda #num_color
			jsr vdc_block_fill_extend
			ldx #2
			lda #kb_color
			jsr vdc_block_fill_extend
		}

		lda #<(VDC_ATTRIBUTES+20*80+5)
		sta write_fill_copy_target
		lda #>(VDC_ATTRIBUTES+20*80+5)
		sta write_fill_copy_target+1
		lda #main_fade1
		ldx #17
		jsr vdc_block_fill

		ldx #4
		lda #num_fade
		jsr vdc_block_fill_extend
		ldx #2
		lda #kb_fade
		jsr vdc_block_fill_extend

		lda #<(VDC_ATTRIBUTES+21*80+5)
		sta write_fill_copy_target
		lda #>(VDC_ATTRIBUTES+21*80+5)
		sta write_fill_copy_target+1
		lda #main_fade2
		ldx #25
		jsr vdc_block_fill
	}
rts

enqueue_file
	ldx #playlist_middle_row
	ldy #playlist_left_column
	clc
	jsr PLOT

	lda #WHT
	jsr CHROUT

	ldx playlist_scroll_pos
	lda playlist_file_flags,x
	eor #$80
	sta playlist_file_flags,x
	bpl +
	lda #RVSON
	jsr CHROUT

+	!ifdef c128 {
		lda #0
		ldx #<playlist_filename_background
		ldy #>playlist_filename_background
		jsr print_msg_rle
	}

	ldx playlist_scroll_pos
	jsr calc_filename_address
	lda #16
	jsr print_msg

	!ifdef c128 {
		ldx playlist_scroll_pos
		ldy #playlist_middle_row
		jsr append_file_size
	}

	lda #RVSOFF
	jsr CHROUT
rts

playlist_page_down
	clc
	lda playlist_scroll_pos
	adc #(playlist_half_page_size*2)
	sta playlist_scroll_pos
	sec
	lda playlist_length
	sbc #1
	cmp playlist_scroll_pos
	bcs +
	sta playlist_scroll_pos
+	jsr display_playlist
rts

playlist_page_up
	sec
	lda playlist_scroll_pos
	sbc #(playlist_half_page_size*2)
	bcs +
	lda #0
+	sta playlist_scroll_pos
	jsr display_playlist
rts

!ifndef c128 {
	show_file_size
		clc
		ldx #21
		ldy #1
		jsr PLOT

		lda #0
		ldx #<erase_size_field_msg
		ldy #>erase_size_field_msg
		jsr print_msg_rle

		ldx playlist_scroll_pos
		lda playlist_file_sizes_highs,x
		sta file_size_in_kb+1
		lda playlist_file_sizes_lows,x

		lsr file_size_in_kb+1
		ror
		lsr file_size_in_kb+1
		ror
		sta file_size_in_kb

		sec
		tax
		ldy file_size_in_kb+1
		jsr get_num_length

		clc
		tya
		adc #8
		sta tempzp_c
		sec
		lda #15
		sbc tempzp_c
		lsr
		tay
		lda #RIGHT
	-	jsr CHROUT
		dey
		bne -

		lda #0
		ldx #<pl_size_msg
		ldy #>pl_size_msg
		jsr print_msg

		lda #CYAN
		jsr CHROUT

		sec
		ldx file_size_in_kb
		ldy file_size_in_kb+1
		jsr print_uint16

		lda #LBLU
		jsr CHROUT
		lda #" "
		jsr CHROUT

		lda #0
		ldx #<kb_msg
		ldy #>kb_msg
		jsr print_msg
	rts

} else {

	append_file_size
		sty tempzp_d
		lda playlist_file_sizes_highs,x
		sta file_size_in_kb+1
		lda playlist_file_sizes_lows,x

		lsr file_size_in_kb+1
		ror
		lsr file_size_in_kb+1
		ror
		sta file_size_in_kb

		sec
		tax
		ldy file_size_in_kb+1
		jsr get_num_length
		sty tempzp_c

		sec
		lda #file_sizes_column
		sbc tempzp_c
		tay

		ldx tempzp_d
		clc
		jsr PLOT

		sec
		ldx file_size_in_kb
		ldy file_size_in_kb+1
		jsr print_uint16

		lda #0
		ldx #<kb_msg
		ldy #>kb_msg
		jsr print_msg
	rts
}
