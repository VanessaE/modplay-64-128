; this section is responsible for initializing everything at startup
; note that the first byte of this file is page-aligned from modplay.s

init
	; make sure interrupts can't do anything if one fires and the
	; KERNAL is out before actual interrupt sources have been set up.
	; the target is a single RTI in modplay.s

	lda #<lockout_interrupts
	sta CPU_IRQ_vector
	lda #>lockout_interrupts
	sta CPU_IRQ_vector+1

	lda #<lockout_interrupts
	sta CPU_NMI_vector
	lda #>lockout_interrupts
	sta CPU_NMI_vector+1

	!ifdef c128 {
		lda #1
		sta C128_VIC_CLOCK_SPEED
		jsr disable_vic_screen
		lda #$20
		sta RPTFLAG ; disables key repeat other than cursor, space, delete
	}

	jsr CLALL

	!ifdef scpu {
		bit SCPU_PRESENT
		bmi +

		sta SCPU_TURBO_ON
		sta SCPU_ENABLE_HW_REGS
		lda #%10000100					; disable all local RAM echoing
		sta SCPU_OPTIMIZATION_MODE
		sta SCPU_DISABLE_HW_REGS
	  +
	}

	lda #0

	ldy #0
-	sta main_variables_zone,y
	sta main_variables_zone+$0100,y
	sta main_variables_zone+$0200,y
	sta main_variables_zone+$0300,y
	sta main_variables_zone+$0400,y ; main vars end at $0fff

	sta main_variables_zone+$0500,y ; a few random small tables
	sta main_variables_zone+$0600,y ; audio buf left
	sta main_variables_zone+$0700,y ; audio buf right

	sta playlist_file_sizes_lows,y
	sta playlist_file_sizes_highs,y
	iny
	bne -

	!ifdef scpu {			; now that the main vars zone is zeroed, we can
		bit SCPU_PRESENT	; save the state of the detect flag
		bmi +
		lda #$80
		sta supercpu_detected

		sta SCPU_ENABLE_HW_REGS

		lda SCPU_RAM_LAST_PAGE
		sta supercpu_last_free_page
		lda SCPU_RAM_LAST_BANK
		sta supercpu_last_free_bank

		sta SCPU_DISABLE_HW_REGS
	  +
	}

	!ifdef c128 { ; reset F-keys to normal PETSCII codes
		ldy #9
	-	lda #1
		sta PKYBUF,y
		lda fkey_codes,y
		sta PKYDEF,y
		dey
		bpl -
	}

	ldy #0
-	lda default_config,y
	sta config_space,y
	cmp #$ff
	beq +
	iny
	jmp -

+	lda FA
	sta boot_device
	sta load_device
	lda #0
	sta MSGFLG ; suppress "SEARCHING FOR..." message

	; try to load the config file

	lda config_filename_len
	ldx #<config_filename
	ldy #>config_filename
	jsr SETNAM

	!ifdef c128 {
		lda #0
		ldx #0
		jsr SETBNK
	}

	lda #0
	ldx boot_device
	ldy #$ff
	jsr SETLFS

	lda #0
	ldx #<config_space
	ldy #>config_space
	jsr LOAD
	bcc +
	jsr read_err_channel

