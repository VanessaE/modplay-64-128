; this file loads the current directory into memory as a set of "arrays"
; for, and manages most aspects of the main menu playlist.

!ifndef c128 {
	playlist_top_row			= 3
	playlist_bottom_row			= 19
	playlist_left_column		= 1
	playlist_width				= 16
	dirname_row					= 2
	dirname_col					= 1
	file_list_number_row		= 13
	file_list_number_column		= 22

	playlist_pane_base_addr = VIC_SCREEN + 3*40 + 1

	mini_popup_lower_left_corner_addr = VIC_SCREEN + 1 + mini_popup_left_column + mini_popup_bottom_row * 40

} else {
	playlist_top_row			= 0
	playlist_bottom_row			= 18
	playlist_left_column		= 1
	playlist_width				= 26
	dirname_row					= 2
	dirname_col					= 9
	file_list_number_row		= 4
	file_list_number_column		= 17
	file_sizes_column			= 21

	playlist_pane_base_addr = VDC_SCREEN + 3*80 + 5

	mini_popup_lower_left_corner_addr = VDC_SCREEN + 1 + mini_popup_left_col_real + mini_popup_bottom_row * 80

}

playlist_pane_height = playlist_bottom_row - playlist_top_row + 1
playlist_bottom_row_addr = playlist_pane_base_addr + (playlist_pane_height - 1)*screen_width

playlist_half_page_size = (playlist_pane_height - 1) / 2
playlist_middle_row = (playlist_bottom_row + playlist_top_row) / 2

; utility_pointer_b is for the screen code versions of the filenames
; utility_pointer_c is used for the plain PETSCII versions

load_directory
	lda #0
	sta playlist_scroll_pos
	lda exp_petscii_filenames_start_page
	sta utility_pointer_c+1

	!ifndef c128 {
		lda exp_screencode_filenames_start_page
		sta utility_pointer_b+1
	} else {
		lda #<VDC_filename_cache
		sta utility_pointer_b
		lda #>VDC_filename_cache
		sta utility_pointer_b+1
	}

	lda #0
	sta utility_pointer_c
	sta utility_pointer_c+2
	sta utility_pointer_b
	sta utility_pointer_b+2

	lda #0
	sta playlist_length

	jsr dir_open
	jsr .err

	clc
	jsr draw_mini_popup

	lda #0
	ldx #<scanning_dir_msg
	ldy #>scanning_dir_msg
	sec
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

	clc
	!ifndef c128 {
		ldx #mini_popup_bottom_row
		ldy #mini_popup_left_column+1
	} else {
		ldx #mini_popup_height
		ldy #0
	}
	jsr PLOT

	lda #BLK
	jsr CHROUT

	clc
	ldx #mini_popup_bottom_row
	ldy #mini_popup_left_column+1
	jsr PLOT

	!ifndef c128 {
		ldy #16
		lda #32
	-	jsr CHROUT
		dey
		bne -
	} else {
		lda #ESC
		jsr CHROUT
		lda #"q"
		jsr CHROUT
	}

	clc
	ldx #mini_popup_bottom_row
	ldy #mini_popup_left_column+1
	jsr PLOT

	lda #16
	ldx #<string_buffer+32
	ldy #>string_buffer+32
	sec
	jsr print_msg

	!ifndef c128 {
		lda #<mini_popup_lower_left_corner_addr
		sta expansion_transfer_local_addr
		lda #>mini_popup_lower_left_corner_addr
		sta expansion_transfer_local_addr+1

		lda utility_pointer_b
		sta expansion_memory_target_pointer
		lda utility_pointer_b+1
		sta expansion_memory_target_pointer+1
		lda utility_pointer_b+2
		sta expansion_memory_target_pointer+2

		lda #16
		sta stash_size
		lda #0
		sta stash_size+1

		+JSR_INDIRECT (stash_block_vec)

	} else {
		lda #<(mini_popup_lower_left_corner_addr-1)
		sta fill_copy_source
		lda #>(mini_popup_lower_left_corner_addr-1)
		sta fill_copy_source+1
	
		lda utility_pointer_b
		sta fill_copy_target
		lda utility_pointer_b+1
		sta fill_copy_target+1

		ldx #16
		jsr vdc_block_copy
	}

	lda #<string_buffer+32
	sta expansion_transfer_local_addr
	lda #>string_buffer+32
	sta expansion_transfer_local_addr+1

	lda utility_pointer_c
	sta expansion_memory_target_pointer
	lda utility_pointer_c+1
	sta expansion_memory_target_pointer+1
	lda utility_pointer_c+2
	sta expansion_memory_target_pointer+2

	lda #16
	sta stash_size
	lda #0
	sta stash_size+1

	+JSR_INDIRECT (stash_block_vec)

