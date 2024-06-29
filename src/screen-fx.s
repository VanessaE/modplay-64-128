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

	+	dex
		bne scroll_down_loop

jmp blank_out_last_scrolled_line ; exit through that routine


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
			dey
			jsr vdc_block_copy

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

	+	dex
		bne scroll_up_loop
; just fall through

blank_out_last_scrolled_line
	!ifndef c128 {
		ldy #0
		lda #$20
	-	sta (tempzp_e),y
		iny
		cpy scroll_area_width
		bne -
	} else {
		lda #$20
		ldx scroll_area_width
		dex
		jsr vdc_block_fill
	}

rts
