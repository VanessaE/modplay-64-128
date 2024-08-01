; RAM driver for standard REU

!text "reu driver",0,0,0

; this is the average cycles per output sample pair
; for faster CPUs, divide the raw count by the CPU MHz and round up.
; see full details below.

reu_set_cycle_counts
	!ifndef c128 {
		lda #72
	} else {
		lda #76/2 ; equivalent 1 MHz cycles
	}
	sta ram_driver_cycle_count
rts

; enter with .X = row number, .Y = pattern number
reu_fetch_row
	lda #0
	sta utility_pointer_b+2

	tya						; pattern number -> offset:  N*1024
	asl
	rol utility_pointer_b+2
	asl
	rol utility_pointer_b+2
	sta utility_pointer_b+1

	txa						; use LSB to multiply row no. x16
	sta utility_pointer_b
	lda #0
	asl utility_pointer_b
	rol
	asl utility_pointer_b
	rol
	asl utility_pointer_b
	rol
	asl utility_pointer_b
	rol

	adc utility_pointer_b+1		; finish the addition, now we have an offset into
	sta utility_pointer_b+1		; the pattern data
	lda utility_pointer_b+2
	adc #0
	sta utility_pointer_b+2

	lda current_file_type
	cmp #1
	bne +

; add the header length and now we have the real address of the desired row

	clc
	lda utility_pointer_b
	adc #<header15_seek_to_pat_data
	sta DMA_LO

	lda utility_pointer_b+1
	adc #>header15_seek_to_pat_data
	jmp ++

+	clc
	lda utility_pointer_b
	adc #<header31_seek_to_pat_data
	sta DMA_LO

	lda utility_pointer_b+1
	adc #>header31_seek_to_pat_data

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

; SET-UP LOOKAHEAD INDEXES/ADDRESSES
; This plugs in the necessary adjustments to the mixer routine down below
; so that it knows where to look for lookahead data.  This and the mixer
; routine are part of the RAM driver because they have to be carefully
; tailored to each system's/device's quirks to maximize speed and minimize lag
; and delays.
;
; Enter with .Y = track number to work on

mixer_loop_segment_length = mixer_loop_end - mixer_loop_start
fetch_loop_segment_length = fetch_loop_end - fetch_loop_start

csr_f_idx    = cur_steprate_f - fetch_loop_start + 1
csr_l_idx    = cur_steprate_l - fetch_loop_start + 1
chkend_l_idx =        ckend_l - fetch_loop_start + 1
chkend_m_idx =        ckend_m - fetch_loop_start + 1
chkend_h_idx =        ckend_h - fetch_loop_start + 1
fetchlen_idx =       fetchlen - fetch_loop_start + 1

set_mixer_and_lookahead_addrs
	ldx lookahead_code_offsets_set_read_byte_code_addr,y

	tya
	clc
	adc #>sample_data_buffer
	sta rd_la_track_0 + 2,x

	lda current_steprates_lows,y
	sta utility_zpbk_counter+1

	lda current_steprates_fract,y
	sta temp_zpbk_a
	lsr utility_zpbk_counter+1
	ror
	lsr utility_zpbk_counter+1
	ror
	lsr utility_zpbk_counter+1
	ror
	lsr utility_zpbk_counter+1
	ror
	sta utility_zpbk_counter

; so utility_zpbk_counter is equal to 1/16 the step rate, and temp_zpbk_a will
; track the fraction part as the indexes are calculated below.

	!zone lookahead_idx_set {
		!for .idx4, 1, 15 {

			!set la_rd_addr_ld = rd_la_track_0 + mixer_loop_segment_length * (.idx4 - 1)
			!set la_rd_addr_st = rd_la_track_0 + mixer_loop_segment_length * .idx4

			lda temp_zpbk_a
			adc utility_zpbk_counter
			sta temp_zpbk_a
			lda la_rd_addr_ld + 1,x
			adc utility_zpbk_counter+1
			sta la_rd_addr_st + 1,x
		}
	}

	tya
	ldx #fetch_loop_segment_length
	jsr multiply_8x8

	clc
	lda #<fetch_loop_start
	adc product
	sta fill_copy_target
	lda #>fetch_loop_start
	adc product+1
	sta fill_copy_target+1

	ldx seq_current_track

	lda current_steprates_fract,x
	ldy #csr_f_idx
	sta (fill_copy_target),y

	lda current_steprates_lows,x
	ldy #csr_l_idx
	sta (fill_copy_target),y

	lda current_sample_end_addr_lows,x
	ldy #chkend_l_idx
	sta (fill_copy_target),y

	lda current_sample_end_addr_mids,x
	ldy #chkend_m_idx
	sta (fill_copy_target),y

	lda current_sample_end_addr_highs,x
	ldy #chkend_h_idx
	sta (fill_copy_target),y

	lda current_steprates_lows,x
	bne +
	lda #1 ; minimum lookahead length 1 even if the track needs "one-bit" steps 😛

