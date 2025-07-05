; SET SAMPLE OFFSET

run_effect_set_sample_offset
	ldx current_sample_numbers,y
	lda #0
	sta temp_zpbk_a
	lda seq_command_arguments,y
	asl
	rol temp_zpbk_a
	clc
	adc sample_start_addresses_mids,x
	sta sample_pointers_mids,y
	lda sample_start_addresses_highs,x
	adc temp_zpbk_a
	sta sample_pointers_highs,y
rts
