; this file handles various screen effects like the gray-out-blur-out action

!text "screen fx",0

!ifndef c128 {
	gray_out_blur_out
		jsr gray_out
		jsr blur_out
		jsr set_ascii_screen
	rts
}

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

!ifndef c128 {
	blur_out
		ldy #0
	-	!for .page, 0, 3 {
			lda #132
			ldx VIC_SCREEN + .page*256,y
			cpx #128
			bcs +
			lda blurring_table,x
		+	sta VIC_SCREEN + .page*256,y
		}
		dey
		bne -
	rts
}

set_normal_screen ; also switches back to the PETSCII charset on C64
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
	set_ascii_screen
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
	jsr CHROUT
rts

!ifdef c128 {
	reset_attributes_charset

		lda #<VDC_ATTRIBUTES
		sta fill_copy_target
		lda #>VDC_ATTRIBUTES
		sta fill_copy_target+1
		lda #$01
		ldx #255
		jsr vdc_block_fill

		ldy #7
		ldx #255
		lda #$01
	-	jsr vdc_block_fill_extend
		dey
		bne -
	rts
}

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
; might be open), .A = length of the progress bar in "segments" (8 per char).

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

		jsr vdc_write_ram_reg_31_select_only
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
		jsr vdc_continue_write_ram
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
		jsr vdc_continue_write_ram
	}
rts
