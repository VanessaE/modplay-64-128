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
		lda #24 + 2
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
	lda expansion_transfer_local_addr
	sta DMA_ADL
	lda expansion_transfer_local_addr+1
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
	lda expansion_transfer_local_addr
	sta DMA_ADL
	lda expansion_transfer_local_addr+1
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

fetch_loop_segment_length = reu_fetch_unroll_close - reu_fetch_unroll_open

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
				sta sample_pointers_lows+track				; 3
				sta sample_pointers_mids+track				; 3
				sta sample_pointers_highs+track				; 3

				!set steprate_fract_addr	= reu_cur_steprate_f + fetch_loop_segment_length * track + 1
				!set steprate_int_addr		= reu_cur_steprate_i + fetch_loop_segment_length * track + 1
				!set samp_end_low_addr		= reu_ckend_l + fetch_loop_segment_length * track + 1
				!set samp_end_mid_addr		= reu_ckend_m + fetch_loop_segment_length * track + 1
				!set samp_end_high_addr		= reu_ckend_h + fetch_loop_segment_length * track + 1

				sta steprate_fract_addr						; 4
				sta steprate_int_addr						; 4

				sta samp_end_low_addr						; 4
				sta samp_end_high_addr						; 4
				lda #1										; 2
				sta samp_end_mid_addr						; 4

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
				sta samp_end_low_addr						; 4
				lda sample_loop_end_addresses_mids,y		; 5
				sta samp_end_mid_addr						; 4
				lda sample_loop_end_addresses_highs,y		; 5
				sta samp_end_high_addr						; 4
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
