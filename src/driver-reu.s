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

set_lookahead_addrs
	!for lookahead_track, 0, 3 {
		lda #0
		sta sequencer_temp_a
		sta sequencer_temp_a+1
		clc

		!zone lookahead_idx_set {
			!for .idx4, 1, 15 {

				!if lookahead_track = 0 {
					!if .idx4 = 1  { !set .t = la_0_1  }
					!if .idx4 = 2  { !set .t = la_0_2  }
					!if .idx4 = 3  { !set .t = la_0_3  }
					!if .idx4 = 4  { !set .t = la_0_4  }
					!if .idx4 = 5  { !set .t = la_0_5  }
					!if .idx4 = 6  { !set .t = la_0_6  }
					!if .idx4 = 7  { !set .t = la_0_7  }
					!if .idx4 = 8  { !set .t = la_0_8  }
					!if .idx4 = 9  { !set .t = la_0_9  }
					!if .idx4 = 10 { !set .t = la_0_10 }
					!if .idx4 = 11 { !set .t = la_0_11 }
					!if .idx4 = 12 { !set .t = la_0_12 }
					!if .idx4 = 13 { !set .t = la_0_13 }
					!if .idx4 = 14 { !set .t = la_0_14 }
					!if .idx4 = 15 { !set .t = la_0_15 }
				}

				!if lookahead_track = 1 {
					!if .idx4 = 1  { !set .t = la_1_1  }
					!if .idx4 = 2  { !set .t = la_1_2  }
					!if .idx4 = 3  { !set .t = la_1_3  }
					!if .idx4 = 4  { !set .t = la_1_4  }
					!if .idx4 = 5  { !set .t = la_1_5  }
					!if .idx4 = 6  { !set .t = la_1_6  }
					!if .idx4 = 7  { !set .t = la_1_7  }
					!if .idx4 = 8  { !set .t = la_1_8  }
					!if .idx4 = 9  { !set .t = la_1_9  }
					!if .idx4 = 10 { !set .t = la_1_10 }
					!if .idx4 = 11 { !set .t = la_1_11 }
					!if .idx4 = 12 { !set .t = la_1_12 }
					!if .idx4 = 13 { !set .t = la_1_13 }
					!if .idx4 = 14 { !set .t = la_1_14 }
					!if .idx4 = 15 { !set .t = la_1_15 }
				}

				!if lookahead_track = 2 {
					!if .idx4 = 1  { !set .t = la_2_1  }
					!if .idx4 = 2  { !set .t = la_2_2  }
					!if .idx4 = 3  { !set .t = la_2_3  }
					!if .idx4 = 4  { !set .t = la_2_4  }
					!if .idx4 = 5  { !set .t = la_2_5  }
					!if .idx4 = 6  { !set .t = la_2_6  }
					!if .idx4 = 7  { !set .t = la_2_7  }
					!if .idx4 = 8  { !set .t = la_2_8  }
					!if .idx4 = 9  { !set .t = la_2_9  }
					!if .idx4 = 10 { !set .t = la_2_10 }
					!if .idx4 = 11 { !set .t = la_2_11 }
					!if .idx4 = 12 { !set .t = la_2_12 }
					!if .idx4 = 13 { !set .t = la_2_13 }
					!if .idx4 = 14 { !set .t = la_2_14 }
					!if .idx4 = 15 { !set .t = la_2_15 }
				}

				!if lookahead_track = 3 {
					!if .idx4 = 1  { !set .t = la_3_1  }
					!if .idx4 = 2  { !set .t = la_3_2  }
					!if .idx4 = 3  { !set .t = la_3_3  }
					!if .idx4 = 4  { !set .t = la_3_4  }
					!if .idx4 = 5  { !set .t = la_3_5  }
					!if .idx4 = 6  { !set .t = la_3_6  }
					!if .idx4 = 7  { !set .t = la_3_7  }
					!if .idx4 = 8  { !set .t = la_3_8  }
					!if .idx4 = 9  { !set .t = la_3_9  }
					!if .idx4 = 10 { !set .t = la_3_10 }
					!if .idx4 = 11 { !set .t = la_3_11 }
					!if .idx4 = 12 { !set .t = la_3_12 }
					!if .idx4 = 13 { !set .t = la_3_13 }
					!if .idx4 = 14 { !set .t = la_3_14 }
					!if .idx4 = 15 { !set .t = la_3_15 }
				}

				lda sequencer_temp_a
				adc current_steprates_fract + lookahead_track
				sta sequencer_temp_a
				lda sequencer_temp_a+1
				adc current_steprates_lows + lookahead_track
				sta sequencer_temp_a+1
				adc #<(sample_data_buffer + lookahead_track * lookahead_track_offset)
				sta .t + 1
				lda #>(sample_data_buffer + lookahead_track * lookahead_track_offset)
				adc #0
				sta .t + 2
			}
		}
	}
