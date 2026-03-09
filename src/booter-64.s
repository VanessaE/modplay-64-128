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

* = program_start

splash_text_begin = splash_data
splash_text_end = splash_data + 1024
splash_colors_begin = splash_data + 1000
splash_colors_end = splash_colors_begin + 1024

boot_start
	lda #0
	sta VIC_BORDER
	sta VIC_BACKGROUND

	jsr c64u_speed_check

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

+	lda #WHT ; FIXME -- this should be #BLK
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

	sta exp_screencode_filenames_start_page
	adc #16

	sta exp_menu_start_page
	adc #8

	sta exp_loader_bg_start_page
	adc #8

	sta exp_player_bg_start_page
	adc #8

	sta exp_file_data_start_page
	adc #8

	sta highest_exp_addresss_used+1

	lda #<1000
	sta stash_size
	lda #>1000
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

	lda #<loader_background_data+1000
	sta expansion_transfer_local_addr
	lda #>loader_background_data+1000
	sta expansion_transfer_local_addr+1

	lda exp_loader_bg_start_page
	clc
	adc #4
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

	lda #<player_background_data+1000
	sta expansion_transfer_local_addr
	lda #>player_background_data+1000
	sta expansion_transfer_local_addr+1

	lda exp_player_bg_start_page
	adc #4
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

local_print_msg
	+LOCAL_PRINT_MSG
rts

; Test if the machine is a C64 Ultimate, Ultimate 64, or oldskool C64

; If the computer's running at 48 MHz, the register will be 0, indicating
; an older-model Ultimate 64.

; if it's running at 64 MHz, it'll still be 255, indicating a C64 Ultimate or
; later-model Ultimate 64 Elite II+.

; Anything else, it's either an oldskool C64, or some kind of turbo is in
; play that we didn't detect.

; after that, do a second test with a shorter loop that's just enough for the
; raster low to roll over to 0 if the 1 MHz setting works.  If it stays on
; line 255, the speed has been manually set to 2 MHz or higher by the user.

; Bottom line:

; Assume an oldskool C64 if the speed cannot freely be switched between 1 MHz
; and 48/64 MHz -- that is, the first test must return 0 or 255, the second
; must return 0.


c64u_speed_check
	sei
	+DISABLE_VIC_SCREEN

	bit SCPU_PRESENT		; if SCPU is detected, disable its turbo
	bmi +

	sta SCPU_TURBO_OFF

+	lda #15
	sta c64u_speed_select	; on U64 this selects 48 MHz, on C64U it's 64 MHz

	ldx #254				; wait for raster line 254, then 255
-	cpx VIC_RASTER_LOW
	bne -
	inx
-	cpx VIC_RASTER_LOW
	bne -

	ldx #168				; 20 cycles per loop * 168 = ~3360 cycles
-	lda $1234
	lda $1234
	lda $1234
	bit $02
	dex
	bne -

	; read and store the raster low register

	lda VIC_RASTER_LOW
	sta temp_abs_a

	; Now do it all again, but this time, at 1 MHz

	lda #0
	sta c64u_speed_select

	ldx #254				; wait for line 255
-	cpx VIC_RASTER_LOW
	bne -
	inx
-	cpx VIC_RASTER_LOW
	bne -

	ldx #7					; delay loop, 70 cycles
-	nop
	bit $02
	dex
	bne -

	; read the low register again

	lda VIC_RASTER_LOW
	bne u64_turbo_broken	; if non 0, then the machine is stuck at 2+ MHz.

	lda temp_abs_a			; if second test passed, and the first test gave
	beq is_u64				; us 0 or 255, we have working turbo control
	cmp #255
	beq is_c64u
	cmp #43					; if the first test gave a value of 43 or higher,
	bcc u64_turbo_broken	; the machine is at 1 MHz.  Anything else = broken
	lda #0
	sta c64u_detect
	jmp c64u_speed_check_exit

is_u64
	lda #$60
	sta c64u_detect
	jmp c64u_speed_check_exit

is_c64u
	lda #$80
	sta c64u_detect
	jmp c64u_speed_check_exit

u64_turbo_broken
	lda #$ff
	sta c64u_detect

c64u_speed_check_exit
	+ENABLE_VIC_SCREEN
	cli

	lda c64u_detect
	cmp #$ff
	beq +
	rts

+	lda #0
	ldx #<turbo_broken_msg_1
	ldy #>turbo_broken_msg_1
	jsr local_print_msg

	lda #0
	ldx #<turbo_broken_msg_2
	ldy #>turbo_broken_msg_2
	jsr local_print_msg

	- jmp - ; hang here, we can't proceed without reliable speed control.

rts


program_load_decrunch_stub_origin
	!pseudopc program_load_decrunch_stub {
		lda c64u_detect
		beq + ; $ff was trapped-out earlier.

		lda #15+128  ; the high bit being set disables badline emulation
		sta c64u_speed_select

		lda main_filename_lengths+2
		ldx #<(main_filename+32)
		ldy #>(main_filename+32)
		jmp ++

	+	bit SCPU_PRESENT
		bmi +

		lda main_filename_lengths+1
		ldx #<(main_filename+16)
		ldy #>(main_filename+16)
		jmp ++

	+	lda main_filename_lengths
		ldx #<main_filename
		ldy #>main_filename

	++	jsr SETNAM

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
		!text "mp64.main-scpu",0,0
		!text "mp64.main-c64u",0,0

	main_filename_lengths
		!byte 9
		!byte 14
		!byte 14

	initializing_msg
		!byte HOME
		!fill 14,DOWN
		!fill 12,RIGHT
		!text CYAN,"Initializing..."
		!byte 0
	}

turbo_broken_msg_1
	!byte CLR,LOWER,LRED
;                                                  |<-- 40
	!text "Turbo was detected, but either it's not",RETURN
	!text "one of C64 Ultimate, Ultimate64, or",RETURN
	!text "SuperCPU, or user programs can't change",RETURN
	!text "the setting.  Please enable turbo",RETURN
	!text "control and restart, or disable turbo",RETURN
	!text "entirely.",RETURN,RETURN
	!byte 0

turbo_broken_msg_2
	!text "On C64U/U64: Open the main menu,",RETURN
	!text "Select Turbo Boost -> Turbo Control",RETURN
	!text "and set it to \"Turbo Registers\"."
	!byte 0

reu_driver_origin
	!pseudopc reu_driver {
		!source "src/drv-reu-blockops.s"
	}

charset_alt_data
	!binary "etc/charset-64a.bin"

splash_data
	!binary "etc/splash-40.pet",,5 ; why 5?  because we don't need the .pet header 🙂

loader_background_data
	!binary "etc/loaderbg-64-marq.pet",,5

player_background_data
	!binary "etc/playerbg-64-marq.pet",,5
