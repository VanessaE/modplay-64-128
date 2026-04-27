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
splash_attrs_begin = splash_data + 2000
splash_attrs_end = splash_attrs_begin + 2048

loader_background_text_begin = loader_background_data
loader_background_text_end = loader_background_data + 2048
loader_background_attrs_begin = loader_background_data + 2000
loader_background_attrs_end = loader_background_attrs_begin + 2048

player_background_text_begin = player_background_data
player_background_text_end = player_background_data + 2048
player_background_attrs_begin = player_background_data + 2000
player_background_attrs_end = player_background_attrs_begin + 2048

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
	bne ++

	lda #LRED

	bit kernal_4080_mode
	bmi +

	lda #YEL

+	jsr CHROUT

	ldx #<reu_not_found_msg
	ldy #>reu_not_found_msg
	jsr local_print_msg

	- jmp -

++	lda #0
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

	lda #CLR
	jsr CHROUT
	jmp ++

+	ldx #<wrong_screen_msg
	ldy #>wrong_screen_msg ; ends with "ESC x", which flips back to 80 cols
	jsr local_print_msg

++	jsr check_for_64k_vdc

	; upload VDC alt charset

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

	; show the splash screen

	lda #<splash_attrs_begin		; copy the attrs first to avoid the gfx
	sta fill_copy_source			; painting into and hence briefly using
	lda #>splash_attrs_begin		; wrong, possibly-bright, color data.
	sta fill_copy_source+1

	lda #<VDC_ATTRIBUTES
	sta fill_copy_target
	lda #>VDC_ATTRIBUTES
	sta fill_copy_target+1

	lda #0
	ldx #>splash_attrs_end
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

	clc
	sta highest_exp_addresss_used
	sta highest_exp_addresss_used+2

	adc #2

	sta exp_instr_names_start_page
	adc #4

	sta exp_petscii_filenames_start_page
	adc #16

	bit c128_vdc_has_64k
	bmi +

	sta exp_loader_bg_start_page
	adc #16

	sta exp_player_bg_start_page
	adc #16

+	sta exp_file_data_start_page
	adc #16

	sta highest_exp_addresss_used+1

	bit c128_vdc_has_64k
	bmi +
	jsr copy_screens_to_reu
	jmp ++

+	jsr upload_screens_to_vdc_cache

	; copy the program loader to somewhere below where the program
	; itself actually loads or it'll overwrite itself. 😛

++	ldx #0
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
check_for_64k_vdc
	jsr booter_vdc_blank

	lda #0
	sta fill_copy_target

	jsr vdc_set_41464_mode	; set 41464 mode and write a 0 to $0000

	lda #0
	sta fill_copy_target+1
	+VDC_RAM_RW_SETUP
	lda #0
	+VDC_WRITE_RAM

	lda #$80				; try to write a $ff to VDC $8000
	sta fill_copy_target+1
	+VDC_RAM_RW_SETUP
	lda #$ff
	+VDC_WRITE_RAM

	lda #0					; and see what we get back from $0000
	sta fill_copy_target+1
	+VDC_RAM_RW_SETUP

	+VDC_READ_RAM
	bne .not_64k			; if it didn't come back with a 0, VDC has 16 kB
	lda #$80				; otherwise set the flag for 64k,
	sta c128_vdc_has_64k
	lda #CLR
	jsr CHROUT
	jsr DLCHR				; and re-initialize the default charset
	jsr booter_vdc_unblank
	rts

.not_64k
	lda #0
	sta c128_vdc_has_64k
	jsr vdc_set_4416_mode
	lda #CLR
	jsr CHROUT
	jsr booter_vdc_unblank
rts

booter_vdc_blank
	+VDC_BLANK
rts

booter_vdc_unblank
	+VDC_UNBLANK
rts

vdc_set_41464_mode
	lda #28					; set 4164/41464 mode
	sta VDC_ADDR
	+VDC_UPD_RDY_WAIT
	lda #$3f
	sta VDC_DATA
rts

vdc_set_4416_mode			; otherwise put things back the way they were.
	lda #28
	sta VDC_ADDR
	+VDC_UPD_RDY_WAIT
	lda #$2f
	sta VDC_DATA
rts

upload_screens_to_vdc_cache
	; loader background text

	lda #<loader_background_text_begin
	sta fill_copy_source
	lda #>loader_background_text_begin
	sta fill_copy_source+1

	lda #<VDC_64K_CACHE_LDR_BG_TEXT
	sta fill_copy_target
	lda #>VDC_64K_CACHE_LDR_BG_TEXT
	sta fill_copy_target+1

	lda #0
	ldx #>loader_background_text_end
	jsr vdc_upload

	; loader background attributes

	lda #<loader_background_attrs_begin
	sta fill_copy_source
	lda #>loader_background_attrs_begin
	sta fill_copy_source+1

	lda #<VDC_64K_CACHE_LDR_BG_ATTRS
	sta fill_copy_target
	lda #>VDC_64K_CACHE_LDR_BG_ATTRS
	sta fill_copy_target+1

	lda #0
	ldx #>loader_background_attrs_end
	jsr vdc_upload

	; player background text

	lda #<player_background_text_begin
	sta fill_copy_source
	lda #>player_background_text_begin
	sta fill_copy_source+1

	lda #<VDC_64K_CACHE_PLYR_BG_TEXT
	sta fill_copy_target
	lda #>VDC_64K_CACHE_PLYR_BG_TEXT
	sta fill_copy_target+1

	lda #0
	ldx #>player_background_text_end
	jsr vdc_upload

	; player background attributes

	lda #<player_background_attrs_begin
	sta fill_copy_source
	lda #>player_background_attrs_begin
	sta fill_copy_source+1

	lda #<VDC_64K_CACHE_PLYR_BG_ATTRS
	sta fill_copy_target
	lda #>VDC_64K_CACHE_PLYR_BG_ATTRS
	sta fill_copy_target+1

	lda #0
	ldx #>player_background_attrs_end
	jsr vdc_upload
rts

copy_screens_to_reu
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

	; loader background attributes

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

	; player background attributes

	lda #<player_background_data+2000
	sta expansion_transfer_local_addr
	lda #>player_background_data+2000
	sta expansion_transfer_local_addr+1

	lda exp_player_bg_start_page
	adc #8
	sta expansion_memory_target_pointer+1

	jsr reu_stash_block
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

		bit SCPU_PRESENT
		bpl +

		lda #0
		ldx #<initializing_msg
		ldy #>initializing_msg
		+LOCAL_PRINT_MSG

	+	lda EAL
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