.more_files
	ldy playlist_length
	lda playlist_file_sizes_highs,y
	bne +
	lda playlist_file_sizes_lows,y
	cmp #7					; discard any file less than 7 disk blocks long,
	bcs + 					; it's all but impossible for a MOD to be that small.
	jmp .next_entry

+	clc
	lda utility_pointer_b
	adc #16
	sta utility_pointer_b
	lda utility_pointer_b+1
	adc #0
	sta utility_pointer_b+1

	lda utility_pointer_c
	adc #16
	sta utility_pointer_c
	lda utility_pointer_c+1
	adc #0
	sta utility_pointer_c+1

	inc playlist_length
	lda playlist_length
	cmp #255				; end of list space?
	beq .fin

+	clc
	ldx #file_list_number_row
	ldy #file_list_number_column
	jsr PLOT

	lda #LGRN
	jsr CHROUT

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

display_disk_name
	lda playlist_length
	bne +
	rts

+	!ifdef c128 {
		jsr FULLW
	}

	clc
	ldx #dirname_row
	ldy #dirname_col
	jsr PLOT

	lda #0
	ldx #<dirname_background
	ldy #>dirname_background
	sec
	jsr print_msg_rle

	lda #16
	ldx #<current_dir_name
	ldy #>current_dir_name
	jsr center_string

	lda #16
	ldx #<current_dir_name
	ldy #>current_dir_name
	sec
	jsr print_msg

	lda #RVSOFF
	jsr CHROUT
rts

display_playlist
	lda playlist_length
	bne +

	!ifdef c128 {
		jsr set_window_playlist_pane

		clc
		ldx #playlist_middle_row
		ldy #playlist_left_column+2
		jsr PLOT
	}

	lda #0
	ldx #<no_list_loaded_msg
	ldy #>no_list_loaded_msg
	sec
	!ifndef c128 {
		jsr print_msg_rle
	} else {
		jsr print_msg
	}
	rts

+	!ifdef c128 {
		jsr set_window_playlist_pane
	}

	jsr erase_playlist_pane

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

.pl_print_lp
	ldx playlist_print_file_counter
	clc
	jsr direct_print_single_entry

	!ifdef c128 {
		ldx playlist_print_file_counter
		jsr append_file_size
	}

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
	tax
	clc
	jsr direct_print_single_entry

	!ifdef c128 {
		ldx playlist_print_file_counter
		jsr append_file_size
	} else {
		jsr show_file_size
	}
rts

erase_file_list
	lda #0
	ldx #0
-	sta load_buffer,x
	dex
	bne -

	sta expansion_memory_target_pointer
	sta expansion_memory_target_pointer+2

	sta stash_size
	lda #1
	sta stash_size+1

	lda exp_petscii_filenames_start_page
	sta expansion_memory_target_pointer+1

	lda #<load_buffer
	sta expansion_transfer_local_addr
	lda #>load_buffer
	sta expansion_transfer_local_addr+1

	!ifndef c128 {
		ldx #32 ; erase the screencode versions also on C64
	} else {
		ldx #16
	}

-	+JSR_INDIRECT (stash_block_vec)

	inc expansion_memory_target_pointer+1

	dex
	bne -

	!ifdef c128 {
		lda #<VDC_filename_cache
		sta fill_copy_target
		lda #>VDC_filename_cache
		sta fill_copy_target+1

		lda #0
		ldx #15
		jsr vdc_block_fill

		ldy #255
	-	lda #0
		ldx #15
		jsr vdc_block_fill_extend
		dey
		bne -
	}
rts

