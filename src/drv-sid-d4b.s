; Audio driver for SID chip, 4-bit mode
;
; This is audio driver #1

!zone sid_4bit_driver {

; ISR-common will call this function to set up the various vectors to the
; routines below.

sid_4bit_dithered_driver_init
	lda #<sid_4bit_dithered_set_volume_table_resolution
	sta audio_set_resolution_vec
	lda #>sid_4bit_dithered_set_volume_table_resolution
	sta audio_set_resolution_vec+1

	lda #<sid_4bit_dithered_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec
	lda #>sid_4bit_dithered_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec+1

	lda #<sid_4bit_dithered_start
	sta audio_start_vec
	lda #>sid_4bit_dithered_start
	sta audio_start_vec+1

	lda #<sid_4bit_dithered_mute
	sta audio_mute_vec
	lda #>sid_4bit_dithered_mute
	sta audio_mute_vec+1

	lda #<reset_sids
	sta audio_stop_vec
	lda #>reset_sids
	sta audio_stop_vec+1

	bit stereo_enable
	bmi +

	lda #<sid_isr_4b_dithered_mono
	sta audio_isr_vec
	lda #>sid_isr_4b_dithered_mono
	sta audio_isr_vec+1
	rts

+	clc
	lda stereo_sid_addr
	adc #$18
	sta .s2a+1
	lda stereo_sid_addr+1
	adc #0
	sta .s2a+2

	lda #<sid_isr_4b_dithered_stereo
	sta audio_isr_vec
	lda #>sid_isr_4b_dithered_stereo
	sta audio_isr_vec+1

	jsr reset_sids
rts

sid_4bit_dithered_set_isr_cycle_count

	!ifndef scpu {
		!ifndef c128 {
			lda #65
			bit stereo_enable
			bpl .sid_4b_set_count
			lda #87
		} else {
			lda #68 / 2
			bit stereo_enable
			bpl .sid_4b_set_count
			lda #92 / 2
		}
	} else {
		lda #7
	}

.sid_4b_set_count
	sta audio_driver_isr_cycle_count
rts

sid_4bit_dithered_set_volume_table_resolution
	lda #7
	bit stereo_enable
	bmi +
	lda #6
+	sta volume_tables_resolution
rts

sid_4bit_dithered_start
	jsr reset_sids

	lda #$ff						; voice 3 max frequency
	sta SID_VOICE3_FREQ_LOW
	sta SID_VOICE3_FREQ_HIGH

	lda #0							; voice 3 ADSR
	sta SID_VOICE3_ENV_AD
	sta SID_VOICE3_ENV_SR

	lda #$81						; voice 3 waveform = noise + gate
	sta SID_VOICE3_CR

	jsr sid_apply_digi_boost
rts

sid_4bit_dithered_mute
rts

sid_isr_4b_dithered_mono		; 7 cycles coming in
	+NMI_SAVE_AX				; 6

	ldx audio_out_buf_index		; 3

	clc							; 2
	lda SID_VOICE3_OSC_OUT		; 4
	and #$0f					; 2
	adc audio_buffer_left,x		; 4
	adc audio_buffer_right,x	; 4
	bcc +						; 3/2
	lda #$0f					; 2
	bne ++						; 3

+	tax							; 2
	lda divide_by_16_table,x	; 4
++	sta SID_VOLUME				; 4
	inc audio_out_buf_index		; 5

	+NMI_RESTORE_AX				; 6
+NMI_EXIT						; 9 cycles to exit on stock C64, 11 on C128
								; 26 on SCPU

sid_isr_4b_dithered_stereo		; 7 cycles coming in
	+NMI_SAVE_AX				; 6

	ldx audio_out_buf_index		; 3

	lda SID_VOICE3_OSC_OUT		; 4
	and #$0f					; 2
	sta nmi_temp_b				; 3
	clc							; 2
	adc audio_buffer_left,x		; 4
	bcc +						; 3/2
	clc							; 2
	lda #$0f					; 2
	bne ++						; 3

+	tax							; 2
	lda divide_by_16_table,x	; 4
	ldx audio_out_buf_index		; 3

++	sta SID_VOLUME				; 4

	lda nmi_temp_b				; 3
	adc audio_buffer_right,x	; 4
	bcc +						; 3/2
	lda #$0f					; 2
	bne ++						; 3
+	tax							; 2
	lda divide_by_16_table,x	; 4
++
.s2a sta $1234					; 4 / will be set to right SID addr + $18, above
	inc audio_out_buf_index		; 5

	+NMI_RESTORE_AX				; 6
+NMI_EXIT						; 9, 11, or 26

}
