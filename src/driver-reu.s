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

	lda #56
	sta pitch_fine_adjust_constant

	; this count divides that figure back down to normal.

	lda #3
	sta mixer_count_shifts
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
	ldx audio_in_buf_index

	; restart CIA #2 timers

	lda #$11		; A counts cycles, continuous mode, force-load, start now
	sta CIA2+$0e
	lda #$59		; B counts timer A underflows, one-shot, force-load, start now
	sta CIA2+$0f

reu_gen_sample_loop
	lda #<sample_data_buffer							; 2
	sta DMA_ADL											; 4
	clc													; 2
	ldy #$91											; 2

	!for track, 0, 3 {
		!zone fetchloop {

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

			clc											; 2
			lda track_current_loop_flags+track			; 3
			bne .reu_sample_has_loop					; 3/2
			sta sample_pointers_mids+track				; 3
			sta sample_pointers_highs+track				; 3
			sta current_steprates_fract+track			; 3
			sta current_steprates_lows+track			; 3
			bcc .reu_fetch_sample_data					; 3

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
			ldy #$91									; 2

		.reu_fetch_sample_data

			lda #(lookahead_track_offset/4)				; 2

			!ifdef c128 {
				sta VIC+$30								; 4
			}

			sta DMA_DAL									; 4
			sty DMA_CMD									; 4 + (8 or 16)
			sta DMA_DAL									; 4
			sty DMA_CMD									; 4 + (8 or 16)
			sta DMA_DAL									; 4
			sty DMA_CMD									; 4 + (8 or 16)
			sta DMA_DAL									; 4
			sty DMA_CMD									; 4 + (8 or 16)

			!ifdef c128 {
				sty VIC+$30								; 4
			}
		}
	}

	!for .idx2, 0, 15 {
		inx													; 2
	-	cpx audio_out_buf_index								; 3    / wait for a free
		beq -												; 3/2  / slot in the buffer

		!if .idx2 = 1  { la_0_1  = * }
		!if .idx2 = 2  { la_0_2  = * }
		!if .idx2 = 3  { la_0_3  = * }
		!if .idx2 = 4  { la_0_4  = * }
		!if .idx2 = 5  { la_0_5  = * }
		!if .idx2 = 6  { la_0_6  = * }
		!if .idx2 = 7  { la_0_7  = * }
		!if .idx2 = 8  { la_0_8  = * }
		!if .idx2 = 9  { la_0_9  = * }
		!if .idx2 = 10 { la_0_10 = * }
		!if .idx2 = 11 { la_0_11 = * }
		!if .idx2 = 12 { la_0_12 = * }
		!if .idx2 = 13 { la_0_13 = * }
		!if .idx2 = 14 { la_0_14 = * }
		!if .idx2 = 15 { la_0_15 = * }

		; these LDY addrs are correct for lookahead pass 0, and they all get
		; overwritten entirely by the sequencer in passes 1-15

		ldy sample_data_buffer								; 4 
		lda (volume_table_vectors),y						; 5

		!if .idx2 = 1  { la_3_1  = * }
		!if .idx2 = 2  { la_3_2  = * }
		!if .idx2 = 3  { la_3_3  = * }
		!if .idx2 = 4  { la_3_4  = * }
		!if .idx2 = 5  { la_3_5  = * }
		!if .idx2 = 6  { la_3_6  = * }
		!if .idx2 = 7  { la_3_7  = * }
		!if .idx2 = 8  { la_3_8  = * }
		!if .idx2 = 9  { la_3_9  = * }
		!if .idx2 = 10 { la_3_10 = * }
		!if .idx2 = 11 { la_3_11 = * }
		!if .idx2 = 12 { la_3_12 = * }
		!if .idx2 = 13 { la_3_13 = * }
		!if .idx2 = 14 { la_3_14 = * }
		!if .idx2 = 15 { la_3_15 = * }

		ldy sample_data_buffer + 3*lookahead_track_offset	; 4
		adc (volume_table_vectors+3*2),y					; 5
		sta audio_buffer_left,x								; 5

		!if .idx2 = 1  { la_1_1  = * }
		!if .idx2 = 2  { la_1_2  = * }
		!if .idx2 = 3  { la_1_3  = * }
		!if .idx2 = 4  { la_1_4  = * }
		!if .idx2 = 5  { la_1_5  = * }
		!if .idx2 = 6  { la_1_6  = * }
		!if .idx2 = 7  { la_1_7  = * }
		!if .idx2 = 8  { la_1_8  = * }
		!if .idx2 = 9  { la_1_9  = * }
		!if .idx2 = 10 { la_1_10 = * }
		!if .idx2 = 11 { la_1_11 = * }
		!if .idx2 = 12 { la_1_12 = * }
		!if .idx2 = 13 { la_1_13 = * }
		!if .idx2 = 14 { la_1_14 = * }
		!if .idx2 = 15 { la_1_15 = * }

		ldy sample_data_buffer + 1*lookahead_track_offset	; 4
		lda (volume_table_vectors+1*2),y					; 5

		!if .idx2 = 1  { la_2_1  = * }
		!if .idx2 = 2  { la_2_2  = * }
		!if .idx2 = 3  { la_2_3  = * }
		!if .idx2 = 4  { la_2_4  = * }
		!if .idx2 = 5  { la_2_5  = * }
		!if .idx2 = 6  { la_2_6  = * }
		!if .idx2 = 7  { la_2_7  = * }
		!if .idx2 = 8  { la_2_8  = * }
		!if .idx2 = 9  { la_2_9  = * }
		!if .idx2 = 10 { la_2_10 = * }
		!if .idx2 = 11 { la_2_11 = * }
		!if .idx2 = 12 { la_2_12 = * }
		!if .idx2 = 13 { la_2_13 = * }
		!if .idx2 = 14 { la_2_14 = * }
		!if .idx2 = 15 { la_2_15 = * }

		ldy sample_data_buffer + 2*lookahead_track_offset	; 4
		adc (volume_table_vectors+2*2),y					; 5
		sta audio_buffer_right,x							; 5
	}

	lda CIA2+$0f											; 4
	and #$01												; 2
	beq +													; 3/2
	jmp reu_gen_sample_loop									; 6

