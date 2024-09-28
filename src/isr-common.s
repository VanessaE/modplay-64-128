; this code starts and stops the audio interrupt

; ##### Start the ISR and initialize the audio device/driver

!text "isr common",0

isr_set_interval
	; audio driver and RAM driver times may vary, so we just add them together
	; according to what the drivers and CPU speed checks indicate
	;
	; IMPORTANT:
	;
	; for accuracy-sake, the total cycle count *must not* exceed 3 raster
	; lines (so 195 cycles on NTSC or 189 cycles on PAL) when the screen is
	; enabled on the C64, otherwise the round-up code below will overflow.
	; If the screen is off or it's the C128, just keep the total under 255.
	;
	; that said, 3 rasters is already a bit slow, so if a combo of drivers
	; is too slow, that combo should only be allowed when the screen is turned
	; off, or only on faster machines if that's the only choice (e.g. C128, or
	; if an accelerator is in use).

	clc
	lda #mixer_cycle_count
	adc audio_driver_isr_cycle_count
	adc ram_driver_fetch_cycle_count

	!ifndef c128 {
		bit enable_screen_on_playback
		bpl +

		sta dividend				; on C64 with the screen on, we need to
		lda raster_len				; sync to the VIC-II raster, so we divide
		sta divisor					; that total cycles figure by the raster
		lda #0						; line length
		sta dividend+1	
		sta divisor+1
		jsr divide_16by16

		clc
		lda quotient				; discard the remainder and add 1
		adc #1
		ldx raster_len
		jsr multiply_8x8			; and multiply it back up, thus rounding
		lda product					; the ISR time to the next whole multiple
	}								; of the raster length

; if the screen is off, or on C128 in any case, we don't need all that BS 😛
; because no VIC-II/IIe screen means no need to sync to the raster.

+	sta isr_trigger_interval
rts

isr_startup
	sei

	ldy #0
	lda #$80
-	sta audio_buffer_left,y
	sta audio_buffer_right,y
	iny
	bne -

	lda isr_trigger_interval
	sec
	sbc #1					; subtract 1 cycle because the CIA will add 1.
	sta CIA1+$06			; set the result as CIA #1 timer B interval
	lda #0
	sta CIA1+$07

	jsr enable_kernal_only	; theres a minuscule chance that an NMI can fire
	lda #<lockout_nmi		; while changing this vector, this'll make sure it
	sta CPU_NMI_vector		; is always "whole".
	lda #>lockout_nmi
	sta CPU_NMI_vector+1
	jsr disable_roms

	; force CIA2 to generate an NMI so that we can lock them out.
	lda #0					; stop CIA #2 timer A
	sta CIA2+$0e
	sta CIA2+$04			; set Timer A to 0, after starting
	sta CIA2+$05			; NMI will occur immediately
	lda #$81
	sta CIA2+$0d			; set Timer A as source for NMI
	lda #$01
	sta CIA2+$0e			; start Timer A -> NMI

	lda #$03				; disable both CIA #1 timers' IRQ's
	sta CIA1+$0d
	bit CIA1+$0d			; and clear any pending IRQs

	lda #0
	sta VIC+$1a				; disable VIC raster IRQ
	lda VIC+$19				; and clear any VIC IRQ that's pending.  normally
	sta VIC+$19				; we could lsr here but that doesn't work on SCPU

	!ifndef c128 {
		; if the screen is off, don't bother with the double-IRQ code,
		; just point the IRQ directly to the audio driver entry

		bit enable_screen_on_playback
		bmi +

		lda audio_isr_vec
		sta CPU_IRQ_vector
		lda audio_isr_vec+1
		sta CPU_IRQ_vector+1

		lda #$82				; enable timer B IRQ
		sta CIA1+$0d
		lda #$11				; start CIA timer B in continuous mode,
		sta CIA1+$0f			; counting Phi2 cycles, no output on PB6

		bne ++

		; C64 NTSC fix: turn two of the nop's in irq_stage_2 below into
		; 'lda ($ea,x)' turning 2 bytes/4 cycles into 2 bytes/6 cycles

	+	bit pal_flag
		bmi +
		lda #$a1
		sta ntsc_adj

	+	lda #<irq_stage_1
		sta CPU_IRQ_vector
		lda #>irq_stage_1
		sta CPU_IRQ_vector+1

		lda #254				; stage 1 IRQ will fire on line 254
		sta VIC+$12
		lda #$81
		sta VIC+$1a				; and now enable the raster IRQ

	} else {
		; on C128, it's similar to C64 with screen off
		lda audio_isr_vec
		sta CPU_IRQ_vector
		lda audio_isr_vec+1
		sta CPU_IRQ_vector+1

		lda #$82				; enable timer B IRQ
		sta CIA1+$0d
		lda #$11
		sta CIA1+$0f			; start CIA timer B
	}

