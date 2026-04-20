; RAM driver for standard REU, music-related functions

; the sequencer will look here (via a vector) to find the address and offsets
; into the fetch routine that it must use to do the self-mod stuff.

!zone reu_driver_music_ops {

; this is the average fetch time, in cycles, per final output sample pair
; see full details in doc/timing-info.txt.

reu_set_selfmod_and_mixer_vectors
	lda filter_setting
	bmi +

	lda #<run_mixer_standard
	sta reu_mixer_call_vec+1
	lda #>run_mixer_standard
	sta reu_mixer_call_vec+2

	lda #<mixer_standard_do_selfmods_for_pitch_change
	sta mixer_selfmod_pitch_change_vec+1
	lda #>mixer_standard_do_selfmods_for_pitch_change
	sta mixer_selfmod_pitch_change_vec+2
	rts

+	lda #<run_mixer_lowpass
	sta reu_mixer_call_vec+1
	lda #>run_mixer_lowpass
	sta reu_mixer_call_vec+2

	lda #<mixer_lowpass_do_selfmods_for_pitch_change
	sta mixer_selfmod_pitch_change_vec+1
	lda #>mixer_lowpass_do_selfmods_for_pitch_change
	sta mixer_selfmod_pitch_change_vec+2
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
	sta DMA_EXTERNAL_LO
	lda utility_pointer_b+1
	sta DMA_EXTERNAL_HI
	lda utility_pointer_b+2
	sta DMA_EXTERNAL_BANK

	lda #<seq_current_row_data
	sta DMA_LOCAL_LO
	lda #>seq_current_row_data
	sta DMA_LOCAL_HI

	lda #0
	sta DMA_LENGTH_HI

	ldy #$91

	!ifndef scpu {
		lda #16
		sta DMA_LENGTH_LO
		+C128_2MHZ_OFF_FOR_REU
		sty DMA_CMD
		+C128_2MHZ_ON_FOR_REU
	} else {
		; on SCPU, we split the transfer into small pieces to minimize
		; interference with the audio ISR's timing.
		lda #8
		sta DMA_LENGTH_LO
		sty DMA_CMD
		sta DMA_LENGTH_LO
		sty DMA_CMD
	}
rts

; THE ACTUAL FETCH ROUTINE
; The hard work happens here 🙂

reu_fetch_loop_segment_length = reu_fetch_segment_close - reu_fetch_segment_start

reu_run_fetch_and_mixer
	lda #0													; 2
	sta DMA_LOCAL_LO										; 4
	sta DMA_LENGTH_HI										; 4
	lda audio_in_buf_index									; 3
	and #$f0												; 2
	tax														; 2

	reu_fetch_main_loop
		clc													; 2
		ldy #$b1											; 2
		lda #>sample_data_buffer							; 2

			!for reu_fetch_track, 0, 3 {
			  !zone reu_fetchloop {
				!set .ftrk = reu_fetch_track
				!if .ftrk = 0 { !set reu_fetch_segment_start = * }

				!ifdef use_profiler {
					+FETCH_PROFILER_A
					lda #>sample_data_buffer
				}

				!if .ftrk = 0 { ; this conditional MUST have the same code length
					sta DMA_LOCAL_HI						; 4
				} else {
					inc DMA_LOCAL_HI						; 5
				}

				bit current_track_gate_flags + .ftrk		; 3
				bmi +										; 3/2
				jmp .reu_end_of_track_fetch					; 3

			+	lda current_sample_pointers_fracts + .ftrk	; 3
				!if .ftrk = 0 { !set reu_cur_steprate_f = * }
				adc #0										; 2
				sta current_sample_pointers_fracts + .ftrk	; 3

				lda current_sample_pointers_lows + .ftrk	; 3
				!if .ftrk = 0 { !set reu_cur_steprate_i = * }
				adc #0										; 2
				sta current_sample_pointers_lows + .ftrk	; 3
				sta DMA_EXTERNAL_LO							; 4
				bcc .reu_fix_dma_top_two_bytes				; 3/2

				inc current_sample_pointers_mids + .ftrk	; 5
				lda current_sample_pointers_mids + .ftrk	; 3
				sta DMA_EXTERNAL_HI							; 4
				bne .reu_fix_dma_top_byte					; 3/2

				inc current_sample_pointers_highs + .ftrk	; 5
				lda current_sample_pointers_highs + .ftrk	; 3
				sta DMA_EXTERNAL_BANK						; 4
				bcs .reu_check_end							; 3 (always branches)

			.reu_fix_dma_top_two_bytes
				lda current_sample_pointers_mids + .ftrk	; 3
				sta DMA_EXTERNAL_HI							; 4

			.reu_fix_dma_top_byte
				lda current_sample_pointers_highs + .ftrk	; 3
				sta DMA_EXTERNAL_BANK						; 4

			.reu_check_end
				lda current_sample_pointers_lows + .ftrk	; 3
				!if .ftrk = 0 { !set reu_ckend_l = * }
				cmp #0										; 2

				lda current_sample_pointers_mids + .ftrk	; 3
				!if .ftrk = 0 { !set reu_ckend_m = * }
				sbc #0										; 2

				lda current_sample_pointers_highs + .ftrk	; 3
				!if .ftrk = 0 { !set reu_ckend_h = * }
				sbc #0										; 2

				bcc .reu_fetch_sample_data					; 3/2

				clc											; 2
				lda current_track_loop_flags + .ftrk		; 3
				bne .reu_sample_has_loop					; 3/2
				sta current_track_gate_flags + .ftrk		; 3
				sta DMA_EXTERNAL_LO							; 4
				sta DMA_EXTERNAL_HI							; 4
				sta DMA_EXTERNAL_BANK						; 4
				dec current_active_tracks_count				; 5
				bcc .reu_fetch_sample_data					; 3 (always branches)

			.reu_sample_has_loop
				lda #0										; 2
				sta current_sample_pointers_fracts + .ftrk	; 3
				ldy current_sample_numbers + .ftrk			; 3
				lda sample_loop_start_addresses_lows,y		; 5
				sta current_sample_pointers_lows + .ftrk	; 3
				sta DMA_EXTERNAL_LO							; 4
				lda sample_loop_start_addresses_mids,y		; 5
				sta current_sample_pointers_mids + .ftrk	; 3
				sta DMA_EXTERNAL_HI							; 4
				lda sample_loop_start_addresses_highs,y		; 5
				sta current_sample_pointers_highs + .ftrk	; 3
				sta DMA_EXTERNAL_BANK						; 4
				ldy #$b1									; 2

			.reu_fetch_sample_data

				!if .ftrk = 0 { !set reu_fetchlen = * }
				lda #1										; 2
				sta DMA_LENGTH_LO							; 4

				; N below will vary by pitch, on average it'll be around 32
				; on C64

				+C128_2MHZ_OFF_FOR_REU
				sty DMA_CMD									; 4 + N
				+C128_2MHZ_ON_FOR_REU

				!ifdef use_profiler {
					+FETCH_PROFILER_B 7, .ftrk
				}

			.reu_end_of_track_fetch
			; when a track is not gated, the code skips the whole fetch

			}

		!if reu_fetch_track = 0 { reu_fetch_segment_close = * }
		}

	reu_mixer_call_vec
	; this will be set to one of the mixer routines
	  jsr $1234												; 6

	!ifdef c64u {
		jsr viz_waveform_c64u_fill_cache
	}

	dec mixer_countdown										; 5
	beq +													; 3/2
	jmp reu_fetch_main_loop									; 3

+	stx audio_in_buf_index
rts

; ====================================
; === fetch loop self-mod routines ===
; ====================================

; This plugs the step rate values into the fetch routine, and runs the
; subroutine to set up the byte offsets in the mixer so it gets the right
; data.

reu_do_selfmods_for_pitch_change
	ldx seq_current_track
	lda reu_selfmod_fetch_segment_base_table,x
	sta utility_pointer
	lda reu_selfmod_fetch_segment_base_table+4,x
	sta utility_pointer+1

	; current steprate fract offset
	ldy #(reu_cur_steprate_f - reu_fetch_segment_start + 1)
	lda current_steprates_fracts,x
	sta (utility_pointer),y

	; current steprate int offset
	ldy #(reu_cur_steprate_i - reu_fetch_segment_start + 1)
	lda current_steprates_ints,x
	sta (utility_pointer),y

	mixer_selfmod_pitch_change_vec	; returns total lookahead distance in .A
	  jsr $1234

	; fetch length addr
	ldy #(reu_fetchlen - reu_fetch_segment_start + 1)
	sta (utility_pointer),y
rts

; This simply plugs the sample/loop end addresses into the fetch routine.

reu_do_selfmods_for_instrument_change
	ldx seq_current_track
	lda reu_selfmod_fetch_segment_base_table,x
	sta utility_pointer
	lda reu_selfmod_fetch_segment_base_table+4,x
	sta utility_pointer+1

	; sample pointer LSB end-check offset
	ldy #(reu_ckend_l - reu_fetch_segment_start + 1)
	lda current_sample_end_addr_lows,x
	sta (utility_pointer),y

	; end-check mid byte
	ldy #(reu_ckend_m - reu_fetch_segment_start + 1)
	lda current_sample_end_addr_mids,x
	sta (utility_pointer),y

	; end-check MSB
	ldy #(reu_ckend_h - reu_fetch_segment_start + 1)
	lda current_sample_end_addr_highs,x
	sta (utility_pointer),y
rts
}

reu_selfmod_fetch_segment_base_table
	!byte <reu_fetch_segment_start
	!byte <(reu_fetch_segment_start + reu_fetch_loop_segment_length)
	!byte <(reu_fetch_segment_start + reu_fetch_loop_segment_length*2)
	!byte <(reu_fetch_segment_start + reu_fetch_loop_segment_length*3)

	!byte >reu_fetch_segment_start
	!byte >(reu_fetch_segment_start + reu_fetch_loop_segment_length)
	!byte >(reu_fetch_segment_start + reu_fetch_loop_segment_length*2)
	!byte >(reu_fetch_segment_start + reu_fetch_loop_segment_length*3)
