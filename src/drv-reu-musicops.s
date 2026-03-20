; RAM driver for standard REU, music-related functions

; the sequencer will look here (via a vector) to find the address and offsets
; into the fetch routine that it must use to do the self-mod stuff.

!zone reu_driver_music_ops {

; this is the average fetch time, in cycles, per final output sample pair
; see full details in doc/timing-info.txt.

reu_set_selfmod_and_mixer_vectors
	lda filter_setting
	bmi +

	lda #<run_mixer_standard_lookahead
	sta reu_mixer_call_vec+1
	lda #>run_mixer_standard_lookahead
	sta reu_mixer_call_vec+2

	lda #<mixer_standard_do_selfmods_for_pitch_change
	sta reu_selfmod_init_vec+1
	lda #>mixer_standard_do_selfmods_for_pitch_change
	sta reu_selfmod_init_vec+2
	rts

+	lda #<run_mixer_lowpass_lookahead
	sta reu_mixer_call_vec+1
	lda #>run_mixer_lowpass_lookahead
	sta reu_mixer_call_vec+2

	lda #<mixer_lowpass_do_selfmods_for_pitch_change
	sta reu_selfmod_init_vec+1
	lda #>mixer_lowpass_do_selfmods_for_pitch_change
	sta reu_selfmod_init_vec+2
rts

reu_set_cycle_counts
	!ifndef scpu {
		!ifndef c128 {
			lda #31 + 2
		} else {
			lda #48 / 2 ; equivalent 1 MHz cycles
		}
	} else {
		lda #16 + 1 ; equivalent 1 MHz cycles
	}
	sta ram_driver_fetch_cycle_count
rts

reu_fetch_row
	clc
	lda utility_pointer_b
	sta DMA_LO
	lda utility_pointer_b+1
	sta DMA_HI
	lda utility_pointer_b+2
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
			sta C128_VIC_CLOCK_SPEED
			sty DMA_CMD
			sty C128_VIC_CLOCK_SPEED
			cli
		}
	} else {
		; on SCPU, we split the transfer into small pieces to minimize
		; interference with the audio ISR's timing.
		lda #8
		sta DMA_DAL
		sty DMA_CMD
		sta DMA_DAL
		sty DMA_CMD
	}
rts

; THE ACTUAL FETCH ROUTINE
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
				!set .ftrk = reu_fetch_track

				!set .reu_steprate_fract_addr	= reu_cur_steprate_f + reu_fetch_loop_segment_length * .ftrk + 1
				!set .reu_steprate_int_addr		= reu_cur_steprate_i + reu_fetch_loop_segment_length * .ftrk + 1
				!set .reu_samp_end_low_addr		= reu_ckend_l + reu_fetch_loop_segment_length * .ftrk + 1
				!set .reu_samp_end_mid_addr		= reu_ckend_m + reu_fetch_loop_segment_length * .ftrk + 1
				!set .reu_samp_end_high_addr	= reu_ckend_h + reu_fetch_loop_segment_length * .ftrk + 1

				lda #(>sample_data_buffer) + .ftrk			; 2
				sta DMA_ADH									; 4

				lda sample_pointers_fracts + .ftrk			; 3
				!if .ftrk = 0 { !set reu_cur_steprate_f = * }
				adc #0										; 2
				sta sample_pointers_fracts + .ftrk			; 3

				lda sample_pointers_lows + .ftrk			; 3
				!if .ftrk = 0 { !set reu_cur_steprate_i = * }
				adc #0										; 2
				sta sample_pointers_lows + .ftrk			; 3
				sta DMA_LO									; 4
				bcc .reu_fix_dma_top_two_bytes				; 3/2

				inc sample_pointers_mids + .ftrk			; 5
				lda sample_pointers_mids + .ftrk			; 3
				sta DMA_HI									; 4
				bne .reu_fix_dma_top_byte					; 3/2

				inc sample_pointers_highs + .ftrk			; 5
				lda sample_pointers_highs + .ftrk			; 3
				sta DMA_BANK								; 4
				jmp .reu_check_end							; 3

			.reu_fix_dma_top_two_bytes
				lda sample_pointers_mids + .ftrk			; 3
				sta DMA_HI									; 4

			.reu_fix_dma_top_byte
				lda sample_pointers_highs + .ftrk			; 3
				sta DMA_BANK								; 4

			.reu_check_end
				lda sample_pointers_lows + .ftrk			; 3
				!if .ftrk = 0 { !set reu_ckend_l = * }
				cmp #0										; 2

				lda sample_pointers_mids + .ftrk			; 3
				!if .ftrk = 0 { !set reu_ckend_m = * }
				sbc #0										; 2

				lda sample_pointers_highs + .ftrk			; 3
				!if .ftrk = 0 { !set reu_ckend_h = * }
				sbc #0										; 2

				bcc .reu_fetch_sample_data					; 3/2

				clc											; 2
				lda track_current_loop_flags + .ftrk		; 3
				bne .reu_sample_has_loop					; 3/2
				sta sample_pointers_lows + .ftrk			; 3
				sta sample_pointers_mids + .ftrk			; 3
				sta sample_pointers_highs + .ftrk			; 3
				sta .reu_steprate_fract_addr				; 4
				sta .reu_steprate_int_addr					; 4

				sta .reu_samp_end_low_addr					; 4
				sta .reu_samp_end_high_addr					; 4
				lda #1										; 2
				sta .reu_samp_end_mid_addr					; 4

				jmp .reu_fetch_sample_data					; 3

			.reu_sample_has_loop
				lda #0										; 2
				sta sample_pointers_fracts + .ftrk			; 3
				ldy current_sample_numbers + .ftrk			; 3
				lda sample_loop_start_addresses_lows,y		; 5
				sta sample_pointers_lows + .ftrk			; 3
				sta DMA_LO									; 4
				lda sample_loop_start_addresses_mids,y		; 5
				sta sample_pointers_mids + .ftrk			; 3
				sta DMA_HI									; 4
				lda sample_loop_start_addresses_highs,y		; 5
				sta sample_pointers_highs + .ftrk			; 3
				sta DMA_BANK								; 4
				lda sample_loop_end_addresses_lows,y		; 5
				sta .reu_samp_end_low_addr					; 4
				lda sample_loop_end_addresses_mids,y		; 5
				sta .reu_samp_end_mid_addr					; 4
				lda sample_loop_end_addresses_highs,y		; 5
				sta .reu_samp_end_high_addr					; 4
				ldy #$91									; 2

			.reu_fetch_sample_data

				!if .ftrk = 0 { !set reu_fetchlen = * }
				lda #1										; 2
				sta DMA_DAL									; 4

				!ifdef c128 {
					!ifndef scpu {
						sei									; 2
						dec C128_VIC_CLOCK_SPEED						; 7
					}
				}

				; N below will vary by pitch, on average it'll be around 32
				; on C64

				sty DMA_CMD									; 4 + N

				!ifdef c128 {
					!ifndef scpu {
						sty C128_VIC_CLOCK_SPEED						; 4
						cli									; 2
					}
				}
			}

		!if reu_fetch_track = 0 { reu_fetch_unroll_close = * }
		}

	reu_mixer_call_vec
	; this will be set to one of the mixer routines
	  jsr $1234												; 6

	dec mixer_countdown										; 5
	beq +													; 3/2
	jmp reu_fetch_main_loop									; 3

