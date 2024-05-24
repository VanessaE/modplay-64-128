; display the splash screen

!source "src/constants.h"

!convtab pet
!cpu 6510

* = program_start_addr

show_splash
	lda #0
	sta VIC+$20
	sta VIC+$21
	!ifdef c128 {
		lda kernal_4080_mode
		bpl +
		jsr SWAPPER

+		jsr disable_screen
		jsr c128_set_2mhz_mode
		ldx #<wrong_screen_msg
		ldy #>wrong_screen_msg
		jsr print_msg
		jsr SWAPPER
	}

	ldx #<splash_data
	ldy #>splash_data
	jsr print_msg

	ldx #<example_rle_msg
	ldy #>example_rle_msg
	jsr print_msg_rle

	!ifdef c128 {
		jsr enable_screen
		jsr c128_set_1mhz_mode
	}
	
	rts ; return to the autorunner, which will load the rest of the file.


!ifdef c128 {
	wrong_screen_msg
		!byte LGRAY,CLEAR,LOWER
		!fill 12, DOWN
		!text "   Please switch to the VDC display."
		!byte 0
}

test_msg
	!text "Just seeing stuff"
	!byte 0

example_rle_msg
	!byte $81, "6"
	!byte $05, $ff
	!byte $81, " "
	!text $8b, "hello world"
	!byte $81, " "
	!text $06, "A"
	!text $09, "B"
	!byte $81, " "
	!text $85, "yeah!"
	!byte 0

; that should render as:
;
; "🮖🮖🮖🮖🮖 hello world AAAAAABBBBBBBBB yeah!"

!source "src/misc-macros.h"

+RLE_DECODE
+PRINT_MSG
+PRINT_MSG_RLE

!ifdef c128 {
	+SCREEN_ONOFF
	+C128_CPU_FREQ
}

splash_data
	!ifndef c128 {
		!binary "etc/splash-64-t.seq"
	} else {
		!binary "etc/splash-128-t.seq"
	}

	!byte 0,0,0
