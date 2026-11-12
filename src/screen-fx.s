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

; PROGRESS BAR
;
; Before calling init_progress_bar, set:
;
;   progress_bar_color   the bar's color, as a PETSCII color code
;   progress_bar_total   (2 bytes) the amount that means the bar is full
;   progress_bar_step    (2 bytes) how much of that amount each call to
;                        update_progress_bar stands for
;
; the last two are in whatever units suit the caller (pages, blocks...), as long
; as it's the same for both.
;
; init_progress_bar draws the empty bar and its frame.  enter with .A = the
; length of the bar in characters (31 at most), .X = column, .Y = row.  the
; frame is drawn in the row above, the column to the left, and the row below the
; given coordinates (and of course, to the right of it).
;
; update_progress_bar takes no arguments.  it counts one more step, and fills
; the bar to match.  it never fills past the end, however many times it's called.
;
; a caller that changes progress_bar_step or progress_bar_total while the bar is
; in use has to call progress_bar_set_scale afterwards, which keeps what's been
; counted so far.

!ifndef c128 {
	progbar_frame_top = $af
	progbar_frame_bottom = $b7
} else {
	progbar_frame_top = $a4
	progbar_frame_bottom = $a3
}

progbar_frame_left = $aa
progbar_frame_right = $b4

init_progress_bar
	sta temp_abs_a ; length in characters
	asl
	asl
	asl
	sta progress_bar_max_length ; length in segments, eight per character
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

	lda progress_bar_color
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

	lda #0
	sta progress_bar_filled
	sta progress_bar_accum
	sta progress_bar_accum+1
	sta progress_bar_accum+2

; work out how far one step moves the bar:  the step times the bar's length in
; segments.  the bar gains a segment each time the running total of those
; reaches progress_bar_total, so nothing has to be divided.

progress_bar_set_scale
	lda progress_bar_step
	sta multiplicand_a
	lda progress_bar_step+1
	sta multiplicand_a+1
	lda progress_bar_max_length
	sta multiplicand_b
	lda #0
	sta multiplicand_b+1

	sec
	jsr multiply_16x16

	lda product
	sta progress_bar_scaled_step
	lda product+1
	sta progress_bar_scaled_step+1
	lda product+2
	sta progress_bar_scaled_step+2
rts

update_progress_bar
	clc
	lda progress_bar_accum
	adc progress_bar_scaled_step
	sta progress_bar_accum
	lda progress_bar_accum+1
	adc progress_bar_scaled_step+1
	sta progress_bar_accum+1
	lda progress_bar_accum+2
	adc progress_bar_scaled_step+2
	sta progress_bar_accum+2

	; add a segment for each whole progress_bar_total that's in there, and
	; stop when the bar is full (which is also what ends this if the total
	; is zero)

.pbar_check
	lda progress_bar_filled
	cmp progress_bar_max_length
	bcs .pbar_draw

	lda progress_bar_accum+2
	bne .pbar_add_segment

	lda progress_bar_accum
	cmp progress_bar_total
	lda progress_bar_accum+1
	sbc progress_bar_total+1
	bcc .pbar_draw

.pbar_add_segment
	sec
	lda progress_bar_accum
	sbc progress_bar_total
	sta progress_bar_accum
	lda progress_bar_accum+1
	sbc progress_bar_total+1
	sta progress_bar_accum+1
	bcs +
	dec progress_bar_accum+2

+	inc progress_bar_filled
	bne .pbar_check ; (always)

.pbar_draw
	lda progress_bar_filled
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
	beq .pbar_done ; no part-filled character (and a full bar ends here,
	               ; so that it doesn't write over the frame)
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
.pbar_done
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

		jsr fetch_block_vec

		; menu text

		jsr vic_set_target_to_text

		lda exp_menu_start_page
		sta expansion_memory_target_pointer+1

		jsr fetch_block_vec
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

		jsr fetch_block_vec

		; loader background text

		jsr vic_set_target_to_text

		lda exp_loader_bg_start_page
		sta expansion_memory_target_pointer+1

		jsr fetch_block_vec
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

		jsr fetch_block_vec

		; player background text

		jsr vic_set_target_to_text

		lda exp_player_bg_start_page
		sta expansion_memory_target_pointer+1

		jsr fetch_block_vec
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
	; copy 2 kB (a whole screen's worth of text or attributes) from one place
	; in VDC memory to another.  enter with .A = the high byte of the source
	; address, .Y = the high byte of the target.  both have to be page-aligned,
	; and all of the places that this is used with are.

	vdc_copy_2k
		sta fill_copy_source+1
		sty fill_copy_target+1
		lda #0
		sta fill_copy_source
		sta fill_copy_target

		ldx #0
		jsr vdc_block_copy

		ldy #7
	-	jsr vdc_block_copy_extend
		dey
		bne -
	rts

	vdc_copy_main_menu_to_cache

		; menu attributes

		lda #>VDC_ATTRIBUTES
		ldy #>VDC_64K_CACHE_MENU_ATTRS
		jsr vdc_copy_2k

		; menu text

		lda #>VDC_SCREEN
		ldy #>VDC_64K_CACHE_MENU_TEXT
		jsr vdc_copy_2k
	rts

	vdc_retrieve_main_menu_from_cache
		; menu attributes

		lda #>VDC_64K_CACHE_MENU_ATTRS
		ldy #>VDC_ATTRIBUTES
		jsr vdc_copy_2k

		; menu text

		lda #>VDC_64K_CACHE_MENU_TEXT
		ldy #>VDC_SCREEN
		jsr vdc_copy_2k
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

		jsr fetch_block_vec

		jsr vdc_bg_upload_attrs

		; loader background text

		jsr vdc_set_load_buf_as_relay

		lda exp_loader_bg_start_page
		sta expansion_memory_target_pointer+1

		jsr fetch_block_vec

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

		jsr fetch_block_vec

		jsr vdc_bg_upload_attrs

		; player background text

		jsr vdc_set_load_buf_as_relay

		lda exp_player_bg_start_page
		sta expansion_memory_target_pointer+1

		jsr fetch_block_vec

	jmp vdc_bg_upload_text

	vdc_copy_loader_bg_from_cache

		; loader background attributes

		lda #>VDC_64K_CACHE_LDR_BG_ATTRS
		ldy #>VDC_ATTRIBUTES
		jsr vdc_copy_2k

		; loader background text

		lda #>VDC_64K_CACHE_LDR_BG_TEXT
		ldy #>VDC_SCREEN
		jsr vdc_copy_2k
	rts

	vdc_copy_player_bg_from_cache

		; player background attributes

		lda #>VDC_64K_CACHE_PLYR_BG_ATTRS
		ldy #>VDC_ATTRIBUTES
		jsr vdc_copy_2k

		; player background text

		lda #>VDC_64K_CACHE_PLYR_BG_TEXT
		ldy #>VDC_SCREEN
		jsr vdc_copy_2k
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
