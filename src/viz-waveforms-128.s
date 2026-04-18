; This file contains the C128 waveforms visualizer, displaying a very simple,
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

viz_bytes_to_plot = 39

viz_waveform_plot
	!for .v48, 1, 2 {
		!if .v48 = 1 {
			bit viz_waveforms_shift_for_8_bit
			bmi +
			jmp viz_waveform_plot_c128_4bit
		} else {
			!set viz_waveform_plot_c128_4bit = *
		}

	+	lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_2 - 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_2 - 1)
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

		!if .v48 = 1 {
			cmp #128
			bcc +
			sbc #128
			lsr
			lsr
			ora #$80
			jmp ++
		} else {
			asl
			asl
			cmp #32
			bcc +
			eor #$a1 ; same as sbc #32 : ora #$80 : adc #1
			jmp ++
		}

	+	lda #32

	++	+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_3 - 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_3 - 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_left,x

		!if .v48 = 1 {
			cmp #128
			bcs +
			lsr
			lsr
			ora #$80
			jmp ++
		} else {
			asl
			asl
			cmp #32
			bcs +
			ora #$81
			jmp ++
		}

	+	lda #32

	++	+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_5 - 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_5 - 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_right,x

		!if .v48 = 1 {
			cmp #128
			bcc +
			sbc #128
			lsr
			lsr
			ora #$80
			jmp ++
		} else {
			asl
			asl
			cmp #32
			bcc +
			eor #$a1
			jmp ++
		}

	+	lda #32

	++	+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --

		lda #18
		sta VDC_ADDR
		lda #>(visualizer_line_6 - 1)
		sta VDC_DATA

		lda #19
		sta VDC_ADDR
		lda #<(visualizer_line_6 - 1)
		sta VDC_DATA

		+VDC_UPD_RDY_WAIT

		lda #31
		sta VDC_ADDR

		ldx temp_zpbk_a
		ldy #viz_bytes_to_plot

	--	lda audio_buffer_right,x

		!if .v48 = 1 {
			cmp #128
			bcs +
			lsr
			lsr
			ora #$80
			jmp ++
		} else {
			asl
			asl
			cmp #32
			bcs +
			ora #$81
			jmp ++
		}

	+	lda #32

	++	+VDC_UPD_RDY_WAIT
		sta VDC_DATA
		inx
		inx
		dey
		bpl --
		rts
	}


; set all colors to light green

viz_waveform_colors
	!byte $05, $05, $05, $05, $05, $05
