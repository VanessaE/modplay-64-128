; PATTERN BREAK

run_effect_pattern_break
	stx temp_zpbk_a+1

	lda seq_command_arguments,y
	and #$0f
	sta temp_zpbk_a
	lda seq_command_arguments,y
	lsr
	lsr
	lsr
	lsr
	clc
	tax
	lda nybble_x10,x
	adc temp_zpbk_a

	cmp #64
	bcc +
	lda #0

+	ora #$80
	sta pattern_break_target_row

	ldx temp_zpbk_a+1
rts

; POSITION JUMP

run_effect_position_jump
	lda seq_command_arguments,y

	cmp number_of_song_positions
	bcc +
	lda #0

+	sta pos_jump_target_pattern
rts
