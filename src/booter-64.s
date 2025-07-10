; this stub serves to show the splash and load the rest of the program
; (C64 version)

!source "src/constants-64.h"
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

* = default_start

splash_text_begin = splash_data
splash_text_end = splash_data + 1024
splash_colors_begin = splash_data + 1000
splash_colors_end = splash_colors_begin + 1024

boot_start
; first, show the splash screen
	lda #0
	sta VIC_BORDER
	sta VIC_BACKGROUND
	lda #WHT ; FIXME -- this should be #BLK
	jsr CHROUT
	lda #LOWER
	jsr CHROUT
	lda #NOSHIFTCOM
	jsr CHROUT

	lda #CLR
	jsr CHROUT

	sei
	+C64_ENABLE_CHAR_ROM_ONLY

	; park the C64 alternate charset in RAM at $d000

	lda #<charset_alt_data
	sta fill_copy_source
	lda #>charset_alt_data
	sta fill_copy_source+1

	lda #<VIC_CHARSETS
	sta fill_copy_target
	lda #>VIC_CHARSETS
	sta fill_copy_target+1

	ldx #>(charset_alt_data+$0800)
	jsr block_copy_generic

	; download the standard charset from ROM $d800 into RAM underneath

	lda #<(VIC_CHARSETS+$0800)
	sta fill_copy_source
	lda #>(VIC_CHARSETS+$0800)
	sta fill_copy_source+1

	lda #<(VIC_CHARSETS+$0800)
	sta fill_copy_target
	lda #>(VIC_CHARSETS+$0800)
	sta fill_copy_target+1

	ldx #>(VIC_CHARSETS+$1000)
	jsr block_copy_generic

	; copy the splash screen

	+ENABLE_KERNAL_ONLY

	lda #<splash_colors_begin		; copy the colors first to avoid the gfx
	sta fill_copy_source			; painting into and hence briefly using
	lda #>splash_colors_begin		; wrong, possibly-bright, color data.
	sta fill_copy_source+1

	lda #<VIC_COLOR_RAM
	sta fill_copy_target
	lda #>VIC_COLOR_RAM
	sta fill_copy_target+1

	ldx #>splash_colors_end
	jsr block_copy_generic

	lda #<splash_text_begin
	sta fill_copy_source
	lda #>splash_text_begin
	sta fill_copy_source+1

	lda #<VIC_SCREEN
	sta fill_copy_target
	lda #>VIC_SCREEN
	sta fill_copy_target+1

	ldx #>splash_text_end
	jsr block_copy_generic

	+C64_NORMAL_SCREEN

	cli

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
-	lda program_load_decrunch_stub_origin,x
	sta program_load_decrunch_stub,x
	lda program_load_decrunch_stub_origin+$100,x
	sta program_load_decrunch_stub+$100,x
	lda program_load_decrunch_stub_origin+$200,x
	sta program_load_decrunch_stub+$200,x
	inx
	bne -

; now call that stub to load and execute the main program file

	jmp program_load_decrunch_stub

block_copy_generic
	stx .vic_end_page+1

	ldy #0
-	lda (fill_copy_source),y
	sta (fill_copy_target),y
	iny
	bne -
	inc fill_copy_source+1
	inc fill_copy_target+1
	lda fill_copy_source+1
.vic_end_page
	cmp #0
	bne -
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
		!text "mp64.main",0,0,0,0,0,0,0
		!text "mp64.main-scpu",0

	main_filename_lengths
		!byte 9
		!byte 14

	initializing_msg
		!byte HOME
		!fill 14,DOWN
		!fill 12,RIGHT
		!text CYAN,  "Initializing..."
		!byte 0
	}

charset_alt_data
	!binary "etc/charset-64a.bin"

splash_data
	!binary "etc/splash-40.pet",,5 ; why 5?  because we don't need the .pet header 🙂
