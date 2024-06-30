; this file handles various screen effects like the gray-out-blur-out action

!text "screen fx",0

!ifndef c128 {
	gray_out_blur_out
		jsr gray_out
		jsr blur_out
		jsr switch_to_secondary_screen
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
		sta vdc_fill_copy_dst
		lda #>VDC_ATTRIBUTES
		sta vdc_fill_copy_dst+1
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
		+	sta secondary_screen + .page*256,y
		}
		dey
		bne -
	rts
}

switch_to_primary_screen ; also switches to the PETSCII charset on C64
	!ifndef c128 {
		lda CIA2
		and #$fc
		sta CIA2
		lda #$27
		sta VIC+$18
		lda #>VIC_SCREEN			; and point the KERNAL appropriately, for
		sta HIBASE					; screen editor/CHROUT/etc.
	} else {
		lda #12
		sta VDC
		lda #>VDC_SCREEN
		sta VDC+1
		lda #13
		sta VDC
		lda #<VDC_SCREEN
		sta VDC+1
		sta VDC_VM3 ; point the KERNAL
	}
rts

clear_primary_screen_early	; redirect the KERNAL and clear
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

!ifndef c128 {
	switch_to_secondary_screen ; also switches to the ASCII charset on C64
		lda CIA2
		and #$fc
		sta CIA2
		lda #$34
		sta VIC+$18
		lda #>secondary_screen ; point the KERNAL
		sta HIBASE
	rts
}

!ifdef c128 {
	reset_attributes_charset

		lda #<VDC_ATTRIBUTES
		sta vdc_fill_copy_dst
		lda #>VDC_ATTRIBUTES
		sta vdc_fill_copy_dst+1
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
	clc
	lda scroll_area_base_addr

	!ifndef c128 {
		sta tempzp_d
		adc #screen_width
		sta tempzp_e
		lda scroll_area_base_addr+1
		sta tempzp_d+1
		adc #0
		sta tempzp_e+1
	} else {
		sta vdc_fill_copy_src
		adc #screen_width
		sta vdc_fill_copy_dst
		lda scroll_area_base_addr+1
		sta vdc_fill_copy_src+1
		adc #0
		sta vdc_fill_copy_dst+1
	}

	ldx scroll_area_height

	scroll_down_loop

		!ifndef c128 {

			ldy scroll_area_width
			dey
		-	lda (tempzp_d),y
			sta (tempzp_e),y
			dey
			bpl -

			dex
			beq blank_out_last_scrolled_line

			sec
			lda tempzp_d
			sbc #screen_width
			sta tempzp_d
			lda tempzp_d+1
			sbc #0
			sta tempzp_d+1

			lda tempzp_e
			sbc #screen_width
			sta tempzp_e
			lda tempzp_e+1
			sbc #0
			sta tempzp_e+1

		} else {

			ldy scroll_area_width
			dey
			jsr vdc_block_copy

			dex
			beq blank_out_last_scrolled_line

			sec
			lda vdc_fill_copy_src
			sbc #screen_width
			sta vdc_fill_copy_src
			lda vdc_fill_copy_src+1
			sbc #0
			sta vdc_fill_copy_src+1

			lda vdc_fill_copy_dst
			sbc #screen_width
			sta vdc_fill_copy_dst
			lda vdc_fill_copy_dst+1
			sbc #0
			sta vdc_fill_copy_dst+1
		}

	jmp scroll_down_loop

; placed between the two scroll routines so that their BEQ's can both reach.

blank_out_last_scrolled_line
	bit scroll_area_blank_last_line_flag
	bmi +
	rts

+	!ifndef c128 {
		ldy #0
		lda #$20
	-	sta (tempzp_d),y
		iny
		cpy scroll_area_width
		bne -
	} else {
		lda vdc_fill_copy_src
		sta vdc_fill_copy_dst
		lda vdc_fill_copy_src+1
		sta vdc_fill_copy_dst+1
		lda #$20
		ldx scroll_area_width
		dex
		jsr vdc_block_fill
	}
rts


scroll_area_up
	sec
	lda scroll_area_base_addr

	!ifndef c128 {
		sta tempzp_d
		sbc #screen_width
		sta tempzp_e
		lda scroll_area_base_addr+1
		sta tempzp_d+1
		sbc #0
		sta tempzp_e+1
	} else {
		sta vdc_fill_copy_src
		sbc #screen_width
		sta vdc_fill_copy_dst
		lda scroll_area_base_addr+1
		sta vdc_fill_copy_src+1
		sbc #0
		sta vdc_fill_copy_dst+1
	}

	ldx scroll_area_height

	scroll_up_loop

		!ifndef c128 {

			ldy scroll_area_width
			dey
		-	lda (tempzp_d),y
			sta (tempzp_e),y
			dey
			bpl -

			dex
			beq blank_out_last_scrolled_line

			clc
			lda tempzp_d
			adc #screen_width
			sta tempzp_d
			lda tempzp_d+1
			adc #0
			sta tempzp_d+1

			lda tempzp_e
			adc #screen_width
			sta tempzp_e
			lda tempzp_e+1
			adc #0
			sta tempzp_e+1

		} else {

			ldy scroll_area_width
			jsr vdc_block_copy

			dex
			beq blank_out_last_scrolled_line

			clc
			lda vdc_fill_copy_src
			adc #screen_width
			sta vdc_fill_copy_src
			lda vdc_fill_copy_src+1
			adc #0
			sta vdc_fill_copy_src+1

			lda vdc_fill_copy_dst
			adc #screen_width
			sta vdc_fill_copy_dst
			lda vdc_fill_copy_dst+1
			adc #0
			sta vdc_fill_copy_dst+1
		}

	jmp scroll_up_loop

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
	sta tempzp_c ; length in characters
	stx progress_bar_column
	sty progress_bar_row

	ldx progress_bar_row
	dex
	ldy progress_bar_column
	clc
	jsr PLOT

	lda #LGRY
	jsr CHROUT

	ldy tempzp_c
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

	ldy tempzp_c
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

	ldy tempzp_c
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
	sta progress_bar_addr

	lda product+1
	adc #>screen_base_addr
	sta progress_bar_addr+1

	lda progress_bar_addr
	adc progress_bar_column
	sta progress_bar_addr
	lda progress_bar_addr+1
	adc #0
	sta progress_bar_addr+1

rts

; enter this one with .A = number of segments to draw, max 255

update_progress_bar
	sta tempzp_c

	!ifdef c128 {
		lda #18
		sta VDC
		lda progress_bar_addr+1
		sta VDC+1

		lda #19
		sta VDC
		lda progress_bar_addr
		sta VDC+1

	-	bit VDC
		bpl -

		lda #31
		sta VDC
	}

	lda tempzp_c
	lsr
	lsr
	lsr
	beq nofill
	tay
	dey

	lda #$a0

-	!ifndef c128 {
		sta (progress_bar_addr),y
	} else {
	-	bit VDC
		bpl -

		sta VDC+1
	}

	dey
	cpy #255
	bne -

nofill
	lda tempzp_c
	and #$07
	tax

	lda progress_bar_segments,x

	!ifndef c128 {
		lsr tempzp_c
		lsr tempzp_c
		lsr tempzp_c
		ldy tempzp_c

		sta (progress_bar_addr),y
	} else {
	-	bit VDC
		bpl -

		sta VDC+1
	}
rts

progress_bar_segments
!ifndef c128 {
	!byte $20, $65, $74, $75, $61, $f6, $ea, $e7
} else {
	!byte $20, $99, $9a, $9b, $9c, $9d, $9e, $9f
}
