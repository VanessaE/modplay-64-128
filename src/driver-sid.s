; Audio driver for SID chip, 4-bit mode

; ISR init will call this first function to get the proper IRQ entry point
; returns .X/.Y = address low/high

!text "sid driver",0,0,0

sid_init
	jsr sid_mute

	bit stereo_enable
	bmi +

	ldx #<sid_isr_4b_mono
	ldy #>sid_isr_4b_mono
	rts

+	ldx #<sid_isr_4b_stereo
	ldy #>sid_isr_4b_stereo
rts

; This returns the audio driver's desired IRQ
; interval and the output resolution of the volume tables.
; it shall return .A = sample resolution
; and .X/Y = number of cycles between ISR calls, plus some fudge

sid_get_timing
	!ifndef c128 {
		lda #53
	} else {
		lda #26
	}
rts

sid_get_resolution
	lda #4
rts

sid_start
	clc
	lda stereo_sid_addr
	adc #$18
	sta .s2a+1
	lda stereo_sid_addr+1
	sta .s2a+2
rts

sid_stop
	jsr sid_mute
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

; each of the ISRs runs for 53 cycles
