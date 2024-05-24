; Audio driver for SID chip, 4-bit mode

; ##############################
; MACROS

!macro SID_4B_ISR_ENTRY {
	inc VIC+$20			; 6 cycles / just so we can see it running.
	dec VIC+$20			; 6 cycles

	sta isr_accu		; 3 cycles
	; stx isr_regx
	; sty isr_regy

	lda $ff				; 3 cycles
	eor #$0f			; 2 cycles
	sta $ff				; 3 cycles
	sta SID+$18			; 4 cycles

; thee are just for testing, just to put something in the right channel
; to use as timing reference when examining the audio in Audacity

	lda #$0f
	sta $d718
	lda #0
	sta $d718
}

!macro SID_4B_ISR_EXIT {
	; ldy isr_regy
	; ldx isr_regx
	lda isr_accu		; 3 cycles
	bit CIA1+$0d		; 4 cycles / acknowledge Timer B interrupt
	rti					; 6 cycles
}
; ##############################


; Start the driver running
sid_4b_start
	jsr sid_4b_mute

	; tell the ISR where to direct IRQ to after sync

	!ifndef c128 {
		lda #2							; C64 cycle time is 2 rasters, or about
		ldx disable_screen_on_playback	; 7.87 kHz on NTSC and 7.82 kHz on PAL
		bne +

		ldx #<sid_4b_isr_screen_on
		ldy #>sid_4b_isr_screen_on
	} else {
		lda #1							; C128 can do 1 raster, about 17.1 kHz
	}

+	ldx #<sid_4b_isr_screen_off
	ldy #>sid_4b_isr_screen_off
	jmp isr_start

; The actual driver IRQ routines

; ### ISR: NTSC, or C128.

sid_4b_isr_screen_off	; 6 cycles coming in
	+SID_4B_ISR_ENTRY
+SID_4B_ISR_EXIT

; ### END OF ISR


; ### ISR: PAL, or NTSC with screen explicitly enabled by user

sid_4b_isr_screen_on	; 6 cycles coming in
	+SID_4B_ISR_ENTRY

	lda VIC+$12			; 4 cycles / is this raster #254 on NTSC C64 with the
	eor #254			; 2 cycles / screen enabled?  then skip this one.
	ora pal_flag		; 3 cycles
	bne +				; 3 or 2 cycles

	lda isr_cycle_time_alt ; 4 cycles
	bne ++				; 3 or 2 cycles

+	lda isr_cycle_time	; 4 cycles
++	sta CIA1+$06		; 4 cycles

+SID_4B_ISR_EXIT

; ### END OF ISR


; Shut down the driver
sid_4b_mute
	lda #0
	ldx #$20

-	sta SID,x
	dex
	bpl -
rts

