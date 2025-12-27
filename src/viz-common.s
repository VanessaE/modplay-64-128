; this file contains the various routines that can be used by more than one
; visualizer mode

!ifndef c128 {
	visualizer_base_addr = VIC_SCREEN + screen_width * visualizer_screen_row + visualizer_screen_column
	visualizer_width = 36
} else {
	visualizer_base_addr = screen_base_addr + screen_width * visualizer_screen_row + visualizer_screen_column
	visualizer_width = 40
}

visualizer_line_2 = visualizer_base_addr + screen_width
visualizer_line_3 = visualizer_base_addr + screen_width*2
visualizer_line_4 = visualizer_base_addr + screen_width*3
visualizer_line_5 = visualizer_base_addr + screen_width*4
visualizer_line_6 = visualizer_base_addr + screen_width*5

visualizer_colors_base_addr = color_mem_base_addr + screen_width * visualizer_screen_row + visualizer_screen_column

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

; "print" a single character by directly storing it to the screen
; interpreting #RIGHT as a skip-byte symbol

visualizer_print_char
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

		; perform a dummy read to skip ahead one byte
		+VDC_UPD_RDY_WAIT
		bit VDC_DATA
		jmp ++

	+	jsr vdc_write_ram
	}

++	lda temp_abs_b
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
			beq ++
			sta (utility_pointer),y
		} else {
			cmp #RIGHT
			bne +

			+VDC_UPD_RDY_WAIT
			bit VDC_DATA ; do a read to skip the byte, and it's guaranteed to be non-zero
			jmp ++

		+	jsr vdc_write_ram
		}

	++	iny
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
