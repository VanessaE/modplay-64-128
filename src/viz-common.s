; this file contains the various routines that can be used by more than one
; visualizer mode

!ifndef c128 {
	visualizer_area_width				= 36
	visualizer_area_height				= 6

	visualizer_screen_column			= 2
	visualizer_screen_row				= 12

	visualizer_base_addr = VIC_SCREEN + screen_width * visualizer_screen_row + visualizer_screen_column
	visualizer_width = 36

	visualizer_colors_base_addr = color_mem_base_addr + screen_width * visualizer_screen_row + visualizer_screen_column

} else {
	visualizer_area_width				= 40
	visualizer_area_height				= 6

	visualizer_screen_column			= 21
	visualizer_screen_row				= 12

	visualizer_base_addr = screen_base_addr + screen_width * visualizer_screen_row + visualizer_screen_column
	visualizer_width = 40

	visualizer_colors_base_addr = color_mem_base_addr + screen_width * visualizer_screen_row + visualizer_screen_column - 1
}

visualizer_line_2 = visualizer_base_addr + screen_width
visualizer_line_3 = visualizer_base_addr + screen_width*2
visualizer_line_4 = visualizer_base_addr + screen_width*3
visualizer_line_5 = visualizer_base_addr + screen_width*4
visualizer_line_6 = visualizer_base_addr + screen_width*5

visualizer_colors_row_3 = visualizer_colors_base_addr + screen_width*2

; This routine is called before the sequencer starts, so any Zero Page usage
; must be stuff that's safe to use when ZP IS NOT BACKED-UP, and the KERNAL is
; banked-in at this point, so the usual PLOT, CHROUT, etc. calls are available.

visualizer_clear_area
	lda #6 ; height is always 6
	sta erase_screen_area_row_count
	lda #visualizer_width

	!ifndef c128 {
		ldx #<visualizer_base_addr
		ldy #>visualizer_base_addr

		jsr vic_erase_screen_area
	} else {
		ldx #<(visualizer_base_addr-1)
		ldy #>(visualizer_base_addr-1)
		jsr vdc_erase_screen_area
	}
rts

visualizer_prefill_colors
	lda #<visualizer_base_addr
	sta visualizer_base_address
	lda #>visualizer_base_addr
	sta visualizer_base_address+1

	lda #<visualizer_colors_base_addr
	sta utility_pointer
	sta fill_copy_target
	lda #>visualizer_colors_base_addr
	sta utility_pointer+1
	sta fill_copy_target+1

	lda #0
	sta temp_abs_b

	viz_colors_init_next_row
		ldx temp_abs_b

		; the current visualizer will set this address to the proper color table
		viz_row_colors_vec
		  lda $1234,x

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

		inc temp_abs_b
		lda temp_abs_b
		cmp #6
	bne viz_colors_init_next_row
rts

; everything from here on down is called from within the sequencer, so any
; Zero Page usage must be stuff that's allowed when ZP IS BACKED-UP.

; "print" a single character by directly storing it to the screen, and skip
; over a screen position.  on the C64, .Y is the column within the row that
; utility_pointer points at.  on the C128, the VDC's own address register keeps
; track of the position.  neither one changes .A or .X.

!macro VIZ_PUT_CHAR {
	!ifndef c128 {
		sta (utility_pointer),y
		iny
	} else {
		jsr vdc_write_ram
	}
}

!macro VIZ_SKIP_CHAR {
	!ifndef c128 {
		iny
	} else {
		; perform a dummy read to skip ahead one byte
		+VDC_UPD_RDY_WAIT
		bit VDC_DATA
	}
}

; print the four tracks' worth of the song data row that's in the row data
; buffer:  note name, sample number, effect command and its parameters.  on the
; C64, utility_pointer must point at the start of the screen row.  on the C128,
; the VDC must be set up to write at the first track's position.
;
; trashes .A, .X, .Y and utility_pointer_b.

viz_row_data_track_offset = sequencer_temp_y

viz_row_data_print_tracks
	!ifndef c128 {
		ldy #0
	}

	ldx #0

