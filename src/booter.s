; this stub serves to load the rest of the program

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

; install the charsets
	!ifndef c128 {
		sei
		jsr enable_char_rom_only

		; park the ASCII charset in RAM at $d000, standard at $d800

		lda #<charset_64
		sta fill_copy_source
		lda #>charset_64
		sta fill_copy_source+1

		lda #<VIC_CHARSETS
		sta fill_copy_target
		lda #>VIC_CHARSETS
		sta fill_copy_target+1

		ldy #0
	-	lda (fill_copy_source),y
		sta (fill_copy_target),y
		inc fill_copy_source
		bne +
		inc fill_copy_source+1
	+	inc fill_copy_target
		bne -

		inc fill_copy_target+1
		lda fill_copy_target+1
		cmp #>(VIC_CHARSETS+$1000)
		bne -

		jsr enable_kernal_only

	} else {				; on the C128, upload it to the VDC
		bit kernal_4080_mode
		bpl +

		lda #CLR
		jsr CHROUT

	+	lda #<charset_128_alt
		sta fill_copy_source
		lda #>charset_128_alt
		sta fill_copy_source+1

		lda #<VDC_CHARSETS
		sta fill_copy_target
		lda #>VDC_CHARSETS
		sta fill_copy_target+1

		jsr vdc_ram_rw_setup

	.nextchar
		ldy #0

	-	lda (fill_copy_source),y
		jsr vdc_write_ram
		iny
		cpy #8
		bne -

		lda #0
	-	jsr vdc_write_ram
		dey
		bne -

		clc
		lda fill_copy_source
		adc #8
		sta fill_copy_source
		bcc +
		inc fill_copy_source+1
	+	lda fill_copy_source+1
		cmp #>(charset_128_alt+$0800)
		bne .nextchar
	}

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
		sec
		jsr print_msg_rle

	+	lda #36 ; reduce VDC refresh rate, speeds it up
		sta VDC_ADDR
		lda #0
		sta VDC_DATA
		ldx #<splash_data
		ldy #>splash_data
		sec
		jsr print_msg_rle

		pla
		bmi out ; if started on 80 columns, stay in 2 MHz mode.

		dec VIC_2_MHZ
		jsr enable_screen

	} else {
		+C64_NORMAL_SCREEN
		lda #$36					; disable BASIC, else it'll corrupt the
		sta $01						; splash data
		ldx #<splash_data
		ldy #>splash_data
		sec
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
+PRINT_MSG
+SCREEN_ONOFF

!source "src/misc-functions.s"

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

!ifndef c128 {
	charset_64
		!binary "etc/charset-64a.bin"
		!binary "etc/charset-64p.bin"
} else {
	charset_128_alt
		!binary "etc/charset-128a.bin"
}
