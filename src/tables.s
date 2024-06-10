; generate volume scaler tables
; these tables scale the amplitude of the sample data according to the volume
; the mod asks for, converts the signed samples to unsigned, and downscales
; the resolution of the final numbers according to the needs of the audio
; driver.

; enter with .A = desired output resolution

!text "tables",0

generate_volume_tables
	cmp volume_tables_resolution
	bne +
	rts

+	sta volume_tables_resolution
	lda #<volume_tables_low
	sta tempzp_d
	lda #>volume_tables_low
	sta tempzp_d+1
	lda #0
	sta bval_cnt			; byte value counter
	sta vol_cnt				; volume counter

	--	ldx vol_cnt
	-	lda bval_cnt
		jsr multiply_8x8 	; returns 14 bit value in 'product' (top 2 bits are
							; always 0 here) MSB is also in .A at exit.

		asl product			; multiply by 4 then displace downward by one byte
		rol					; is identical to dividing by 64 (14 --> 8 bit),
		asl product			; but is considerably faster.
		rol
		sta product

; MOD samples are 2's-compliment signed, this will offset where the data
; is stored in the page, so that the output from the table is unsigned.

		lda bval_cnt
		clc
		adc #$80
		tay

; re-center the amplitude range to keep the middle sample value at $7f/80.

		sec
		lda #64
		sbc vol_cnt
		asl
		clc
		adc product

; divide the final value down to the resolution the audio driver needs
; only 4 or 8 bits allowed -- note that we actually shift one extra step
; so the volume tables actually output 3-bit or 7-bit values to avoid the
; mixer needing to do that shift in realtime.

		ldx volume_tables_resolution
		cpx #4
		bne .nd

		lsr
		lsr
		lsr
		lsr

	.nd	lsr
		sta (tempzp_d),y
		inc bval_cnt
		bne --
		inc tempzp_d+1
		inc vol_cnt
		lda vol_cnt
		cmp #34		; the first 33 pages can fit below the screens at $c800...
		bne +
		lda #>volume_tables_high	; ...while the rest goes under the KERNAL.
		sta tempzp_d+1
		bne -
	+	cmp #65
		bne -
rts

!text "arp table",0

twelfth_root_2 = 1.059463

semitones_table_fracts

	!byte 0
	!for s2, 1, 15 {
		!zone {
			.n = twelfth_root_2 ^ s2
			.ni = int(.n)
			!byte (.n-.ni)*256
		}
	}

semitones_table_lows

	!byte 1
	!for s1, 1, 15 {
		!byte int(twelfth_root_2 ^ s1)
	}