erase_playlist_pane
	!ifndef c128 {

		lda #<(VIC_SCREEN + 3*40 + 1)
		sta fill_copy_target
		lda #>(VIC_SCREEN + 3*40 + 1)
		sta fill_copy_target+1

		ldx #3

	--	lda #32
		ldy #15

	-	sta (fill_copy_target),y
		dey
		bpl -

		clc
		lda fill_copy_target
		adc #40
		sta fill_copy_target
		lda fill_copy_target+1
		adc #0
		sta fill_copy_target+1

		inx
		cpx #20
		bne --

	} else {
		lda #<(VDC_SCREEN + 3*80 + 5)
		sta fill_copy_target
		lda #>(VDC_SCREEN + 3*80 + 5)
		sta fill_copy_target+1

		ldy #3

	-	lda #32
		ldx #26
		jsr vdc_block_fill

		clc
		lda fill_copy_target
		adc #80
		sta fill_copy_target
		lda fill_copy_target+1
		adc #0
		sta fill_copy_target+1

		iny
		cpy #22
		bne -

	}
rts

; manually fill the colors so that the scroll code doesn't have to mess with them

prefill_playlist_colors
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
		sta fill_copy_target
		lda #>(VDC_ATTRIBUTES+ 3*80+5)
		sta fill_copy_target+1
		lda #main_fade2
		ldx #26
		jsr vdc_block_fill

		lda #<(VDC_ATTRIBUTES+ 4*80+5)
		sta fill_copy_target
		lda #>(VDC_ATTRIBUTES+ 4*80+5)
		sta fill_copy_target+1
		lda #main_fade1
		ldx #17
		jsr vdc_block_fill

		ldx #4
		lda #num_fade
		jsr vdc_block_fill_extend
		ldx #3
		lda #kb_fade
		jsr vdc_block_fill_extend

		!for .row, 5, 11 {
			lda #<(VDC_ATTRIBUTES+.row*80+5)
			sta fill_copy_target
			lda #>(VDC_ATTRIBUTES+.row*80+5)
			sta fill_copy_target+1
			lda #main_color
			ldx #17
			jsr vdc_block_fill

			ldx #4
			lda #num_color
			jsr vdc_block_fill_extend
			ldx #3
			lda #kb_color
			jsr vdc_block_fill_extend
		}

		lda #<(VDC_ATTRIBUTES+12*80+5)
		sta fill_copy_target
		lda #>(VDC_ATTRIBUTES+12*80+5)
		sta fill_copy_target+1
		lda #hl_color
		ldx #26
		jsr vdc_block_fill

		!for .row, 13, 19 {
			lda #<(VDC_ATTRIBUTES+.row*80+5)
			sta fill_copy_target
			lda #>(VDC_ATTRIBUTES+.row*80+5)
			sta fill_copy_target+1
			lda #main_color
			ldx #17
			jsr vdc_block_fill

			ldx #4
			lda #num_color
			jsr vdc_block_fill_extend
			ldx #3
			lda #kb_color
			jsr vdc_block_fill_extend
		}

		lda #<(VDC_ATTRIBUTES+20*80+5)
		sta fill_copy_target
		lda #>(VDC_ATTRIBUTES+20*80+5)
		sta fill_copy_target+1
		lda #main_fade1
		ldx #17
		jsr vdc_block_fill

		ldx #4
		lda #num_fade
		jsr vdc_block_fill_extend
		ldx #3
		lda #kb_fade
		jsr vdc_block_fill_extend

		lda #<(VDC_ATTRIBUTES+21*80+5)
		sta fill_copy_target
		lda #>(VDC_ATTRIBUTES+21*80+5)
		sta fill_copy_target+1
		lda #main_fade2
		ldx #26
		jsr vdc_block_fill
	}
rts

enqueue_file
	ldx playlist_scroll_pos
	lda playlist_file_flags,x
	eor #$80
	sta playlist_file_flags,x

	lda #playlist_middle_row
	sta screen_row_to_print_at
	clc
	jsr direct_print_single_entry
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

; this expects the file entry number in the list in .X
; and set screen_row_to_print_at to the line number to print on
;
; set the carry to get the address of the PETSCII filename
; or clear to get the address of the screen code version

