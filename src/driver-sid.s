; Audio driver for SID chip, 4-bit mode

	; ISR init will call this first function to get the proper IRQ entry point
	; returns .X/.Y = address low/high

sid_4b_init
	jsr sid_4b_mute

	bit stereo_enable
	bmi +

	ldx #<sid_4b_isr_mono
	ldy #>sid_4b_isr_mono
	rts

+	ldx #<sid_4b_isr_stereo
	ldy #>sid_4b_isr_stereo
rts

; This little stub just needs to return the audio driver's desired IRQ
; interval and the output resolution of the volume tables.

sid_4b_timing_resolution
	!ifndef c128 {
		ldx #3		; C64 cycle time is 3 rasters, about 5.2 kHz
	} else {
		ldx #95		; C128 at 2 MHz is twice as fast, and we don't have to
					; sync to the VIC-IIe raster since it's blanked, so 10.4 kHz
	}

	lda #4	; tell voltab generator routine that we want 4-bit data 
rts

sid_4b_start
	clc
	lda stereo_sid_addr
	adc #$18
	sta .s2a+1
	lda stereo_sid_addr+1
	sta .s2a+2
rts

sid_4b_stop
	jsr sid_4b_mute
rts

sid_4b_mute
	lda #0
	ldx #$20

-	sta SID,x
	dex
	bpl -
rts


sid_4b_isr_mono					; 7 cycles coming in
	sta .iam + 1				; 4
	stx .ixm + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
	lda audio_buffer_left,x		; 4
	sta SID+$18					; 4
	sta VIC+$20

.iam lda #00					; 2
.ixm ldx #00					; 2
	bit CIA1+$0d				; 4 / acknowledge CIA#1 timer B interrupt
rti								; 6 cycles to exit


sid_4b_isr_stereo				; 7 cycles coming in
	sta .ias + 1				; 4
	stx .ixs + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
	lda audio_buffer_left,x		; 4
	sta SID+$18					; 4
	sta VIC+$20

	lda audio_buffer_right,x	; 4
.s2a sta $1234					; 4 / will be set to right SID addr + $18, above

.ias lda #00					; 2
.ixs ldx #00					; 2
	bit CIA1+$0d				; 4 / acknowledge CIA#1 timer B interrupt
rti								; 6 cycles to exit

; ISR requires 45+4 cycles in mono, 53+4 cycles for stereo
