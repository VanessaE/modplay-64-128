; This file contains all of the various in-player visualizers

!text "viz-row-data",0

!ifndef c128 {
	vizualizer_base_addr = secondary_screen + screen_width * visualizer_screen_row + visualizer_screen_column
} else {
	vizualizer_base_addr = screen_base_addr + screen_width * visualizer_screen_row + visualizer_screen_column
}

viz_line_2 = vizualizer_base_addr + screen_width
viz_line_3 = vizualizer_base_addr + screen_width*2
viz_line_4 = vizualizer_base_addr + screen_width*3
viz_line_5 = vizualizer_base_addr + screen_width*4
viz_line_6 = vizualizer_base_addr + screen_width*5

vizualizer_colors_base_addr = color_mem_base_addr + screen_width * visualizer_screen_row + visualizer_screen_column

vizualizer_colors_row_3 = vizualizer_colors_base_addr + screen_width*2

; set up base addresses, print the column dividers, and pre-fill the colors
;
; This routine is called before the sequencer starts, so any Zero Page usage
; must be stuff that's safe to use when ZP IS NOT BACKED-UP, and the KERNAL is
; banked-in at this point, so the usual PLOT, CHROUT, etc. calls are available.

viz_row_data_init
	!ifndef c128 {
		bit enable_screen_on_playback
		bpl no_vrdi
	}

	lda #<vizualizer_base_addr
	sta visualizer_base_address
	lda #>vizualizer_base_addr
	sta visualizer_base_address+1

	lda #<vizualizer_colors_base_addr
	sta utility_pointer
	sta fill_copy_target
	lda #>vizualizer_colors_base_addr
	sta utility_pointer+1
	sta fill_copy_target+1

	lda #0
	sta temp_abs_b

	lda #0
	ldx #<viz_row_position
	ldy #>viz_row_position
	jsr print_msg

	vis_init_next_row
		ldx temp_abs_b
		lda viz_row_data_colors,x
		ldx #visualizer_area_width

		!ifndef c128 {
			jsr local_ram_block_fill
		} else {
			jsr vdc_block_fill
		}

		clc
		lda utility_pointer
		adc #screen_width
		sta utility_pointer
		sta fill_copy_target
		lda utility_pointer+1
		adc #0
		sta utility_pointer+1
		sta fill_copy_target+1

		lda #0
		ldx #<viz_dividers_msg
		ldy #>viz_dividers_msg

		!ifndef c128 {
			jsr print_msg_ascii
		} else {
			jsr print_msg
		}

		inc temp_abs_b
		lda temp_abs_b
		cmp #6
	bne vis_init_next_row

	lda #0
	sta scroll_area_blank_last_line_flag

  no_vrdi
rts

; everything from here on down is called from within the sequencer, so any
; Zero Page usage must be stuff that's allowed when ZP IS BACKED-UP.

; fetch and print the first four rows of song data when a new pattern is
; selected, and clear the top two lines of the visualizer.  Expects the
; newly-selected pattern number in .Y

viz_row_data_pattern_preload
	!ifndef c128 {
		bit enable_screen_on_playback
		bmi +
		rts
	}

+	lda #<vizualizer_base_addr
	sta utility_pointer 
	lda #>vizualizer_base_addr
	sta utility_pointer+1
	jsr viz_row_data_erase_row

	lda #<viz_line_2
	sta utility_pointer 
	lda #>viz_line_2
	sta utility_pointer+1
	jsr viz_row_data_erase_row

	lda #<viz_line_3
	sta utility_pointer 
	lda #>viz_line_3
	sta utility_pointer+1

	ldx #0
	jsr viz_row_data_fetch_and_print

	lda #<viz_line_4
	sta utility_pointer 
	lda #>viz_line_4
	sta utility_pointer+1
	inx
	jsr viz_row_data_fetch_and_print

	lda #<viz_line_5
	sta utility_pointer 
	lda #>viz_line_5
	sta utility_pointer+1
	inx
	jsr viz_row_data_fetch_and_print
