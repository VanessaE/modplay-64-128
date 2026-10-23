; this code starts and stops the audio interrupt

; ##### Start the ISR and initialize the audio device/driver

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

	!ifdef c64u {
		; on C64U and U64, ignore all the timings specified
		; by the drivers and just run at a fixed 48.7 or 49.2 kHz.

		lda #20
		bit pal_flag
		bmi +
		lda #21
	  +

	} else {
		clc
		lda mixer_cycle_count
		adc audio_driver_isr_cycle_count
		adc ram_driver_fetch_cycle_count

		; on non-SCPU setups, add some fudge just to ensure
		; the sequencer always has enough time to run

		!ifndef scpu {
			!ifdef c128 {
				adc #15					; if multirate is available, bump the
				bit multirate_enable	; sample rate up a bit on C128.
				bmi +
				adc #5
			  +
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
	}

+	sta isr_trigger_interval
rts

isr_startup
	lda #$80
	jsr fill_audio_buffers

	sec
	lda isr_trigger_interval
	sbc #1					; subtract 1 cycle because the CIA will add 1.
	sta CIA2_TIMER_A_LOW	; set the result as CIA #2 timer A interval
	lda isr_trigger_interval+1
	sbc #0
	sta CIA2_TIMER_A_HIGH

	!ifndef badlines_exist {
		; on C128 and C64U, it's similar to oldskool C64 with screen off

		lda #$81				; enable only the timer A interrupt
		sta CIA2_ICR
		lda cia_cra_startup_val
		sta CIA2_CRA

	} else {

		; if the screen is off, don't bother starting the double-IRQ code,
		; just point the NMI vector at the audio driver and get on with it

		bit enable_screen_on_playback
		bmi +

		lda #$81			; enable timer A interrupt
		sta CIA2_ICR
		lda cia_cra_startup_val
		sta CIA2_CRA

		bne ++

		+ !ifndef scpu {
			; C64 NTSC fix: turn two of the nop's in vic_raster_sync_stage_2
			; below into `lda ($ea,x)`, thus turning 2 bytes/4 cycles into
			; 2 bytes/6 cycles

			bit pal_flag
			bmi +
			lda #$a1
			sta ntsc_adj

		+	lda #254				; stage 1 IRQ will fire on line 254
			sta VIC_RASTER_LOW
			lda VIC_CONTROL_A
			and #$7f
			sta VIC_CONTROL_A

			lda VIC_IRQ_FLAGS
			sta VIC_IRQ_FLAGS

			lda #$01
			sta VIC_IRQ_MASK		; and now enable the raster IRQ
			cli

		} else {
			sta SCPU_TURBO_ON		; on SCPU we don't have to double-IRQ...

			ldx #254				; ...we can just spin-wait for line 254
		-	cpx VIC_RASTER_LOW
			bne -

			inx						; just in case we were already there,
		-	cpx VIC_RASTER_LOW		; now wait for line 255.
			bne -

			ldx #49					; waste 49, 1 MHz cycles
		-	sta $c7ff				; anywhere above $C000 will do, we just
			dex						; want to force the SCPU to wait on its
			bne -					; async write cache.
			lda #$81				; enable timer A interrupt
			sta CIA2_ICR			; a CIA write takes 2, 1 MHz cycles
			lda cia_cra_startup_val

			sta CIA2_CRA			; start timer A
									; we should now be on line 255, cycle 53.
		}
	}

; on stock machines, set up for quick interrupt exit.
; saves one cycle in the ISR's

++	!ifndef scpu {
		lda CIA2_CRA			; set CIA2 serial register to input, so that
		and #%10111111			; we can store to it without affecting the
		sta CIA2_CRA			; hardware output line.
		lda #$40				; $40 is the opcode for "RTI"
		sta CIA2_SDR
	}
rts

	; This code is based on "Double-IRQ" stable interrupt method from
	; adapted to only be called/run once.  It's only used on oldskool C64's
	; when the screen is turned on, but not on C128's or C64U.
	;
	; https://codebase64.org/doku.php?id=base:the_double_irq_method
	; (author unknown)

vic_raster_sync_stage_1		; 7 cycles to enter
	sta .s1a + 1			; 4 / we're about to trash .A so back it up
	inc VIC_RASTER_LOW		; 6
	lda VIC_IRQ_FLAGS		; 4
	sta VIC_IRQ_FLAGS		; 4
	lda #<vic_raster_sync_stage_2 ; 2
	sta CPU_IRQ_vector		; 4
	lda #>vic_raster_sync_stage_2 ; 2
	sta CPU_IRQ_vector+1	; 4
	cli						; 2 / 37 cycles for switchover
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

vic_raster_sync_stage_2		; 7 cycles to enter, plus jitter of 1 cycle
	lda #0					; 2 / disable further raster IRQ's, CIA 2 will
	sta VIC_IRQ_MASK		; 4 / handle the audio interrupt from now on.
	lda VIC_IRQ_FLAGS		; 4
	sta VIC_IRQ_FLAGS		; 4

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
	lda VIC_RASTER_LOW		; 4 / 61 cycles, -0/+1
	cmp #255				; 2
	beq fixcycle			; 3 or 2

fixcycle					; we are now at cycle 5 of line 255
	lda (0,x)				; 6
	lda (0,x)				; 6
	lda (0,x)				; 6
	lda (0,x)				; 6
	lda (0,x)				; 6
	lda (0,x)				; 6
	nop						; 2
	nop						; 2 / waste 40 cycles

	lda #$81				; 2 enable timer A interrupt
	sta CIA2_ICR			; 4
	lda cia_cra_startup_val	; 4

							; we should now be on cycle 55 of line 255, JUST
							; past where the next bad line delay will end.

	sta CIA2_CRA			; 4 / start timer A

	lda #<lockout_interrupts ; make sure IRQs can never do anything again
	sta CPU_IRQ_vector		; if somehow they manage to run.
	lda #>lockout_interrupts
	sta CPU_IRQ_vector+1

.s1a lda #0					; restore .A
rti

; ##### end of ISR Init


; ##### just what it says on the tin, this stops the ISR and silences the audio

isr_reset_timers_interrupts
	sei
	jsr enable_kernal_only

	; Disable CIA interrupts and the VIC raster IRQ, if there is one
	lda #$7f
	sta CIA1_ICR
	sta CIA2_ICR
	lda #0
	sta VIC_IRQ_MASK

	lda #<vic_raster_sync_stage_1
	sta CPU_IRQ_vector
	lda #>vic_raster_sync_stage_1
	sta CPU_IRQ_vector+1

	lda audio_isr_vec
	sta CPU_NMI_vector
	lda audio_isr_vec+1
	sta CPU_NMI_vector+1

	; stop the three CIA timers we're not using

	lda #0
	sta CIA1_CRA
	sta CIA1_CRB
	sta CIA2_CRB

	jsr disable_roms
rts
