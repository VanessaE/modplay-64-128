; SET SAMPLE OFFSET

run_effect_set_sample_offset
	!ifndef turbo_available {
		lda current_multirate_levels,y
		beq +
		jmp multirate_set_sample_offset
	  +
	}

	ldx current_sample_numbers,y
	clc
	lda seq_command_arguments,y
	adc sample_start_addresses_mids,x
	sta current_sample_pointers_mids,y
	lda sample_start_addresses_highs,x
	adc #0
	sta current_sample_pointers_highs,y

	lda #0
	sta current_sample_pointers_lows,y
	sta current_sample_pointers_fracts,y
rts