rts

; fetch and print one song data row, with the row number in .X
viz_row_data_fetch_and_print
	!ifndef c128 {
		bit enable_screen_on_playback
		bmi +
		rts
	  +
	}

	cpx #64
	bcc +
	rts

+	stx temp_abs_x
	sty temp_abs_y2

	jsr fetch_row_data

	!ifdef c128 { ; only display the row # on C128, C64 screen is too small
		jsr vdc_write_ram_reg_31_select_only

		txa
		jsr display_byte_hex_direct

	-	bit VDC		; perform a dummy read to skip ahead one byte
		bpl -
		bit VDC+1
	}

	!for .viz_tr, 0, 3 {
		; get/print note name
		lda seq_current_row_data + .viz_tr*4 + 1
		and #$0f
		ora seq_current_row_data + .viz_tr*4 + 2
		bne +

		lda #$2d
		jsr viz_row_data_print_char
		jsr viz_row_data_print_char
		jsr viz_row_data_print_char
		bne ++

	+	lda seq_current_row_data + .viz_tr*4 + 2
		sta utility_pointer_b
		lda seq_current_row_data + .viz_tr*4 + 1
		and #$0f
		sta utility_pointer_b+1

		clc
		lda utility_pointer_b
		adc #<viz_note_number_lookup_table
		sta utility_pointer_b
		lda utility_pointer_b+1
		adc #>viz_note_number_lookup_table
		sta utility_pointer_b+1

		ldy #0
		lda (utility_pointer_b),y
		asl
		asl
		tax
		lda note_names_table,x
		jsr viz_row_data_print_char
		inx
		lda note_names_table,x
		jsr viz_row_data_print_char
		inx
		lda note_names_table,x
		jsr viz_row_data_print_char

		; get/print sample number

	++	ldx seq_current_row_data + .viz_tr*4
		lda divide_by_16_table,x
		jsr to_hex
		jsr viz_row_data_print_char

		lda seq_current_row_data + .viz_tr*4
		jsr to_hex
		jsr viz_row_data_print_char

		; get/print effect command number

		lda seq_current_row_data + .viz_tr*4 + 1
		lsr
		lsr
		lsr
		lsr
		jsr to_hex
		jsr viz_row_data_print_char

		; get/print effect command params

		ldx seq_current_row_data + .viz_tr*4 + 3
		lda divide_by_16_table,x
		jsr to_hex
		jsr viz_row_data_print_char

		lda seq_current_row_data + .viz_tr*4 + 3
		jsr to_hex
		jsr viz_row_data_print_char

		!if .viz_tr < 3 {
			lda #RIGHT
			jsr viz_row_data_print_char
		}
	}

	ldx temp_abs_x
	ldy temp_abs_y2
rts

; "print" a single character by directly storing it to the screen
; interpreting #RIGHT as a skip-byte symbol

viz_row_data_print_char
	sta temp_abs_b

	!ifndef c128 {
		lda temp_abs_b

		cmp #RIGHT
		beq +

		ldy #0
		sta (utility_pointer),y
	+	inc utility_pointer
		bne ++
		inc utility_pointer+1
	} else {
		lda temp_abs_b
		cmp #RIGHT
		bne +

	-	bit VDC		; perform a dummy read to skip ahead one byte
		bpl -
		bit VDC+1
		jmp ++

	+	jsr vdc_continue_write_ram
	}

++	lda temp_abs_b
rts

; scroll the visualizer up one line

viz_row_data_scroll
	!ifndef c128 {
		bit enable_screen_on_playback
		bpl no_vrdsc
	}

	stx temp_abs_x
	sty temp_abs_y

	lda #<vizualizer_base_addr
	sta scroll_area_target_addr
	lda #>vizualizer_base_addr
	sta scroll_area_target_addr+1

	lda #visualizer_area_width
	sta scroll_area_width
	lda #visualizer_area_height
	sta scroll_area_height

	jsr scroll_area_up

	lda seq_current_row
	cmp #61
	bne +

	lda #<viz_line_6
	sta utility_pointer 
	lda #>viz_line_6
	sta utility_pointer+1
	jsr viz_row_data_erase_row

