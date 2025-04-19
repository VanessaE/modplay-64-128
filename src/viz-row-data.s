; This file contains the row data visualizer (e.g. music/sequencer data,
; similar to what Protracker shows)

!text "viz-row-data",0

; print the column dividers and pre-fill the colors
;
; This routine is called before the sequencer starts, so any Zero Page usage
; must be stuff that's safe to use when ZP IS NOT BACKED-UP, and the KERNAL is
; banked-in at this point, so the usual PLOT, CHROUT, etc. calls are available.

viz_row_data_init
	!ifndef c128 {
		bit enable_screen_on_playback
		bpl no_vrdi
	}

	lda #<viz_row_data_colors
	sta viz_row_colors_vec+1
	lda #>viz_row_data_colors
	sta viz_row_colors_vec+2

	jsr visualizer_prefill_colors

	lda #0
	sta temp_abs_b

	lda #0
	ldx #<visualizer_row_position
	ldy #>visualizer_row_position
	jsr print_msg

	vis_row_data_init_next_row
		lda #0
		ldx #<viz_row_data_dividers_msg
		ldy #>viz_row_data_dividers_msg

		!ifndef c128 {
			jsr print_msg_ascii
		} else {
			jsr print_msg
		}

		inc temp_abs_b
		lda temp_abs_b
		cmp #6
	bne vis_row_data_init_next_row

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

+	lda #<visualizer_base_addr
	sta utility_pointer 
	lda #>visualizer_base_addr
	sta utility_pointer+1
	jsr visualizer_erase_row

	lda #<visualizer_line_2
	sta utility_pointer 
	lda #>visualizer_line_2
	sta utility_pointer+1
	jsr visualizer_erase_row

	lda #<visualizer_line_3
	sta utility_pointer 
	lda #>visualizer_line_3
	sta utility_pointer+1

	ldx #0
	jsr viz_row_data_fetch_and_print

	lda #<visualizer_line_4
	sta utility_pointer 
	lda #>visualizer_line_4
	sta utility_pointer+1
	inx
	jsr viz_row_data_fetch_and_print

	lda #<visualizer_line_5
	sta utility_pointer 
	lda #>visualizer_line_5
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
		jsr vdc_ram_rw_setup

		txa
		jsr display_byte_hex_direct

	-	bit VDC_ADDR	; perform a dummy read to skip ahead one byte
		bpl -
		bit VDC_DATA
	}

	!for .viz_tr, 0, 3 {
		; get/print note name
		lda seq_current_row_data + .viz_tr*4 + 1
		and #$0f
		ora seq_current_row_data + .viz_tr*4 + 2
		bne +

		lda #$2d
		jsr visualizer_print_char
		jsr visualizer_print_char
		jsr visualizer_print_char
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
		jsr visualizer_print_char
		inx
		lda note_names_table,x
		jsr visualizer_print_char
		inx
		lda note_names_table,x
		jsr visualizer_print_char

		; get/print sample number

	++	ldx seq_current_row_data + .viz_tr*4
		lda divide_by_16_table,x
		jsr to_hex
		jsr visualizer_print_char

		lda seq_current_row_data + .viz_tr*4
		jsr to_hex
		jsr visualizer_print_char

		; get/print effect command number
		; and its parameters, if possible.

		; if the effect number points to a "start" jump table entry with
		; high byte = 0, then the command is unimplemented. if greater than
		; 15, it and its params must be garbage.

		lda seq_current_row_data + .viz_tr*4 + 1
		lsr
		lsr
		lsr
		lsr
		cmp #16
		bcc +
		lda #$3f
		jsr visualizer_print_char
		jmp ++

	+	jsr to_hex
		jsr visualizer_print_char

		; unimplemented or garbage commands get a param of "??"

		lda seq_current_row_data + .viz_tr*4 + 1
		and #$f0
		lsr
		lsr
		lsr
		tax ; .X will need command no. * 2
		lda start_effect_command_jump_table+1,x
		bne +++

	++	lda #$3f
		jsr visualizer_print_char
		jsr visualizer_print_char
		jmp +

	+++	ldx seq_current_row_data + .viz_tr*4 + 3
		lda divide_by_16_table,x
		jsr to_hex
		jsr visualizer_print_char

		lda seq_current_row_data + .viz_tr*4 + 3
		jsr to_hex
		jsr visualizer_print_char

	+	!if .viz_tr < 3 {
			lda #RIGHT
			jsr visualizer_print_char
		}
	}

	ldx temp_abs_x
	ldy temp_abs_y2
rts

; scroll the visualizer up one line

viz_row_data_scroll
	!ifndef c128 {
		bit enable_screen_on_playback
		bpl no_vrdsc
	}

	stx temp_abs_x
	sty temp_abs_y

	lda #<visualizer_base_addr
	sta scroll_area_target_addr
	lda #>visualizer_base_addr
	sta scroll_area_target_addr+1

	lda #visualizer_area_width
	sta scroll_area_width
	lda #visualizer_area_height
	sta scroll_area_height

	jsr scroll_area_up

	lda seq_current_row
	cmp #61
	bne +

	lda #<visualizer_line_6
	sta utility_pointer 
	lda #>visualizer_line_6
	sta utility_pointer+1
	jsr visualizer_erase_row

+	ldx temp_abs_x
	ldy temp_abs_y

  no_vrdsc
rts

; if the user toggles mute on a track, this switches the color on the highlight
; row between red and white.  ENter with .Y = track number, mute status set in
; track_current_enable_flags + .Y

viz_row_data_show_track_mute
	!ifndef c128 {
		sty temp_abs_y2
		clc
		lda #<visualizer_colors_row_3
		adc viz_row_data_mute_color_cols,y
		sta utility_pointer
		lda #>visualizer_colors_row_3
		adc #0
		sta utility_pointer+1
		lda track_current_enable_flags,y
		eor #$80
		clc
		rol
		rol
		adc #1
		ldy #viz_row_data_mute_colors_width
	-	sta (utility_pointer),y
		dey
		bpl -
		ldy temp_abs_y2
	} else {
		clc
		lda #<visualizer_colors_row_3
		adc viz_row_data_mute_color_cols,y
		sta fill_copy_target
		lda #>visualizer_colors_row_3
		adc #0
		sta fill_copy_target+1
		clc
		lda track_current_enable_flags,y
		bpl +
		lda #7
	+	adc #8
		ldx #viz_row_data_mute_colors_width
		jsr vdc_block_fill
	}
rts

!ifndef c128 {
	viz_row_data_mute_color_cols
		!byte 0,9,18,27
	viz_row_data_mute_colors_width = 7
} else {
	viz_row_data_mute_color_cols
		!byte 3,12,21,30
	viz_row_data_mute_colors_width = 8
}

viz_row_data_colors
	!ifndef c128 {
		; dk. gray, lt. blue, white, lt. blue, lt. blue, dk. gray
		!byte $0b, $0e, $01, $0e, $0e, $0b
	} else {
		; dk. gray, dk. cyan, white, dk. cyan, dk. cyan, dk. gray
		!byte $01, $06, $0f, $06, $06, $01
	}

viz_row_data_dividers_msg
	!ifndef c128 {
		!fill 10,RIGHT
		!byte LGRY,$82
		!fill 8,RIGHT
		!byte $82
		!fill 8,RIGHT
		!byte $82,RETURN
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
