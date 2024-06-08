; RAM driver for standard REU

; this bit tells other code how fast the RAM driver actually is
; and is the average number of 1 MHz cycles consumed by the RAM driver mixer
; per final sample byte pair, plus some fudge (so on C128 this will be a bit
; over half the number of cycles needed).

!text "reu driver",0,0,0

reu_set_mixer_speed_figures
	!ifndef c128 {
		lda #120
	} else {
		lda #65
	}
	sta ram_driver_mixer_cycle_count

	; since the REU driver fetches/buffers 8 sample pairs per mixer loop
	; this adjustment will result in calculated tick times 8x higher than is
	; "correct", for precision-sake later on.

	lda #103
	sta tempo_fine_adjust_constant

	; this count divides that figure back down to normal.

	lda #3
	sta mixer_count_shifts

	lda #56
	sta pitch_fine_adjust_constant

rts

reu_fetch_row
	lda #0
	sta tempzpbk_g
	sta tempzpbk_g+2

	ldx current_song_pos	; pattern number -> offset:  N*1024
	lda pattern_table,x
	asl
	rol tempzpbk_g+2
	asl
	rol tempzpbk_g+2
	sta tempzpbk_g+1

	lda seq_current_row		; use LSB to multiply row no. x16
	sta tempzpbk_g
	lda #0
	asl tempzpbk_g
	rol
	asl tempzpbk_g
	rol
	asl tempzpbk_g
	rol
	asl tempzpbk_g
	rol

	adc tempzpbk_g+1		; finish the addition, now we have an offset into
	sta tempzpbk_g+1		; the pattern data
	lda tempzpbk_g+2
	adc #0
	sta tempzpbk_g+2

	lda current_file_type
	cmp #1
	bne +

; add the header length and now we have the real address of the desired row

	lda tempzpbk_g
	adc #<(header15_seek_to_pt+127)
	sta DMA_LO
	lda tempzpbk_g+1
	adc #>(header15_seek_to_pt+127)
	jmp ++

+	lda tempzpbk_g
	adc #<(header31_seek_to_pt+131)
	sta DMA_LO
	lda tempzpbk_g+1
	adc #>(header31_seek_to_pt+131)

++	sta DMA_HI
	lda #0
	rol
	sta DMA_BANK

	lda #<seq_current_row_data
	sta DMA_ADL
	lda #>seq_current_row_data
	sta DMA_ADH

	lda #0
	sta DMA_DAH

	ldy #$91
	lda #8
	sta DMA_DAL		; run it twice to get 16 bytes, so that the ISR won't

	!ifdef c128 {
		sta VIC+$30
	}

	sty DMA_CMD		; get more than an 8-cycle delay
	sta DMA_DAL
	sty DMA_CMD

	!ifdef c128 {
		sty VIC+$30
	}
rts

reu_stash_block
	lda #<load_buffer
	sta DMA_ADL
	lda #>load_buffer
	sta DMA_ADH

	lda stash_pointer
	sta DMA_LO
	lda stash_pointer+1
	sta DMA_HI
	lda stash_pointer+2
	sta DMA_BANK

	lda stash_size
	sta DMA_DAL
	lda stash_size+1
	sta DMA_DAH

	lda #$90

	!ifdef c128 {
		sta VIC+$30
	}

	sta DMA_CMD

	!ifdef c128 {
		inc VIC+$30
	}
rts

; This came from Codebase, author unknown
; https://codebase64.org/doku.php?id=base:reu_detect

REUCOMMAND_STASH    = $90   ; immediately, no reload
REUCOMMAND_FETCH    = $91   ; immediately, no reload

reu_get_size
	!ifdef c128 {
		dec VIC+$30
	}

	ldx #0  ; pre-init
	; first write signatures to banks in *descending* order (banks 255..0):
.wrlp
	dex
	stx reu_banknum
	lda #<reu_signature_start
	ldx #>reu_signature_start
	ldy #REUCOMMAND_STASH
	jsr set_registers_AXY
	ldx reu_banknum
	bne .wrlp	; all banks written?

; now check signatures in *ascending* order:
; banknum just became zero so no need to init it
.rdlp
	lda #<reu_sig_candidate_start
	ldx #>reu_sig_candidate_start
	ldy #REUCOMMAND_FETCH
	jsr set_registers_AXY
	; compare data
	ldx #8 ; signature length, minus 1
