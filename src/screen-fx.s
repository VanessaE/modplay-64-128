; this file handles various screen effects like the gray-out-blur-out action

gray_out
	!ifndef c128 {
		lda #11
		ldy #0
	-	!for .page, 0, 3 {
			sta VIC_COLOR_RAM+.page*256,y
		}
		dey
		bne -
	} else {

		lda #<VDC_ATTRIBUTES
		sta fill_copy_target
		lda #>VDC_ATTRIBUTES
		sta fill_copy_target+1
		lda #$81
		ldx #255
		jsr vdc_block_fill

		ldy #7
		ldx #255
		lda #$81
	-	jsr vdc_block_fill_extend
		dey
		bne -
	}
rts

set_standard_charset
	!ifndef c128 {
		+C64_NORMAL_SCREEN
	} else {
		lda #12
		sta VDC_ADDR
		lda #>VDC_SCREEN
		sta VDC_DATA
		lda #13
		sta VDC_ADDR
		lda #<VDC_SCREEN
		sta VDC_DATA
		sta VDC_VM3 ; point the KERNAL
	}
rts

!ifndef c128 {
	set_alt_charset
		lda #$34
		sta VIC_MEM_CTRL
	rts
}

clear_screen_early	; redirect the KERNAL and clear
	!ifndef c128 {			; the primary screen
		lda #>VIC_SCREEN
		sta HIBASE
	} else {
		lda #<VDC_SCREEN
		sta VDC_VM3
	}
	lda #CLR
jmp CHROUT

scroll_area_down
	sec
	lda scroll_area_target_addr
	sta fill_copy_target
	sbc #screen_width
	sta fill_copy_source
	lda scroll_area_target_addr+1
	sta fill_copy_target+1
	sbc #0
	sta fill_copy_source+1

	ldx scroll_area_width
	ldy scroll_area_height
	dey

	scroll_down_loop
	!ifndef c128 {
		jsr local_ram_block_copy
	} else {
		jsr vdc_block_copy
	}

	sec
	lda scroll_area_target_addr
	sbc #screen_width
	sta scroll_area_target_addr
	sta fill_copy_target
	lda scroll_area_target_addr+1
	sbc #0
	sta scroll_area_target_addr+1
	sta fill_copy_target+1

	sec
	lda scroll_area_target_addr
	sbc #screen_width
	sta fill_copy_source
	lda scroll_area_target_addr+1
	sbc #0
	sta fill_copy_source+1

	dey
	bne scroll_down_loop

	bit scroll_area_blank_last_line_flag
	bpl +

	lda #$20

	!ifndef c128 {
		jsr local_ram_block_fill
	} else {
		jsr vdc_block_fill
	}
  +
rts

scroll_area_up
	clc
	lda scroll_area_target_addr
	sta fill_copy_target
	adc #screen_width
	sta fill_copy_source
	lda scroll_area_target_addr+1
	sta fill_copy_target+1
	adc #0
	sta fill_copy_source+1

	ldx scroll_area_width
	ldy scroll_area_height
	dey

	scroll_up_loop
	!ifndef c128 {
		jsr local_ram_block_copy
	} else {
		jsr vdc_block_copy
	}

	clc
	lda scroll_area_target_addr
	adc #screen_width
	sta scroll_area_target_addr
	sta fill_copy_target
	lda scroll_area_target_addr+1
	adc #0
	sta scroll_area_target_addr+1
	sta fill_copy_target+1

	clc
	lda scroll_area_target_addr
	adc #screen_width
	sta fill_copy_source
	lda scroll_area_target_addr+1
	adc #0
	sta fill_copy_source+1

	dey
	bne scroll_up_loop

	bit scroll_area_blank_last_line_flag
	bpl +

	lda #$20

	!ifndef c128 {
		jsr local_ram_block_fill
	} else {
		jsr vdc_block_fill
	}
  +
rts

; enter with .X/.Y = column and row of the progress bar itself (on C128, that
; that means the real row/column, not the position within whatever popup
; might be open), .A = length of the progress bar in segments (8 per char).

; the frame will be drawn in the row above, the column to the left, and the
; row below the given coordinates (and of course, to the right of it)

; maximum bar length is 255 segments, one segment shy of 32 chars.

!ifndef c128 {
	progbar_frame_top = $af
	progbar_frame_bottom = $b7
} else {
	progbar_frame_top = $a4
	progbar_frame_bottom = $a3
}

progbar_frame_left = $aa
progbar_frame_right = $b4

draw_empty_progress_bar
	sta progress_bar_max_length
	lsr
	lsr
	lsr
	sta temp_abs_a ; length in characters
	stx progress_bar_column
	sty progress_bar_row

	ldx progress_bar_row
	dex
	ldy progress_bar_column
	clc
	jsr PLOT

	lda #LGRY
	jsr CHROUT

	ldy temp_abs_a
	lda #progbar_frame_top
