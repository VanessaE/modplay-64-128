; This file contains the C64/C64U row data visualizer (e.g. music/sequencer
; data, similar to what Protracker shows)

; print the column dividers and pre-fill the colors
;
; This routine is called before the sequencer starts, so any Zero Page usage
; must be stuff that's safe to use when ZP IS NOT BACKED-UP, and the KERNAL is
; banked-in at this point, so the usual PLOT, CHROUT, etc. calls are available.

viz_row_data_init
	!ifdef badlines_exist {
		bit enable_screen_on_playback
		bpl no_vrdi
	}

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
	!ifdef badlines_exist {
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
	!ifdef badlines_exist {
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

	jsr viz_row_data_print_tracks

	ldx temp_abs_x
	ldy temp_abs_y2
rts

; scroll the visualizer up one line

viz_row_data_scroll
	!ifdef badlines_exist {
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
rts

viz_row_data_mute_color_cols
	!byte 0,9,18,27
viz_row_data_mute_colors_width = 7

viz_row_data_colors

	; dk. gray, lt. blue, white, lt. blue, lt. blue, dk. gray
	!byte $0b, $0e, $01, $0e, $0e, $0b

viz_row_data_dividers_msg
	!fill 10,RIGHT
	!byte LGRY,$7d
	!fill 8,RIGHT
	!byte $7d
	!fill 8,RIGHT
	!byte $7d,RETURN
	!byte 0
