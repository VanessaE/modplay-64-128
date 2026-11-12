; This file contains the C128 row data visualizer (e.g. music/sequencer data,
; similar to what Protracker shows)

; print the column dividers and pre-fill the colors
;
; This routine is called before the sequencer starts, so any Zero Page usage
; must be stuff that's safe to use when ZP IS NOT BACKED-UP, and the KERNAL is
; banked-in at this point, so the usual PLOT, CHROUT, etc. calls are available.

viz_row_data_init
	jsr visualizer_clear_area

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
	sec
	jsr print_msg

	vis_row_data_init_next_row
		lda #0
		ldx #<viz_row_data_dividers_msg
		ldy #>viz_row_data_dividers_msg

		sec
		jsr print_msg

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
	lda #<visualizer_base_addr
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

	ldx seq_current_row
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
jmp viz_row_data_fetch_and_print

; fetch and print one song data row, with the row number in .X
viz_row_data_fetch_and_print
	cpx #64
	bcc +
	rts

+	stx temp_abs_x
	sty temp_abs_y2

	jsr fetch_row_data

	jsr vdc_ram_rw_setup

	txa
	jsr display_byte_hex_direct

	; perform a dummy read to skip ahead one byte
	+VDC_UPD_RDY_WAIT
	bit VDC_DATA

	jsr viz_row_data_print_tracks

	ldx temp_abs_x
	ldy temp_abs_y2
rts

; scroll the visualizer up one line

viz_row_data_scroll
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
	clc
	lda #<(visualizer_colors_row_3 + 1)
	adc viz_row_data_mute_color_cols,y
	sta fill_copy_target
	lda #>(visualizer_colors_row_3 + 1)
	adc #0
	sta fill_copy_target+1
	clc
	lda track_current_enable_flags,y
	bpl +
	lda #7
+	adc #8
	ldx #viz_row_data_mute_colors_width
jmp vdc_block_fill

viz_row_data_mute_color_cols
	!byte 3,12,21,30
viz_row_data_mute_colors_width = 8

viz_row_data_colors
	; dk. gray, dk. cyan, white, dk. cyan, dk. cyan, dk. gray
	!byte $01, $06, $0f, $06, $06, $01

viz_row_data_dividers_msg
	!fill 3,RIGHT
	!byte LGRY,$7d
	!fill 8,RIGHT
	!byte $7d
	!fill 8,RIGHT
	!byte $7d
	!fill 8,RIGHT
	!byte $7d,RETURN
	!byte 0
