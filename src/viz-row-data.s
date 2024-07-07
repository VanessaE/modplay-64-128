; This file contains all of the various in-player visualizers

!text "viz-row-data",0

!ifndef c128 {
	viz_tl_corner_addr = secondary_screen + screen_width * visualizer_screen_row + visualizer_screen_column
} else {
	viz_tl_corner_addr = screen_base_addr + screen_width * visualizer_screen_row + visualizer_screen_column
}

viz_line_2 = viz_tl_corner_addr + screen_width
viz_line_3 = viz_tl_corner_addr + screen_width*2
viz_line_4 = viz_tl_corner_addr + screen_width*3
viz_line_5 = viz_tl_corner_addr + screen_width*4
viz_line_6 = viz_tl_corner_addr + screen_width*5

viz_colors_tl_corner_addr = color_mem_base_addr + screen_width * visualizer_screen_row + visualizer_screen_column

viz_row_data_init
	!ifndef c128 {
		bit enable_screen_on_playback
		bmi +
		rts

	+	lda #<viz_colors_tl_corner_addr
		sta visualizer_address_temp
		lda #>viz_colors_tl_corner_addr
		sta visualizer_address_temp+1
	} else {
		lda #<viz_colors_tl_corner_addr
		sta write_fill_copy_target
		lda #>viz_colors_tl_corner_addr
		sta write_fill_copy_target+1
	}

	lda #0
	sta tempzp_c

	lda #UP
	jsr CHROUT

	vis_init_next_row
		!ifndef c128 {
			ldy #0
			ldx tempzp_c
			lda viz_row_data_colors,x
		-	sta (visualizer_address_temp),y
			iny
			cpy #visualizer_area_width
			bne -

			clc
			lda visualizer_address_temp
			adc #screen_width
			sta visualizer_address_temp
			lda visualizer_address_temp+1
			adc #0
			sta visualizer_address_temp+1

			lda #0
			ldx #<viz_dividers_msg
			ldy #>viz_dividers_msg
			jsr print_msg_ascii
		} else {
			ldx tempzp_c
			lda viz_row_data_colors,x
			ldx #visualizer_area_width-1
			jsr vdc_block_fill

			clc
			lda write_fill_copy_target
			adc #screen_width
			sta write_fill_copy_target
			lda write_fill_copy_target+1
			adc #0
			sta write_fill_copy_target+1

			lda #0
			ldx #<viz_dividers_msg
			ldy #>viz_dividers_msg
			jsr print_msg
		}

		inc tempzp_c
		lda tempzp_c
		cmp #6
	bne vis_init_next_row

	lda #0
	sta scroll_area_blank_last_line_flag
rts

viz_row_data_pattern_preload
	!ifndef c128 {
		bit enable_screen_on_playback
		bmi +
		rts

	+	lda #<viz_tl_corner_addr
		sta visualizer_address_tempzpbk_a
		lda #>viz_tl_corner_addr
		sta visualizer_address_tempzpbk_a+1
	} else {
		lda #18
		sta VDC
		lda #>viz_tl_corner_addr
		sta VDC+1

		lda #19
		sta VDC
		lda #<viz_tl_corner_addr
		sta VDC+1

	-	bit VDC
		bpl -
	}

	jsr viz_row_data_erase_row

	!ifndef c128 {
		lda #<viz_line_2
		sta visualizer_address_tempzpbk_a
		lda #>viz_line_2
		sta visualizer_address_tempzpbk_a+1
	} else {
		lda #18
		sta VDC
		lda #>viz_line_2
		sta VDC+1

		lda #19
		sta VDC
		lda #<viz_line_2
		sta VDC+1

	-	bit VDC
		bpl -
	}

	jsr viz_row_data_erase_row

	lda #<viz_line_3
	sta visualizer_address_tempzpbk_a
	lda #>viz_line_3
	sta visualizer_address_tempzpbk_a+1

	ldx #0
	jsr viz_row_data_fetch_and_print

	lda #<viz_line_4
	sta visualizer_address_tempzpbk_a
	lda #>viz_line_4
	sta visualizer_address_tempzpbk_a+1

	inx
	jsr viz_row_data_fetch_and_print

	lda #<viz_line_5
	sta visualizer_address_tempzpbk_a
	lda #>viz_line_5
	sta visualizer_address_tempzpbk_a+1

	inx
	jsr viz_row_data_fetch_and_print

	lda #<viz_line_6
	sta visualizer_address_tempzpbk_a
	lda #>viz_line_6
	sta visualizer_address_tempzpbk_a+1
rts

viz_row_data_fetch_and_print
	!ifndef c128 {
		bit enable_screen_on_playback
		bmi +
		rts
	  +
	}

	sty sequencer_temp_y
	cpx #64
	bcc +

	!ifndef c128 {
		lda #<viz_line_6
		sta visualizer_address_tempzpbk_a
		lda #>viz_line_6
		sta visualizer_address_tempzpbk_a+1
	} else {
		lda #18
		sta VDC
		lda #>viz_line_6
		sta VDC+1

		lda #19
		sta VDC
		lda #<viz_line_6
		sta VDC+1

	-	bit VDC
		bpl -
	}

	jsr viz_row_data_erase_row

	rts

