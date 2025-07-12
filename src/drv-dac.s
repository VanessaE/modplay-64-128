; Audio driver for 8-bit DAC output
; either plain old single DAC at some address for mono, or User Port or
; Expansion Port DigiMAX for stereo.
;
; This is audio driver #3

!zone dac_driver {

; ISR-common will call this function to set up the various vectors to the
; routines below.

dac_driver_init
	lda #<dac_set_volume_table_resolution
	sta audio_set_resolution_vec
	lda #>dac_set_volume_table_resolution
	sta audio_set_resolution_vec+1

	lda #<dac_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec
	lda #>dac_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec+1

	lda #<dac_start
	sta audio_start_vec
	lda #>dac_start
	sta audio_start_vec+1

	lda #<dac_mute
	sta audio_mute_vec
	lda #>dac_mute
	sta audio_mute_vec+1

	lda #<dac_stop
	sta audio_stop_vec
	lda #>dac_stop
	sta audio_stop_vec+1

	lda dac_addr
	sta .da1+1
	sta .da2+1
	lda dac_addr+1
	sta .da1+2
	sta .da2+2

	bit stereo_enable
	bmi is_stereo_dac

	lda #<dac_isr_mono
	sta audio_isr_vec
	lda #>dac_isr_mono
	sta audio_isr_vec+1
	rts

is_stereo_dac
	lda dac_addr+1
	cmp #$dd
	bne not_up_stereo

	lda CIA2_PORT_A
	and #%11110011
	ora #%00000100
	sta .dca+1

	lda CIA2_PORT_A
	and #%11110011
	sta .dcb+1

	lda #<dac_isr_stereo_user_port
	sta audio_isr_vec
	lda #>dac_isr_stereo_user_port
	sta audio_isr_vec+1
	rts

not_up_stereo
	clc
	lda dac_addr
	adc #1
	sta .db+1
	lda dac_addr+1
	adc #0
	sta .db+2

	lda #<dac_isr_stereo
	sta audio_isr_vec
	lda #>dac_isr_stereo
	sta audio_isr_vec+1
rts

dac_set_isr_cycle_count
	!ifndef scpu {
		bit stereo_enable
		bmi .sicc_st

		!ifndef c128 {
			lda #50
		} else {
			lda #52 / 2
		}

		jmp .sicc_out

	.sicc_st
		ldx dac_addr+1
		cpx #$dd
		beq .sicc_st_up

		!ifndef c128 {
			lda #52
		} else {
			lda #(55 + 1) / 2
		}

		jmp .sicc_out

	.sicc_st_up

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

dac_set_volume_table_resolution
	lda #7
	bit stereo_enable
	bmi +
	lda #6
+	sta volume_tables_resolution
rts

dac_start
	lda #$ff
	sta CIA2_DDR_B

	bit stereo_enable
	bpl +
	lda dac_addr+1
	cmp #$dd
	bne +

	lda CIA2_DDR_A
	ora #%00001100
	sta CIA2_DDR_A
+ rts

dac_mute
rts

dac_stop
	lda dac_addr+1
	cmp #$dd
	bne +

	lda CIA2_PORT_A
	and #%11110111
	ora #%00000100
	sta CIA2_PORT_A
+ rts

dac_isr_mono					; 7 cycles coming in
	sta .iam + 1				; 4
	stx .ixm + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
	clc							; 2
	lda audio_buffer_left,x		; 4
	adc audio_buffer_right,x	; 4

.da1 sta $1234					; 4

.iam lda #00					; 2
.ixm ldx #00					; 2
!ifndef scpu {
	jmp CIA1_SDR				; 3+6 cycles to exit (does an implicit read of CIA1_ICR)
} else {
	bit CIA1_ICR				; 4 / acknowledge CIA#1 timer B interrupt
	rti							; 6 cycles to exit
}


dac_isr_stereo					; 7 cycles coming in
	sta .ias + 1				; 4
	stx .ixs + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
	lda audio_buffer_left,x		; 4
.da2 sta $1234					; 4
	lda audio_buffer_right,x	; 4
.db  sta $1234					; 4 / will be set to right DAC addr + $18, above

.ias lda #00					; 2
.ixs ldx #00					; 2
!ifndef scpu {
	jmp CIA1_SDR				; 3+6 cycles to exit
} else {
	bit CIA1_ICR				; 4
	rti							; 6 cycles to exit
}


dac_isr_stereo_user_port		; 7 cycles coming in
	sta .iasup + 1				; 4
	stx .ixsup + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
.dca lda #0						; 2
	sta CIA2_PORT_A				; 4
	lda audio_buffer_left,x		; 4
	sta CIA2_PORT_B				; 4
.dcb lda #0						; 2
	sta CIA2_PORT_A				; 4
	lda audio_buffer_right,x	; 4
	sta CIA2_PORT_B				; 4

.iasup lda #00					; 2
.ixsup ldx #00					; 2
!ifndef scpu {
	jmp CIA1_SDR				; 3+6 cycles to exit
} else {
	bit CIA1_ICR				; 4
	rti							; 6 cycles to exit
}

}
