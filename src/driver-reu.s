; RAM driver for standard REU

!text "reu driver",0,0,0

; the sequencer will look here (via a vector) to find the address and offsets
; into the fetch routine that it must use to do the self-mod stuff.

reu_fetch_routine_index_table
	!word reu_fetch_unroll_open
	!byte reu_cur_steprate_f - reu_fetch_unroll_open + 1
	!byte reu_cur_steprate_i - reu_fetch_unroll_open + 1
	!byte reu_ckend_l - reu_fetch_unroll_open + 1
	!byte reu_ckend_m - reu_fetch_unroll_open + 1
	!byte reu_ckend_h - reu_fetch_unroll_open + 1
	!byte reu_fetchlen - reu_fetch_unroll_open + 1
	!byte reu_fetch_unroll_close - reu_fetch_unroll_open ; fetch loop segment length

; this is the average cycles per sample pair for any one track.
; see full details below.

reu_set_cycle_counts
	!ifndef c128 {
		lda #24+2
	} else {
		lda #(26 + 2)/2 ; equivalent 1 MHz cycles
	}
	sta ram_driver_fetch_cycle_count
rts

; enter with .X = row number, .Y = pattern number
reu_fetch_row
	lda utility_pointer_b
	sta DMA_LO
	lda utility_pointer_b+1
	sta DMA_HI
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
	lda #16
	sta DMA_DAL

	!ifndef c128 {
		sty DMA_CMD
	} else {			; on C128 we need to disable interrupts, lest the ISR
		sei				; fire while the clock is at 1 MHz
		sta VIC+$30
		sty DMA_CMD
		sty VIC+$30
		cli
	}
rts

reu_fetch_block
	lda #<load_buffer
	sta DMA_ADL
	lda #>load_buffer
	sta DMA_ADH

	lda expansion_memory_target_pointer
	sta DMA_LO
	lda expansion_memory_target_pointer+1
	sta DMA_HI
	lda expansion_memory_target_pointer+2
	sta DMA_BANK

	lda stash_size
	sta DMA_DAL
	lda stash_size+1
	sta DMA_DAH
	lda #$91

	!ifdef c128 {
		dec VIC+$30
	}

	sta DMA_CMD

	!ifdef c128 {
		sta VIC+$30
	}
rts

reu_stash_block
	lda #<load_buffer
	sta DMA_ADL
	lda #>load_buffer
	sta DMA_ADH

	lda expansion_memory_target_pointer
	sta DMA_LO
	lda expansion_memory_target_pointer+1
	sta DMA_HI
	lda expansion_memory_target_pointer+2
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

; THE ACTUAL FETCH AND MIX ROUTINE
; The hard work happens here 🙂

reu_run_fetch_and_mixer
	lda #0
	sta DMA_DAH
	lda audio_in_buf_index
	and #$f0
	tax

	reu_fetch_main_loop
		lda #0												; 2
		sta DMA_ADL											; 4
		clc													; 2
		ldy #$91											; 2

		reu_fetch_unroll_open
		  !for track, 0, 3 {
			!zone fetchloop {
				lda #(>sample_data_buffer)+track			; 2
				sta DMA_ADH									; 4

				lda sample_pointers_fracts+track			; 3
				!if track = 0 { !set reu_cur_steprate_f = * }
				adc #0										; 2
				sta sample_pointers_fracts+track			; 3
				lda sample_pointers_lows+track				; 3
				!if track = 0 { !set reu_cur_steprate_i = * }
				adc #0										; 2
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
				jmp .reu_check_end							; 3

			.reu_fix_dma_top_two_bytes
				lda sample_pointers_mids+track				; 3
				sta DMA_HI									; 4

			.reu_fix_dma_top_byte
				lda sample_pointers_highs+track				; 3
				sta DMA_BANK								; 4

			.reu_check_end
				lda sample_pointers_lows+track				; 3
				!if track = 0 { !set reu_ckend_l = * }
				cmp #0										; 2

				lda sample_pointers_mids+track				; 3
				!if track = 0 { !set reu_ckend_m = * }
				sbc #0										; 2

				lda sample_pointers_highs+track				; 3
				!if track = 0 { !set reu_ckend_h = * }
				sbc #0										; 2

				bcc .reu_fetch_sample_data					; 3/2

				clc											; 2
				lda track_current_loop_flags+track			; 3
				bne .reu_sample_has_loop					; 3/2
				sta sample_pointers_mids+track				; 3
				sta sample_pointers_highs+track				; 3
				sta current_steprates_fracts+track			; 3
				sta current_steprates_ints+track			; 3
				jmp .reu_fetch_sample_data					; 3

			.reu_sample_has_loop
				lda #0										; 2
				sta sample_pointers_fracts+track			; 3
				ldy current_sample_numbers+track			; 3
				lda sample_loop_start_addresses_lows,y		; 5
				sta sample_pointers_lows+track				; 3
				sta DMA_LO									; 4
				lda sample_loop_start_addresses_mids,y		; 5
				sta sample_pointers_mids+track				; 3
				sta DMA_HI									; 4
				lda sample_loop_start_addresses_highs,y		; 5
				sta sample_pointers_highs+track				; 3
				sta DMA_BANK								; 4
				lda sample_loop_end_addresses_lows,y		; 5
				sta current_sample_end_addr_lows+track		; 3
				lda sample_loop_end_addresses_mids,y		; 5
				sta current_sample_end_addr_mids+track		; 3
				lda sample_loop_end_addresses_highs,y		; 5
				sta current_sample_end_addr_highs+track		; 3
				ldy #$91									; 2

			.reu_fetch_sample_data

				!if track = 0 { !set reu_fetchlen = * }
				lda #1										; 2
				sta DMA_DAL									; 4

				; if the ISR would fire too soon after a fetch starts, just
				; wait-out the timer and postpone the fetch.

				lda isr_minimum_times_before_fetch+track	; 3
			-	cmp CIA1+$06								; 4
				bcs -										; 3/2

				!ifdef c128 {
					sei										; 2
					dec VIC+$30								; 7
				}

				sty DMA_CMD									; 4 + N

				; N will vary by pitch, on average it'll be around 32 (2*16) on C64

				!ifdef c128 {
					sty VIC+$30								; 4
					cli										; 2
				}
			}

		!if track = 0 { reu_fetch_unroll_close = * }
		}

		jsr run_lookahead_and_mixer ; that's over in sequencer.s

		dec mixer_countdown									; 5
		beq +												; 3/2
	jmp reu_fetch_main_loop									; 3