-			lda reu_sig_candidate_start, x
		cmp reu_signature_start, x
		bne .failed
		dex
		bpl -
		; bank has correct signature
	inc reu_banknum ; next bank (== number of banks already found)
	bne .rdlp

	ldx reu_banknum
	jmp +

.failed
	clc
	ldx reu_banknum

+	dex
	stx reu_highest_bank		; if 0, REU not detected at all.

	!ifdef c128 {
		inc VIC+$30
	}
rts

set_registers_AXY ; setup REU registers (used for both reading and writing in size test only)
	; A/X: c64 address
	; Y: REU command
	sta DMA_ADL
	stx DMA_ADH
	ldx #0
	stx DMA_LO
	stx DMA_HI
	lda reu_banknum
	sta DMA_BANK
	lda #9 ; signature length
	sta DMA_DAL
	stx DMA_DAH
	sty DMA_CMD
rts

; rough draft mixer code

reu_mixer_entry
	lda #0
	sta DMA_DAH
	lda #>sample_data_buffer
	sta DMA_ADH
	ldx #$91

reu_gen_sample_loop
	lda #<sample_data_buffer							; 2
	sta DMA_ADL											; 4

	!for track, 0, 3 {
		!zone fetchloop {

			clc											; 2
			lda sample_pointers_fract+track				; 3
			adc current_steprates_fract+track			; 3
			sta sample_pointers_fract+track				; 3
			bcc .reu_fix_dma_low_byte					; 3/2

			lda sample_pointers_lows+track				; 3
			adc current_steprates_lows+track			; 3
			sta sample_pointers_lows+track				; 3
			sta DMA_LO									; 4
			bcc .reu_fix_dma_high_byte					; 3/2

			inc sample_pointers_mids+track				; 5
			lda sample_pointers_mids+track				; 3
			sta DMA_HI									; 4
			beq .reu_fix_dma_bank						; 3/2

			inc sample_pointers_highs+track				; 5
			lda sample_pointers_highs+track				; 3
			sta DMA_BANK								; 4
			bne .reu_check_end							; 3

		.reu_fix_dma_low_byte
			lda sample_pointers_lows+track				; 3
			sta DMA_LO									; 4

		.reu_fix_dma_high_byte
			lda sample_pointers_mids+track				; 3
			sta DMA_HI									; 4

		.reu_fix_dma_bank
			lda sample_pointers_highs+track				; 3
			sta DMA_BANK								; 4

		.reu_check_end
			sec											; 2
			lda sample_pointers_lows+track				; 3
			cmp current_sample_end_addr_lows+track		; 3
			bcc .reu_fetch_sample_data					; 3/2

			lda sample_pointers_mids+track				; 3
			cmp current_sample_end_addr_mids+track		; 3
			bcc .reu_fetch_sample_data					; 3/2

			lda sample_pointers_highs+track				; 3
			cmp current_sample_end_addr_highs+track		; 3
			bcc .reu_fetch_sample_data					; 3/2

			lda track_current_loop_flags+track			; 3
			bne .reu_sample_has_loop					; 3/2
			sta current_steprates_fract+track			; 3
			sta current_steprates_lows+track			; 3
			sta sample_data_lookahead_indexes+track*8   ; 4
			sta sample_data_lookahead_indexes+track*8+1 ; 4
			sta sample_data_lookahead_indexes+track*8+2 ; 4
			sta sample_data_lookahead_indexes+track*8+3 ; 4
			sta sample_data_lookahead_indexes+track*8+4 ; 4
			sta sample_data_lookahead_indexes+track*8+5 ; 4
			sta sample_data_lookahead_indexes+track*8+6 ; 4
			sta sample_data_lookahead_indexes+track*8+7 ; 4
			beq .reu_fetch_sample_data					; 3

		.reu_sample_has_loop
			lda #0										; 2
			sta sample_pointers_fract+track				; 3
			ldy current_sample_numbers+track			; 3
			lda sample_loop_start_addresses_lows,y		; 5
			sta sample_pointers_lows+track				; 4
			sta DMA_LO									; 4
			lda sample_loop_start_addresses_mids,y		; 5
			sta sample_pointers_mids+track				; 4
			sta DMA_HI									; 4
			lda sample_loop_start_addresses_highs,y		; 5
			sta sample_pointers_highs+track				; 4
			sta DMA_BANK								; 4
			lda sample_loop_end_addresses_lows,y		; 5
			sta current_sample_end_addr_lows+track		; 3
			lda sample_loop_end_addresses_mids,y		; 5
			sta current_sample_end_addr_mids+track		; 3
			lda sample_loop_end_addresses_highs,y		; 5
			sta current_sample_end_addr_highs+track		; 3

		.reu_fetch_sample_data
			lda #32										; 2
			sta DMA_DAL									; 4

			!ifdef c128 {
				sta VIC+$30								; 4
			}

			stx DMA_CMD									; 4 + 32

			!ifdef c128 {
				stx VIC+$30								; 6
			}
		}
	}

