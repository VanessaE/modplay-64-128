; RAM driver for standard REU

!text "reu driver",0,0,0

; this is the average cycles per output sample pair
; for faster CPUs, divide the raw count by the CPU MHz and round up.
; written here as fetch routine time plus lookahead/mixer routine time
; see full details below.

reu_set_cycle_counts
	!ifndef c128 {
		lda #42+54
	} else {
		lda #39+27 ; equivalent 1 MHz cycles
	}
	sta ram_driver_cycle_count
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

; SET-UP LOOKAHEAD INDEXES/ADDRESSES
; This plugs in the necessary adjustments to the mixer routine down below
; so that it knows where to look for lookahead data.  This and the mixer
; routine are part of the RAM driver because they have to be carefully
; tailored to each system's/device's quirks to maximize speed and minimize lag
; and delays.
;
; Enter with .Y = track number to work on

mixer_loop_segment_length = mixer_loop_end - mixer_loop_start

set_lookahead_addrs
	tya
	ldx #lookahead_track_offset
	jsr multiply_8x8

	clc
	lda #0
	sta sequencer_temp_a
	lda product
	adc #<sample_data_buffer
	sta sequencer_temp_a+1
	lda product+1
	adc #>sample_data_buffer
	sta sequencer_temp_a+2

	ldx lookahead_code_offsets_set_read_byte_addr,y

	!zone lookahead_idx_set {
		!for .idx4, 0, 15 {
			lda sequencer_temp_a
			adc current_steprates_fract,y
			sta sequencer_temp_a
			lda sequencer_temp_a+1
			adc current_steprates_lows,y
			sta sequencer_temp_a+1
			sta rd_la_track_0 + mixer_loop_segment_length*.idx4 + 1,x
			lda sequencer_temp_a+2
			adc #0
			sta sequencer_temp_a+2
			sta rd_la_track_0 + mixer_loop_segment_length*.idx4 + 2,x
		}
	}
rts

; set the sample's volume, and set the address targets in the mixer below
; enter with .A = volume level, .Y = track number
; .Y will be preserved

set_volume_addrs
	sta current_sample_volume_levels,y

	sec
	cmp #33
	bcc +
	clc
	adc #>volume_table_lower
	bcs ++

+	adc #(>volume_table_upper)-34

++	ldx lookahead_code_offsets_set_volume_addr,y

	!zone lookahead_idx_set {
		!for .idx4, 0, 15 {
			sta vol_addr_0 + mixer_loop_segment_length*.idx4 + 2,x
		}
	}
rts

lookahead_code_offsets_set_read_byte_addr
	!byte 0
	!byte rd_la_track_1 - rd_la_track_0
	!byte rd_la_track_2 - rd_la_track_0
	!byte rd_la_track_3 - rd_la_track_0

lookahead_code_offsets_set_volume_addr
	!byte 0
	!byte vol_addr_1 - vol_addr_0
	!byte vol_addr_2 - vol_addr_0
	!byte vol_addr_3 - vol_addr_0


; THE ACTUAL MIXER ROUTINE
; The hard work happens here 🙂

