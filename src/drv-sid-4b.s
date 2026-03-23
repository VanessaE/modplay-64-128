; Audio driver for SID chip, 4-bit mode
;
; This is audio driver #1

!zone sid_4bit_driver {

; ISR-common will call this function to set up the various vectors to the
; routines below.

sid_4bit_driver_init
	lda #<sid_4bit_set_volume_table_resolution
	sta audio_set_resolution_vec
	lda #>sid_4bit_set_volume_table_resolution
	sta audio_set_resolution_vec+1

	lda #<sid_4bit_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec
	lda #>sid_4bit_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec+1

	lda #<sid_4bit_start
	sta audio_start_vec
	lda #>sid_4bit_start
	sta audio_start_vec+1

	lda #<sid_4bit_mute
	sta audio_mute_vec
	lda #>sid_4bit_mute
	sta audio_mute_vec+1

	lda #<reset_sids
	sta audio_stop_vec
	lda #>reset_sids
	sta audio_stop_vec+1

	bit stereo_enable
	bmi +

	lda #<sid_isr_4b_mono
	sta audio_isr_vec
	lda #>sid_isr_4b_mono
	sta audio_isr_vec+1
	rts

+	clc
	lda stereo_sid_addr
	adc #$18
	sta .s2a+1
	lda stereo_sid_addr+1
	adc #0
	sta .s2a+2

	lda #<sid_isr_4b_stereo
	sta audio_isr_vec
	lda #>sid_isr_4b_stereo
	sta audio_isr_vec+1

	jsr reset_sids
rts

; This sets the audio ISR's cycle count, in 1 MHz units.

; For faster CPUs, divide the raw count by the CPU MHz and round up to the
; next whole 1 MHz equivalent count.  Don't forget to account for clock
; stretching and cache misses.
;
; on SCPU, the count could be as low as 6, but we're fudging it for now.

sid_4bit_set_isr_cycle_count

	!ifndef scpu {
		!ifndef c128 {
			lda #52
		} else {
			lda #(55 + 1) / 2
		}
	} else {
		lda #7
	}

	sta audio_driver_isr_cycle_count
rts

sid_4bit_set_volume_table_resolution
	lda #3
	sta volume_tables_resolution
rts

sid_4bit_start
	jsr reset_sids

	bit sid_type_left
	bpl +
	jsr enable_8580_digiboost_left

+	bit stereo_enable
	bmi +
	rts

+	bit sid_type_right
	bpl +
	jsr enable_8580_digiboost_right
  +
rts

sid_4bit_mute
rts

sid_isr_4b_mono					; 7 cycles coming in
	+IRQ_SAVE_AX				; 6

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
	clc							; 2
	lda audio_buffer_left,x		; 4
	adc audio_buffer_right,x	; 4
	ror							; 2
	sta SID_VOLUME				; 4

	+IRQ_RESTORE_AX				; 6
+IRQ_EXIT						; 9 cycles to exit on stock C64/128, 10 w/SCPU


sid_isr_4b_stereo				; 7 cycles coming in
	+IRQ_SAVE_AX				; 6

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
	lda audio_buffer_left,x		; 4
	sta SID_VOLUME				; 4
	lda audio_buffer_right,x	; 4
.s2a sta $1234					; 4 / will be set to right SID addr + $18, above

	+IRQ_RESTORE_AX				; 6
+IRQ_EXIT						; 9 or 10


}