-	jsr CHROUT
	dey
	bne -

	ldx progress_bar_row
	ldy progress_bar_column
	dey
	clc
	jsr PLOT

	lda #progbar_frame_left
	jsr CHROUT

	lda #LGRN
	jsr CHROUT

	!ifdef c128 {
		lda #UPPER
		jsr CHROUT
	}

	ldy temp_abs_a
	lda #" "
-	jsr CHROUT
	dey
	bne -

	!ifdef c128 {
		lda #LOWER
		jsr CHROUT
	}

	lda #MGRY
	jsr CHROUT

	lda #progbar_frame_right
	jsr CHROUT

	ldx progress_bar_row
	inx
	ldy progress_bar_column
	clc
	jsr PLOT

	ldy temp_abs_a
	lda #progbar_frame_bottom
-	jsr CHROUT
	dey
	bne -

	lda progress_bar_row
	ldx #screen_width
	jsr multiply_8x8

	clc
	lda product
	adc #<screen_base_addr
	sta progress_bar_char_pointer
	lda product+1
	adc #>screen_base_addr
	sta progress_bar_char_pointer+1

	lda progress_bar_char_pointer
	adc progress_bar_column
	sta progress_bar_char_pointer
	lda progress_bar_char_pointer+1
	adc #0
	sta progress_bar_char_pointer+1
rts

; enter this one with .A = number of segments to draw, max 255

update_progress_bar
	sta temp_abs_a

	!ifdef c128 {

		lda progress_bar_char_pointer
		sta fill_copy_target
		lda progress_bar_char_pointer+1
		sta fill_copy_target+1

		jsr vdc_ram_rw_setup
	}

	lda temp_abs_a
	lsr
	lsr
	lsr
	beq nofill
	tay
	dey

	lda #$a0

-	!ifndef c128 {
		sta (progress_bar_char_pointer),y
	} else {
		jsr vdc_write_ram
	}

	dey
	cpy #255
	bne -

nofill
	lda temp_abs_a
	and #$07
	tax

	lda progress_bar_segments,x

	!ifndef c128 {
		lsr temp_abs_a
		lsr temp_abs_a
		lsr temp_abs_a
		ldy temp_abs_a
		sta (progress_bar_char_pointer),y

	} else {
		jsr vdc_write_ram
	}
rts