direct_print_single_entry
	stx temp_abs_x

	jsr calc_filename_address

	!ifndef c128 {
		stx expansion_memory_target_pointer
		sty expansion_memory_target_pointer+1
		lda #0
		sta expansion_memory_target_pointer+2
		sta stash_size+1
		lda #16
		sta stash_size

		ldx screen_row_to_print_at
		lda #40
		jsr multiply_8x8

		clc
		lda product
		adc #<VIC_SCREEN + 1
		sta fill_copy_target
		lda product+1
		adc #>VIC_SCREEN + 1
		sta fill_copy_target+1

	} else {
		stx fill_copy_source
		sty fill_copy_source+1

		clc
		lda screen_row_to_print_at
		adc #3
		ldx #80
		jsr multiply_8x8

		clc
		lda product
		adc #<VDC_SCREEN + 6
		sta utility_pointer
		lda product+1
		adc #>VDC_SCREEN + 6
		sta utility_pointer+1
	}

	ldx temp_abs_x
	lda playlist_file_flags,x
	bmi dp_is_enqueued

		!ifndef c128 {
			clc
			lda product
			adc #<VIC_SCREEN + 1
			sta expansion_transfer_local_addr
			lda product+1
			adc #>VIC_SCREEN + 1
			sta expansion_transfer_local_addr+1

			+JSR_INDIRECT (fetch_block_vec)
		} else {

			lda utility_pointer
			sta fill_copy_target
			lda utility_pointer+1
			sta fill_copy_target+1

			ldx #16
			jsr vdc_block_copy
		}
		rts

	; if a file is enqued, we need to invert the text colors

	dp_is_enqueued

		!ifndef c128 {
			lda #<string_buffer
			sta expansion_transfer_local_addr
			lda #>string_buffer
			sta expansion_transfer_local_addr+1

			+JSR_INDIRECT (fetch_block_vec)

			lda #<string_buffer
			sta fill_copy_source
			lda #>string_buffer
			sta fill_copy_source+1

			ldy #15
		-	lda (fill_copy_source),y
			ora #$80
			sta (fill_copy_target),y
			dey
			bpl -

		} else {
			lda fill_copy_source
			sta fill_copy_target
			lda fill_copy_source+1
			sta fill_copy_target+1

			jsr vdc_ram_rw_setup

			ldy #0
		-	jsr vdc_read_ram
			sta string_buffer,y
			iny
			cpy #16
			bne -

			lda utility_pointer
			sta fill_copy_target
			lda utility_pointer+1
			sta fill_copy_target+1

			jsr vdc_ram_rw_setup

			ldy #0
		-	lda string_buffer,y
			ora #$80
			jsr vdc_write_ram
			iny
			cpy #16
			bne -
		}
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
		sec
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
		sta temp_abs_a
		sec
		lda #15
		sbc temp_abs_a
		lsr
		tay
		lda #RIGHT
	-	jsr CHROUT
		dey
		bne -

		lda #0
		ldx #<pl_size_msg
		ldy #>pl_size_msg
		sec
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
		sec
		jsr print_msg
	rts

} else {

	append_file_size
		lda playlist_file_sizes_highs,x
		sta file_size_in_kb+1
		lda playlist_file_sizes_lows,x

		lsr file_size_in_kb+1
		ror
		lsr file_size_in_kb+1
		ror
		sta file_size_in_kb

		sec
		ldx file_size_in_kb
		ldy file_size_in_kb+1
		jsr uint16_to_string

		lda #31
		sta VDC_ADDR

		ldx #1 ; ignore the first char, the num will always be 4 space-padded digits
	-	lda uint16_string_buffer,x
		jsr vdc_write_ram
		inx
		cpx #6
		bne -

		lda #32
		jsr vdc_write_ram
		!ct scr {
			lda #"k"
			jsr vdc_write_ram
			lda #"B"
			jsr vdc_write_ram
		}
	rts
}

; this little subroutine iterates through the playlist, playing whatever
; is found, or is selected, as appropriate.

playlist_iterate
	bit playlist_iterate_mode		; play all files?
	bpl playlist_load_next_file

	ldx playlist_scroll_pos			; okay, selected-only.
	lda playlist_file_flags,x		; is the file selected?
	bpl playlist_next_file

playlist_load_next_file
	lda #0
	sta current_file_type
	clc
	jsr load_file_to_expansion
	lda current_file_type
	beq playlist_next_file			; did the file load?
	jsr start_main_player

	!ifndef c128 {
		bit enable_screen_on_playback
		bpl +
	}

	sec
	jsr draw_medium_popup

+	bit seq_abort_flag				; if the song exited with $80 here,
	bpl playlist_next_file			; the user pressed F7 to bail-out
	rts

playlist_next_file
	inc playlist_scroll_pos
	lda playlist_scroll_pos
	cmp playlist_length
	bne playlist_iterate

	dec playlist_scroll_pos
rts