+	ldy #fetchlen_idx
	sta (fill_copy_target),y

	; it takes 4, 1 MHz cycles (the final STY $abs) to start a fetch.
	; on C128, add 13, 1 MHz cycles to that for clock switching
	; (SEI:DEC $D030 + STY $D030:CLI)

	; we'll allow up to 20 cycles' ISR delay before postponing the mixer
	; too much more and it'll be audible.

	sec

	!ifndef c128 {
		sbc #16		; that is, add 4 cycles and subtract 20
	} else {
		sbc #3		; that is, add 17 and subtract 20
	}

	bcs +
	lda #1	; if the time is short enough, limit the timer check to one loop
+	sta isr_minimum_times_before_fetch,x
	ldy seq_current_track
rts

; set the sample's volume, and set the address targets in the mixer below
; enter with .A = volume level, .Y = track number
; .Y will be preserved

set_volume_addrs
	sta current_sample_volume_levels,y
	cmp #64
	bne +
	lda #63

+	lsr
	cmp #16
	bcs +

	adc #>volume_table_lower
	bcc ++

+	clc
	adc #(>volume_table_upper)-16

++	ldx lookahead_code_offsets_set_volume_code_addr,y

	!zone lookahead_idx_set {
		!for .idx4, 0, 15 {
			sta vol_addr_0 + mixer_loop_segment_length*.idx4 + 2,x
		}
	}
rts

lookahead_code_offsets_set_read_byte_code_addr
	!byte 0
	!byte rd_la_track_1 - rd_la_track_0
	!byte rd_la_track_2 - rd_la_track_0
	!byte rd_la_track_3 - rd_la_track_0

lookahead_code_offsets_set_volume_code_addr
	!byte 0
	!byte vol_addr_1 - vol_addr_0
	!byte vol_addr_2 - vol_addr_0
	!byte vol_addr_3 - vol_addr_0


; THE ACTUAL MIXER ROUTINE
; The hard work happens here 🙂

