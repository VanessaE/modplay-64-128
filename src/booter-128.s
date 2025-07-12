; this stub serves to show the splash and load the rest of the program
; (C128 version)

!source "src/constants-128.h"
!source "src/misc-macros.s"

!macro LOCAL_PRINT_MSG {
	stx print_msg_addr
	sty print_msg_addr+1
	ldy #0
-	lda (print_msg_addr),y
	beq +

	jsr CHROUT
	iny
	bne -
  +
}

!convtab pet
!cpu 6510

* = program_start

splash_text_begin = splash_data
splash_text_end = splash_data + 2048
splash_colors_begin = splash_data + 2000
splash_colors_end = splash_colors_begin + 2048

boot_start

	; copy the REU driver into its proper memory slot

	+ENABLE_KERNAL_ONLY

	ldx #0
-	lda reu_driver_origin,x
	sta reu_driver,x
	inx
	bne -

	; check REU size/presence (duh 😛 )

	jsr reu_get_size
	lda reu_highest_bank
	bne +

	ldx #<reu_not_found_msg
	ldy #>reu_not_found_msg
	jsr local_print_msg

	- jmp -

	; show the splash screen

+	lda #0
	sta VIC_BORDER
	sta VIC_BACKGROUND
	lda #WHT ; FIXME -- this should be #BLK
	jsr CHROUT
	lda #LOWER
	jsr CHROUT
	lda #NOSHIFTCOM
	jsr CHROUT

	lda #36 ; reduce VDC refresh interval, speeds it up
	sta VDC_ADDR

	lda kernal_4080_mode
	pha
	bpl + ; if positive, we're on 40 columns

	+DISABLE_VIC_SCREEN
	lda #1
	sta VIC_2_MHZ
	jmp ++

+	ldx #<wrong_screen_msg
	ldy #>wrong_screen_msg ; ends with "ESC x", which flips back to 80 cols
	jsr local_print_msg

	; upload VDC alt charset

++	lda #CLR
	jsr CHROUT
	lda #<charset_alt_data
	sta fill_copy_source
	lda #>charset_alt_data
	sta fill_copy_source+1

	lda #<VDC_CHARSETS
	sta fill_copy_target
	lda #>VDC_CHARSETS
	sta fill_copy_target+1

	lda #$80
	ldx #>(charset_alt_data+$0800)
	jsr vdc_upload

	lda #<splash_colors_begin		; copy the colors first to avoid the gfx
	sta fill_copy_source			; painting into and hence briefly using
	lda #>splash_colors_begin		; wrong, possibly-bright, color data.
	sta fill_copy_source+1

	lda #<VDC_ATTRIBUTES
	sta fill_copy_target
	lda #>VDC_ATTRIBUTES
	sta fill_copy_target+1

	lda #0
	ldx #>splash_colors_end
	jsr vdc_upload

	lda #<splash_text_begin
	sta fill_copy_source
	lda #>splash_text_begin
	sta fill_copy_source+1

	lda #<VDC_SCREEN
	sta fill_copy_target
	lda #>VDC_SCREEN
	sta fill_copy_target+1

	lda #0
	ldx #>splash_text_end
	jsr vdc_upload

	pla
	bmi .out ; if started on 80 columns, stay in 2 MHz mode.

	dec VIC_2_MHZ
	+ENABLE_VIC_SCREEN