reu_start_mixer
	lda #0
	sta DMA_DAH
	lda #>sample_data_buffer
	sta DMA_ADH
	ldx audio_in_buf_index

	reu_mixer_main_loop										; 6 cycles to enter
		lda #<sample_data_buffer							; 2
		sta DMA_ADL											; 4
		clc													; 2
		ldy #$91											; 2

		!for track, 0, 3 {
			!zone fetchloop {

				lda sample_pointers_fract+track				; 3
				adc current_steprates_fract+track			; 3
				sta sample_pointers_fract+track				; 3
				bcc .reu_fix_dma_top_three_bytes			; 3/2

				lda sample_pointers_lows+track				; 3
				adc current_steprates_lows+track			; 3
				sta sample_pointers_lows+track				; 3
				sta DMA_LO									; 4
				bcc .reu_fix_dma_top_two_bytes				; 3/2

				inc sample_pointers_mids+track				; 5
				lda sample_pointers_mids+track				; 3
				sta DMA_HI									; 4
				bne .reu_fix_dma_top_byte					; 3/2

				inc sample_pointers_highs+track				; 5
				lda sample_pointers_highs+track				; 3
				sta DMA_BANK								; 4
				bne .reu_check_end							; 3

			.reu_fix_dma_top_three_bytes
				lda sample_pointers_lows+track				; 3
				sta DMA_LO									; 4

			.reu_fix_dma_top_two_bytes
				lda sample_pointers_mids+track				; 3
				sta DMA_HI									; 4

			.reu_fix_dma_top_byte
				lda sample_pointers_highs+track				; 3
				sta DMA_BANK								; 4

			.reu_check_end
				sec											; 2
				lda sample_pointers_lows+track				; 3
				cmp current_sample_end_addr_lows+track		; 3
				lda sample_pointers_mids+track				; 3
				cmp current_sample_end_addr_mids+track		; 3
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
				sta DMA_DAL									; 4

				!ifdef c128 {
					sta VIC+$30								; 4
				}

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

	mixer_loop_start
	  !for .idx2, 0, 15 {
		inx												; 2
	-	cpx audio_out_buf_index							; 3    / wait for a free
		beq -											; 3/2  / slot in the buffer

		; the various `LDY sample_data_buffer` below will have their addresses
		; re-written by the above set_lookahead_addrs routine. Similarly, each
		; corresponding `LDA/ADC volume_table_lower,Y` will have its high byte
		; re-written by the set_volume_addrs routine.

		!if .idx2 = 0 { rd_la_track_0 = * }
		ldy sample_data_buffer							; 4

 		!if .idx2 = 0 { vol_addr_0 = * }
		lda volume_table_lower,y						; 4

		!if .idx2 = 0 { rd_la_track_3 = *}
		ldy sample_data_buffer							; 4

		!if .idx2 = 0 { vol_addr_3 = *}
		adc volume_table_lower,y						; 4
		sta audio_buffer_left,x							; 5

		!if .idx2 = 0 { rd_la_track_1 = * }
		ldy sample_data_buffer							; 4

		!if .idx2 = 0 { vol_addr_1 = * }
		lda volume_table_lower,y						; 4

		!if .idx2 = 0 { rd_la_track_2 = * }
		ldy sample_data_buffer							; 4

		!if .idx2 = 0 { vol_addr_2 = * }
		adc volume_table_lower,y						; 4
		sta audio_buffer_right,x						; 5

		!if .idx2 = 0 { !set mixer_loop_end = * }
	  }

	stx audio_in_buf_index								; 3

	dec mixer_countdown									; 5
	beq +												; 3/2
	jmp reu_mixer_main_loop								; 6

+ rts


; ============================================================================
; TIMING INFO, assuming stock C64/128, 4-bit SID stereo, no accelerator/turbo
; All times rounded-up.
;
; -----------
;
; fetch loop open:
; 2+4+2+2 = 10 cycles
;
; time just to fetch 64 bytes of lookahead data for one track
; 2 +4+4+16 +4+4+16 +4+4+16 +4+4+16 = 98 cycles
;
; minimum time - all four tracks only need to update the fract bytes,
; and not at the end of sample yet:
;
; 10 + (3+3+3+3 +3+4 +3+4 +3+4)*4 + (2+3+3+3+3+3+3+3)*4 + 98*4 = 626 cycles
;
; most likely case, all four tracks updating two bytes,
; and not at the end of sample yet:
;
; 10 + (3+3+3+2 +3+3+3+4+3 +3+4 +3+4)*4 + (2+3+3+3+3+3+3+3)*4 + 98*4 = 658
;
; worst case, all four tracks have to update all four bytes,
; and not at the end of sample yet:
;
; 10 + (3+3+3+2 +3+3+3+4+2 +5+3+4+2 +5+3+4+3)*4 + (2+3+3+3+3+3+3+3)*4 + 98*4 = 714
;
; For the C128, the hardware does clock stretching on I/O accesses, but only
; for the one cycle when the actual read/write is being committed.  Most of
; the fetch instructions, and all of the actual DMA fetches, run in 1 MHz mode
; for their whole duration. The explicit 1/2 MHz switching above adds 13,
; 2 MHz cycles (5 for the shift down to 1 MHz, 8 to shift back up).
;
; Since there's half as much data being fetched, that machine's fetch timings
; are:
;
; 2 +4 +4+8+16 +8+8+16 +8+8+16 +8+8+16 +13 = 143 cycles per track, 572 total
;
; ---------
;
; lookahead/mixer push-to-buffers runtime:
; 2+3+3 +4+4+4+4+5 +4+4+4+4+5 = 42 cycles per pass, 816 cycles total (16 passes)
;
; mixer loop close:
; 3+5+2+6 = 16 cycles
;
; audio ISR takes 53 cycles
;
; Grand totals (using "most likely" fetch scenario):
;
; C64:   (658 + 816 + 16) / 16 + 53 = ~147 cycles   --  round up to 150
; C128:  (658 + 572 + 816) / 16 + 53 = ~181 cycles  --  round up to 185
;
; ---------
;
; So the C64 should be run at about 6.8 kHz with the screen off, SID 4-bit stereo:
; 1022727/150 = ~6818.2
;
; or 5.2 KHz with the screen on (so ISR is always 3 rasters):
; 1022727/(65*3) = ~5244.8
;
; C128 should be able to run at 11 kHz:
; (1022727*2)/185 = ~11056.5
;
; ============================================================================
