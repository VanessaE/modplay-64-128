; Audio driver for SID chip, 4-bit mode

	; ISR init will call this first function to get the proper IRQ entry point
	; it shall return .X/.Y = address low/high

sid_4b_init
	jsr sid_4b_mute

	ldx #<sid_4b_isr
	ldy #>sid_4b_isr
rts

; This little stub just needs to return the audio driver's desired IRQ
; interval and the output resolution of the volume tables.

; .A shall hold the resolution value
; .X shall hold iteration timer value (SIGNED)

; .X should not be less than -20 ($eb) or greater than 4, or thereabouts.
; That corresponds to about 4.3 kHz to 51.1 kHz, but it depends on what each
; platform can handle, so drivers on a given platform build need to take
; CPU speed into consideration.

sid_4b_timing_resolution
	!ifndef c128 {
		ldx #2 ; C64 cycle time is 2 rasters, about 7.87 kHz on NTSC, 7.82 kHz on PAL
	} else {
		ldx #1 ; C128 at 2 MHz can go as fast as every raster, about 17.1 kHz
	}

	lda #4	; tell player routine that we want 4-bit data from the voltab gen
rts

sid_4b_start ; does nothing for now :-P
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

sid_4b_isr				; 7 cycles coming in
	inc VIC+$20			; 6
	sta .ia + 1			; 4

	lda $ff				; 3
	eor #$0f			; 2
	sta $ff				; 3
	sta SID+$18			; 4

.ia	lda #00				; 2
	bit CIA1+$0d		; 4 / acknowledge CIA#1 timer B interrupt
	dec VIC+$20			; 6
rti						; 6 cycles to exit