+	stx audio_in_buf_index
rts


; ============================================================================
; REU DRIVER TIMING INFO
; assuming stock C64/128, 4-bit SID stereo, no accelerator/turbo, C64 screen
; turned on unless otherwise noted.  All times rounded-up to the next whole
; cycle.
;
; -----------
;
; fetch DMA calls alone:
;
; on average, the step rate will be close to 1.7, so it'll be fetching
; 16 * 1.7 = ~27 bytes per transfer:
;
; 2 +4+4+27 = 37 cycles per track, total 148 cycles
;
; Worst possible case would be playing the highest note, B-4, which would have
; a step rate of about 8.688, so fetching 16 * 8.333 = ~139 bytes:
;
; 2 +4+4+139 = 149 cycles per track, total 596 cycles
;
; plus it takes at least 3+4+3 = 10 cycles to check the CIA timer in case the
; fetch has to be postponed for the sake of the ISR
;
; For the C128, the hardware does clock stretching on I/O accesses, but only
; for the one cycle when the actual read/write is being committed.  Most of
; the fetch instructions, and all of the actual DMA fetches, run in 1 MHz mode
; for their whole duration. The explicit 1/2 MHz switching above adds 18,
; 2 MHz cycles (9 for the shift down to 1 MHz, 9 to shift back up).
;
; being almost twice as fast, it'll have half the step rates, so best step rate
; will be about 0.137, typical will be around 0.9, worst around 4.2, so it'll
; be fetching ~2, ~13, and ~66 bytes, respectively.
;
; that machine's fetch timings should be about:
;
; most likely:    2 +4+8+13 + 18 = 45 cycles, total 180
; worst possible: 2 +4+8+66 + 13 = 93 cycles, total 372
; CIA timer check: 3+5+3 = 11 cycles
;
; ----------
;
; fetch loop open:
; 2+4+2+2 = 10 cycles
;
; within the loop (not counting the above DMA calls, those are added below):
;
; minimum time (also the most likely case), all four tracks updating two
; bytes of the 4-byte address, and not at the end of the sample yet:
;
; (3+2+3 +2+3+4+3 +3+4 +3+4)*4 + (3+2+3+2+3+2+3)*4 = 208 cycles
;
; worst possible case, all four tracks have to update all four bytes, not at
; the end of sample yet:
;
; (3+2+3+2 +2+3+4+2 +5+3+4+2 +5+3+4+3)*4 + (3+2+3+2+3+2+3)*4 = 272 cycles
;
; ---------
; fetch routine main loop close:
; 5+2+6 = 13 cycles
;
; Total fetch runtime for all four tracks,
; amortized across 16 output samples:
;
; C64:
; likely: (10 + 208 + 148 + 13) / 16 = ~24 cycles
; worst:  (10 + 272 + 596 + 13) / 16 = ~56 cycles
;
; C128:
; likely: (10 + 208 + 180 + 11) / 16 = ~26 cycles
; worst:  (10 + 272 + 372 + 11) / 16 = ~42 cycles
;
; ---------
; lookahead/mixer/push-to-buffer routine runtime per output sample
; (see sequencer.s):
;
; (52 * 16 + 26) / 16 = ~54 cycles
;
; ------------
; GRAND TOTALS
;
; Factoring-in the mixer/lookahead runtime of 54 cycles per byte, plus 53
; 53 cycles per byte for the ISR, plus the "likely" code path in the fetch
; routine, plus some fudge:
;
; the C64 should be run at almost 7.7 kHz with the
; screen off, SID 4-bit stereo:
; 1022727 / (24 + 54 + 53 + 2) = ~7689.7
;
; or about 5.2 KHz with the screen on since ISR is always 3 rasters:
; 1022727 / (65 * 3) = ~5244.8
;
; C128 should be able to run at about 15.5 kHz:
; (1022727 * 2) / (26 + 54 + 53 + 2) = ~15151.5
;
; These timings do not take into account convergeance.  As the sample rate
; rises, the step rates drop, which decreases the lookahead fetch length,
; which in turn further reduces the cycle counts.
;
; ============================================================================
