; Audio driver for single 8-bit DAC output

; This is audio driver #3

!zone dac_driver {

; ISR-common will call this function to set up the various vectors to the
; routines below.

dac_driver_init
	lda #0
	sta stereo_enable

	lda #<dac_set_volume_table_resolution
	sta audio_set_resolution_vec+1
	lda #>dac_set_volume_table_resolution
	sta audio_set_resolution_vec+2

	lda #<dac_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec+1
	lda #>dac_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec+2

	lda #<dac_start
	sta audio_start_vec+1
	lda #>dac_start
	sta audio_start_vec+2

	lda #<dac_stop
	sta audio_stop_vec+1
	lda #>dac_stop
	sta audio_stop_vec+2

	lda dac_addr
	sta .da+1
	lda dac_addr+1
	sta .da+2

	lda #<dac_isr_mono
	sta audio_isr_vec
	lda #>dac_isr_mono
	sta audio_isr_vec+1
rts

dac_set_isr_cycle_count
	!ifndef scpu {
		!ifndef c128 {
			lda #50
		} else {
			lda #52 / 2
		}
	} else {
		lda #8
	}

	sta audio_driver_isr_cycle_count
rts

dac_set_volume_table_resolution
	lda #6
	sta volume_tables_resolution
rts

dac_start
	lda #$ff
	sta CIA2_DDR_B

	lda CIA2_DDR_A
	ora #%00001100
	sta CIA2_DDR_A
rts

dac_stop
	lda dac_addr+1
	cmp #$dd
	bne +

	lda CIA2_PORT_A
	and #%11110111
	ora #%00000100
	sta CIA2_PORT_A
  +
rts

dac_isr_mono					; 7 cycles coming in
	+NMI_SAVE_AX				; 6

	ldx audio_out_buf_index		; 3
	clc							; 2
	lda audio_buffer_left,x		; 4
	adc audio_buffer_right,x	; 4

.da sta $1234					; 4
	inc audio_out_buf_index		; 5

	+NMI_RESTORE_AX				; 6
+NMI_EXIT						; 9 cycles to exit on stock C64, 11 on C128
								; 26 on SCPU

}