!ifndef c128 {
	vic_copy_main_menu_to_reu
		jsr vic_set_copy_size

		lda #0
		sta expansion_memory_target_pointer
		sta expansion_memory_target_pointer+2

		; menu text

		lda #<VIC_SCREEN
		sta expansion_transfer_local_addr
		lda #>VIC_SCREEN
		sta expansion_transfer_local_addr+1

		lda exp_menu_start_page
		sta expansion_memory_target_pointer+1

		jsr reu_stash_block

		; menu colors

		lda #<VIC_COLOR_RAM
		sta expansion_transfer_local_addr
		lda #>VIC_COLOR_RAM
		sta expansion_transfer_local_addr+1

		lda exp_menu_start_page
		clc
		adc #4
		sta expansion_memory_target_pointer+1
	jmp reu_stash_block

	vic_retrieve_main_menu_from_reu
		jsr vic_set_copy_size

		lda #0
		sta expansion_memory_target_pointer
		sta expansion_memory_target_pointer+2

		; menu colors

		jsr vic_set_target_to_color_ram

		lda exp_menu_start_page
		clc
		adc #4
		sta expansion_memory_target_pointer+1

		+JSR_INDIRECT (fetch_block_vec)

		; menu text

		jsr vic_set_target_to_text

		lda exp_menu_start_page
		sta expansion_memory_target_pointer+1

		+JSR_INDIRECT (fetch_block_vec)
	rts

	vic_retrieve_loader_bg_from_reu
		jsr vic_set_copy_size

		lda #0
		sta expansion_memory_target_pointer
		sta expansion_memory_target_pointer+2

		; loader background colors

		jsr vic_set_target_to_color_ram

		lda exp_loader_bg_start_page
		adc #4
		sta expansion_memory_target_pointer+1

		+JSR_INDIRECT (fetch_block_vec)

		; loader background text

		jsr vic_set_target_to_text

		lda exp_loader_bg_start_page
		sta expansion_memory_target_pointer+1

		+JSR_INDIRECT (fetch_block_vec)
	rts

	vic_retrieve_player_bg_from_reu
		jsr vic_set_copy_size

		lda #0
		sta expansion_memory_target_pointer
		sta expansion_memory_target_pointer+2

		; player background colors

		jsr vic_set_target_to_color_ram

		lda exp_player_bg_start_page
		clc
		adc #4
		sta expansion_memory_target_pointer+1

		+JSR_INDIRECT (fetch_block_vec)

		; player background text

		jsr vic_set_target_to_text

		lda exp_player_bg_start_page
		sta expansion_memory_target_pointer+1

		+JSR_INDIRECT (fetch_block_vec)
	rts

	vic_set_copy_size
		lda #<1000
		sta stash_size
		lda #>1000
		sta stash_size+1
	rts

	vic_set_target_to_color_ram
		lda #<VIC_COLOR_RAM
		sta expansion_transfer_local_addr
		lda #>VIC_COLOR_RAM
		sta expansion_transfer_local_addr+1
	rts

	vic_set_target_to_text
		lda #<VIC_SCREEN
		sta expansion_transfer_local_addr
		lda #>VIC_SCREEN
		sta expansion_transfer_local_addr+1
	rts

} else {
	vdc_copy_main_menu_to_cache

		; menu attributes

		lda #<VDC_ATTRIBUTES
		sta fill_copy_source
		lda #>VDC_ATTRIBUTES
		sta fill_copy_source+1

		lda #<VDC_64K_CACHE_MENU_ATTRS
		sta fill_copy_target
		lda #>VDC_64K_CACHE_MENU_ATTRS
		sta fill_copy_target+1

		ldx #0
		jsr vdc_block_copy

		ldy #7
	-	jsr vdc_block_copy_extend
		dey
		bne -

		; menu text

		lda #<VDC_SCREEN
		sta fill_copy_source
		lda #>VDC_SCREEN
		sta fill_copy_source+1

		lda #<VDC_64K_CACHE_MENU_TEXT
		sta fill_copy_target
		lda #>VDC_64K_CACHE_MENU_TEXT
		sta fill_copy_target+1

		ldx #0
		jsr vdc_block_copy

		ldy #7
	-	jsr vdc_block_copy_extend
		dey
		bne -
	rts

	vdc_retrieve_main_menu_from_cache
		; menu attributes

		lda #<VDC_64K_CACHE_MENU_ATTRS
		sta fill_copy_source
		lda #>VDC_64K_CACHE_MENU_ATTRS
		sta fill_copy_source+1

		lda #<VDC_ATTRIBUTES
		sta fill_copy_target
		lda #>VDC_ATTRIBUTES
		sta fill_copy_target+1

		ldx #0
		jsr vdc_block_copy

		ldy #7
	-	jsr vdc_block_copy_extend
		dey
		bne -

		; menu text

		lda #<VDC_64K_CACHE_MENU_TEXT
		sta fill_copy_source
		lda #>VDC_64K_CACHE_MENU_TEXT
		sta fill_copy_source+1

		lda #<VDC_SCREEN
		sta fill_copy_target
		lda #>VDC_SCREEN
		sta fill_copy_target+1

		ldx #0
		jsr vdc_block_copy

		ldy #7
	-	jsr vdc_block_copy_extend
		dey
		bne -
	rts

	vdc_retrieve_loader_bg_from_reu
		jsr vdc_set_fetch_size

		lda #0
		sta expansion_memory_target_pointer
		sta expansion_memory_target_pointer+2

		; loader background attributes

		jsr vdc_set_load_buf_as_relay

		clc
		lda exp_loader_bg_start_page
		adc #8
		sta expansion_memory_target_pointer+1

		+JSR_INDIRECT (fetch_block_vec)

		jsr vdc_bg_upload_attrs

		; loader background text

		jsr vdc_set_load_buf_as_relay

		lda exp_loader_bg_start_page
		sta expansion_memory_target_pointer+1

		+JSR_INDIRECT (fetch_block_vec)

	jmp vdc_bg_upload_text

	vdc_retrieve_player_bg_from_reu
		jsr vdc_set_fetch_size

		lda #0
		sta expansion_memory_target_pointer
		sta expansion_memory_target_pointer+2

		; player background attributes

		jsr vdc_set_load_buf_as_relay

		clc
		lda exp_player_bg_start_page
		adc #8
		sta expansion_memory_target_pointer+1

		+JSR_INDIRECT (fetch_block_vec)

		jsr vdc_bg_upload_attrs

		; player background text

		jsr vdc_set_load_buf_as_relay

		lda exp_player_bg_start_page
		sta expansion_memory_target_pointer+1

		+JSR_INDIRECT (fetch_block_vec)

	jmp vdc_bg_upload_text

	vdc_copy_loader_bg_from_cache

		; loader background attributes

		lda #<VDC_64K_CACHE_LDR_BG_ATTRS
		sta fill_copy_source
		lda #>VDC_64K_CACHE_LDR_BG_ATTRS
		sta fill_copy_source+1

		lda #<VDC_ATTRIBUTES
		sta fill_copy_target
		lda #>VDC_ATTRIBUTES
		sta fill_copy_target+1

		ldx #0
		jsr vdc_block_copy

		ldy #7
	-	jsr vdc_block_copy_extend
		dey
		bne -

		; loader background text

		lda #<VDC_64K_CACHE_LDR_BG_TEXT
		sta fill_copy_source
		lda #>VDC_64K_CACHE_LDR_BG_TEXT
		sta fill_copy_source+1

		lda #<VDC_SCREEN
		sta fill_copy_target
		lda #>VDC_SCREEN
		sta fill_copy_target+1

		ldx #0
		jsr vdc_block_copy

		ldy #7
	-	jsr vdc_block_copy_extend
		dey
		bne -
	rts

	vdc_copy_player_bg_from_cache

		; player background attributes

		lda #<VDC_64K_CACHE_PLYR_BG_ATTRS
		sta fill_copy_source
		lda #>VDC_64K_CACHE_PLYR_BG_ATTRS
		sta fill_copy_source+1

		lda #<VDC_ATTRIBUTES
		sta fill_copy_target
		lda #>VDC_ATTRIBUTES
		sta fill_copy_target+1

		ldx #0
		jsr vdc_block_copy

		ldy #7
	-	jsr vdc_block_copy_extend
		dey
		bne -

		; player background text

		lda #<VDC_64K_CACHE_PLYR_BG_TEXT
		sta fill_copy_source
		lda #>VDC_64K_CACHE_PLYR_BG_TEXT
		sta fill_copy_source+1

		lda #<VDC_SCREEN
		sta fill_copy_target
		lda #>VDC_SCREEN
		sta fill_copy_target+1

		ldx #0
		jsr vdc_block_copy

		ldy #7
	-	jsr vdc_block_copy_extend
		dey
		bne -
	rts

	vdc_set_fetch_size
		lda #<2000
		sta stash_size
		lda #>2000
		sta stash_size+1
	rts

	vdc_set_load_buf_as_relay
		lda #<load_buffer
		sta expansion_transfer_local_addr
		sta fill_copy_source
		lda #>load_buffer
		sta expansion_transfer_local_addr+1
		sta fill_copy_source+1
	rts

	vdc_bg_upload_attrs
		lda #<VDC_ATTRIBUTES
		sta fill_copy_target
		lda #>VDC_ATTRIBUTES
		sta fill_copy_target+1

		jsr vdc_ram_rw_setup

		ldy #0
	-	lda (fill_copy_source),y
		jsr vdc_write_ram
		iny
		bne -
		inc fill_copy_source+1
		lda fill_copy_source+1
		cmp #>(load_buffer+$0800)
		bne -
	rts

	vdc_bg_upload_text
		lda #<VDC_SCREEN
		sta fill_copy_target
		lda #>VDC_SCREEN
		sta fill_copy_target+1

		jsr vdc_ram_rw_setup

		ldy #0
	-	lda (fill_copy_source),y
		jsr vdc_write_ram
		iny
		bne -
		inc fill_copy_source+1
		lda fill_copy_source+1
		cmp #>(load_buffer+$0800)
		bne -
	rts
}

