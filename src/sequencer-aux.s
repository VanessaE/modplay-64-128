;=============================
; Sequencer auxillary routines

; fetch the row indicated by .X, from pattern indicated by .Y, from expansion
; RAM into the row data buffer.

fetch_row_data
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

	adc utility_pointer_b+1		; finish the addition, now we have a relative
	sta utility_pointer_b+1		; offset from the first pattern byte
	lda utility_pointer_b+2
	adc #0
	sta utility_pointer_b+2

	; add exp_file_data_start_page*256 offsets since the pattern
	; data sits quite some ways up from the start of exp RAM

	clc
	lda utility_pointer_b+1
	adc exp_file_data_start_page
	sta utility_pointer_b+1
	bcc fetch_row_expansion_vec
	inc utility_pointer_b+2

	fetch_row_expansion_vec
		jmp $1234 ; just exit back to the caller via the fetch routine

; [re-]start a new sample
; enter with .A = sample number, .Y = track number

start_sample
	sta current_sample_numbers,y
	tax

	lda seq_commands,y
	cmp #9	; let the set-sample-offset cmd handle the pointer, if applicable
	beq +

	lda sample_start_addresses_mids,x
	sta current_sample_pointers_mids,y
	lda sample_start_addresses_highs,x
	sta current_sample_pointers_highs,y

+	lda #0
	sta current_sample_pointers_fracts,y
	sta current_sample_pointers_lows,y
	sta current_fetch_loop_ofl_amounts,y

	lda sample_default_loop_flags,x
	sta current_track_loop_flags,y

	lda sample_end_addresses_lows,x
	sta current_sample_end_addr_lows,y
	lda sample_end_addresses_mids,x
	sta current_sample_end_addr_mids,y
	lda sample_end_addresses_highs,x
	sta current_sample_end_addr_highs,y

	lda sample_default_loop_flags,x
	sta current_track_loop_flags,y

	; the fetcher restarts loops from these per-track copies

	lda sample_loop_start_addresses_lows,x
	sta current_loop_start_lows,y
	lda sample_loop_start_addresses_mids,x
	sta current_loop_start_mids,y
	lda sample_loop_start_addresses_highs,x
	sta current_loop_start_highs,y

	!ifndef turbo_available {
		lda #0
		sta current_multirate_levels,y

		bit multirate_enable
		bpl +

		jsr multirate_apply_level
	  +
	}

	lda current_track_gate_flags,y
	bmi +

	inc current_active_tracks_count
	lda #$80
	sta current_track_gate_flags,y

	; if extended command #5 is called-for on this track and row, use
	; its fine-tune value instead of the sample's default.

+	lda seq_commands,y
	cmp #14
	bne .not_ext_5
	lda seq_command_arguments,y
	and #$f0
	cmp #$50
	bne .not_ext_5

	jsr extcmd_set_fine_tune
	jmp .apply_default_ft

.not_ext_5
	lda sample_default_fine_tunes,x
	sta current_fine_tune_values,y

.apply_default_ft
	jsr do_selfmod_instrument_vec

	ldy seq_current_track
	ldx current_sample_numbers,y
rts

; convert a note period into a sample stepper value
; enter with .Y = track number

set_pitch_by_table_lookup
	lda current_track_gate_flags,y
	bmi +
	rts

+	lda current_note_periods_lows,y
	lda current_note_periods_lows,y
	sta utility_pointer
	lda current_note_periods_highs,y
	asl utility_pointer
	rol
	sta utility_pointer+1

	clc
	lda utility_pointer
	adc #<steprate_lookup_table
	sta utility_pointer
	lda utility_pointer+1
	adc #>steprate_lookup_table
	sta utility_pointer+1

	tya
	tax

	ldy #0
	lda (utility_pointer),y
	sta current_steprates_fracts,x
	iny
	lda (utility_pointer),y
	sta current_steprates_ints,x

	!ifndef turbo_available {
		jsr multirate_shift_steprate
	}

	ldy seq_current_track
	jsr do_selfmod_pitch_vec
rts

; enter with .A = desired fine tune value
; and .X = the index into the row data for the channel's period value
; get the result from product+2/+3
; this routine is .Y-safe.

calculate_fine_tuning
	pha
	lda seq_current_row_data+1,x
	and #$0f
	sta multiplicand_b+1
	lda seq_current_row_data+2,x
	sta multiplicand_b
	pla

fine_tuning_mult_b_is_preset
	asl
	tax
	lda fine_tuning_table,x
	sta multiplicand_a
	lda fine_tuning_table+1,x
	sta multiplicand_a+1

	sec
	jsr multiply_16x16

	; multiplying the upper three bytes by 2 and then using the highest two
	; bytes is the same as dividing the entire four-byte result by 32768

	asl product+1
	rol product+2
	rol product+3
rts