+	lda #0
	sta current_menu_page

	; test highest C128 bank number (normally it'll only return 1 or 3, unless
	; the user's MMU hack is broken :-P)

	!ifdef c128 {

		lda #<main_mem_free_end
		sta indstash_addr
		lda #>main_mem_free_end
		sta indstash_addr+1

		ldy #0

		ldx #%11111110	; select bank 3
		lda #$33
		jsr IND_STASH

		ldx #%10111110	; select bank 2
		lda #$22
		jsr IND_STASH

		ldx #%01111110	; select bank 1
		lda #$11
		jsr IND_STASH

		lda #0
		sta main_mem_free_end

	; now try to read them back

		lda #<main_mem_free_end
		sta indfetch_addr
		lda #>main_mem_free_end
		sta indfetch_addr+1

		ldx #%11111110	; select bank 3
		jsr IND_FETCH
		cmp #$33
		bne +
		lda #3
		jmp ++

	+	ldx #%10111110	; select bank 2
		jsr IND_FETCH
		cmp #$22
		bne +
		lda #2
		jmp ++

	+	ldx #%01111110	; select bank 1
		jsr IND_FETCH
		cmp #$11
		bne +
		lda #1
		jmp ++

	+	lda #0
	++	sta c128_highest_bank

	}

	; REU start page, to be specific
	lda #0
	sta expansion_memory_start_page

	; generate tables for JackAsser's "Seriously fast" 8x8 multiply
	; Code by Graham (reformatted for Acme and my code style)
	; https://codebase64.org/doku.php?id=base:table_generator_routine_for_fast_8_bit_mul_table

+	ldx #0
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

	ldx #0
-	txa
	lsr
	lsr
	lsr
	lsr
	sta divide_by_16_table,x
	inx
	bne -

	ldx #0
-	txa
	and #$f0
	sta and_f0_table,x
	inx
	bne -

	; J0x's count raster lines code, to know if machine is PAL or NTSC

	sei
--	lda VIC_RASTER_LOW
-	cmp VIC_RASTER_LOW
	beq -
	bmi --
	cmp #$20			; leaves carry set if PAL
	cli

	ldx #63

	lda #0
	ror					; which we then roll into bit 7 of a 0 value
	sta pal_flag
	bmi +				; if not PAL, add 2 to the length, for NTSC
	inx
	inx
+	stx raster_len

	lda CIA2_CRA	; ensure that the TOD clock counts 50 or 60 ticks/sec
	and #$7f		; depending on PAL or NTSC -- except this doesn't work on PAL SX64
	ora pal_flag
	sta CIA2_CRA

	jsr semitones_table_copy
	jsr fine_tuning_table_copy
	jsr note_names_table_copy
	jsr sixteenth_semitones_table_copy

	ldx #15
-	lda nybble_x10_origin,x
	sta nybble_x10,x
	dex
	bpl -

	ldx #7
-	lda progress_bar_segments_origin,x
	sta progress_bar_segments,x
	dex
	bpl -

	ldx #28
-	lda mod_magic_numbers_origin,x
	sta mod_magic_numbers,x
	dex
	bpl -

	ldx #0
-	lda mah_table_6581_origin,x
	sta mah_table_6581,x
	lda mah_table_8580_origin,x
	sta mah_table_8580,x
	inx
	bne -

	jsr under_kernal_code_copy

	lda #0
	sta DMA_ADDR_CONTROL	; just to make sure it's in normal mode 😛

	lda #<reu_fetch_block
	sta fetch_block_vec+1
	lda #>reu_fetch_block
	sta fetch_block_vec+2

	lda #<reu_stash_block
	sta stash_block_vec+1
	lda #>reu_stash_block
	sta stash_block_vec+2

	lda #<reu_fetch_row
	sta fetch_row_expansion_vec+1
	lda #>reu_fetch_row
	sta fetch_row_expansion_vec+2

	lda #<reu_set_cycle_counts
	sta ram_driver_set_cycle_counts_vec+1
	lda #>reu_set_cycle_counts
	sta ram_driver_set_cycle_counts_vec+2

	lda #<reu_run_fetch_and_mixer
	sta run_fetch_and_mixer_vec+1
	lda #>reu_run_fetch_and_mixer
	sta run_fetch_and_mixer_vec+2

	lda #<reu_do_selfmods_for_pitch_change
	sta do_selfmod_pitch_vec+1
	lda #>reu_do_selfmods_for_pitch_change
	sta do_selfmod_pitch_vec+2

	lda #<reu_do_selfmods_for_instrument_change
	sta do_selfmod_instrument_vec+1
	lda #>reu_do_selfmods_for_instrument_change
	sta do_selfmod_instrument_vec+2

	jsr disable_roms

	jsr set_cia2_cra_default_val

	jsr init_audio_driver
	jsr check_sid_type_left
	jsr check_sid_type_right

	jsr generate_note_number_lookup_table

	!ifdef c128 {
		jsr erase_file_list
	}

	jsr ascii_table_copy

	lda #0						; (the loader sets this for each file)
	sta multirate_enable
rts

; ####### end of main init code

; Support/copy-in routines

zero_count	!byte 0

copy_code				; call this with fill_copy_source = source,
	ldy #0				; fill_copy_target = target, data will be copied
--	lda #3				; until three 0's are found.
	sta zero_count
-	lda (fill_copy_source),y
	sta (fill_copy_target),y
	inc fill_copy_source
	bne +
	inc fill_copy_source+1

+	inc fill_copy_target
	bne +
	inc fill_copy_target+1

+	and #$ff
	bne --
	dec zero_count
	bne -
rts

semitones_table_copy
	ldx #31
-	lda semitones_table_origin,x
	sta semitones_table,x
	dex
	bpl -
rts

fine_tuning_table_copy
	ldx #31
-	lda fine_tuning_table_origin,x
	sta fine_tuning_table,x
	dex
	bpl -
rts

sixteenth_semitones_table_copy
	ldx #15
-	lda sixteenth_semitones_table_lows_origin,x
	sta sixteenth_semitones_table_lows,x
	lda sixteenth_semitones_table_highs_origin,x
	sta sixteenth_semitones_table_highs,x
	dex
	bpl -
rts

one_semitone				= 1.059463094 ; 2^(1/12)
one_eighth_semitone			= 1.007246412 ; 2^(1/(12*8))
one_sixteenth_semitone		= 1.003616666 ; 2^(1/(12*16))

semitones_table_origin
	!for s2, 0, 15 {
		!zone {
			!word int((one_semitone ^ s2) * 256)
		}
	}

; Since we're dealing with note periods, not frequencies,
; the table has to be "inverted".

fine_tuning_table_origin
	!for ft, 0, -7 {
		!word int((one_eighth_semitone ^ ft) * 32768)
	}
	!for ft, 8, 1 {
		!word int((one_eighth_semitone ^ ft) * 32768)
	}

sixteenth_semitones_table_lows_origin
	!for vib, 0, -15 {
		!zone {
			!byte int((one_sixteenth_semitone ^ vib) * 32768) AND 255
		}
	}

sixteenth_semitones_table_highs_origin
	!for vib, 0, -15 {
		!zone {
			!byte int((one_sixteenth_semitone ^ vib) * 32768 / 256)
		}
	}

note_names_table_copy
	ldx #0

-	lda note_names_table_origin,x
	cmp #"#" ; if it's a pound, replace it with a sharp accidental, char #95
	bne +
	lda #95

+	sta note_names_table,x
	inx
	cpx #244
	bne -
  +
rts

ascii_table_copy
	ldx #0
-	lda ascii_to_petscii_table_origin,x
	sta ascii_to_petscii_table,x
	inx
	bne -
rts

fkey_codes					!byte $85,$89,$86,$8a,$87,$8b,$88,$8c

default_config
	!ifdef c128 {			; signature
		!byte 128,"c",1,2,8
	} else ifdef c64u {
		!byte 48,"c",6,4,"u"
	} else {
		!byte 64,0,"c",6,4
	}

	!ifdef turbo_available {
		!byte 8					; default device
		!word $d420				; default stereo SID addr
		!word $dd01				; default DAC addr
		!byte 1					; default audio driver (SID 4-bit)
		!byte 1					; default RAM driver (REU)
		!byte $80				; default Stereo mode (on)
		!byte 0					; default visualizer mode (row data)
		!byte $80				; default dithering mode (on)
		!byte 0					; [always 0]
		!byte 0					; [always 0]
		!byte 0					; [always 0]
		!byte $ff				; end of file marker
	} else ifdef c128{
		!byte 8					; default device
		!word $d700				; default stereo SID addr
		!word $dd01				; default DAC addr
		!byte 2					; default audio driver (SID Mahoney method)
		!byte 1					; default RAM driver (REU)
		!byte $80				; default Stereo mode (on)
		!byte 0					; default visualizer mode (row data)
		!byte 0					; default dithering mode (off)
		!byte $80				; default screen enable (on)
		!byte $40				; default load filter setting (good)
		!byte 1					; default multirate mode (preferred)
		!byte $ff				; end of file marker
	} else {
		!byte 8					; default device
		!word $d700				; default stereo SID addr
		!word $dd01				; default DAC addr
		!byte 2					; default audio driver (SID Mahoney method)
		!byte 1					; default RAM driver (REU)
		!byte $80				; default Stereo mode (on)
		!byte 0					; default visualizer mode (row data)
		!byte 0					; default dithering mode (off)
		!byte $80				; default screen enable (on)
		!byte $80				; default load filter setting (best)
		!byte 1					; default multirate mode (preferred)
		!byte $ff				; end of file marker
	}

configuration_data_end

nybble_x10_origin
	!byte 0,10,20,30,40,50,60,70,80,90,100,110,120,130,140,150

progress_bar_segments_origin
	!byte $20, $65, $74, $75, $61, $f6, $ea, $e7

!ct raw {
	mod_magic_numbers_origin ; type 1 is 15 samples e.g. Soundtracker
		!text "M.K." ; file type 2 \___ Protracker
		!text "M!K!" ;             /
		!text "FLT4" ; file type 4 \___ StarTrekker
		!text "FLT8" ;             /
		!text "4CHN" ; file type 6 ¯|
		!text "6CHN" ;              |-- FastTracker
		!text "8CHN" ; file type 8 _|
		!byte 0
}

note_names_table_origin
!ct scr {
	!text "???",0
	!text "B-4",0,"A#4",0,"A-4",0,"G#4",0,"G-4",0,"F#4",0,"F-4",0,"E-4",0,"D#4",0,"D-4",0,"C#4",0,"C-4",0
	!text "B-3",0,"A#3",0,"A-3",0,"G#3",0,"G-3",0,"F#3",0,"F-3",0,"E-3",0,"D#3",0,"D-3",0,"C#3",0,"C-3",0
	!text "B-2",0,"A#2",0,"A-2",0,"G#2",0,"G-2",0,"F#2",0,"F-2",0,"E-2",0,"D#2",0,"D-2",0,"C#2",0,"C-2",0
	!text "B-1",0,"A#1",0,"A-1",0,"G#1",0,"G-1",0,"F#1",0,"F-1",0,"E-1",0,"D#1",0,"D-1",0,"C#1",0,"C-1",0
	!text "B-0",0,"A#0",0,"A-0",0,"G#0",0,"G-0",0,"F#0",0,"F-0",0,"E-0",0,"D#0",0,"D-0",0,"C#0",0,"C-0",0
}

mah_table_6581_origin
	!source "src/mah-table-6581.s"

mah_table_8580_origin
	!source "src/mah-table-8580.s"

binsearch_note_period_table
	!word  57,  60,   64,   67,   71,   76,   80,   85,   90,   95,  101,  107
	!word 113, 120,  127,  135,  143,  151,  160,  170,  180,  190,  202,  214
	!word 226, 240,  254,  269,  285,  302,  320,  339,  360,  381,  404,  428
	!word 453, 480,  508,  538,  570,  604,  640,  678,  720,  762,  808,  856
	!word 907, 961, 1017, 1077, 1141, 1209, 1281, 1357, 1440, 1525, 1616, 1712

ascii_to_petscii_table_origin
	!byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60 ; $00
	!byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60 ; $10
	!byte $20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$2a,$2b,$2c,$2d,$2e,$2f ; $20
	!byte $30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3a,$3b,$3c,$3d,$3e,$3f ; $30
	!byte $40,$61,$62,$63,$64,$65,$66,$67,$68,$69,$6a,$6b,$6c,$6d,$6e,$6f ; $40
	!byte $70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7a,$5b,$60,$5d,$5e,$a4 ; $50
	!byte $27,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f ; $60
	!byte $50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$28,$7d,$29,$27,$60 ; $70
	!byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60 ; $80
	!byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60 ; $90
	!byte $20,$21,$43,$5c,$4f,$79,$7d,$73,$22,$63,$41,$3c,$2d,$2d,$72,$a3 ; $a0
	!byte $4f,$2b,$32,$33,$27,$55,$70,$2e,$2c,$31,$4f,$3e,$60,$60,$60,$3f ; $b0
	!byte $61,$61,$61,$61,$61,$61,$61,$63,$65,$65,$65,$65,$69,$69,$69,$69 ; $c0
	!byte $64,$6e,$6f,$6f,$6f,$6f,$6f,$58,$30,$75,$75,$75,$75,$79,$60,$62 ; $d0
	!byte $41,$41,$41,$41,$41,$41,$41,$43,$45,$45,$45,$45,$49,$49,$49,$49 ; $e0
	!byte $44,$4e,$4f,$4f,$4f,$4f,$4f,$2f,$4f,$55,$55,$55,$55,$59,$60,$59 ; $f0
