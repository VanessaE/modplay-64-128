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

viz_waveform_plot
	!ifndef c128 {
		viz_bytes_to_plot = 35

		bit viz_waveforms_shift_for_8_bit
		bpl viz_64_plot_for_4bit

		ldx audio_in_buf_index
		dex
		ldy #viz_bytes_to_plot
	-	lda audio_buffer_left,x
		lsr
		lsr
		lsr
		ora #$80
		sta visualizer_line_2,y
		lda audio_buffer_right,x
		lsr
		lsr
		lsr
		ora #$80
		sta visualizer_line_5,y
		dex
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
		ora #$80
		sta visualizer_line_2,y
		lda audio_buffer_right,x
		asl
		ora #$80
		sta visualizer_line_5,y
		dex
		dex
		dey
		bpl -
		rts

	} else {

		viz_bytes_to_plot = 37

		lda #18
		sta VDC_ADDR
		lda #>visualizer_line_2
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<visualizer_line_2
		sta VDC_DATA

	-	bit VDC_ADDR
		bpl -

		lda #31
		sta VDC_ADDR

		sec
		lda audio_in_buf_index
		sbc #(viz_bytes_to_plot*2 + 1)
		sta temp_zpbk_a
		tax
		ldy #viz_bytes_to_plot

		bit viz_waveforms_shift_for_8_bit
		bpl viz_128_plot_for_4bit

	--	lda audio_buffer_left,x
		lsr
		lsr
		lsr
		ora #$80
	-	bit VDC_ADDR
		bpl -
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>visualizer_line_5
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<visualizer_line_5
		sta VDC_DATA

	-	bit VDC_ADDR
		bpl -

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot
	--	lda audio_buffer_right,x
		lsr
		lsr
		lsr
		ora #$80
	-	bit VDC_ADDR
		bpl -
		sta VDC_DATA
		inx
		inx
		dey
		bpl --
		rts

	viz_128_plot_for_4bit
	--	lda audio_buffer_left,x
		asl
		ora #$80
	-	bit VDC_ADDR
		bpl -
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>visualizer_line_5
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<visualizer_line_5
		sta VDC_DATA

	-	bit VDC_ADDR
		bpl -

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot
	--	lda audio_buffer_right,x
		asl
		ora #$80
	-	bit VDC_ADDR
		bpl -
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