.out
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

	lda #0
	sta expansion_memory_start_page

	+SET_EXPANSION_ZONES

	lda #<2000
	sta stash_size
	lda #>2000
	sta stash_size+1

	lda #0
	sta expansion_memory_target_pointer
	sta expansion_memory_target_pointer+2

	; loader background text

	lda #<loader_background_data
	sta expansion_transfer_local_addr
	lda #>loader_background_data
	sta expansion_transfer_local_addr+1

	lda exp_loader_bg_start_page
	sta expansion_memory_target_pointer+1

	jsr reu_stash_block

	; loader background colors

	lda #<loader_background_data+2000
	sta expansion_transfer_local_addr
	lda #>loader_background_data+2000
	sta expansion_transfer_local_addr+1

	lda exp_loader_bg_start_page
	clc
	adc #8
	sta expansion_memory_target_pointer+1

	jsr reu_stash_block

	; player background text

	lda #<player_background_data
	sta expansion_transfer_local_addr
	lda #>player_background_data
	sta expansion_transfer_local_addr+1

	lda exp_player_bg_start_page
	sta expansion_memory_target_pointer+1

	jsr reu_stash_block

	; player background colors

	lda #<player_background_data+2000
	sta expansion_transfer_local_addr
	lda #>player_background_data+2000
	sta expansion_transfer_local_addr+1

	lda exp_player_bg_start_page
	adc #8
	sta expansion_memory_target_pointer+1

	jsr reu_stash_block

	; copy the program loader to somewhere below where the program
	; itself actually loads or it'll overwrite itself. 😛

	ldx #0
-	lda program_load_decrunch_stub_origin,x
	sta program_load_decrunch_stub,x
	lda program_load_decrunch_stub_origin+$100,x
	sta program_load_decrunch_stub+$100,x
	lda program_load_decrunch_stub_origin+$200,x
	sta program_load_decrunch_stub+$200,x
	inx
	bne -

	; load and execute the main program file

	jmp program_load_decrunch_stub

vdc_upload
	sta .vdc_uploading_charset+1
	stx .vdc_end_page+1

	+VDC_RAM_RW_SETUP
	ldy #0

.vdc_next_byte
+	lda (fill_copy_source),y
	+VDC_WRITE_RAM
	iny
	php

.vdc_uploading_charset	; if this is 0, upload every byte contiguously...
	lda #0				;
	beq +

	tya
	and #$07			; otherwise upload 8 real bytes,
	bne +				; then fill 8 zeroes, repeat ...

	lda #0
	ldx #8
-	+VDC_WRITE_RAM
	dex
	bne -

+	plp					; to recall if .Y reached 0
	bne .vdc_next_byte

	inc fill_copy_source+1
	lda fill_copy_source+1
.vdc_end_page
	cmp #0
	bne .vdc_next_byte
rts

local_print_msg
	+LOCAL_PRINT_MSG
rts

program_load_decrunch_stub_origin
	!pseudopc program_load_decrunch_stub {
		lda main_filename_lengths+1
		ldx #<(main_filename+16)
		ldy #>(main_filename+16)

		bit SCPU_PRESENT
		bpl +

		lda main_filename_lengths
		ldx #<main_filename
		ldy #>main_filename

	+	jsr SETNAM

		lda #0
		ldx #0
		jsr SETBNK

		lda #0
		ldx FA
		ldy #$ff
		jsr SETLFS

		lda #0
		jsr LOAD

		sei
		+ENABLE_KERNAL_ONLY

		lda #0
		ldx #<initializing_msg
		ldy #>initializing_msg
		+LOCAL_PRINT_MSG

		lda EAL
		sta $04
		lda EAL+1
		sta $05

		jsr decrunch

		jmp program_start

	decrunch
		!source "src/exomain.asm"

	main_filename
		!text "mp128.main",0,0,0,0,0,0
		!text "mp128.main-scpu",0

	main_filename_lengths
		!byte 10
		!byte 15

	initializing_msg
		!byte HOME
		!fill 14,DOWN
		!fill 29,RIGHT
		!text CYAN,"   Initializing...    "
		!byte 0
	}

reu_driver_origin
	!pseudopc reu_driver {
		!source "src/drv-reu-blockops.s"
	}

wrong_screen_msg
	!byte LOWER,LGRY,CLR
	!fill 12,DOWN
	!text "Please switch to the 80-column display.",ESC,"x"
	!byte 0

charset_alt_data
	!binary "etc/charset-128a.bin"

splash_data
	!binary "etc/splash-80.pet",,5 ; why 5?  because we don't need the .pet header 🙂

loader_background_data
	!binary "etc/loaderbg-128.pet",,5

player_background_data
	!binary "etc/playerbg-128.pet",,5