+	stx audio_in_buf_index
rts

; mixer loop open:
; 2+4+2+2 = 10 cycles

; time to fetch 64 bytes of lookahead data for one track
; 2 +4+4+16 +4+4+16 +4+4+16 +4+4+16 = 98 cycles

; mixer minimum time - all four tracks update only the fract bytes
; end of sample check needs to do only one byte, but not end of sample yet
; (3+3+3+3 +3+4 +3+4 +3+4)*4 + (2+3+3+3)*4 + 98*4 = 568 cycles
;
; mixer likely average case, 4 tracks updating two bytes
; two bytes to check end of sample, but not end yet
; (3+3+3+2 +3+3+3+4+3 +3+4 +3+4)*4 + (2+3+3+2 +3+3+3)*4 + 98*4 = 632

; mixer worst case, all four tracks have to update all four bytes, and all four
; end-of-sample bytes need to be checked, but not end of sample yet
; (3+3+3+2 +3+3+3+4+2 +5+3+4+2 +5+3+4+3)*4 + (2+3+3+2 +3+3+2 +3+3+3)*4 + 98*4 = 720

; time inside the lookahead code:
; (2+3+3 +4+5 +4+5+5 +4+5 +4+5+5)*16 = 864 cycles

; time to close the loop: 4+2+2+6 = 14 cycles

; best case:
; 10 + 568 + 864 + 14 = 1456 cycles for 8 sample pairs
; 1456 / 16 = average of 91 cycles/sample

; likely average:
; 10 + 632 + 864 + 14 = 1520 cycles
; 1520 / 16 = average of 95 cycles/sample

; worst case:
; 10 + 720 + 864 + 14 = 1608 cycles
; 1608 / 16 = average of ~101 cycles/sample
