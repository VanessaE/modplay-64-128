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
	sta VIC_BORDER
	sta VIC_BACKGROUND

	!ifdef c128 {
		jsr disable_screen
		lda #1
		sta VIC_2_MHZ

	+	lda kernal_4080_mode
		pha
		bmi + ; if negative, already on 80 columns

		lda #0
		ldx #<wrong_screen_msg
		ldy #>wrong_screen_msg ; ends with "ESC x", which flips back to 80 cols
		jsr print_msg_rle

	+	lda #36 ; reduce VDC refresh rate, speeds it up
		sta VDC_ADDR
		lda #0
		sta VDC_DATA
		ldx #<splash_data
		ldy #>splash_data
		jsr print_msg_rle

		pla
		bmi out ; if started on 80 columns, stay in 2 MHz mode.

		dec VIC_2_MHZ
		jsr enable_screen

	} else {
		lda CIA2_PORT_A				; select VIC-II bank 2
		and #$fd
		sta CIA2_PORT_A
		lda #$04					; point VIC-II to $8000 for the screen
		sta VIC_MEM_CTRL			; and use the char ROM image at $9000
		lda #$80					; point the KERNAL appropriately
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

; we have to copy the program loader to somewhere below where the program
; itself actually loads or it'll overwrite itself. 😛 

	ldx #0
-	lda program_loader_origin,x
	sta program_loader,x
	lda program_loader_origin+$100,x
	sta program_loader+$100,x
	inx
	bne -

; now call that stub to load and execute the main program file

	jmp program_loader

program_loader_origin
	!pseudopc program_loader {
		lda main_filename_lengths+1
		ldx #<(main_filename+16)
		ldy #>(main_filename+16)

		bit SCPU_PRESENT
		bpl +

		lda main_filename_lengths
		ldx #<main_filename
		ldy #>main_filename

	+	jsr SETNAM

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

	main_filename
		!ifndef c128 {
			!text "mp64.main",0,0,0,0,0,0,0
			!text "mp64.main-scpu",0
		} else {
			!text "mp128.main",0,0,0,0,0,0
			!text "mp128.main-scpu",0
		}

	main_filename_lengths
		!ifndef c128 {
			!byte 9
			!byte 14
		} else {
			!byte 10
			!byte 15
		}
	}

+PRINT_MSG_RLE
+SCREEN_ONOFF

!ifdef c128 {
	wrong_screen_msg
		!byte $80+3
			!byte LOWER,LGRY,CLR
		!byte 12,DOWN
		!byte $80+41
			!text "Please switch to the 80-column display."
			!byte ESC,"x"
		!byte 0
}

splash_data
	!ifndef c128 {
		!binary "etc/splash-40.rle"
		!byte 0,0,0
	} else {
		!binary "etc/splash-80.rle"
		!byte 0,0,0
	}