+	ldx temp_abs_x
	ldy temp_abs_y

  no_vrdsc
rts

; blank-out a line of the visualizer display pointed to by fill_copy_target

viz_row_data_erase_row
	sty temp_abs_y2

	!ifdef c128 {
		lda utility_pointer
		sta fill_copy_target
		lda utility_pointer+1
		sta fill_copy_target+1

		jsr vdc_write_ram_reg_31_select_only
	}

	ldy #0

	vre_loop
		lda viz_row_erase_msg,y
		beq .done_erase

		!ifndef c128 {
			cmp #RIGHT
			beq ++
			sta (utility_pointer),y
		} else {
			cmp #RIGHT
			bne +

		-	bit VDC
			bpl -
			bit VDC+1 ; do a read to skip the byte, and it's guaranteed to be non-zero
			jmp ++

		+	jsr vdc_continue_write_ram
		}

	++	iny
		cpy #visualizer_area_width
	bne vre_loop

.done_erase
	ldy temp_abs_y2
rts


; if the user toggles mute on a track, this switches the color on the highlight
; row between red and white.  ENter with .Y = track number, mute status set in
; track_current_enable_flags + .Y

viz_show_track_mute
	!ifndef c128 {
		sty temp_abs_y2
		clc
		lda #<vizualizer_colors_row_3
		adc viz_mute_color_cols,y
		sta utility_pointer
		lda #>vizualizer_colors_row_3
		adc #0
		sta utility_pointer+1
		lda track_current_enable_flags,y
		eor #$80
		clc
		rol
		rol
		adc #1
		ldy #viz_mute_colors_width
	-	sta (utility_pointer),y
		dey
		bpl -
		ldy temp_abs_y2
	} else {
		clc
		lda #<vizualizer_colors_row_3
		adc viz_mute_color_cols,y
		sta fill_copy_target
		lda #>vizualizer_colors_row_3
		adc #0
		sta fill_copy_target+1
		clc
		lda track_current_enable_flags,y
		bpl +
		lda #7
	+	adc #8
		ldx #viz_mute_colors_width
		jsr vdc_block_fill
	}
rts


!ifndef c128 {
	viz_mute_color_cols
		!byte 0,9,18,27
	viz_mute_colors_width = 7
} else {
	viz_mute_color_cols
		!byte 3,12,21,30
	viz_mute_colors_width = 8
}

viz_row_erase_msg
	!ifdef c128 {
		!byte $20,$20,RIGHT
	}
	!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
	!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
	!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
	!byte $20,$20,$20,$20,$20,$20,$20,$20,0

viz_row_data_colors
	!ifndef c128 {
		; dk. gray, lt. blue, white, lt. blue, lt. blue, dk. gray
		!byte $0b, $0e, $01, $0e, $0e, $0b
	} else {
		; dk. gray, dk. cyan, white, dk. cyan, dk. cyan, dk. gray
		!byte $01, $06, $0f, $06, $06, $01
	}

viz_dividers_msg
	!ifndef c128 {
		!fill 10,RIGHT
		!byte LGRY,$01
		!fill 8,RIGHT
		!byte $01
		!fill 8,RIGHT
		!byte $01,RETURN
		!byte 0
	} else {
		!fill 3,RIGHT
		!byte LGRY,$7d
		!fill 8,RIGHT
		!byte $7d
		!fill 8,RIGHT
		!byte $7d
		!fill 8,RIGHT
		!byte $7d,RETURN
		!byte 0
	}

viz_row_position
	!ifndef c128 {
		!byte UP,RETURN,0
	} else {
		!fill 6,UP
		!byte RETURN
		!byte 0
	}