rts

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

	stx audio_in_buf_index									; 3

	dec mixer_countdown										; 5
	beq +													; 3/2
	jmp reu_mixer_main_loop									; 6

+ rts


; ============================================================================
; TIMING INFO, assuming stock C64/128, 4-bit SID stereo, no accelerator/turbo
; All times rounded-up.
; C128-specific numbers given are in 1 MHz equivalents.
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
; 626 / 16 = average of ~40 cycles per set of fetched samples
;
; most likely case, all four tracks updating two bytes,
; and not at the end of sample yet:
;
; 10 + (3+3+3+2 +3+3+3+4+3 +3+4 +3+4)*4 + (2+3+3+3+3+3+3+3)*4 + 98*4 = 658
; 658 / 16 = ~42 cycles per sample set
;
; worst case, all four tracks have to update all four bytes,
; and not at the end of sample yet:
;
; 10 + (3+3+3+2 +3+3+3+4+2 +5+3+4+2 +5+3+4+3)*4 + (2+3+3+3+3+3+3+3)*4 + 98*4 = 714
; 714 / 16 = ~45 cycles per sample set
;
;
; For the C128, the hardware does clock stretching on I/O accesses, but only
; for the one cycle when the actual read/write is being committed.  Most of
; the fetch instructions, and all of the actual DMA fetches, run in 1 MHz mode
; for their whole duration. The explicit 1/2 MHz switching above adds 13,
; 2 MHz cycles (5 for the shift down to 1 MHz, 8 to shift back up).
;
; Since there's half as much data being fetched,
; that machine's fetch timings are:
;
; 2 +4 +4+8+16 +8+8+16 +8+8+16 +8+8+16 +13 = 143 cycles per track, 572 total
; so (626 + 572 to 714 + 572) / 2 = 599 to 643 cycles total runtime
;
; So we'll use 658 / 16 = ~42 cycles for the C64, and for the C128 we'll use
; (658 + 572) / 16 / 2 = ~39 cycles
;
; ---------
;
; lookahead/mixer push-to-buffers runtime:
; 2+3+3 +4+5 +4+5+5 +4+5 +4+5+5 = 54 cycles on C64, 27 cycles on C128
;
; mixer loop close:
; 3+5+2+6 = 16 cycles
; so we'll just call it 1 cycle per sample set on both machines
;
; grand totals for the whole fetch/mix/buffer run (averages per sample pair):
; C64:  42 + 54 + 1 = 97 cycles, we'll round it up to 100
; C128: 39 + 27 + 1 = 67 cycles, round up to 68
;
; audio ISR takes 53 cycles on C64, 28 on C128
;
; ---------
;
; So the C64 should be run at almost 6.7 kHz with the screen off, SID 4-bit stereo:
; 1022727/(100+53) = ~6684.49
;
; or 5.2 KHz with the screen on (so ISR is always 3 rasters):
; 1022727/(65*3) = ~5244.75
;
; C128 should be able to run at 10.6 kHz:
; 1022727/(68+28) = ~10653.41
;
; ============================================================================