+	stx sequencer_temp_x

	ldx current_song_pos
	ldy pattern_table,x
	ldx sequencer_temp_x
	jsr fetch_row_data

	!ifdef c128 {
		lda #18
		sta VDC
		lda visualizer_address_tempzpbk_a+1
		sta VDC+1

		lda #19
		sta VDC
		lda visualizer_address_tempzpbk_a
		sta VDC+1
	} else {
		lda visualizer_address_tempzpbk_a
		sta visualizer_address_tempzpbk_b
		lda visualizer_address_tempzpbk_a+1
		sta visualizer_address_tempzpbk_b+1
	}

	!ifdef c128 {
		lda divide_by_16_table,x
		jsr to_hex
		jsr viz_row_data_print_char

		txa
		jsr to_hex
		jsr viz_row_data_print_char

		lda #$5d
		jsr viz_row_data_print_char
	}

	!for .viz_tr, 0, 3 {
		lda seq_current_row_data + .viz_tr*4
		bne +

		lda #$2d
		jsr viz_row_data_print_char
		jsr viz_row_data_print_char
		jsr viz_row_data_print_char
		bne ++

	+	sec
		sbc #1
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

	++	ldx seq_current_row_data + .viz_tr*4 + 1
		lda divide_by_16_table,x
		jsr to_hex
		jsr viz_row_data_print_char

		lda seq_current_row_data + .viz_tr*4 + 1
		jsr to_hex
		jsr viz_row_data_print_char

		lda seq_current_row_data + .viz_tr*4 + 2
		jsr to_hex
		jsr viz_row_data_print_char

		ldx seq_current_row_data + .viz_tr*4 + 3
		lda divide_by_16_table,x
		jsr to_hex
		jsr viz_row_data_print_char

		lda seq_current_row_data + .viz_tr*4 + 3
		jsr to_hex
		jsr viz_row_data_print_char

		!if .viz_tr < 3 {
			!ifndef c128 {
				lda #$01
			} else {
				lda #$5d
			}
			jsr viz_row_data_print_char
		}
	}

	ldx sequencer_temp_x
	ldy sequencer_temp_y
rts

viz_row_data_print_char
	sta tempzpbk_h
	sty tempzpbk_j

	!ifndef c128 {
		lda tempzpbk_h
		ldy #0
		sta (visualizer_address_tempzpbk_b),y
		inc visualizer_address_tempzpbk_b
		bne +
		inc visualizer_address_tempzpbk_b+1
	} else {
	-	bit VDC
		bpl -

		lda #31
		sta VDC
		lda tempzpbk_h
		sta VDC+1
	}

+	lda tempzpbk_h
	ldy tempzpbk_j
rts

viz_row_data_scroll
	!ifndef c128 {
		bit enable_screen_on_playback
		bmi +
		rts
	  +
	}

	sty sequencer_temp_y

	lda #<viz_line_2
	sta scroll_area_target_addr
	lda #>viz_line_2
	sta scroll_area_target_addr+1

	lda #visualizer_area_width
	sta scroll_area_width
	lda #visualizer_area_height-1
	sta scroll_area_height

	; the scroll routine uses Zero Page addrs that aren't safe to use inside
	; the player, so we have to preserve them, else it'll stomp on some
	; sequencer variables

	lda tempzp_d
	sta tempzp_d_backup
	lda tempzp_d+1
	sta tempzp_d_backup+1

	lda tempzp_e
	sta tempzp_e_backup
	lda tempzp_e+1
	sta tempzp_e_backup+1

	jsr scroll_area_up

	lda tempzp_d_backup
	sta tempzp_d
	lda tempzp_d_backup+1
	sta tempzp_d+1
	lda tempzp_e_backup
	sta tempzp_e
	lda tempzp_e_backup+1
	sta tempzp_e+1

	ldy sequencer_temp_y
rts

viz_row_data_erase_row
	sty sequencer_temp_y

	!ifdef c128 {
	-	bit VDC
		bpl -

		lda #31
		sta VDC
	}

	ldy #0

.vre_loop
	lda viz_row_erase_msg,y
	beq .done_erase

	!ifndef c128 {
		cmp #RIGHT
		beq ++
		sta (visualizer_address_tempzpbk_a),y
	} else {
		cmp #RIGHT
		bne +

		bit VDC+1 ; do a read to skip the byte, and it's guaranteed to be non-zero
		bne ++

	+	sta VDC+1
	}

++	iny
	cpy #visualizer_area_width
	bne .vre_loop

.done_erase
	ldy sequencer_temp_y
rts

viz_row_erase_msg
	!ifndef c128 {
		!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
		!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
		!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
		!byte $20,$20,$20,$20,$20,$20,$20,$20,0
	} else {
		!byte $20,$20,RIGHT
		!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
		!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
		!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
		!byte $20,$20,$20,$20,$20,$20,$20,$20,0
	}


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
		!byte RETURN
		!fill 10,RIGHT
		!byte LGRY,$01
		!fill 8,RIGHT
		!byte $01
		!fill 8,RIGHT
		!byte $01
		!byte 0
	} else {
		!byte RETURN
		!fill 2,RIGHT
		!byte LGRY,$7d
		!fill 8,RIGHT
		!byte $7d
		!fill 8,RIGHT
		!byte $7d
		!fill 8,RIGHT
		!byte $7d
		!byte 0
	}

tempzp_d_backup
	!byte 0,0
tempzp_e_backup
	!byte 0,0
