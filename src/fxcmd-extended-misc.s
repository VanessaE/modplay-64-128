; "Extended commands" common stuff and misc command routines
;
; like primary commands, these need a track number in .Y

start_extended_effect
	stx sequencer_temp_x
	ldx seq_command_arguments,y
	lda divide_by_16_table,x
	asl
	tax

	lda extended_effect_command_jump_table+1,x
	sta start_extended_effect_vec+2
	beq dont_start_extended_effect
	lda extended_effect_command_jump_table,x
	sta start_extended_effect_vec+1

	start_extended_effect_vec
		jsr $1234

	dont_start_extended_effect

	ldx sequencer_temp_x
rts

run_extended_effect
rts

extcmd_set_fine_tune
	lda seq_command_arguments,y
	and #$0f
	clc
	adc #8
	and #$0f
	sta current_fine_tune_values,y
rts

extended_effect_command_jump_table
	!word 0 ; filter on/off
	!word extcmd_fine_slide_up
	!word extcmd_fine_slide_down
	!word 0 ; glissando on/off
	!word 0 ; vibrato waveform
	!word extcmd_set_fine_tune
	!word 0 ; loop pattern
	!word 0 ; tremolo waveform
	!word 0 ; [unused]
	!word 0 ; retrigger sample
	!word 0 ; fine volume slide up
	!word 0 ; fine volume slide down
	!word 0 ; cut/truncate sample
	!word 0 ; delay sample start
	!word 0 ; delay pattern
	!word 0 ; invert loop
