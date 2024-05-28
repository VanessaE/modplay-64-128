; display the splash screen

!source "src/constants-com.h"

!ifndef c128 {
	!source "src/constants-64.h"
} else {
	!source "src/constants-128.h"
}
!convtab pet
!cpu 6510

* = program_start

show_splash
	php
	sei
	jsr enable_kernal_only
	lda #0
	sta VIC+$20
	sta VIC+$21
	!ifdef c128 {
		jsr disable_screen
		jsr c128_set_2mhz_mode
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
		jsr c128_set_1mhz_mode
		jsr SWAPPER
	} else {
		ldx #<splash_data
		ldy #>splash_data
		jsr print_msg_rle
	}
out
	jsr enable_roms
	plp
	rts ; return to the autorunner, which will load the rest of the file.

!source "src/misc-macros.s"

print_msg
	+PRINT_MSG
rts

print_msg_rle
	+PRINT_MSG_RLE
rts

+SCREEN_ONOFF
+ROM_SWITCHING

!ifdef c128 {
	+CPU_FREQ
}

!ifdef c128 {
	wrong_screen_msg
		!byte LGRY,CLR,LOWER
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

