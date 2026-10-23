; routines common to all mixer types

; distance between the per-track input caches in sample_data_buffer.  oldskool
; builds with multirate in use fetch a fixed MULTIRATE_WINDOW bytes per track,
; so the four caches are packed into the first page, MULTIRATE_WINDOW bytes
; apart.  turbo builds, and oldskool builds in striding mode, keep one page per
; track.  (the assembled addresses below are for the packed layout, and are
; re-written at the start of playback when that's not what the file needs.)

!ifndef turbo_available {
	MIXER_CACHE_STRIDE = MULTIRATE_WINDOW
} else {
	MIXER_CACHE_STRIDE = $0100
}

!ifndef turbo_available {

	; oldskool builds set these up at the start of playback, for each file, in
	; reu_set_cache_layout.  with multirate in use the four caches are packed
	; into the first page, MULTIRATE_WINDOW bytes apart, and all of the mixer's
	; read addresses are in that page.  in striding mode each track gets a
	; page of its own, like in the turbo builds.

	mixer_cache_offsets
		!byte 0, MULTIRATE_WINDOW, MULTIRATE_WINDOW*2, MULTIRATE_WINDOW*3
	reu_cache_hi_bytes
		!byte >sample_data_buffer, >sample_data_buffer
		!byte >sample_data_buffer, >sample_data_buffer
}

!macro MIXER_VOL_SELFMOD_LOOP .seg_base, .seg_len, .base_table {
	ldx .base_table,y
	!for .idx6, 0, 15 {
		sta .seg_base + .seg_len * .idx6 + 2,x
	}
}

!macro MIXER_PITCH_SELFMOD_LOOP .seg_base, .seg_len, .base_table {
	ldy seq_current_track

	!ifndef turbo_available {
		lda mixer_cache_offsets,y	; this track's cache offset within its page
	} else {
		lda #0
	}

	sta utility_zpbk_counter

	lda #0
	sta temp_zpbk_b ; this one will track the fraction during adding

	lda current_steprates_fracts,y
	sta temp_zpbk_a

	lda current_steprates_ints,y
	lsr
	ror temp_zpbk_a
	lsr
	ror temp_zpbk_a
	lsr
	ror temp_zpbk_a
	lsr
	ror temp_zpbk_a
	sta temp_zpbk_a+1

	ldx .base_table,y

	!for .wr_idx, 0, 15 {

		!set .rd_addr = .seg_base + .seg_len * .wr_idx

		lda utility_zpbk_counter	; the last-generated int becomes the
		sta .rd_addr + 1,x			; index for that cycle of the write loop

		lda temp_zpbk_b				; add up the fractions
		adc temp_zpbk_a				; and just store them
		sta temp_zpbk_b

		lda utility_zpbk_counter	; add the ints, result to be used in the
		adc temp_zpbk_a+1			; next cycle of the loop (above)
		sta utility_zpbk_counter
	}

	adc #1						; (only striding mode and turbo builds use the result)
}
