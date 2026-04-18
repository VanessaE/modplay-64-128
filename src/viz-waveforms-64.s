; This file contains the oldskool C64 waveforms visualizer, displaying a very
; simple, low-resolution character-based plot of the output sample data

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
	!for .v48, 1, 2 {
		!if .v48 = 1 {
			bit viz_waveforms_shift_for_8_bit
			bpl viz_waveform_plot_c64_4bit
		} else {
			!set viz_waveform_plot_c64_4bit = *
		}

		ldx audio_in_buf_index
		dex
		ldy #viz_bytes_to_plot

	-	lda audio_buffer_left,x

		!if .v48 = 1 {
			lsr
			lsr
			cmp #32
			bcc +
			eor #$a0  ; same as sbc #32 : ora #$80
		} else {
			asl
			asl
			cmp #32
			bcc +
			eor #$a1 ; same as sbc #32 : ora #$80 : adc #1
		}

		sta visualizer_line_2,y
		lda #32
		sta visualizer_line_3,y
		jmp ++

	+	!if .v48 = 1 {
			ora #$80
		} else {
			ora #$81
		}

		sta visualizer_line_3,y
		lda #32
		sta visualizer_line_2,y

	++	lda audio_buffer_right,x

		!if .v48 = 1 {
			lsr
			lsr
			cmp #32
			bcc +
			eor #$a0
		} else {
			asl
			asl
			cmp #32
			bcc +
			eor #$a1
		}

		sta visualizer_line_5,y
		lda #32
		sta visualizer_line_6,y
		jmp ++

	+	!if .v48 = 1 {
			ora #$80
		} else {
			ora #$81
		}

		sta visualizer_line_6,y
		lda #32
		sta visualizer_line_5,y

	++	dex
		dex
		dey
		bpl -
		rts
	}

; set all colors to light green

viz_waveform_colors
	!byte $0d, $0d, $0d, $0d, $0d, $0d
