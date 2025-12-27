; This file contains the waveforms visualizer, displaying a very simple,
; low-resolution character-based plot of the output sample data

viz_waveform_init
	jsr visualizer_clear_area

	lda #<viz_waveform_colors
	sta viz_row_colors_vec+1
	lda #>viz_waveform_colors
	sta viz_row_colors_vec+2

	jsr visualizer_prefill_colors

	lda audio_driver
	cmp #1
	bne aud_is_8bit
	bit dither_enable
	bmi aud_is_8bit

	lda #0
	sta viz_waveforms_shift_for_8_bit
	rts

aud_is_8bit
	lda #$80
	sta viz_waveforms_shift_for_8_bit
rts

viz_bytes_to_plot = 35

viz_waveform_plot
	!ifndef c128 {

		bit viz_waveforms_shift_for_8_bit
		bpl viz_64_plot_for_4bit

		ldx audio_in_buf_index
		dex
		ldy #viz_bytes_to_plot

	-	lda audio_buffer_left,x
		lsr
		lsr
		cmp #32
		bcc +

 		eor #$a0 ; same as sbc #32 : ora #$80
		sta visualizer_line_2,y
		lda #32
		sta visualizer_line_3,y
		jmp ++

	+	ora #$80
		sta visualizer_line_3,y
		lda #32
		sta visualizer_line_2,y

	++	lda audio_buffer_right,x
		lsr
		lsr
		cmp #32
		bcc +

 		eor #$a0
		sta visualizer_line_5,y
		lda #32
		sta visualizer_line_6,y
		jmp ++

	+	ora #$80
		sta visualizer_line_6,y
		lda #32
		sta visualizer_line_5,y

	++	dex
		dex
		dey
		bpl -
		rts

	viz_64_plot_for_4bit
		ldx audio_in_buf_index
		dex
		ldy #viz_bytes_to_plot

	-	lda audio_buffer_left,x
		asl
		asl
		cmp #32
		bcc +

 		eor #$a1 ; same as sbc #32 : ora #$80 : adc #1
		sta visualizer_line_2,y
		lda #32
		sta visualizer_line_3,y
		jmp ++

	+	ora #$81
		sta visualizer_line_3,y
		lda #32
		sta visualizer_line_2,y

	++	lda audio_buffer_right,x
		asl
		asl
		cmp #32
		bcc +

 		eor #$a1
		sta visualizer_line_5,y
		lda #32
		sta visualizer_line_6,y
		jmp ++

	+	ora #$81
		sta visualizer_line_6,y
		lda #32
		sta visualizer_line_5,y

	++	dex
		dex
		dey
		bpl -
		rts

	} else {

		bit viz_waveforms_shift_for_8_bit
		bmi +
		jmp viz_128_plot_for_4bit

	+	lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_2 + 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_2 + 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		sec
		lda audio_in_buf_index
		sbc #(viz_bytes_to_plot*2 + 1)
		sta temp_zpbk_a
		tax
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_left,x
		cmp #128
		bcc +
		sbc #128
		lsr
		lsr
		ora #$80
		jmp ++

	+	lda #32
	++
		+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_3 + 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_3 + 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_left,x
		cmp #128
		bcs +
		lsr
		lsr
		ora #$80
		jmp ++

	+	lda #32
	++
		+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_5 + 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_5 + 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_right,x
		cmp #128
		bcc +
		sbc #128
		lsr
		lsr
		ora #$80
		jmp ++

	+	lda #32
	++
		+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_6 + 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_6 + 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_right,x
		cmp #128
		bcs +
		lsr
		lsr
		ora #$80
		jmp ++

	+	lda #32
	++
		+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --
		rts

	viz_128_plot_for_4bit
	+	lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_2 + 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_2 + 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		sec
		lda audio_in_buf_index
		sbc #(viz_bytes_to_plot*2 + 1)
		sta temp_zpbk_a
		tax
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_left,x
		asl
		asl
		cmp #32
		bcc +
 		eor #$a1 ; same as sbc #32 : ora #$80 : adc #1
		jmp ++

	+	lda #32
	++
		+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_3 + 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_3 + 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_left,x
		asl
		asl
		cmp #32
		bcs +
 		ora #$81
		jmp ++

	+	lda #32
	++
		+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_5 + 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_5 + 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_right,x
		asl
		asl
		cmp #32
		bcc +
 		eor #$a1 ; same as sbc #32 : ora #$80 : adc #1
		jmp ++

	+	lda #32
	++
		+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_6 + 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_6 + 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_right,x
		asl
		asl
		cmp #32
		bcs +
 		ora #$81
		jmp ++

	+	lda #32
	++
		+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --
		rts
	}


; set all colors to light green

viz_waveform_colors
	!ifndef c128 {
		!byte $0d, $0d, $0d, $0d, $0d, $0d
	} else {
		!byte $05, $05, $05, $05, $05, $05
	}
