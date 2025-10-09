; VOLUME SLIDING

start_effect_volume_slide
	lda seq_command_arguments,y
	sta volume_slide_rates,y
rts

run_effect_volume_slide
	lda volume_slide_rates,y
	and #$f0
	beq vsdown
	lsr
	lsr
	lsr
	lsr

slide_volume_up
	clc
	adc current_sample_volume_levels,y
	cmp #64
	bcc +
	lda #64
+	sta current_sample_volume_levels,y
	jmp set_volume

vsdown
	lda volume_slide_rates,y
	and #$0f
	bne slide_volume_down
	rts

slide_volume_down
	sta temp_zpbk_a
	sec
	lda current_sample_volume_levels,y
	sbc temp_zpbk_a
	bcs +
	lda #0
+	sta current_sample_volume_levels,y
	jmp set_volume

extcmd_fine_vol_slide_up
	lda seq_command_arguments,y
	and #$0f
	sta volume_slide_rates,y
	jmp slide_volume_up

extcmd_fine_vol_slide_down
	lda seq_command_arguments,y
	and #$0f
	sta volume_slide_rates,y
	jmp slide_volume_down
rts
