; this section is responsible for initializing everything at startup
; note that the first byte of this file is page-aligned from modplay.s

; signature we write to REU banks, first byte is bank number
reu_signature_start
reu_banknum
	!text 0,"reutest!"

; target buffer when reading signatures back from REU
reu_sig_candidate_start
	!text $ff,"icanhaz?"; same length as above

lockout_interrupts ; any interrupt that gets here exits unacknowledged
rti

init
	!ifdef c128 {
		lda #1
		sta VIC_2_MHZ
		jsr disable_screen
		lda #$20
		sta RPTFLAG ; disables key repeat other than cursor, space, delete
	}

	jsr RESTOR ; this also undoes the "READY. trap"
	jsr CLALL

	!ifdef scpu {
		bit SCPU_PRESENT
		bmi +

		sta SCPU_TURBO_ON
		sta SCPU_ENABLE_HW_REGS
		!ifndef c128 {
			lda #%01000100
		} else {
			lda #%10000100
		}
		sta SCPU_OPTIMIZATION_MODE
		sta SCPU_DISABLE_HW_REGS
	  +
	}

	lda #0
	ldx #<initializing_msg
	ldy #>initializing_msg
	jsr print_msg

	lda #0

	!ifndef c128 {
		ldy #$cc ; length of the low memory area where player vars will go
	} else {
		ldy #$a2
	}

-	dey
	sta low_memory_area,y
	bne -

	ldy #0
