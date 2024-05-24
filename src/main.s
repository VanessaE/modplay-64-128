; Modplay 64/128 v2.0 -- Copright 2024 Vanessa Dannenberg
;
; This code and related resources are released under Creative Commons license
; CC-By-NC-SA v4.0 -- see license.txt for all the legal mumbo-jumbo
;
; To build this project, you will need GNU Make (probably part of your
; operating system's "build essential" package), Acme Assembler, xxd, and the
; c1541 tool from VICE.
;
; Just enter the top directory and type 'make'.  By default, it builds
; everything, but you can specify targets such as "c64" or "c128" to limit
; it to just one machine.
;
; The Geany project file included in this package has a command already
; set-up in the "Build" menu.  Just click Build -> Assemble.
;
; Look in 'bin/' for the final builds, or if you prefer, there are ready-to-
; use disk images in the 'disk-images/' directory (obviously ;-) ).
;
; Run with LOAD"<whatever>",x,1

; main program code

!source "src/constants.h"

!convtab pet
!cpu 6510

* = program_start_addr

start
	!ifndef c128 {			; undo the "READY." trap
		lda #$ca
		ldx #$f1
	} else {
		lda #$79
		ldx #$ef
	}

	sta chrout_vec
	stx chrout_vec+1

	!ifdef c128 {
		jsr c128_set_2mhz_mode
	}

	ldx #<initializing_msg
	ldy #>initializing_msg
	jsr print_msg

; Codefault's count raster lines, to know if PAL or NTSC

	sei
	jsr disable_roms

	--	ldx #$aa
		-	tax
			lda VIC+$12
			bne -
		txa
		bmi --

	sta rasters_lo
	sec
	sbc #7 				; if rasters_lo > 6, the carry stays set, meaning PAL
	lda #0
	rol					; which we then roll into bit 0 of a 0 value
	sta pal_flag
	eor #$01			; invert the flag and double it
	asl					; so that raster_len is 63 on PAL, or 65 on NTSC
	adc #63
	sta raster_len


	; generate tables for JackAsser's "Seriously fast" 8x8 multiply
	; Code by Graham (reformatted for Acme and my code style)
	; https://codebase64.org/doku.php?id=base:table_generator_routine_for_fast_8_bit_mul_table

	ldx #0
	txa
	clc			; Sorry Graham, this is more readable than '!byte $c9' ;-)
	bcc +

	-	tya
	+	adc #0
	ml1
		sta multabhi,x
		tay
		cmp #$40
		txa
		ror
	ml9
		adc #0
		sta ml9+1
		inx
	ml0
		sta multablo,x
		bne -
		inc ml0+2
		inc ml1+2
		clc
		iny
		bne -

	ldx #0
	ldy #$ff

	-	lda multabhi+1,x
		sta multab2hi+$100,x
		lda multabhi,x
		sta multab2hi,y
		lda multablo+1,x
		sta multab2lo+$100,x
		lda multablo,x
		sta multab2lo,y
		dey
		inx
	bne -

; generate volume scaler tables according to:
;
; (byte_val * (vol_level + 1)) / 64  +  (63 - vol_level + 1) * 2

	lda #<volume_tables_base
	sta vol_tab_gen_vec
	lda #>volume_tables_base
	sta vol_tab_gen_vec+1
	lda #0
	sta bval_cnt		; byte value count
	sta vol_cnt			; volume count

	--	lda vol_cnt
	-	ldx bval_cnt
		jsr multiply_8x8 	; returns 14 bit value in 'product' (top 2 bits are 
							; always 0 here) MSB is also in .A at exit.

		lsr					; divide result by 64: 14 bit --> 8 bit
		ror product
		lsr
		ror product
		lsr
		ror product
		lsr
		ror product
		lsr
		ror product
		lsr
		ror product			; .A is now 0, product LSB has the final mult result

		sec					; add double (inverse of vol + 1) to shift values up
		lda #63				; to keep ~$7f in the middle of each page
		sbc vol_cnt
		clc
		adc #1
		asl
		clc
		adc product

		ldy #0
		sta (vol_tab_gen_vec),y
		inc vol_tab_gen_vec
		inc bval_cnt
		bne --
		inc vol_tab_gen_vec+1
		inc vol_cnt
		lda vol_cnt
		cmp #64
	bne -

	jsr enable_roms
	cli

	ldx #<detect_hw_msg
	ldy #>detect_hw_msg
	jsr print_msg

	jsr reu_get_size		; .A + C (9 bits) = number of banks
	sta reu_num_banks		; if 0, REU not detected at all.
	lda #0
	rol
	sta reu_num_banks+1

; display the main menu, for what little good it'll do :P
	ldx #<mani_menu_scrn
	ldy #>mani_menu_scrn
	jsr print_msg

; ---------------------------
; these would normally be set when the program's menu calls the player

	lda pal_flag					; no need to disable screen if PAL C64...
	eor #$01
;	ora #$01						; ..unless we want to force it...

	sta disable_screen_on_playback

	jsr sid_4b_start

; --------------------------

; ### Make the machine hang here
	lda #0
-	beq -

!source "src/misc-macros.h"

+RLE_DECODE
+PRINT_MSG
+PRINT_MSG_RLE
+MULTIPLY
+SCREEN_ONOFF
+ROM_SWITCHING

!ifdef c128 {
	+VDC_OPS
	+C128_CPU_FREQ
}

!source "src/player-audio.s"

!source "src/drv-reu.s"
!source "src/isr-common.s"
!source "src/drv-sid-4b.s"

!macro STATUS_LINE {
	!byte HOME
	!ifndef c128 {
		!fill 14,DOWN
		!fill 12,RIGHT
	} else {
		!fill 14,DOWN
		!fill 29,RIGHT
	}
}

!ifndef c128 {
	initializing_msg
		+STATUS_LINE
		!text CYAN,  "Initializing..."
		!byte 0

	detect_hw_msg
		+STATUS_LINE
		!text YELLOW,"Detect hardware"
		!byte 0
} else {
	initializing_msg
		+STATUS_LINE
		!text CYAN,  "   Initializing...    "
		!byte 0

	detect_hw_msg
		+STATUS_LINE
		!text YELLOW,"Detecting hardware...."
		!byte 0
}

	; pad the final file to give the machine something significant to load, to
	; create a delay between showing the splash and starting the test code.

	!ifdef c128 {
		!fill 2048, 128
	} else {
		!fill 2048, 64
	}

mani_menu_scrn

	!ifndef c128 {
		!binary "etc/main-64-t.seq"
	} else {
		!binary "etc/main-128-t.seq"
	}

	!byte 0,0,0