+	stx audio_in_buf_index
rts

; =========================================================
; === fetch loop self-mod setup routines ===
; =========================================================

; SET-UP LOOKAHEAD INDEXES/ADDRESSES

; This routine just sets up where in the above fetch loop segment the changes
; will be made

reu_fetch_selfmods_init
	ldx seq_current_track

	lda #(reu_fetch_unroll_close - reu_fetch_unroll_open)
	jsr multiply_8x8

	clc
	lda #<reu_fetch_unroll_open
	adc product
	sta utility_pointer

	lda #>reu_fetch_unroll_open
	adc product+1
	sta utility_pointer+1
rts

; This sets the self-mod steprate values that get added in the fetch routine,
; which control each track's frequency, and sets the associated self-mods in
; the mixer so that the lookahead code finds the right data.
;
; Always operates on the track number specified by seq_current_track

reu_do_selfmods_for_pitch_change
	jsr reu_fetch_selfmods_init

	reu_selfmod_init_vec
	  jsr $1234

	; returns the total lookahead distance in .A

	; fetch length addr
	ldy #(reu_fetchlen - reu_fetch_unroll_open + 1)
	sta (utility_pointer),y

	ldx seq_current_track

	; current steprate fract offset
	ldy #(reu_cur_steprate_f - reu_fetch_unroll_open + 1)
	lda current_steprates_fracts,x
	sta (utility_pointer),y

	; current steprate int offset
	ldy #(reu_cur_steprate_i - reu_fetch_unroll_open + 1)
	lda current_steprates_ints,x
	sta (utility_pointer),y
rts

; This simply sets the three self-mod immediate compares that look for the
; end of the sample, in the fetch routine.
;
; Always operates on the track number specified by seq_current_track

reu_do_selfmods_for_instrument_change
	jsr reu_fetch_selfmods_init

	; sample pointer LSB end-check offset
	ldy #(reu_ckend_l - reu_fetch_unroll_open + 1)
	lda current_sample_end_addr_lows,x
	sta (utility_pointer),y

	; end-check mid byte
	ldy #(reu_ckend_m - reu_fetch_unroll_open + 1)
	lda current_sample_end_addr_mids,x
	sta (utility_pointer),y

	; end-check MSB
	ldy #(reu_ckend_h - reu_fetch_unroll_open + 1)
	lda current_sample_end_addr_highs,x
	sta (utility_pointer),y
rts
}
