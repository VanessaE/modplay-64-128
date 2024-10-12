; Audio driver for SID chip, 4-bit mode
;
; This is audio driver #1

!zone sid_4bit_driver {

!text "sid 4 bit driver",0

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

	lda #<sid_4bit_dithered_stop
	sta audio_stop_vec
	lda #>sid_4bit_dithered_stop
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
rts

; This sets the audio ISR's cycle count, in 1 MHz units.

; For faster CPUs, divide the raw count by the CPU MHz and round up.
; don't forget to account for clock stretching, and be sure to add one 1 MHz
; cycle for "fudge".

sid_4bit_dithered_set_isr_cycle_count

	!ifndef scpu {
		!ifndef c128 {
			lda #78
			bit stereo_enable
			bpl +
			lda #92
		} else {
			lda #(81 + 1) / 2
			bit stereo_enable
			bpl +
			lda #96 / 2
		}
	} else {
		lda #8					; could be as low as 6 but we're fudging it.
	}

+	sta audio_driver_isr_cycle_count
rts

; this returns the output resolution of the volume tables in .A

sid_4bit_dithered_set_volume_table_resolution
	lda #8
	sta volume_tables_resolution
rts

sid_4bit_dithered_start
	lda #0
	ldx #$20

-	sta SID,x
	dex
	bpl -

	lda #$ff
	sta SID+$06
	sta SID+$0d

	sta SID+$0e	; voice 3 freq = $ffff
	sta SID+$0f

	lda #0		; voice 3 ADSR = 0,0,f,0
	sta SID+$13
	lda #$f0
	sta SID+$14

	lda #$81	; voice 3 waveform = noise + gate
	sta SID+$12

	lda #$49
	sta SID+$04
	sta SID+$0b

	bit stereo_enable
	bmi +
	rts

+	lda stereo_sid_addr
	sta utility_pointer
	lda stereo_sid_addr+1
	sta utility_pointer+1

	lda #$ff
	ldy #$06
	sta (utility_pointer),y
	ldy #$0d
	sta (utility_pointer),y

	ldy #$0e						; right SID voice 3 freq = $ffff
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

	lda #$49
	ldy #$04
	sta (utility_pointer),y
	ldy #$0b
	sta (utility_pointer),y

rts

sid_4bit_dithered_mute
rts

sid_4bit_dithered_stop
rts

sid_isr_4b_dithered_mono		; 7 cycles coming in
	sta .iam + 1				; 4
	stx .ixm + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3

	clc							; 2
	lda audio_buffer_left,x		; 4
	adc audio_buffer_right,x	; 4
	ror							; 2
	sta .sd4bm+1				; 4
	lda SID+$1b					; 4
	and #$0f					; 2
	clc							; 2
.sd4bm adc #0					; 2
	bcc +						; 3/2
	lda #$8f					; 2
	bne ++						; 3
+	tax							; 2
	lda divide_by_16_table,x	; 4
	ora #$80					; 2 / cut-off voice 3 from audio path
++	sta SID+$18					; 4

.iam lda #00					; 2
.ixm ldx #00					; 2
	bit CIA1+$0d				; 4 / acknowledge CIA#1 timer B interrupt
rti								; 6 cycles to exit


sid_isr_4b_dithered_stereo		; 7 cycles coming in
	sta .ias + 1				; 4
	stx .ixs + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3

	lda SID+$1b					; 4
	and #$0f					; 2
	sta .sd4br+1				; 4
	clc							; 2
	adc audio_buffer_left,x		; 4
	bcc +						; 3/2
	clc							; 2
	lda #$8f					; 2
	bne ++						; 3
+	tax							; 2
	lda divide_by_16_table,x	; 4
	ora #$80					; 2 / cut-off voice 3 from audio path
++	sta SID+$18					; 4

	ldx audio_out_buf_index		; 3
.sd4br
	lda #0						; 2
	adc audio_buffer_right,x	; 4
	bcc +						; 3/2
	lda #$8f					; 2
	bne ++						; 3
+	tax							; 2
	lda divide_by_16_table,x	; 4
	ora #$80					; 2 / cut-off voice 3 from audio path
++
.s2a sta $1234					; 4 / will be set to right SID addr + $18, above

.ias lda #00					; 2
.ixs ldx #00					; 2
	bit CIA1+$0d				; 4 / acknowledge CIA#1 timer B interrupt
rti								; 6 cycles to exit

}