copy_main_menu_to_cache_quick
	!ifdef c128 {
		bit c128_vdc_has_64k
		bmi +
		rts
	  +
	}

	bit main_menu_cache_is_valid
	bpl +
	rts

+	!ifndef c128 {
		jsr vic_copy_main_menu_to_reu
	} else {
		jsr vdc_copy_main_menu_to_cache
	}

	lda #$80
	sta main_menu_cache_is_valid
rts

retrieve_main_menu_from_cache_quick
	!ifndef c128 {
		jsr vic_retrieve_main_menu_from_reu
	} else {
		jsr vdc_retrieve_main_menu_from_cache
	}
rts

; .X/.Y = address of the top left corner, .A = width to erase
; erase_screen_area_row_count must also be set.

!ifndef c128 {
	vic_erase_screen_area
		sta temp_abs_y
		stx fill_copy_target
		sty fill_copy_target+1
		ldx erase_screen_area_row_count

	--	ldy #0
		lda #32 ; space
	-	sta (fill_copy_target),y
		iny
		cpy temp_abs_y
		bne -

		clc
		lda fill_copy_target
		adc #40
		sta fill_copy_target
		lda fill_copy_target+1
		adc #0
		sta fill_copy_target+1

		dex
		bne --
	rts
} else {
	vdc_erase_screen_area
		sta temp_abs_b
		stx fill_copy_target
		sty fill_copy_target+1

	-	lda #32 ; space
		ldx temp_abs_b
		jsr vdc_block_fill

		clc
		lda fill_copy_target
		adc #80
		sta fill_copy_target
		lda fill_copy_target+1
		adc #0
		sta fill_copy_target+1

		dec erase_screen_area_row_count
		bne -
	rts
}
