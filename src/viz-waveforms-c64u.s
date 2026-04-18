; This file contains the C64U waveforms visualizer, displaying a very simple,
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

viz_bytes_to_plot = 36

viz_waveform_plot
	!for .v48, 1, 2 {
		!if .v48 = 1 {
			bit viz_waveforms_shift_for_8_bit
			bpl viz_waveform_plot_c64u_4bit
		} else {
			!set viz_waveform_plot_c64u_4bit = *
		}

		ldy viz_waveform_c64_cache_idx
		cpy #viz_bytes_to_plot
		beq +
		rts

	+	dey

	-	lda viz_waveform_c64u_cache_l,y

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

	++	lda viz_waveform_c64u_cache_r,y

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

	++	dey
		bpl -
		lda #0
		sta viz_waveform_c64_cache_idx
		rts
	}

viz_waveform_c64u_fill_cache
	lda viz_waveform_c64_cache_idx
	cmp #viz_bytes_to_plot
	beq +
	lda visualizer_mode
	beq +

	stx audio_in_buf_index

	lda audio_buffer_right,x
	sta viz_waveform_c64_cache_tmp
	lda audio_buffer_left,x

	ldx viz_waveform_c64_cache_idx

	sta viz_waveform_c64u_cache_l,x
	lda viz_waveform_c64_cache_tmp
	sta viz_waveform_c64u_cache_r,x

	inc viz_waveform_c64_cache_idx

	ldx audio_in_buf_index
+	rts

viz_waveform_c64u_cache_l
	!fill 36
viz_waveform_c64u_cache_r
	!fill 36
viz_waveform_c64_cache_idx
	!byte 0
viz_waveform_c64_cache_tmp
	!byte 0

; set all colors to light green

viz_waveform_colors
	!byte $0d, $0d, $0d, $0d, $0d, $0d
