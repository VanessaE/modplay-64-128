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
			bpl +
			lda #87
		} else {
			lda #68 / 2
			bit stereo_enable
			bpl +
			lda #(91 + 1) / 2
		}
	} else {
		lda #7
	}

+	sta audio_driver_isr_cycle_count
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

	bit sid_type_left
	bpl +
	jsr enable_8580_digiboost_left

+	lda #$ff
	sta SID_VOICE3_FREQ_LOW
	sta SID_VOICE3_FREQ_HIGH

	lda #0		; voice 3 ADSR = 0,0,f,0
	sta SID_VOICE3_ENV_AD
	lda #$f0
	sta SID_VOICE3_ENV_SR

	lda #$81	; voice 3 waveform = noise + gate
	sta SID_VOICE3_CR

	bit stereo_enable
	bmi +
	rts

+	bit sid_type_right
	bpl +
	jsr enable_8580_digiboost_right

+	lda stereo_sid_addr
	sta utility_pointer
	lda stereo_sid_addr+1
	sta utility_pointer+1
 
	lda #$ff
	ldy #$0e					; right SID voice 3 freq = $ffff
	sta (utility_pointer),y
	ldy #$0f
	sta (utility_pointer),y

	lda #0						; right SID voice 3 ADSR = 0,0,f,0
	ldy #$13
	sta (utility_pointer),y
	lda #$f0
	ldy #$18
	sta (utility_pointer),y

	lda #$81					; right SID voice 3 wave = noise + gate
	ldy #$12
	sta (utility_pointer),y
rts

sid_4bit_dithered_mute
rts

sid_isr_4b_dithered_mono		; 7 cycles coming in
	sta .iam + 1				; 4
	stx .ixm + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3

	clc							; 2
	lda SID_VOICE3_OSC_OUT		; 4
	and #$0f					; 2
	adc audio_buffer_left,x		; 4
	adc audio_buffer_right,x	; 4
	bcc +						; 3/2
	lda #$0f					; 2
	jmp ++						; 3

+	tax							; 2
	lda divide16_or80_table,x	; 4
++	sta SID_VOLUME				; 4

.iam lda #00					; 2
.ixm ldx #00					; 2
!ifndef scpu {
	jmp CIA1_SDR				; 3+6 cycles to exit (does an implicit read of CIA1_ICR)
} else {
	bit CIA1_ICR				; 4 / acknowledge CIA#1 timer B interrupt
	rti							; 6 cycles to exit
}


sid_isr_4b_dithered_stereo		; 7 cycles coming in
	sta .ias + 1				; 4
	stx .ixs + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3

	lda SID_VOICE3_OSC_OUT		; 4
	and #$0f					; 2
	sta .sd4br+1				; 4
	clc							; 2
	adc audio_buffer_left,x		; 4
	bcc +						; 3/2
	clc							; 2
	lda #$8f					; 2
	bne ++						; 3
+	tax							; 2
	lda divide16_or80_table,x	; 4
++	sta SID_VOLUME				; 4

	ldx audio_out_buf_index		; 3
.sd4br
	lda #0						; 2
	adc audio_buffer_right,x	; 4
	bcc +						; 3/2
	lda #$8f					; 2
	bne ++						; 3
+	tax							; 2
	lda divide16_or80_table,x	; 4
++
.s2a sta $1234					; 4 / will be set to right SID addr + $18, above

.ias lda #00					; 2
.ixs ldx #00					; 2
!ifndef scpu {
	jmp CIA1_SDR				; 3+6
} else {
	bit CIA1_ICR				; 4
	rti							; 6 cycles to exit
}

}