.vrd_next_track
	stx viz_row_data_track_offset

	; get/print note name

	lda seq_current_row_data+1,x
	and #$0f
	ora seq_current_row_data+2,x
	bne +

	lda #$2d
	+VIZ_PUT_CHAR
	+VIZ_PUT_CHAR
	+VIZ_PUT_CHAR
	jmp .vrd_sample_number

	; the lookup table is page-aligned, so the period's low byte is the low
	; byte of the entry's address as it is (see assemble-errs.s)

+	lda seq_current_row_data+2,x
	sta utility_pointer_b
	lda seq_current_row_data+1,x
	and #$0f
	clc
	adc #>viz_note_number_lookup_table
	sta utility_pointer_b+1

	ldx #0
	lda (utility_pointer_b,x)
	asl
	asl
	tax
	lda note_names_table,x
	+VIZ_PUT_CHAR
	lda note_names_table+1,x
	+VIZ_PUT_CHAR
	lda note_names_table+2,x
	+VIZ_PUT_CHAR

	; get/print sample number

.vrd_sample_number
	ldx viz_row_data_track_offset
	lda seq_current_row_data,x
	jsr .vrd_put_hex_byte

	; get/print effect command number
	; and its parameters, if possible.

	; if the effect number points to a "start" jump table entry with
	; high byte = 0, then the command is unimplemented.

	ldx viz_row_data_track_offset
	lda seq_current_row_data+1,x
	tax
	lda divide_by_16_table,x
	cmp #14 ; extended commands need extra checks
	bne +

	lda #$45 ; "E"
	+VIZ_PUT_CHAR

	ldx viz_row_data_track_offset
	lda seq_current_row_data+3,x
	tax
	lda divide_by_16_table,x
	cmp #5 ; ext cmd 5 needs custom handling
	beq .vrd_print_cmd_args
	tax
	lda extended_effect_command_jump_table_highs,x
	beq .vrd_print_arg_qmarks
	bne .vrd_print_cmd_args

+	tax
	jsr to_hex
	+VIZ_PUT_CHAR

	; unimplemented commands get a param of "??"

	lda start_effect_command_jump_table_highs,x
	bne .vrd_print_cmd_args

.vrd_print_arg_qmarks
	lda #$3f
	+VIZ_PUT_CHAR
	+VIZ_PUT_CHAR
	jmp .vrd_track_done

.vrd_print_cmd_args
	ldx viz_row_data_track_offset
	lda seq_current_row_data+3,x
	jsr .vrd_put_hex_byte

.vrd_track_done
	clc
	lda viz_row_data_track_offset
	adc #4
	cmp #16
	beq +

	tax
	+VIZ_SKIP_CHAR
	jmp .vrd_next_track
  +
rts

; print the byte in .A as two hex digits

.vrd_put_hex_byte
	tax
	lda divide_by_16_table,x
	jsr to_hex
	+VIZ_PUT_CHAR
	txa
	jsr to_hex
	+VIZ_PUT_CHAR
rts

; blank-out a line of the visualizer display pointed to by fill_copy_target

visualizer_erase_row
	sty temp_abs_y2

	!ifdef c128 {
		lda utility_pointer
		sta fill_copy_target
		lda utility_pointer+1
		sta fill_copy_target+1

		jsr vdc_ram_rw_setup
	}

	ldy #0

	vre_loop
		lda visualizer_row_erase_msg,y
		beq .done_erase

		!ifndef c128 {
			cmp #RIGHT
			beq .viz_erase_iny
			sta (utility_pointer),y
		} else {
			cmp #RIGHT
			bne +

			+VDC_UPD_RDY_WAIT
			bit VDC_DATA ; do a read to skip the byte, and it's guaranteed to be non-zero
			jmp .viz_erase_iny

		+	jsr vdc_write_ram
		}

	.viz_erase_iny
		iny
		cpy #visualizer_area_width
	bne vre_loop

.done_erase
	ldy temp_abs_y2
rts

visualizer_row_erase_msg
	!ifdef c128 {
		!byte $20,$20,RIGHT
	}
	!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
	!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
	!byte $20,$20,$20,$20,$20,$20,$20,$20,RIGHT
	!byte $20,$20,$20,$20,$20,$20,$20,$20,0

visualizer_row_position
	!ifndef c128 {
		!byte UP,RETURN,0
	} else {
		!byte HOME
		!fill 7,DOWN
		!byte RETURN
		!byte 0
	}
