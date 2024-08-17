; Audio driver for SID chip, 4-bit mode

!text "sid driver",0

; This sets the audio ISR's cycle count, in 1 MHz units.
; for faster CPUs, divide the raw count by the CPU MHz and round up.

sid_set_isr_cycle_count
	!ifndef c128 {
		lda #53
	} else {
		lda #28
	}
	sta audio_driver_isr_cycle_count
rts

; ISR init will call this function to clear/mute the SID and get the proper
; IRQ entry point.
; returns .X/.Y = address low/high

sid_init
	jsr sid_mute

	clc
	lda stereo_sid_addr
	sta utility_pointer
	adc #$18
	sta .s2a+1
	lda stereo_sid_addr+1
	sta utility_pointer+1
	sta .s2a+2

	lda #$ff
	sta SID+6
	sta SID+13
	sta SID+20

	lda #$49
	sta SID+4
	sta SID+11
	sta SID+18

	bit stereo_enable
	bmi +

	ldx #<sid_isr_4b_mono
	ldy #>sid_isr_4b_mono
	rts

+	lda #$ff
	ldy #6
	sta (utility_pointer),y
	ldy #13
	sta (utility_pointer),y
	ldy #20
	sta (utility_pointer),y

	lda #$49
	ldy #4
	sta (utility_pointer),y
	ldy #11
	sta (utility_pointer),y
	ldy #18
	sta (utility_pointer),y

	ldx #<sid_isr_4b_stereo
	ldy #>sid_isr_4b_stereo
rts

; this returns the output resolution of the volume tables in .A

sid_get_volume_table_resolution
	lda #4
	sta volume_tables_resolution
rts

sid_start
rts

sid_mute
	lda #0
	ldx #$20

-	sta SID,x
	dex
	bpl -
rts

sid_isr_4b_mono					; 7 cycles coming in
	sta .iam + 1				; 4
	stx .ixm + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
	clc							; 2
	lda audio_buffer_left,x		; 4
	adc audio_buffer_right,x	; 4
	lsr							; 2
	sta SID+$18					; 4

.iam lda #00					; 2
.ixm ldx #00					; 2
	bit CIA1+$0d				; 4 / acknowledge CIA#1 timer B interrupt
rti								; 6 cycles to exit


sid_isr_4b_stereo				; 7 cycles coming in
	sta .ias + 1				; 4
	stx .ixs + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
	lda audio_buffer_left,x		; 4
	sta SID+$18					; 4
	lda audio_buffer_right,x	; 4
.s2a sta $1234					; 4 / will be set to right SID addr + $18, above

.ias lda #00					; 2
.ixs ldx #00					; 2
	bit CIA1+$0d				; 4 / acknowledge CIA#1 timer B interrupt
rti								; 6 cycles to exit

; C64: each of the ISRs runs for 53 cycles
; C128: each runs for 56 cycles including clock stretching, divide by 2 = 28 cycles