++	cli
rts

!ifndef c128 {
; This code is based on "Double-IRQ" stable interrupt method from
; adapted to only be called/run once.
; https://codebase64.org/doku.php?id=base:the_double_irq_method
; (author unknown)

	irq_stage_1					; 7 cycles to enter
		!ifdef scpu {
			sta SCPU_TURBO_OFF	; 4
		}
		inc VIC+$12				; 6
		lda VIC+$19				; 4
		sta VIC+$19				; 4
		sta .s1a + 1			; 4 / we're about to trash .A so back it up
		lda #<irq_stage_2		; 2
		sta CPU_IRQ_vector		; 4
		lda #>irq_stage_2		; 2
		sta CPU_IRQ_vector+1	; 4
		cli						; 2 / 37 cycles for switchover (43 on C128)
		nop
		nop
		nop
		nop
		nop
		nop
		nop
		nop						; 55 cycles / stage 2 could fire here on PAL if
		nop						;             stage 1's jitter maxed-out at 7 cycles
		nop
		nop
		nop						; 63 / or as late as here if stage 1 was on-time on PAL
		nop						; 65 / or as late as here on NTSC
		nop
		nop

	irq_stage_2					; 7 cycles to enter, plus jitter of 1 cycle
		lda #0					; 2 / disable VIC interrupts, CIA#1 will handle
		sta VIC+$1a				; 4 / the IRQ from now on.
		lda VIC+$19				; 4
		sta VIC+$19				; 4

		pla						; 4 / discard stage 2's return address and cpu status
		pla						; 4 / so that we return via stage 1's stack values
		pla 					; 4
	ntsc_adj
		nop						; 2 \__ these become 'lda ($ea,x)'
		nop						; 2 /   on NTSC to add 2 more cycles
		nop						; 2
		nop						; 2
		nop						; 2
		nop						; 2
		lda (0,x)				; 6
		lda (0,x)				; 6
		lda VIC+$12				; 4 / 61 cycles, -0/+1
		cmp #255				; 2
		beq fixcycle			; 3 or 2

	fixcycle					; we are now at cycle 5 of line 255
		lda (0,x)				; 6
		lda (0,x)				; 6
		lda (0,x)				; 6
		lda (0,x)				; 6
		nop						; 2  / waste 26 cycles

		lda audio_isr_vec		; 4 / re-point the IRQ to the audio driver
		sta CPU_IRQ_vector		; 4 / entry point
		lda audio_isr_vec+1		; 4
		sta CPU_IRQ_vector+1	; 4

		lda #$82				; 2 enable timer B IRQ
		sta CIA1+$0d			; 4
		lda #$11				; 2

								; we should now be on cycle 55 of line 255, JUST
								; past where the next bad line delay will end.

		sta CIA1+$0f			; 4 / start CIA timer B

	.s1a lda #0					; restore .A
		cli

		!ifdef scpu {
			sta SCPU_TURBO_ON
		}
	rti
}

; ##### end of ISR Init


; ##### just what it says on the tin, this stops the ISR and silences the audio

isr_shutdown
	sei

	lda #0
	sta CIA1+$0f

	!ifndef c128 {
		lda #0
		sta VIC+$1a
		lda #$81
		sta CIA1+$0d
	} else {
		lda #$81
		sta VIC+$1a
	}

	lda VIC+$19
	lda CIA1+$0d

	!ifdef c128 {
		lda #36
		sta VDC
		lda #0
		sta VDC+1
	}
rts

lockout_nmi ; exit any NMI that gets here, unacknowledged
rti
