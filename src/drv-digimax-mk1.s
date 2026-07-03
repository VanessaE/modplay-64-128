; Audio driver for DigiMAX Mk1.
;
; This is audio driver #4

!zone digimax_mk1_driver {

; ISR-common will call this function to set up the various vectors to the
; routines below.

digimax_mk1_driver_init
	lda #$80
	sta stereo_enable

	lda #<digimax_mk1_set_vol_tab_resolution
	sta audio_set_resolution_vec
	lda #>digimax_mk1_set_vol_tab_resolution
	sta audio_set_resolution_vec+1

	lda #<digimax_mk1_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec
	lda #>digimax_mk1_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec+1

	lda #<digimax_mk1_start
	sta audio_start_vec
	lda #>digimax_mk1_start
	sta audio_start_vec+1

	lda #<digimax_mk1_mute
	sta audio_mute_vec
	lda #>digimax_mk1_mute
	sta audio_mute_vec+1

	lda #<digimax_mk1_stop
	sta audio_stop_vec
	lda #>digimax_mk1_stop
	sta audio_stop_vec+1

	lda dac_addr
	sta .da1+1
	lda dac_addr+1
	sta .da1+2

	lda dac_addr+1
	cmp #$dd
	bne .notup

	lda CIA2_PORT_A
	and #%11110011
	ora #%00001000
	sta .dm1a+1

	ora #%00000100
	sta .dm1b+1

	lda #<digimax_isr_mk1_up
	sta audio_isr_vec
	lda #>digimax_isr_mk1_up
	sta audio_isr_vec+1
	rts

.notup
	clc
	lda dac_addr
	adc #1
	sta .db1+1
	lda dac_addr+1
	adc #0
	sta .db1+2

	lda #<digimax_isr_mk1_ep
	sta audio_isr_vec
	lda #>digimax_isr_mk1_ep
	sta audio_isr_vec+1
rts

digimax_mk1_set_isr_cycle_count
	!ifndef scpu {
		ldx dac_addr+1
		cpx #$dd
		beq .sicc_is_up

		!ifndef c128 {
			lda #52
		} else {
			lda #(55 + 1) / 2
		}

		jmp .sicc_out

	.sicc_is_up

		!ifndef c128 {
			lda #64
		} else {
			lda #(69 + 1) / 2
		}

	} else {
		lda #8
	}

.sicc_out
	sta audio_driver_isr_cycle_count
rts

digimax_mk1_set_vol_tab_resolution
	lda #7
	sta volume_tables_resolution
rts

digimax_mk1_start
	lda #$ff
	sta CIA2_DDR_B

	lda dac_addr+1
	cmp #$dd
	bne +

	lda CIA2_DDR_A
	ora #%00001100
	sta CIA2_DDR_A
+ rts

digimax_mk1_mute
rts

digimax_mk1_stop
	lda dac_addr+1
	cmp #$dd
	bne +

	lda CIA2_PORT_A
	and #%11110111
	ora #%00000100
	sta CIA2_PORT_A
+ rts

digimax_isr_mk1_ep				; 7 cycles coming in
	+NMI_SAVE_AX				; 6

	ldx audio_out_buf_index		; 3
	lda audio_buffer_left,x		; 4
.da1 sta $1234					; 4
	lda audio_buffer_right,x	; 4
.db1 sta $1234					; 4 / will be set to right DAC addr + $18, above
	inc audio_out_buf_index		; 5

	+NMI_RESTORE_AX				; 6
+NMI_EXIT						; 9 or 10


digimax_isr_mk1_up				; 7 cycles coming in
	+NMI_SAVE_AX				; 6

	ldx audio_out_buf_index		; 3
.dm1a lda #0					; 2
	sta CIA2_PORT_A				; 4
	lda audio_buffer_left,x		; 4
	sta CIA2_PORT_B				; 4
.dm1b lda #0					; 2
	sta CIA2_PORT_A				; 4
	lda audio_buffer_right,x	; 4
	sta CIA2_PORT_B				; 4
	inc audio_out_buf_index		; 5

	+NMI_RESTORE_AX				; 6
+NMI_EXIT						; 9, 11, or 26

}
