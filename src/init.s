; this section is responsible for initializing everything at startup
; note that the first byte of this file is page-aligned from modplay.s

; signature we write to REU banks, first byte is bank number
reu_signature_start
reu_banknum
	!text 0,"reutest!"

; target buffer when reading signatures back from REU
reu_sig_candidate_start
	!text $ff,"icanhaz?"; same length as above

init
	!ifdef c128 {
		lda #1
		sta VIC+$30
		jsr disable_screen
		lda #$20
		sta RPTFLAG ; disables key repeat other than cursor, space, delete
	}

	jsr RESTOR ; this also undoes the "READY. trap"
	jsr CLALL

	lda #0
	ldx #<initializing_msg
	ldy #>initializing_msg
	jsr print_msg

	sei
	jsr disable_roms

	!ifdef c128 { ; reset F-keys to normal PETSCII codes
		ldy #9
	-	lda #1
		sta PKYBUF,y
		lda fkey_codes,y
		sta PKYDEF,y
		dey
		bpl -
	}

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
	iny
	bne -

	ldy #15
-	lda default_config,y
	sta config_space,y
	dey
	bpl -

	lda FA
	sta boot_device
	sta load_device
	lda #0
	sta MSGFLG ; suppress "SEARCHING FOR..." message

	lda #0
	sta current_menu_page
	!ifdef c128 {
		lda #$80
		sta clear_menu_screen_flag
	}

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


	sec
	lda #>free_memory_end
	sbc #>free_memory_start
	sta main_memory_free_pages
	dec main_memory_free_pages

	; test highest C128 bank number (normally it'll only return 1 or 3, unless
	; the user's MMU hack is broken :-P)

	!ifdef c128 {

		lda #<free_memory_end
		sta indstash_addr
		lda #>free_memory_end
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
		sta free_memory_end

	; now try to read them back

		lda #<free_memory_end
		sta indfetch_addr
		lda #>free_memory_end
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

	lda #0
	sta ramlink_detect
	sta RAMLINK_REG_ENABLE		; try to enable RAMLink registers
	lda #$30
	sta RAMLINK_8255_PORT_C		; try to write to RAMLink 8255 Port C
	lda #0						; reset REU DMA_ADL in case that write hit an I/O echo
	sta DMA_ADL					; ($df42 -> $df02)
	lda RAMLINK_8255_PORT_C		; if this comes back correct, that write didn't
	cmp #$30					; hit an echo, so there's a RAMLink present.
	bne +
	lda #$80
	sta ramlink_detect
	sta RAMLINK_REG_DISABLE		; disable RAMLink registers.

+	lda #<reu_stash_block
	sta stash_block_vec
	lda #>reu_stash_block
	sta stash_block_vec+1

	lda #<reu_fetch_row
	sta fetch_row_vec+1
	lda #>reu_fetch_row
	sta fetch_row_vec+2

	lda #<reu_set_cycle_counts
	sta ram_driver_set_cycle_counts_vec
	lda #>reu_set_cycle_counts
	sta ram_driver_set_cycle_counts_vec+1

	lda #<reu_start_mixer
	sta start_mixer_vec+1
	lda #>reu_start_mixer
	sta start_mixer_vec+2

	lda #<set_mixer_and_lookahead_addrs
	sta set_la_mixer_addrs_vec+1
	lda #>set_mixer_and_lookahead_addrs
	sta set_la_mixer_addrs_vec+2

	lda #<set_volume_addrs
	sta set_volume_addrs_vec+1
	lda #>set_volume_addrs
	sta set_volume_addrs_vec+2

	lda #0						; refers to the addr in REU
	sta free_memory_start		; main mem driver will use main_mem_free_start for this
	sta free_memory_start+1
	sta free_memory_start+2

	lda #<sid_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec
	lda #>sid_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec+1

	lda #<sid_get_volume_table_resolution
	sta audio_set_resolution_vec
	lda #>sid_get_volume_table_resolution
	sta audio_set_resolution_vec+1

	lda #<sid_init
	sta audio_init_vec
	lda #>sid_init
	sta audio_init_vec+1

	lda #<sid_start
	sta audio_start_vec
	lda #>sid_start
	sta audio_start_vec+1

	lda #<sid_mute
	sta audio_stop_vec
	lda #>sid_mute
	sta audio_stop_vec+1

	!ifndef c128 {
		lda #0
		sta enable_screen_on_playback
	}

	+JSR_INDIRECT (ram_driver_set_cycle_counts_vec)
	+JSR_INDIRECT (audio_driver_set_cycle_count_vec)
	+JSR_INDIRECT (audio_set_resolution_vec)
	jsr isr_set_interval
	lda #4
	sta last_volume_tables_resolution
	lda #0
	sta allow_regen_msg
	sta last_isr_trigger_interval
	jsr regen_all_tables

	; Codefault's count raster lines code, to know if PAL or NTSC

--	ldx #$aa
	-	tax
		lda VIC+$12
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

++	jsr charset_copy

	!ifndef c128 {
		jsr blur_table_copy
	}

	jsr semitones_table_copy

	jsr final_clear_copy

	!ifdef c128 {
		jsr erase_file_list
	}

; ############# we're dumping-out early here

	jmp clear_main_memory

; ############


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



; ####### end of main init code

zero_count	!byte 0

copy_code				; call this with tempzp_d = source,
	ldy #0				; tempzp_e = target, data will be copied
--	lda #3				; until three 0's are found.
	sta zero_count
-	lda (tempzp_d),y
	sta (tempzp_e),y
	inc tempzp_d
	bne +
	inc tempzp_d+1

+	inc tempzp_e
	bne +
	inc tempzp_e+1

+	and #$ff
	bne --
	dec zero_count
	bne -
rts

final_clear_copy
	lda #<clear_main_memory_origin
	sta tempzp_d
	lda #>clear_main_memory_origin
	sta tempzp_d+1
	lda #<clear_main_memory
	sta tempzp_e
	lda #>clear_main_memory
	sta tempzp_e+1
	jsr copy_code

	ldy #$ff
-	iny
	lda fmemtxt,y
	sta clear_main_memory+$40,y
	bne -
rts

clear_main_memory_origin
	lda #<wipe_memory_start
	sta tempzp_d
	lda #>wipe_memory_start
	sta tempzp_d+1
	lda #0
	ldy #0
-	sta (tempzp_d),y
	inc tempzp_d
	bne -
	inc tempzp_d+1
	ldx tempzp_d+1
	cpx #>free_memory_end
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
		jsr enable_char_rom_only

		; park the ASCII charset in RAM at $d000

		lda #<charset_64
		sta tempzp_d
		lda #>charset_64
		sta tempzp_d+1
		lda #<VIC_CHARSETS
		sta tempzp_e
		lda #>VIC_CHARSETS
		sta tempzp_e+1
		ldy #0
	-	lda (tempzp_d),y
		sta (tempzp_e),y
		inc tempzp_d
		bne +
		inc tempzp_d+1
	+	inc tempzp_e
		bne -
		inc tempzp_e+1
		lda tempzp_e+1
		cmp #>(VIC_CHARSETS+$0800)
		bne -

		; download the standard lower/upper charset to RAM at $d800
		lda #<(VIC_CHARSETS+$0800)
		sta tempzp_d
		lda #>(VIC_CHARSETS+$0800)
		sta tempzp_d+1
		ldy #0
	-	lda (tempzp_d),y
		sta (tempzp_d),y
		iny
		bne -
		inc tempzp_d+1
		lda tempzp_d+1
		cmp #>(VIC_CHARSETS+$1000)
		bne -

		jsr disable_roms
	rts
	} else {				; on the C128, upload it to the VDC
		lda #<charset_128_alt
		sta tempzp_d
		lda #>charset_128_alt
		sta tempzp_d+1
		lda #18
		sta VDC
		lda #>VDC_CHARSETS
		sta VDC+1
		lda #19
		sta VDC
		lda #<VDC_CHARSETS
		sta VDC+1
	.nextchar
		lda #31
		sta VDC
		ldy #0
	-	bit VDC
		bpl -
		lda (tempzp_d),y
		sta VDC+1
		iny
		cpy #8
		bne -
		lda #0
	-	bit VDC
		bpl -
		sta VDC+1
		dey
		bne -
		clc
		lda tempzp_d
		adc #8
		sta tempzp_d
		bcc +
		inc tempzp_d+1
	+	lda tempzp_d+1
		cmp #>(charset_128_alt+$0800)
		bne .nextchar
	rts
}

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
	ldx #15
-	lda semitones_table_fracts_origin,x
	sta semitones_table_fracts,x
	lda semitones_table_lows_origin,x
	sta semitones_table_lows,x
	dex
	bpl -
rts

twelfth_root_2 = 1.059463

semitones_table_fracts_origin
	!byte 0
	!for s2, 1, 15 {
		!zone {
			.n = twelfth_root_2 ^ s2
			.ni = int(.n)
			!byte (.n-.ni)*256
		}
	}

semitones_table_lows_origin
	!byte 1
	!for s1, 1, 15 {
		!byte int(twelfth_root_2 ^ s1)
	}


fkey_codes					!byte $85,$89,$86,$8a,$87,$8b,$88,$8c

vol_cnt		!byte 0
bval_cnt	!byte 0

default_config
	!ifndef c128 {			; signature
		!byte $ff,0,"c",6,4
	} else {
		!byte $ff,"c",1,2,8
	}
	!byte 8					; default device
	!word $d700				; default stereo SID addr
	!word $dd01				; default DigiMAX/DAC addr
	!byte 0					; default audio driver
	!byte 1					; default RAM driver
	!byte $80				; default Stereo mode (on/off)
	!byte 0					; default filter setting
	!byte 0					; default resonance setting
	!byte 0					; default screen enable
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
