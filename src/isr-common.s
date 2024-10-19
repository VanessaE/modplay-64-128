; this code starts and stops the audio interrupt

; ##### Start the ISR and initialize the audio device/driver

!text "isr common",0

isr_set_interval
	; audio driver and RAM driver times may vary, so we just add them together
	; according to what the drivers and CPU speed checks indicate
	;
	; IMPORTANT:
	;
	; the total cycle count below must not exceed 255 prior to rounding!
	;
	; if a combo of drivers is too slow, that combo should probably only be
	; allowed when the screen is turned off, or only on faster machines, if
	; that's the only choice (e.g. C128, or if an accelerator is in use).

	lda #0
	sta isr_trigger_interval+1

	clc
	lda #mixer_cycle_count
	adc audio_driver_isr_cycle_count
	adc ram_driver_fetch_cycle_count

	; on non-SCPU setups, add some fudge just to ensure the sequencer always
	; has enough time to run - 20 cycles on C128 and on C64 when the screen is
	; off, 40 cycles on C64 is the screen is on.

	!ifndef scpu {
		!ifdef c128 {
			adc #20
		} else {
			bit enable_screen_on_playback
			bpl +
			adc #40
			jmp ++
		  + adc #20
		 ++
		}
	}

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
		jsr multiply_8x8			; then multiply it back up, thus rounding
		lda product+1				; the ISR time to the next whole multiple
		sta isr_trigger_interval+1	; of the raster length
		lda product
	}

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

	sec
	lda isr_trigger_interval
	sbc #1					; subtract 1 cycle because the CIA will add 1.
	sta CIA1_TIMER_B_LOW	; set the result as CIA #1 timer B interval
	lda isr_trigger_interval+1
	sbc #0
	sta CIA1_TIMER_B_HIGH

	jsr enable_kernal_only	; theres a minuscule chance that an NMI can fire
	lda #<lockout_nmi		; while changing this vector, this'll make sure it
	sta CPU_NMI_vector		; is always "whole".
	lda #>lockout_nmi
	sta CPU_NMI_vector+1
	jsr disable_roms

	; force CIA2 to generate an NMI so that we can lock them out.
	lda #0					; stop CIA #2 timer A
	sta CIA2_CRA
	sta CIA2_TIMER_A_LOW	; set Timer A to 0, after starting
	sta CIA2_TIMER_A_HIGH	; NMI will occur immediately
	lda #$81
	sta CIA2_ICR			; set Timer A as source for NMI
	lda #$01
	sta CIA2_CRA			; start Timer A -> NMI

	lda #$03				; disable both CIA #1 timers' IRQ's
	sta CIA1_ICR
	bit CIA1_ICR			; and clear any pending IRQs

	lda #0
	sta VIC_IRQ_MASK		; disable VIC raster IRQ
	lda VIC_IRQ_FLAGS		; and clear any VIC IRQ that's pending.  normally
	sta VIC_IRQ_FLAGS		; we could lsr here but that doesn't work on SCPU

	!ifndef c128 {
		; if the screen is off, don't bother with the double-IRQ code,
		; just point the IRQ directly to the audio driver entry

		bit enable_screen_on_playback
		bmi +

		lda audio_isr_vec
		sta CPU_IRQ_vector
		lda audio_isr_vec+1
		sta CPU_IRQ_vector+1

		lda #$82			; enable timer B IRQ
		sta CIA1_ICR
		lda #$11			; start CIA timer B in continuous mode,
		sta CIA1_CRB		; counting Phi2 cycles, no output on PB6

		bne ++

		+ !ifndef scpu {
			; C64 NTSC fix: turn two of the nop's in irq_stage_2 below into
			; 'lda ($ea,x)' turning 2 bytes/4 cycles into 2 bytes/6 cycles

			bit pal_flag
			bmi +
			lda #$a1
			sta ntsc_adj

		+	lda #<irq_stage_1
			sta CPU_IRQ_vector
			lda #>irq_stage_1
			sta CPU_IRQ_vector+1

			lda #254				; stage 1 IRQ will fire on line 254
			sta VIC_RASTER_LOW
			lda VIC_CONTROL_A
			and #$7f
			sta VIC_CONTROL_A
			lda #$81
			sta VIC_IRQ_MASK		; and now enable the raster IRQ

		} else {
			sta SCPU_TURBO_ON		; on SCPU we don't have to double-IRQ...

			lda audio_isr_vec
			sta CPU_IRQ_vector
			lda audio_isr_vec+1
			sta CPU_IRQ_vector+1

			ldx #254				; ...we can just spin-wait for line 254
		-	cpx VIC_RASTER_LOW
			bne -

			inx						; just in case we were already there,
		-	cpx VIC_RASTER_LOW				; now wait for line 255.
			bne -

			ldx #49					; waste 49, 1 MHz cycles
		-	sta $c7ff				; anywhere above $C000 will do, we just
			dex						; want to force the SCPU to wait on its
			bne -					; async write cache.
			lda #$82				; enable timer B IRQ
			sta CIA1_ICR			; a CIA write takes 2, 1 MHz cycles
			lda #$11
			sta CIA1_CRB			; start CIA timer B
									; we should now be on line 255, cycle 53.
		}

	} else {
		; on C128, it's similar to C64 with screen off
		lda audio_isr_vec
		sta CPU_IRQ_vector
		lda audio_isr_vec+1
		sta CPU_IRQ_vector+1

		lda #$82				; enable timer B IRQ
		sta CIA1_ICR
		lda #$11
		sta CIA1_CRB			; start CIA timer B
	}

++	cli
rts

!ifndef c128 {
; This code is based on "Double-IRQ" stable interrupt method from
; adapted to only be called/run once.
; https://codebase64.org/doku.php?id=base:the_double_irq_method
; (author unknown)

	irq_stage_1					; 7 cycles to enter
		inc VIC_RASTER_LOW				; 6
		lda VIC_IRQ_FLAGS				; 4
		sta VIC_IRQ_FLAGS				; 4
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
		sta VIC_IRQ_MASK				; 4 / the IRQ from now on.
		lda VIC_IRQ_FLAGS				; 4
		sta VIC_IRQ_FLAGS				; 4

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
		lda VIC_RASTER_LOW				; 4 / 61 cycles, -0/+1
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
		sta CIA1_ICR			; 4
		lda #$11				; 2

								; we should now be on cycle 55 of line 255, JUST
								; past where the next bad line delay will end.

		sta CIA1_CRB			; 4 / start CIA timer B

	.s1a lda #0					; restore .A
		cli
	rti
}

; ##### end of ISR Init


; ##### just what it says on the tin, this stops the ISR and silences the audio

isr_shutdown
	sei

	lda #0
	sta CIA1_CRB

	!ifndef c128 {
		lda #0
		sta VIC_IRQ_MASK
		lda #$81
		sta CIA1_ICR
	} else {
		lda #$81
		sta VIC_IRQ_MASK
	}

	lda VIC_IRQ_FLAGS
	lda CIA1_ICR

	!ifdef c128 {
		lda #36
		sta VDC_ADDR
		lda #0
		sta VDC_DATA
	}
rts

lockout_nmi ; exit any NMI that gets here, unacknowledged
rti
