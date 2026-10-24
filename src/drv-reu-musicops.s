; RAM driver for standard REU, music-related functions

; the sequencer will look here (via a vector) to find the address and offsets
; into the fetch routine that it must use to do the self-mod stuff.

!zone reu_driver_music_ops {

; this is the average fetch time, in cycles, per final output sample pair
; see full details in doc/timing-info.txt.

reu_fetch_loop_segment_length = reu_fetch_segment_close - reu_fetch_segment_start

reu_set_selfmod_and_mixer_vectors
	lda #<run_mixer_standard
	sta reu_mixer_call_vec+1
	lda #>run_mixer_standard
	sta reu_mixer_call_vec+2

	lda #<mixer_standard_do_selfmods_for_pitch_change
	sta mixer_selfmod_pitch_change_vec+1
	lda #>mixer_standard_do_selfmods_for_pitch_change
	sta mixer_selfmod_pitch_change_vec+2

	lda #<mixer_standard_set_vol_addrs
	sta reu_mixer_silence_track+1
	lda #>mixer_standard_set_vol_addrs
	sta reu_mixer_silence_track+2

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
		+C128_STA_CLOCK_FOR_REU
		sty DMA_CMD
		+C128_INC_CLOCK_FOR_REU
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

reu_run_fetch_and_mixer
	lda #0													; 2
	sta DMA_LOCAL_LO										; 4
	sta DMA_LENGTH_HI										; 4

	!ifndef turbo_available {
		; all four tracks' caches are in the first page of sample_data_buffer,
		; so the high byte never changes.  each track sets its own low byte.

		lda #>sample_data_buffer
		sta DMA_LOCAL_HI
	}

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

			; this conditional MUST have the same code length both ways

			!ifndef turbo_available {
				; reu_set_cache_layout re-writes this pair for striding mode,
				; to load .ftrk's cache page and store it in DMA_LOCAL_HI.

				!if .ftrk = 0 { !set reu_local_addr_imm = * }
				lda #.ftrk * MULTIRATE_WINDOW			; 2
				sta DMA_LOCAL_LO						; 4
			} else {
				!if .ftrk = 0 {
					sta DMA_LOCAL_HI					; 4
				} else {
					inc DMA_LOCAL_HI					; 5
				}
			}

			bit current_track_gate_flags + .ftrk		; 3
			bmi +										; 3/2
			jmp .reu_end_of_track_fetch					; 3

		+	lda current_fetch_loop_ofl_amounts + .ftrk	; 3
			beq .reu_advance_pointer_and_fetch			; 3/2
			jmp .reu_move_pointer_to_loop_start_offset	; 3

		.reu_advance_pointer_and_fetch
			lda current_sample_pointers_fracts + .ftrk	; 3
			!if .ftrk = 0 { !set reu_cur_steprate_f = * }
			adc #0										; 2
			sta current_sample_pointers_fracts + .ftrk	; 3

			lda current_sample_pointers_lows + .ftrk	; 3
			sta DMA_EXTERNAL_LO							; 4
			!if .ftrk = 0 { !set reu_cur_steprate_i = * }
			adc #0										; 2
			sta current_sample_pointers_lows + .ftrk	; 3
			bcc .reu_fix_hi_and_bank					; 3/2

			lda current_sample_pointers_mids + .ftrk	; 3
			sta DMA_EXTERNAL_HI							; 4
			inc current_sample_pointers_mids + .ftrk	; 5
			bne .reu_fix_bank							; 3/2

			lda current_sample_pointers_highs + .ftrk	; 3
			sta DMA_EXTERNAL_BANK						; 4
			inc current_sample_pointers_highs + .ftrk	; 5
			bcs .reu_do_standard_fetch					; 3 (always branches)

		.reu_fix_hi_and_bank
			lda current_sample_pointers_mids + .ftrk	; 3
			sta DMA_EXTERNAL_HI							; 4

		.reu_fix_bank
			lda current_sample_pointers_highs + .ftrk	; 3
			sta DMA_EXTERNAL_BANK						; 4

		.reu_do_standard_fetch
			!if .ftrk = 0 { !set reu_fetchlen = * }
		.reu_this_fetchlen
			!ifndef turbo_available {
				lda #MULTIRATE_WINDOW					; 2
			} else {
				lda #1									; 2
			}
			sta DMA_LENGTH_LO							; 4

			; N below will vary by pitch, on average it'll be around 32
			; on C64

			+C128_DEC_CLOCK_FOR_REU
			sty DMA_CMD									; 4 + N
			+C128_STY_CLOCK_FOR_REU

		.reu_sample_end_check
			!if .ftrk = 0 { !set reu_ckend_l_a = * }
			lda #0										; 2
			cmp current_sample_pointers_lows + .ftrk	; 3

			!if .ftrk = 0 { !set reu_ckend_m = * }
			lda #0										; 2
			sbc current_sample_pointers_mids + .ftrk	; 3

			!if .ftrk = 0 { !set reu_ckend_h = * }
			lda #0										; 2
			sbc current_sample_pointers_highs + .ftrk	; 3

			bcc +										; 2/3
			jmp .reu_end_of_track_fetch					; 3

		+	lda current_track_loop_flags + .ftrk		; 3
			bne .reu_sample_has_loop					; 3/2

			; .A = 0 implied

			ldy #.ftrk									; 2
			jsr reu_silence_track						; a lot 😕
			jmp .reu_end_of_track_fetch					; 3

		.reu_sample_has_loop
			sec											; 2
			lda current_sample_pointers_lows + .ftrk	; 3
			!if .ftrk = 0 { !set reu_ckend_l_b = * }
			sbc #0										; 2
			sta current_fetch_loop_ofl_amounts + .ftrk	; 3
			jmp .reu_end_of_track_fetch					; 3

		.reu_move_pointer_to_loop_start_offset
			; we can only get here if .A contains a non-zero overflow len.
			; the loop start comes from the per-track copy that start_sample
			; made, which is for whichever decimation level the note is using.
			clc											; 2
			adc current_loop_start_lows + .ftrk			; 4
			sta current_sample_pointers_lows + .ftrk	; 3
			lda current_loop_start_mids + .ftrk			; 4
			adc #0										; 2
			sta current_sample_pointers_mids + .ftrk	; 3
			lda current_loop_start_highs + .ftrk		; 4
			adc #0										; 2
			sta current_sample_pointers_highs + .ftrk	; 3
			lda #0										; 2
			sta current_fetch_loop_ofl_amounts + .ftrk	; 3
			jmp .reu_advance_pointer_and_fetch			; 3

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


; ===============================================
; === fetch loop self-mod and helper routines ===
; ===============================================

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

	!ifdef turbo_available {
		; fetch length addr
		ldy #(reu_fetchlen - reu_fetch_segment_start + 1)
		sta (utility_pointer),y
	} else {
		; with multirate in use, the result counts from the start of the track's
		; cache, which in the packed layout isn't 0, so take that off to get the
		; number of bytes the mixer will read from it, and never fetch more than the
		; window.  (striding mode uses the result as it is.)
		;
		; the length used to be fixed at the window, but that makes every track's DMA
		; burst as long as the window on every block, whatever the pitch, which holds
		; the CPU for longer and costs more time than the cycle counts allow for.

		bit multirate_enable
		bpl .store_fetch_len

		ldx seq_current_track
		sec
		sbc mixer_cache_offsets,x
		cmp #(MULTIRATE_WINDOW + 1)
		bcc .store_fetch_len
		lda #MULTIRATE_WINDOW

.store_fetch_len
		ldy #(reu_fetchlen - reu_fetch_segment_start + 1)
		sta (utility_pointer),y
	}
rts

; This simply plugs the sample/loop end addresses into the fetch routine.

reu_do_selfmods_for_instrument_change
	ldx seq_current_track
	lda reu_selfmod_fetch_segment_base_table,x
	sta utility_pointer
	lda reu_selfmod_fetch_segment_base_table+4,x
	sta utility_pointer+1

	; sample pointer LSB end-check offset
	ldy #(reu_ckend_l_a - reu_fetch_segment_start + 1)
	lda current_sample_end_addr_lows,x
	sta (utility_pointer),y
	ldy #(reu_ckend_l_b - reu_fetch_segment_start + 1)
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

!ifndef turbo_available {

; Sets up the cache layout for the file about to be played.  Run once at the
; start of playback, and it always writes everything, so that the settings from
; the previous file never carry over.
;
;   multirate in use ($80):   caches packed into the first page of
;       sample_data_buffer, MULTIRATE_WINDOW bytes apart, and every fetch is
;       exactly MULTIRATE_WINDOW bytes.
;   striding mode (0):  one page per track and variable-length fetches, which
;       is what the turbo builds do.
;
; this changes, in the fetch routine, the immediate and the register that the
; per-track `lda #imm / sta DMA_LOCAL_xx` pair loads, and the fetch length;
; and in the mixers, the track offsets used by the pitch self-mod and the high
; byte of every cache read address.

reu_set_cache_layout
	ldx #3

.rscl_track
	lda reu_selfmod_fetch_segment_base_table,x
	sta utility_pointer
	lda reu_selfmod_fetch_segment_base_table+4,x
	sta utility_pointer+1

	ldy #(reu_fetchlen - reu_fetch_segment_start + 1)
	lda #MULTIRATE_WINDOW				; (striding mode sets the real length
	sta (utility_pointer),y				; when the pitch self-mod runs)

	bit multirate_enable
	bpl .rscl_striding

	lda .packed_offsets,x				; packed:  cache at track * window,
	sta mixer_cache_offsets,x
	ldy #(reu_local_addr_imm - reu_fetch_segment_start + 1)
	sta (utility_pointer),y				; ...loaded into DMA_LOCAL_LO,
	lda #>sample_data_buffer
	sta reu_cache_hi_bytes,x
	lda #<DMA_LOCAL_LO
	bne .rscl_set_target				; (always)

.rscl_striding
	lda #0								; striding:  cache at the start of its
	sta mixer_cache_offsets,x			; own page, that page being loaded into
	txa									; DMA_LOCAL_HI
	clc
	adc #>sample_data_buffer
	sta reu_cache_hi_bytes,x
	ldy #(reu_local_addr_imm - reu_fetch_segment_start + 1)
	sta (utility_pointer),y
	lda #<DMA_LOCAL_HI

.rscl_set_target
	ldy #(reu_local_addr_imm - reu_fetch_segment_start + 3)
	sta (utility_pointer),y				; (the low byte of the STA's operand)

	dex
	bpl .rscl_track

	; the high byte of every cache read address in the mixer

	lda #<mixer_std_rd_la_track_1
	sta utility_pointer
	lda #>mixer_std_rd_la_track_1
	sta utility_pointer+1
	lda #<mixer_standard_read_addr_idx
	sta utility_pointer_b
	lda #>mixer_standard_read_addr_idx
	sta utility_pointer_b+1
	lda #mixer_standard_loop_segment_length

	; enter with .A = the length of one unrolled segment of the mixer's loop,
	; utility_pointer = the first cache read (track 1, first segment), and
	; utility_pointer_b = the mixer's table of per-track offsets to those.

.rscl_patch_mixer_hi_bytes
	sta .rscl_seg_len
	lda #15
	sta .rscl_seg_count

.rscl_segment
	ldx #3

.rscl_mixer_track
	txa
	tay
	lda (utility_pointer_b),y			; offset of this track's read
	clc
	adc #2								; its high byte
	tay
	lda reu_cache_hi_bytes,x
	sta (utility_pointer),y
	dex
	bpl .rscl_mixer_track

	clc
	lda utility_pointer
	adc .rscl_seg_len
	sta utility_pointer
	bcc +
	inc utility_pointer+1
  +	dec .rscl_seg_count
	bpl .rscl_segment
rts

.packed_offsets						!byte 0, MULTIRATE_WINDOW, MULTIRATE_WINDOW*2, MULTIRATE_WINDOW*3
.rscl_seg_len						!byte 0
.rscl_seg_count						!byte 0
}

; make sure .A = 0 on entry, .Y = track number

reu_silence_track
	stx temp_zpbk_a								; 3

	sta current_track_gate_flags,y				; 4
	dec current_active_tracks_count				; 5

	; the mixer volume selfmod loop needs
	; the vol table high addr byte in .A

	lda #>volume_table							; 2

	reu_mixer_silence_track
	jsr $1234									; 3+6+84 cycles

	ldx temp_zpbk_a								; 3
	ldy #$b1									; 2
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
