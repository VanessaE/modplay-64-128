; routines common to all mixer types

; distance between the per-track input caches in sample_data_buffer.  oldskool
; builds fetch a fixed 16 bytes per track, so the four caches are packed into
; the first page, 16 bytes apart.  turbo builds keep one page per track.

!ifndef turbo_available {
	MIXER_CACHE_STRIDE = 16
} else {
	MIXER_CACHE_STRIDE = $0100
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
		tya						; each track's cache starts at track * 16
		asl
		asl
		asl
		asl
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

	!ifdef turbo_available {
		adc #1
	}
}
