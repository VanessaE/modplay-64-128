; RAM driver for standard REU

!text "reu driver",0,0,0

; the sequencer will look here (via a vector) to find the address and offsets
; into the fetch routine that it must use to do the self-mod stuff.

!zone reu_driver {

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
; see full details in doc/timing-info.txt.

!ifndef scpu {
	mixer_cycle_count = 54
} else {
	mixer_cycle_count = 3
}

reu_set_cycle_counts
	!ifndef scpu {
		!ifndef c128 {
			lda #31 + 2
		} else {
			lda #(38 + 2)/2 ; equivalent 1 MHz cycles
		}
	} else {
		lda #16 + 1 ; equivalent 1 MHz cycles
	}
	sta ram_driver_fetch_cycle_count
rts

; enter with .X = row number, .Y = pattern number
reu_fetch_row
	clc
	lda utility_pointer_b
	sta DMA_LO
	lda utility_pointer_b+1
	adc expansion_memory_start_page
	sta DMA_HI
	lda #0
	adc expansion_memory_start_bank
	sta DMA_BANK

	lda #<seq_current_row_data
	sta DMA_ADL
	lda #>seq_current_row_data
	sta DMA_ADH

	lda #0
	sta DMA_DAH

	ldy #$91

	!ifndef scpu {
		lda #16
		sta DMA_DAL

		!ifndef c128 {
			sty DMA_CMD
		} else {
		; on C128 we need to disable interrupts, lest the ISR fire while the clock
		; is at 1 MHz... except: if there's a SCPU present, 1/2 MHz mode doesn't
		; matter, the SCPU will automatically stretch the clock anyway.

			sei
			sta VIC+$30
			sty DMA_CMD
			sty VIC+$30
			cli
		}
	} else {
		; on SCPU, we split the transfer into smaller pieces to minimize
		; interference with the audio ISR's timing.
		lda #4
		sta DMA_DAL
		sty DMA_CMD
		sta DMA_DAL
		sty DMA_CMD
		sta DMA_DAL
		sty DMA_CMD
		sta DMA_DAL
		sty DMA_CMD
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
		!ifndef scpu {
			dec VIC+$30
		}
	}

	sta DMA_CMD

	!ifdef c128 {
		!ifndef scpu {
			sta VIC+$30
		}
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
		!ifndef scpu {
			sta VIC+$30
		}
	}

	sta DMA_CMD

	!ifdef c128 {
		!ifndef scpu {
			inc VIC+$30
		}
	}
rts

; This came from Codebase, author unknown
; https://codebase64.org/doku.php?id=base:reu_detect

REUCOMMAND_STASH    = $90   ; immediately, no reload
REUCOMMAND_FETCH    = $91   ; immediately, no reload

reu_get_size
	!ifdef c128 {
		!ifndef scpu {
			dec VIC+$30
		}
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
		!ifndef scpu {
			inc VIC+$30
		}
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

reu_fetch_loop_segment_length = reu_fetch_unroll_close - reu_fetch_unroll_open

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
			!for reu_fetch_track, 0, 3 {
			  !zone reu_fetchloop {
				!set .fetch_track = reu_fetch_track

				lda #(>sample_data_buffer)+.fetch_track		; 2
				sta DMA_ADH									; 4

				lda sample_pointers_fracts+.fetch_track		; 3
				!if .fetch_track = 0 { !set reu_cur_steprate_f = * }
				adc #0										; 2
				sta sample_pointers_fracts+.fetch_track		; 3

				lda sample_pointers_lows+.fetch_track		; 3
				!if .fetch_track = 0 { !set reu_cur_steprate_i = * }
				adc #0										; 2
				sta sample_pointers_lows+.fetch_track		; 3
				sta DMA_LO									; 4
				bcc .reu_fix_dma_top_two_bytes				; 3/2

				inc sample_pointers_mids+.fetch_track		; 5
				lda sample_pointers_mids+.fetch_track		; 3
				sta DMA_HI									; 4
				bne .reu_fix_dma_top_byte					; 3/2

				inc sample_pointers_highs+.fetch_track		; 5
				lda sample_pointers_highs+.fetch_track		; 3
				sta DMA_BANK								; 4
				jmp .reu_check_end							; 3

			.reu_fix_dma_top_two_bytes
				lda sample_pointers_mids+.fetch_track		; 3
				sta DMA_HI									; 4

			.reu_fix_dma_top_byte
				lda sample_pointers_highs+.fetch_track		; 3
				sta DMA_BANK								; 4

			.reu_check_end
				lda sample_pointers_lows+.fetch_track		; 3
				!if .fetch_track = 0 { !set reu_ckend_l = * }
				cmp #0										; 2

				lda sample_pointers_mids+.fetch_track		; 3
				!if .fetch_track = 0 { !set reu_ckend_m = * }
				sbc #0										; 2

				lda sample_pointers_highs+.fetch_track		; 3
				!if .fetch_track = 0 { !set reu_ckend_h = * }
				sbc #0										; 2

				bcc .reu_fetch_sample_data					; 3/2

				clc											; 2
				lda track_current_loop_flags+.fetch_track	; 3
				bne .reu_sample_has_loop					; 3/2
				sta sample_pointers_lows+.fetch_track		; 3
				sta sample_pointers_mids+.fetch_track		; 3
				sta sample_pointers_highs+.fetch_track		; 3

				!set .reu_steprate_fract_addr	= reu_cur_steprate_f + reu_fetch_loop_segment_length * .fetch_track + 1
				!set .reu_steprate_int_addr		= reu_cur_steprate_i + reu_fetch_loop_segment_length * .fetch_track + 1
				!set .reu_samp_end_low_addr		= reu_ckend_l + reu_fetch_loop_segment_length * .fetch_track + 1
				!set .reu_samp_end_mid_addr		= reu_ckend_m + reu_fetch_loop_segment_length * .fetch_track + 1
				!set .reu_samp_end_high_addr	= reu_ckend_h + reu_fetch_loop_segment_length * .fetch_track + 1

				sta .reu_steprate_fract_addr				; 4
				sta .reu_steprate_int_addr					; 4

				sta .reu_samp_end_low_addr					; 4
				sta .reu_samp_end_high_addr					; 4
				lda #1										; 2
				sta .reu_samp_end_mid_addr					; 4

				jmp .reu_fetch_sample_data					; 3

			.reu_sample_has_loop
				lda #0										; 2
				sta sample_pointers_fracts+.fetch_track		; 3
				ldy current_sample_numbers+.fetch_track		; 3
				lda sample_loop_start_addresses_lows,y		; 5
				sta sample_pointers_lows+.fetch_track		; 3
				sta DMA_LO									; 4
				lda sample_loop_start_addresses_mids,y		; 5
				sta sample_pointers_mids+.fetch_track		; 3
				sta DMA_HI									; 4
				lda sample_loop_start_addresses_highs,y		; 5
				sta sample_pointers_highs+.fetch_track		; 3
				sta DMA_BANK								; 4
				lda sample_loop_end_addresses_lows,y		; 5
				sta .reu_samp_end_low_addr					; 4
				lda sample_loop_end_addresses_mids,y		; 5
				sta .reu_samp_end_mid_addr					; 4
				lda sample_loop_end_addresses_highs,y		; 5
				sta .reu_samp_end_high_addr					; 4
				ldy #$91									; 2

			.reu_fetch_sample_data

				!if .fetch_track = 0 { !set reu_fetchlen = * }
				lda #1										; 2
				sta DMA_DAL									; 4

				!ifdef c128 {
					!ifndef scpu {
						sei									; 2
						dec VIC+$30							; 7
					}
				}

				; N below will vary by pitch, on average it'll be around 32
				; on C64, which is quite large, so we'll split it into smaller
				; transfers.

				sty DMA_CMD									; 4 + N
				sta DMA_DAL									; 4
				sty DMA_CMD									; 4 + N
				sta DMA_DAL									; 4
				sty DMA_CMD									; 4 + N
				sta DMA_DAL									; 4
				sty DMA_CMD									; 4 + N

				!ifdef c128 {
					!ifndef scpu {
						sty VIC+$30							; 4
						cli									; 2
					}
				}
			}

		!if reu_fetch_track = 0 { reu_fetch_unroll_close = * }
		}

	txa														; 2
	adc #16													; 2

-	ldy audio_out_buf_index									; 3
	cmp and_f0_table,y										; 4
	beq -													; 3/2

	reu_mixer_loop_open
	  !for .idx2, 0, 15 {

		; the various `LDY $nnnn` below will have their addresses re-written
		; by the reu_do_realtime_selfmods_for_pitch_change routine below.
		; Similarly, each corresponding `LDA/ADC $nnnn,Y` will
		; have its high byte re-written by the set_volume routine.
		;
		; the addresses below are arbitrary, chosen only so that they're
		; definitely in absolute mode when assembled, and so that failure
		; to alter one of them is easy to spot in the ML monitor at runtime.

		clc													; 2

		!if .idx2 = 0 { reu_rd_la_track_1 = * }
		ldy $6100											; 4
		!if .idx2 = 0 { reu_vol_addr_1 = * }
		lda $8100,y											; 4

		!if .idx2 = 0 { reu_rd_la_track_4 = *}
		ldy $6400											; 4
		!if .idx2 = 0 { reu_vol_addr_4 = *}
		adc $8400,y											; 4

		ror													; 2
		sta audio_buffer_left,x								; 5

		clc													; 2

		!if .idx2 = 0 { reu_rd_la_track_2 = * }
		ldy $6200											; 4
		!if .idx2 = 0 { reu_vol_addr_2 = * }
		lda $8200,y											; 4

		!if .idx2 = 0 { reu_rd_la_track_3 = * }
		ldy $6300											; 4
		!if .idx2 = 0 { reu_vol_addr_3 = * }
		adc $8300,y											; 4

		ror													; 2
		sta audio_buffer_right,x							; 5

		inx													; 2
	  !if .idx2 = 0 { !set reu_mixer_loop_close = * }
	}

	dec mixer_countdown										; 5
	beq +													; 3/2
	jmp reu_fetch_main_loop									; 3

+	stx audio_in_buf_index
rts


; =========================================================
; === fetch loop and mixer loop self-mod setup routines ===
; =========================================================

reu_mixer_loop_segment_length = reu_mixer_loop_close - reu_mixer_loop_open

reu_set_lookahead_vol_addrs
	ldx reu_lookahead_code_volume_addr_idx,y

	!zone lookahead_idx_set {
		!for idx6, 0, 15 {
			sta reu_vol_addr_1 + reu_mixer_loop_segment_length * idx6 + 2,x
		}
	}
rts

; SET-UP LOOKAHEAD INDEXES/ADDRESSES

; This routine just sets up where in the above fetch loop segment the changes
; will be made

reu_fetch_selfmods_init
	ldx seq_current_track

	ldy #8
	lda (ram_drv_fetch_addr_table_pointer),y ; fetch loop code segment length
	jsr multiply_8x8

	ldy #0
	lda (ram_drv_fetch_addr_table_pointer),y ; fetch loop open code address LSB
	clc
	adc product
	sta utility_pointer

	iny
	lda (ram_drv_fetch_addr_table_pointer),y ; MSB
	adc product+1
	sta utility_pointer+1
rts

; This sets the self-mod steprate values that get added in the fetch routine,
; which control each track's frequency, and sets the associated self-mods in
; the mixer so that the lookahead code finds the right data.
;
; Always operates on the track number specified by seq_current_track

reu_do_realtime_selfmods_for_pitch_change
	jsr reu_fetch_selfmods_init

	ldx seq_current_track
	ldy #2
	lda (ram_drv_fetch_addr_table_pointer),y ; current steprate fract offs
	tay
	lda current_steprates_fracts,x
	sta (utility_pointer),y

	ldy #3
	lda (ram_drv_fetch_addr_table_pointer),y ; current steprate int offs
	tay
	lda current_steprates_ints,x
	sta (utility_pointer),y

	!zone lookahead_idx_set {
		ldy seq_current_track

		lda #0
		sta utility_zpbk_counter
		sta utility_zpbk_counter+1
		sta utility_zpbk_counter+2

		sta temp_zpbk_a
		lda current_steprates_fracts,y
		sta temp_zpbk_a+1

		lda current_steprates_ints,y
		lsr
		ror temp_zpbk_a+1
		ror temp_zpbk_a
		lsr
		ror temp_zpbk_a+1
		ror temp_zpbk_a
		lsr
		ror temp_zpbk_a+1
		ror temp_zpbk_a
		lsr
		ror temp_zpbk_a+1
		ror temp_zpbk_a
		sta temp_zpbk_a+2

		ldx reu_lookahead_code_read_byte_addr_idx,y

		clc
		lda seq_current_track
		adc #>sample_data_buffer

		!for idx4, 0, 15 {
			!set reu_la_rd_addr_st = reu_rd_la_track_1 + reu_mixer_loop_segment_length * idx4
			sta reu_la_rd_addr_st + 2,x
		}

		!for idx5, 0, 15 {

			!set reu_la_rd_addr_st = reu_rd_la_track_1 + reu_mixer_loop_segment_length * idx5

			lda utility_zpbk_counter+2
			sta reu_la_rd_addr_st + 1,x

			lda utility_zpbk_counter
			adc temp_zpbk_a
			sta utility_zpbk_counter

			lda utility_zpbk_counter+1
			adc temp_zpbk_a+1
			sta utility_zpbk_counter+1

			lda utility_zpbk_counter+2
			adc temp_zpbk_a+2
			sta utility_zpbk_counter+2
		}
	}

	lsr
	lsr
	adc #1

+	pha
	ldy #7
	lda (ram_drv_fetch_addr_table_pointer),y ; fetch length addr
	tay
	pla
	sta (utility_pointer),y
rts


; This simply sets the three self-mod immediate compares that look for the
; end of the sample, in the fetch routine.
;
; Always operates on the track number specified by seq_current_track

reu_do_realtime_selfmods_for_instrument_change
	jsr reu_fetch_selfmods_init

	ldx seq_current_track
	ldy #4
	lda (ram_drv_fetch_addr_table_pointer),y ; sample pointer LSB end-check offs
	tay
	lda current_sample_end_addr_lows,x
	sta (utility_pointer),y

	ldy #5
	lda (ram_drv_fetch_addr_table_pointer),y ; end-check mid byte
	tay
	lda current_sample_end_addr_mids,x
	sta (utility_pointer),y

	ldy #6
	lda (ram_drv_fetch_addr_table_pointer),y ; end-check MSB
	tay
	lda current_sample_end_addr_highs,x
	sta (utility_pointer),y
rts

reu_lookahead_code_read_byte_addr_idx
	!byte 0
	!byte reu_rd_la_track_2 - reu_rd_la_track_1
	!byte reu_rd_la_track_3 - reu_rd_la_track_1
	!byte reu_rd_la_track_4 - reu_rd_la_track_1

reu_lookahead_code_volume_addr_idx
	!byte 0
	!byte reu_vol_addr_2 - reu_vol_addr_1
	!byte reu_vol_addr_3 - reu_vol_addr_1
	!byte reu_vol_addr_4 - reu_vol_addr_1

}