reu_start_mixer
	lda #0
	sta DMA_DAH
	ldx audio_in_buf_index

	reu_mixer_main_loop
		lda #0												; 2
		sta DMA_ADL											; 4
		clc													; 2
		ldy #$91											; 2

		fetch_loop_start
		  !for track, 0, 3 {
			!zone fetchloop {
				lda #(>sample_data_buffer)+track			; 2
				sta DMA_ADH									; 4

				lda sample_pointers_fract+track				; 3
				!if track = 0 { !set cur_steprate_f = * }
				adc #0										; 2
				sta sample_pointers_fract+track				; 3
				lda sample_pointers_lows+track				; 3
				!if track = 0 { !set cur_steprate_l = * }
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
				!if track = 0 { !set ckend_l = * }
				cmp #0										; 2

				lda sample_pointers_mids+track				; 3
				!if track = 0 { !set ckend_m = * }
				sbc #0										; 2

				lda sample_pointers_highs+track				; 3
				!if track = 0 { !set ckend_h = * }
				sbc #0										; 2

				bcc .reu_fetch_sample_data					; 3/2

				clc											; 2
				lda track_current_loop_flags+track			; 3
				bne .reu_sample_has_loop					; 3/2
				sta sample_pointers_mids+track				; 3
				sta sample_pointers_highs+track				; 3
				sta current_steprates_fract+track			; 3
				sta current_steprates_lows+track			; 3
				jmp .reu_fetch_sample_data					; 3

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

				!if track = 0 { !set fetchlen = * }
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
		!if track = 0 { fetch_loop_end = * }
		}

	txa													; 2
	adc #16												; 2
	and #$f0											; 2

-	ldy audio_out_buf_index								; 3
	cmp and_f0_table,y									; 4
	beq -												; 3/2

	mixer_loop_start
	  !for .idx2, 0, 15 {

		; the various `LDY sample_data_buffer` below will have their address
		; low bytes re-written by the above set_lookahead_addrs routine.
		; Similarly, each corresponding `LDA/ADC volume_table_lower,Y` will
		; have its high byte re-written by the set_volume_addrs routine.

		!if .idx2 = 0 { rd_la_track_0 = * }
		ldy sample_data_buffer + 0*256					; 4 / yeah I know it's 0, shut up 😛

 		!if .idx2 = 0 { vol_addr_0 = * }
		lda volume_table_lower,y						; 4

		!if .idx2 = 0 { rd_la_track_3 = *}
		ldy sample_data_buffer + 3*256					; 4

		!if .idx2 = 0 { vol_addr_3 = *}
		adc volume_table_lower,y						; 4
		sta audio_buffer_left,x							; 5

		!if .idx2 = 0 { rd_la_track_1 = * }
		ldy sample_data_buffer + 1*256					; 4

		!if .idx2 = 0 { vol_addr_1 = * }
		lda volume_table_lower,y						; 4

		!if .idx2 = 0 { rd_la_track_2 = * }
		ldy sample_data_buffer + 2*256					; 4

		!if .idx2 = 0 { vol_addr_2 = * }
		adc volume_table_lower,y						; 4
		sta audio_buffer_right,x						; 5

		inx												; 2

	  !if .idx2 = 0 { !set mixer_loop_end = * }
	}

	dec mixer_countdown									; 5
	beq +												; 3/2
	jmp reu_mixer_main_loop								; 3

+	stx audio_in_buf_index
rts


; ============================================================================
; REU DRIVER TIMING INFO
; assuming stock C64/128, 4-bit SID stereo, no accelerator/turbo, C64 screen
; turned on unless otherwise noted.  All times rounded-up.
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
; mixer has to be postponed for the sake of the ISR
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
; most likely case (also the minimum time), all four tracks updating two bytes, not at the end of
; the sample yet:
;
; (3+2+3 +2+3+4+3 +3+4 +3+4)*4 + (3+2+3+2+3+2+3)*4 = 208 cycles
;
; worst possible case, all four tracks have to update all four bytes, not at
; the end of sample yet:
;
; (3+2+3+2 +2+3+4+2 +5+3+4+2 +5+3+4+3)*4 + (3+2+3+2+3+2+3)*4 = 272 cycles
;
; ---------
;
; lookahead/mixer push-to-buffers runtime:
; open:  2+2+2 +3+4+3 = 16 cycles
;
; 4+4+4+4+5 +4+4+4+4+5 + 2 = 44 cycles per pass, times 16 passes = 704 cycles
;
; mixer loop close:
; 5+2+6 = 13 cycles
;
; Grand totals (average time per final pair of output samples):
;
; C64:
; best:   (10 + 208 +  56 + 10 + 16 + 704 + 13) / 16 =  ~64 cycles
; likely: (10 + 208 + 148 + 10 + 16 + 704 + 13) / 16 =  ~70 cycles
; worst:  (10 + 272 + 596 + 10 + 16 + 704 + 13) / 16 = ~102 cycles
;
; C128:
; best:   (10 + 208 + 136 + 11 + 16 + 704 + 13) / 16 = ~69 cycles
; likely: (10 + 208 + 180 + 11 + 16 + 704 + 13) / 16 = ~72 cycles
; worst:  (10 + 272 + 372 + 11 + 16 + 704 + 13) / 16 = ~88 cycles
;
; ---------
;
; So factoring-in the ISR runtime of 53 cycles, using the "most likely"
; conditions as the timing basis, and adding a few cycles of fudge...
;
; the C64 should be run at almost 8.2 kHz with the
; screen off, SID 4-bit stereo:
; 1022727 / (70 + 2 + 53) = ~8181.8
;
; or almost 7.9 KHz with the screen on (so ISR is always 2 rasters):
; 1022727 / (65*2) = ~7867.1
;
; C128 should be able to run at almost 15.9 kHz:
; (1022727*2) / (72 + 4 + 53) = ~15856.2
;
; These timings do not take into account convergeance.  As the sample rate
; rises, the step rates drop, which decreases the lookahead fetch length,
; which in turn further reduces the cycle counts.
;
; ============================================================================