-	sta main_variables_zone,y
	sta main_variables_zone+$0100,y
	sta main_variables_zone+$0200,y
	sta main_variables_zone+$0300,y
	sta main_variables_zone+$0400,y
	sta main_variables_zone+$0500,y
	sta main_variables_zone+$0600,y
	sta main_variables_zone+$0700,y
	sta main_variables_zone+$0800,y
	iny
	bne -

	!ifdef scpu {			; now that the main vars zone is zeroed, we can
		bit SCPU_PRESENT	; save the state of the detect flag
		bmi +
		lda #$80
		sta supercpu_detected
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
	!ifdef c128 {
		lda #$80
		sta clear_menu_screen_flag
	}

;	sec
;	lda #>main_mem_free_end
;	sbc #>expansion_memory_start_address
;	sta main_memory_free_pages
;	dec main_memory_free_pages

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

	jsr reu_get_size

	lda #<reu_fetch_block
	sta fetch_block_vec
	lda #>reu_fetch_block
	sta fetch_block_vec+1

	lda #<reu_stash_block
	sta stash_block_vec
	lda #>reu_stash_block
	sta stash_block_vec+1

	lda #<reu_fetch_row
	sta fetch_row_expansion_vec+1
	lda #>reu_fetch_row
	sta fetch_row_expansion_vec+2

	lda #<reu_set_cycle_counts
	sta ram_driver_set_cycle_counts_vec
	lda #>reu_set_cycle_counts
	sta ram_driver_set_cycle_counts_vec+1

	lda #<reu_run_fetch_and_mixer
	sta run_fetch_and_mixer_vec+1
	lda #>reu_run_fetch_and_mixer
	sta run_fetch_and_mixer_vec+2

	lda #<reu_fetch_routine_index_table
	sta fetch_routine_table_lsb+1
	lda #>reu_fetch_routine_index_table
	sta fetch_routine_table_msb+1

	lda #<reu_do_realtime_selfmods_for_pitch_change
	sta do_selfmod_pitch_vec
	lda #>reu_do_realtime_selfmods_for_pitch_change
	sta do_selfmod_pitch_vec+1

	lda #<reu_do_realtime_selfmods_for_instrument_change
	sta do_selfmod_instrument_vec
	lda #>reu_do_realtime_selfmods_for_instrument_change
	sta do_selfmod_instrument_vec+1

	lda #<reu_set_lookahead_vol_addrs
	sta set_lookahead_vol_addrs_vec+1
	lda #>reu_set_lookahead_vol_addrs
	sta set_lookahead_vol_addrs_vec+2

+	lda #0
	sta expansion_memory_start_page
	sta expansion_memory_start_bank

	lda #0
	sta ramlink_detect
	sta RAMLINK_REG_ENABLE		; try to enable RAMLink registers
	lda #$30
	sta RAMLINK_8255_PORT_C		; try to write to RAMLink 8255 Port C
	lda #0						; reset REU DMA_ADL in case that write hit an
	sta DMA_ADL					; I/O echo ($df42 -> $df02)
	lda RAMLINK_8255_PORT_C		; if this comes back correct, that write didn't
	cmp #$30					; hit an echo, so there's a RAMLink present.
	bne +
	lda #$80
	sta ramlink_detect
	sta RAMLINK_REG_DISABLE		; disable RAMLink registers.

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
	ora #$80
	sta divide16_or80_table,x
	inx
	bne -

	ldx #0
-	txa
	and #$f0
	sta and_f0_table,x
	inx
	bne -

	; Codefault's count raster lines code, to know if PAL or NTSC

--	ldx #$aa
	-	tax
		lda VIC_RASTER_LOW
		bne -
	txa
	bmi --

	ldx #63
	sta rasters_lo
	sec
	sbc #7 				; if rasters_lo > 6, the carry stays set, meaning PAL
	lda #0
	ror					; which we then roll into bit 7 of a 0 value
	sta pal_flag
	bmi +				; if not PAL, add 2 to the length, for NTSC
	inx
	inx
+	stx raster_len

	bit pal_flag
	bpl +
	lda #<one_ten_thou_pal
	sta one_ten_thousandth_second
	lda #>one_ten_thou_pal
	sta one_ten_thousandth_second+1
	bne ++

+	lda #<one_ten_thou_ntsc
	sta one_ten_thousandth_second
	lda #>one_ten_thou_ntsc
	sta one_ten_thousandth_second+1

++	lda #1
	sta visualizer_mode
	lda CIA2_CRA	; ensure that the TOD clock counts 50 or 60 ticks/sec
	and #$7f		; depending on PAL or NTSC -- except this doesn't work on PAL SX64
	ora pal_flag
	sta CIA2_CRA

	jsr charset_copy

	!ifndef c128 {
		jsr blur_table_copy
		jsr window_edge_tables_copy
	}

	jsr semitones_table_copy
	jsr note_names_table_copy

	jsr control_code_flags_copy

	!ifdef scpu {
		sta SCPU_TURBO_OFF
	}

	!ifdef c128 {
		lda #0
		sta VIC_2_MHZ
	}

	jsr check_sid_type_left

	!ifdef scpu {
		sta SCPU_TURBO_ON
	}

	!ifdef c128 {
		inc VIC_2_MHZ
	}

	lda audio_driver
	cmp #1
	bne ns4init

	bit dither_enable
	bpl +

	jsr sid_4bit_dithered_driver_init
	jmp ++

+	jsr sid_4bit_driver_init

++	jmp init_tables_gen

ns4init
	cmp #2
	bne nmahinit
	jsr sid_mahoney_driver_init
	jmp init_tables_gen

nmahinit
	jsr dac_driver_init

init_tables_gen
	+JSR_INDIRECT (ram_driver_set_cycle_counts_vec)
	+JSR_INDIRECT (audio_driver_set_cycle_count_vec)
	+JSR_INDIRECT (audio_set_resolution_vec)
	jsr isr_set_interval
	jsr regen_all_tables

	jsr generate_note_number_lookup_table

	!ifdef c128 {
		jsr erase_file_list
	}

	jsr final_clear_copy
	jmp clear_main_memory

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

final_clear_copy
	lda #<clear_main_memory_origin
	sta fill_copy_source
	lda #>clear_main_memory_origin
	sta fill_copy_source+1
	lda #<clear_main_memory
	sta fill_copy_target
	lda #>clear_main_memory
	sta fill_copy_target+1
	jsr copy_code

	ldy #$ff
-	iny
	lda fmemtxt,y
	sta clear_main_memory+$40,y
	bne -
rts

clear_main_memory_origin
	lda #<main_mem_free_start
	sta fill_copy_target
	lda #>main_mem_free_start
	sta fill_copy_target+1
	lda #0
	ldy #0
-	sta (fill_copy_target),y
	inc fill_copy_target
	bne -
	inc fill_copy_target+1
	ldx fill_copy_target+1
	cpx #>main_mem_free_end
	bne -

	ldy #$ff
-	iny
	lda clear_main_memory+$40,y
	sta main_mem_free_start,y
	bne -
	rts

	!byte 0,0,0

fmemtxt
	!text "free memory start",0

charset_copy
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
		lda #<charset_128_alt
		sta fill_copy_source
		lda #>charset_128_alt
		sta fill_copy_source+1

		lda #<VDC_CHARSETS
		sta fill_copy_target
		lda #>VDC_CHARSETS
		sta fill_copy_target+1

		jsr vdc_write_ram_reg_31_select_only

	.nextchar
		ldy #0

	-	lda (fill_copy_source),y
		jsr vdc_continue_write_ram
		iny
		cpy #8
		bne -

		lda #0
	-	jsr vdc_continue_write_ram
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
rts

!ifndef c128 {
	blur_table_copy
		ldy #0
	-	lda blur_table_origin,y
		beq +
		sta blurring_table,y
		iny
		bne -
	+ rts
}

semitones_table_copy
	ldx #31
-	lda semitones_table_origin,x
	sta semitones_table,x
	dex
	bpl -
rts

twelfth_root_2 = 1.059463

semitones_table_origin
	!for s2, 0, 15 {
		!zone {
			!word int((twelfth_root_2 ^ s2) * 256)
		}
	}

control_code_flags_copy
	ldx #31
-	lda control_code_flags_table_low_origin,x
	sta control_code_flags_table_low,x
	lda control_code_flags_table_high_origin,x
	sta control_code_flags_table_high,x
	dex
	bpl -
rts

note_names_table_copy
	ldx #0

-	lda note_names_table_origin,x
	cmp #"#" ; if it's a pound, replace it with a sharp accidental, char #31
	bne +
	lda #31

+	sta note_names_table,x
	inx
	cpx #240
	bne -
  +
rts

; if the byte equals its PETSCII value in that pos, it can hold a new char to
; print in ASCII mode.  If there's a 0, it's a control code that we need to
; pass to CHROUT, e.g. colors, cursor moves, etc.

control_code_flags_table_low_origin
	!byte 0,1,1,1,1,0,1,1,1,1,1,1,1,0,1,1
	!byte 1,0,1,0,0,1,1,1,1,1,1,1,0,0,0,0

control_code_flags_table_high_origin
	!byte 1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
	!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

!ifndef c128 {
	window_edge_tables_copy
		ldx #15
	-	lda window_edge_tables_origin,x
		sta window_edge_tables,x
		dex
		bpl -
	rts

	window_edge_tables_origin
		!byte $ac ; top-left corner
		!byte $bb ; top-right corner
		!byte $bc ; bottom-left corner
		!byte $be ; bottom-right corner
		!byte $60 ; top edge
		!byte $60 ; bottom edge
		!byte $7d ; left edge
		!byte $7d ; right edge

		!byte $08 ; same symbols, but using the ASCII font
		!byte $09
		!byte $0a
		!byte $0b
		!byte $02
		!byte $02
		!byte $01
		!byte $01
}

fkey_codes					!byte $85,$89,$86,$8a,$87,$8b,$88,$8c

default_config
	!ifndef c128 {			; signature
		!byte $64,0,"c",6,4
	} else {
		!byte $80,"c",1,2,8
	}
	!byte 8					; default device
	!word $d700				; default stereo SID addr
	!word $dd01				; default DigiMAX/DAC addr
	!byte 2					; default audio driver (SID Mahoney method)
	!byte 1					; default RAM driver (REU)
	!byte $80				; default Stereo mode (on)
	!byte 0					; default filter setting
	!byte 0					; default resonance setting
	!byte $0				; default dithering mode (off)
	!byte $80				; default screen enable (on)
	!byte $ff				; end of file marker
configuration_data_end

initializing_msg
!ifndef c128 {
		!byte HOME
		!fill 14,DOWN
		!fill 12,RIGHT
		!text CYAN,  "Initializing..."
		!byte 0
} else {
		!byte HOME
		!fill 14,DOWN
		!fill 29,RIGHT
		!text CYAN,  "   Initializing...    "
		!byte 0
}

!ifndef c128 {
	blur_table_origin
		!fill 32,132		; "@" through "z", "[" through "🠜"
		!byte 32			; space
		!fill 31,132		; ' !"#... ' through "?"
		!byte 134				;"━"
		!fill 28,132		; "A" through "Z", "╋" and "🮌" 
		!byte 133				; "┃"
		!byte 132,132		; "🮕" and "🮘"
		!byte 32			; "shift space"
		!fill 10,132		; "▌" thorugh the second "🮇"
		!byte 139			; "┣"
		!byte 132			; "▗"
		!byte 137			; "┗"
		!byte 136			; "┓"
		!byte 132			; "▂"
		!byte 135			; "┏"
		!byte 132,132		; "┻" and "┳"
		!byte 140			; "┫"
		!fill 9,132			; "▎" through "▝"
		!byte 138			; "┛"
		!byte 132,132		; "▘" and "▚"
		!byte 0
}

!ct raw {
	note_names_table_origin
		!text "???",0
		!text "B-4",0,"A#4",0,"A-4",0,"G#4",0,"G-4",0,"F#4",0,"F-4",0,"E-4",0,"D#4",0,"D-4",0,"C#4",0,"C-4",0
		!text "B-3",0,"A#3",0,"A-3",0,"G#3",0,"G-3",0,"F#3",0,"F-3",0,"E-3",0,"D#3",0,"D-3",0,"C#3",0,"C-3",0
		!text "B-2",0,"A#2",0,"A-2",0,"G#2",0,"G-2",0,"F#2",0,"F-2",0,"E-2",0,"D#2",0,"D-2",0,"C#2",0,"C-2",0
		!text "B-1",0,"A#1",0,"A-1",0,"G#1",0,"G-1",0,"F#1",0,"F-1",0,"E-1",0,"D#1",0,"D-1",0,"C#1",0,"C-1",0
		!text "B-0",0,"A#0",0,"A-0",0,"G#0",0,"G-0",0,"F#0",0,"F-0",0,"E-0",0,"D#0",0,"D-0",0,"C#0",0,"C-0",0
}

!align 255,0

binsearch_note_period_table
	!word  57,  60,   64,   67,   71,   76,   80,   85,   90,   95,  101,  107
	!word 113, 120,  127,  135,  143,  151,  160,  170,  180,  190,  202,  214
	!word 226, 240,  254,  269,  285,  302,  320,  339,  360,  381,  404,  428
	!word 453, 480,  508,  538,  570,  604,  640,  678,  720,  762,  808,  856
	!word 907, 961, 1017, 1077, 1141, 1209, 1281, 1357, 1440, 1525, 1616, 1712
