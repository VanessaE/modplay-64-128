; this stub serves to load the rest of the program

!source "src/constants-com.h"
!source "src/misc-macros.s"

!ifndef c128 {
	!source "src/constants-64.h"
} else {
	!source "src/constants-128.h"
}

!convtab pet
!cpu 6510

* = default_start

basic_header
	!word default_start+12		; pointer to next line
	!word $000a					; line number 10
	!byte $9e					; "SYS"

	!ifndef c128 {
		!text " 2062"
	} else {
		!text " 7182"
	}
	!byte 0,0,0

boot_start
; first, show the splash screen
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

		lda #0
		ldx #<wrong_screen_msg
		ldy #>wrong_screen_msg ; ends with "ESC x", which flips back to 80 cols
		jsr print_msg

	+	lda #36 ; reduce VDC refresh rate, speeds it up
		sta VDC
		lda #0
		sta VDC+1
		ldx #<splash_data
		ldy #>splash_data
		jsr print_msg_rle

		pla
		bmi out ; if started on 80 columns, stay in 2 MHz mode.
		dec VIC+$30
		jsr enable_screen

	} else {
		lda CIA2					; CIA: select VIC-II bank 2
		and #$fd
		sta CIA2
		lda #$d4					; point VIC-II to $b400 for the screen
		sta VIC+$18					; and use the char ROM image at $9000
		lda #$b4					; point the KERNAL appropriately
		sta HIBASE
		lda #$36					; disable BASIC, else it'll corrupt the
		sta $01						; splash data
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

; now load and execute the main program file

	lda #(main_filename_end - main_filename - 1)
	ldx #<main_filename
	ldy #>main_filename
	jsr SETNAM

	!ifdef c128 {
		lda #0
		ldx #0
		jsr SETBNK
	}

	lda #0
	ldx FA
	ldy #$ff
	jsr SETLFS

	lda #0
	ldx #<program_start
	ldy #>program_start
	jsr LOAD

	jmp program_start

+PRINT_MSG
+PRINT_MSG_RLE
+SCREEN_ONOFF

!ifdef c128 {
	wrong_screen_msg
		!byte LOWER,LGRY,CLR
		!fill 12,DOWN
		!text "Please switch to the 80-column display."
		!byte ESC,"x"
		!byte 0
}

main_filename
	!ifndef scpu {
		!ifndef c128 {
			!text "mp64.main",0
		} else {
			!text "mp128.main",0
		}
	} else {
		!ifndef c128 {
			!text "mp64-scpu.main",0
		} else {
			!text "mp128-scpu.main",0
		}
	}
main_filename_end

splash_data
	!ifndef c128 {
		!binary "etc/splash-64.rle"
		!byte 0,0,0
	} else {
		!binary "etc/splash-128.rle"
		!byte 0,0,0
	}
