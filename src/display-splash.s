; display the splash screen

!source "src/constants-com.h"
!source "src/misc-macros.s"

!ifndef c128 {
	!source "src/constants-64.h"
} else {
	!source "src/constants-128.h"
}
!convtab pet
!cpu 6510

* = program_start

show_splash
	lda #0
	sta VIC+$20
	sta VIC+$21
	!ifdef c128 {
		jsr disable_screen
		lda #1
		sta VIC+$30

		lda kernal_4080_mode
		pha
		bmi + ; if negative, already on 80 columns
		jsr SWAPPER

	+	lda #36 ; reduce VDC refresh rate, speeds it up
		sta VDC
		lda #0
		sta VDC+1
		ldx #<splash_data
		ldy #>splash_data
		jsr print_msg_rle

		pla
		bmi out ; if started on 80 columns, just exit.

		jsr SWAPPER
		lda #0
		ldx #<wrong_screen_msg
		ldy #>wrong_screen_msg
		jsr print_msg
		jsr enable_screen
		lda #$17
		sta VIC+$18 ;  printing a #LOWER doesn't work... why?! 😕 
		dec VIC+$30
		jsr SWAPPER
	} else {
		lda CIA2					; CIA: select VIC-II bank 2
		and #$fd
		sta CIA2
		lda #$d4					; point VIC-II to $b400 for the screen
		sta VIC+$18					; and use the char ROM image at $9000
		lda #$b4					; point the KERNAL appropriately
		sta HIBASE
		lda #$36					; gotta disable BASIC or it'll corrupt
		sta $01						; the splash image
		ldx #<splash_data
		ldy #>splash_data
		jsr print_msg_rle
		lda #$37
		sta $01
	}

out
	clc
	ldy #splash_ver_pos_col
	ldx #splash_ver_pos_row
	jsr PLOT

	lda #YEL
	jsr CHROUT
	lda #version_major+$30
	jsr CHROUT

	lda #LRED
	jsr CHROUT
	lda #"."
	jsr CHROUT

	lda #RED
	jsr CHROUT
	lda #version_minor+$30
	jsr CHROUT

rts ; return to the autorunner, which will load the rest of the file.

+PRINT_MSG
+PRINT_MSG_RLE
+SCREEN_ONOFF

!ifdef c128 {
	wrong_screen_msg
		!byte LGRY,CLR
		!fill 12, DOWN
		!text "Please switch to the 80-column display."
		!byte 0
}

splash_data
	!ifndef c128 {
		!binary "etc/splash-64.rle"
		!byte 0,0,0
	} else {
		!binary "etc/splash-128.rle"
		!byte 0,0,0
		* = splash_128_end_check
		!byte $ea
	}

