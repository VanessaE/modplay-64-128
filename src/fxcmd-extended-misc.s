; "Extended commands" common stuff and misc command routines
;
; like primary commands, these need a track number in .Y

start_extended_effect
	stx sequencer_temp_x
	ldx seq_command_arguments,y
	lda divide_by_16_table,x
	tax
	lda extended_effect_command_jump_table_highs,x
	sta start_extended_effect_vec+2
	beq dont_start_extended_effect
	lda extended_effect_command_jump_table_lows,x
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
	sta current_fine_tune_values,y
rts

extended_effect_command_jump_table_lows
	!byte 0 ; filter on/off
	!byte <extcmd_fine_slide_up
	!byte <extcmd_fine_slide_down
	!byte 0 ; glissando on/off
	!byte 0 ; vibrato waveform
	!byte <extcmd_set_fine_tune
	!byte 0 ; loop pattern
	!byte 0 ; tremolo waveform
	!byte 0 ; [unused]
	!byte 0 ; retrigger sample
	!byte <extcmd_fine_vol_slide_up
	!byte <extcmd_fine_vol_slide_down
	!byte 0 ; cut/truncate sample
	!byte 0 ; delay sample start
	!byte 0 ; delay pattern
	!byte 0 ; invert loop

extended_effect_command_jump_table_highs
	!byte 0 ; filter on/off
	!byte >extcmd_fine_slide_up
	!byte >extcmd_fine_slide_down
	!byte 0 ; glissando on/off
	!byte 0 ; vibrato waveform
	!byte >extcmd_set_fine_tune
	!byte 0 ; loop pattern
	!byte 0 ; tremolo waveform
	!byte 0 ; [unused]
	!byte 0 ; retrigger sample
	!byte >extcmd_fine_vol_slide_up
	!byte >extcmd_fine_vol_slide_down
	!byte 0 ; cut/truncate sample
	!byte 0 ; delay sample start
	!byte 0 ; delay pattern
	!byte 0 ; invert loop
