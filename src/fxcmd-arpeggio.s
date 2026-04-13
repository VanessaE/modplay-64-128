; ARPEGGIO

start_effect_arpeggio
	lda seq_command_arguments,y
	bne +
	rts

+	tya
	tax

	lda current_note_periods_lows,x
	sta utility_pointer
	lda current_note_periods_highs,x
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

	ldy #0
	lda (utility_pointer),y
	sta multiplicand_a
	iny
	lda (utility_pointer),y
	sta multiplicand_a+1

	ldy seq_current_track

	lda seq_command_arguments,y
	lsr
	lsr
	lsr
	and #$0e ; we want the note offset * 2
	tax
	lda semitones_table,x
	sta multiplicand_b
	inx
	lda semitones_table,x
	sta multiplicand_b+1

	sec
	jsr multiply_16x16

	; for precision sake, the semitones table is 256x higher than "normal", so
	; use the middle two bytes of the product to divide it back down.

	lda product+1
	sta current_arp_extra_note_1st_fracts,y
	lda product+2
	sta current_arp_extra_note_1st_ints,y

	lda seq_command_arguments,y
	and #$0f
	asl
	tax
	lda semitones_table,x
	sta multiplicand_b
	inx
	lda semitones_table,x
	sta multiplicand_b+1

	clc ; reuse the previous multiplicand_a preset
	jsr multiply_16x16

	lda product+1
	sta current_arp_extra_note_2nd_fracts,y
	lda product+2
	sta current_arp_extra_note_2nd_ints,y

	lda #2
	sta arpeggio_counters,y
rts

run_effect_arpeggio
	lda seq_command_arguments,y
	bne +
	rts

+	stx sequencer_temp_x
	ldx arpeggio_counters,y
	inx

	cpx #1
	bne +

	lda current_arp_extra_note_1st_fracts,y
	sta current_steprates_fracts,y
	lda current_arp_extra_note_1st_ints,y
	sta current_steprates_ints,y
	jmp set_arp_pitch_2_3

+	cpx #2
	bne +
	lda current_arp_extra_note_2nd_fracts,y
	sta current_steprates_fracts,y
	lda current_arp_extra_note_2nd_ints,y
	sta current_steprates_ints,y
	jmp set_arp_pitch_2_3

+	ldx #0
	stx arpeggio_counters,y
	jsr set_pitch_by_table_lookup

	ldx sequencer_temp_x
	rts

set_arp_pitch_2_3
	stx arpeggio_counters,y
	+JSR_INDIRECT (do_selfmod_pitch_vec)
	ldx sequencer_temp_x
rts
