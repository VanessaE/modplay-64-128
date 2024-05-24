; this section is responsible for initializing everything at startup

init
	!ifdef c128 {
		jsr c128_set_2mhz_mode
		jsr disable_screen
	}

	jsr RESTOR ; this also undoes the "READY. trap"
	jsr CLALL

	ldx #<initializing_msg
	ldy #>initializing_msg
	jsr print_msg

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
	sta current_page
	!ifdef c128 {
		lda #$80
		sta clear_menu_screen_flag
	}

;	lda config_filename_len
;	ldx #<config_filename
;	ldy #>config_filename
;	jsr SETNAM
;
;	!ifdef c128 {
;		lda #0
;		ldx #0
;		jsr SETBNK
;	}
;
;	lda #0
;	ldx boot_device
;	ldy #$ff
;	jsr SETLFS
;
;	lda #0
;	ldx #<config_space
;	ldy #>config_space
;	jsr LOAD
;	bcc +
;	jsr read_err_channel

+	sei
	jsr disable_roms

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
	sta tempzp_d
	lda #>volume_tables_base
	sta tempzp_d+1
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
		sta (tempzp_d),y
		inc tempzp_d
		inc bval_cnt
		bne --
		inc tempzp_d+1
		inc vol_cnt
		lda vol_cnt
		cmp #64
	bne -

	jsr reu_get_size

	!ifdef c128 { ; reset F-keys to normal PETSCII codes
		ldy #9
	-	lda #1
		sta PKYBUF,y
		lda fkey_codes,y
		sta PKYDEF,y
		dey
		bpl -
	}

	jsr enable_kernal
	cli

rts ; ############# dump out early

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
rts

fkey_codes					!byte $85,$89,$86,$8a,$87,$8b,$88,$8c

default_config
	!ifndef c128 {			; signature
		!byte $ff,0,"c",6,4
	} else {
		!byte $ff,"c",1,2,8
	}
	!byte 10				; default device
	!word $d700				; default stereo SID addr
	!word $de00				; default stereo SID addr
	!byte 0					; default audio driver
	!byte 0					; default RAM driver
	!byte 0					; default filter setting
	!byte 0					; default resonance setting
	!byte $ff				; end of file marker

configuration_data_end