; loop start: 2+4 = 6 cycles

; update fract bytes:
; 2+3+3+3+3 +3+4 +3+4 +3+4 = 35 cycles, per track

; update fract + low:
; minus 8 (1+3+4) plus 16 (3+3+3+4+3) --- 35 + 8 = 43 cycles per track

; update fract + low + mid:
; minus 8 (1+3+4) plus 15 (5+3+4+3) --- 43 + 7 = 50 cycles per track

; update fract + low + mid + high (so all four bytes):
; minus 8 (1+3+4) plus 15 (5+3+4+3) --- 50 + 7 = 57 cycles per track

; add 23 cycles per track for the end-of-sample check

; add 2+4+4+32 = 42 cycles per track to get 32 bytes from the REU

; next step is to mix:

	ldx audio_in_buf_index									; 3
-	cpx audio_out_buf_index									; 3    /  wait for a free
	beq -													; 3/2  /  slot in the buffer

	clc														; 2
	ldy sample_data_buffer									; 3  / track 1
	lda (volume_table_vectors),y							; 5
	ldy sample_data_buffer + 3*8							; 3  / track 4
	adc (volume_table_vectors+3*2),y						; 5
	ror														; 2
	sta audio_buffer_left,x									; 5

	clc														; 2
	ldy sample_data_buffer + 1*8							; 3  / track 2
	lda (volume_table_vectors+1*2),y						; 5
	ldy sample_data_buffer + 2*8							; 3  / track 3
	adc (volume_table_vectors+2*2),y						; 5
	ror														; 2
	sta audio_buffer_right,x								; 5

	inx														; 2

	!for .idx2, 1, 7 {
		stx audio_in_buf_index								; 3
	-	cpx audio_out_buf_index								; 3    /  wait for a free
		beq -												; 3/2  /  slot in the buffer

		clc													; 2
		ldx sample_data_lookahead_indexes       + .idx2		; 4  / track 1
		ldy sample_data_buffer,x							; 4
		lda (volume_table_vectors),y						; 5
		ldx sample_data_lookahead_indexes + 3*8 + .idx2		; 4  / track 4
		ldy sample_data_buffer + 3*8,x						; 4
		adc (volume_table_vectors+3*2),y					; 5
		ror													; 2
		ldx audio_in_buf_index								; 3
		sta audio_buffer_left,x								; 5

		clc													; 2
		ldx sample_data_lookahead_indexes + 1*8 + .idx2		; 4  / track 2
		ldy sample_data_buffer + 1*8,x						; 4
		lda (volume_table_vectors+1*2),y					; 5
		ldx sample_data_lookahead_indexes + 2*8 + .idx2		; 4  / track 3
		ldy sample_data_buffer + 2*8,x						; 4
		adc (volume_table_vectors+2*2),y					; 5
		ror													; 2
		ldx audio_in_buf_index								; 3
		sta audio_buffer_right,x							; 5

		inx													; 2
	}

	dec mixer_output_countdown								; 5
	beq +													; 3/2
	jmp reu_gen_sample_loop									; 6

+ rts

; so downmixing costs:
; 3+3+3 +2+3+5+3+5+2+5 +2+3+5+3+5+2+5 + 2 = 61 cycles for the first sample pair
;
; plus 3+3 +2+4+4+5+4+4+5+2+3+5 +2+4+4+5+4+4+5+2+3+5 +2+3 = 87 cycles
;     for each additional pair (times 7)
;
; plus 5+2+6 = 13 cycles to close the loop

; grand totals for four tracks:

; best case:
; 2+4 + (35 + 23 + 42) * 4 + 61 + 87*7 + 13 = 1089 cycles, avg. ~137 cycles per sample pair

; most common likely case:
; 2+4 + (43 + 23 + 42) * 4 + 61 + 87*7 + 13 = 1121 cycles, avg. ~141 cycles per sample pair

; worst case:
; 2+4 + (57 + 23 + 42) * 4 + 61 + 87*7 + 13 = 1177 cycles, avg. ~147 cycles per sample pair
