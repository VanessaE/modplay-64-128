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
		+VDC_BLOCK_FILL VDC_ATTRIBUTES, 255, $81
		ldy #7
	-	+VDC_BLOCK_FILL_CONT 255, $81
		dey
		bne -
	}
rts

!ifndef c128 {
	blur_out
		ldy #0
	-	!for .page, 0, 3 {
			lda #132
			sec
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
		lda #$37
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
		lda #$24
		sta VIC+$18
		lda #>secondary_screen ; point the KERNAL
		sta HIBASE
	rts
}

!ifdef c128 {
	reset_attributes_charset
		+VDC_BLOCK_FILL VDC_ATTRIBUTES, 255, 1
		ldy #7
	-	+VDC_BLOCK_FILL_CONT 255, 1
		dey
		bne -
	rts
}

;#######################
;# C128 VDC OPERATIONS #
;#######################

!ifdef c128 {
	vdc_read_reg_sw		; sw means "status wait", so only use this and its
		stx VDC			; companion below when waiting for the VDC
	-	bit VDC			; status reg to clear is required
		bpl -
		lda VDC+1
	rts

	vdc_write_reg_sw
		stx VDC
	-	bit VDC
		bpl -
		sta VDC+1
	rts

	; first use the VDC_BLOCK_COPY_INIT macro, then enter with .X = length
	vdc_block_copy
	-	bit VDC
		bpl -

		lda #18
		sta VDC
		lda tempzp_e+1
		sta VDC+1

		lda #19
		sta VDC
		lda tempzp_e
		sta VDC+1

		lda #24
		sta VDC
		lda #$a0
		sta VDC+1

		lda #32
		sta VDC
		lda tempzp_d+1
		sta VDC+1

		lda #33
		sta VDC
		lda tempzp_d
		sta VDC+1

		lda #30
		sta VDC
		stx VDC+1
	rts
}
