; display the splash screen

!source "src/constants.h"

!convtab pet
!cpu 6510

!ifndef c128 {
	* = $0801
} else {
	* = $13d3
}

show_splash
	!ifdef c128 {	; on C128, it'll try to run the splash twice because the
		!fill 13,0	; advance the PC to $13e0
	}

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

	+	ldx #<splash_data
		ldy #>splash_data
		jsr print_msg_rle

		pla
		bmi out ; if started on 80 columns, just exit.

		jsr SWAPPER
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
	rts ; return to the autorunner, which will load the rest of the file.

!source "src/misc-macros.s"

+STRING_OPS

!ifdef c128 {
	+SCREEN_ONOFF
	+C128_CPU_FREQ
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
		!byte 0
		!align 255,0
	}

