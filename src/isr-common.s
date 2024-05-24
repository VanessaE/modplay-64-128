; this code starts and stops the audio interrupt

; Called by the audio driver to set the correct ISR IRQ entry adress
; enter with .X/.Y = address low/high, .A = SIGNED iteration timer amount
; .A should not be less than -20 ($eb) or greater than 4, or thereabouts.
; That corresponds to about 4.3 kHz to 51.1 kHz, but it depends on what each
; platform can handle, so drivers on a given platform build need to take
; CPU speed into consideration.

isr_start
	stx isr_entry_lo+1
	sty isr_entry_hi+1
	ldx #1
	bpl +			; if .A  > 0 , it's an exact no. of rasters per iteration
	beq ++			; if .A == 0 , make it 1 raster per iteration
	eor #$7f		; if .A  < 0 , use abs. value as no. cycles per iteration
	clc				;   (allows to use less than one raster per)
	adc #$81
	bne +++
+	tax
++	lda raster_len
	jsr multiply_8x8		; .A * raster_len = #cycles per iteration
	lda product
+++	sec
	sbc #1					; subtract 1 cycle because the CIA will add 1.
	sta isr_cycle_time
							; drivers which allow the screen to be turned on
	clc						; on NTSC need another val that's one raster longer
	adc raster_len			; than the supplied time, so that a raster can be
	sta isr_cycle_time_alt	; skipped every other frame.  Ignored on PAL.

; initialize audio buffers and ISR variables

	lda #$80
	ldx #0
	-	sta audio_buffer_left,x
		sta audio_buffer_right,x
		dex
	bne -

	; 'Disable NMI' without using kernal and $0318/$0319 by Sokrates
	; https://codebase64.org/doku.php?id=base:nmi_lock_without_kernal
	; (reformatted to match my code style)

	lda #<interrupts_lockout	; change nmi vector to nmiRoutine
	sta $fffa     
	lda #>interrupts_lockout
	sta $fffb
	lda #$00			; stop Timer A
	sta CIA2+$0e 
	sta CIA2+$04		; set Timer A to 0, after starting
	sta CIA2+$05		; NMI will occur immediately
	lda #$81  
	sta CIA2+$0d		; set Timer A as source for NMI 
	lda #$01  
	sta CIA2+$0e		; start Timer A -> NMI

	; from here on NMI is disabled

; Point IRQ to the address provided by the audio driver and set the
; interval to whatever it specified (it will overwrite these lda's)

isr_entry_lo
	lda #0
	sta cpu_irq_vector
isr_entry_hi
	lda #0
	sta cpu_irq_vector+1

	lda isr_cycle_time
	sta CIA1+$06
	lda #0
	sta CIA1+$07

	lda #$7f			; clear CIA interrupt masks
	sta CIA1+$0d

	ldx #0				; disable VIC-II interrupts
	stx VIC+$1a
	lda VIC+$19
	and #$81
	sta VIC+$19
	stx VIC+$19

	lda #$82			; set Timer B to continuous mode, counting Phi2 cycles
	sta CIA1+$0d		; no output on PB6, and start it

	!ifdef c128 {
		jsr c128_set_1mhz_mode
	}

; Jackasser's polling sync method, reformatted to match my code style
; https://codebase64.org/doku.php?id=base:the_polling_method

; NTSC fix: if pal_flag is clear, turn the last two nop's in JA's
; code into 'cmp ($ea,x)' turning 2 bytes/4 cycles into 2 bytes/6 cycles

	lda pal_flag
	bmi sync_vic
	lda #$c1
	sta +

sync_vic
	lda #$11		; to be used below...
	ldx #250

	-	cpx VIC+$12
		bne -
	+DELAY_LOOP Y, 10	; need 52 cycles.  this loop is 49
	bit $ea				; burn 3 more cycles
	inx
	cpx VIC+$12
	beq skip1
	nop
	nop
skip1
	+DELAY_LOOP Y, 10
	bit $ea
	inx
	cpx VIC+$12
	beq skip2
	bit $ea
skip2
	+DELAY_LOOP Y, 10
	bit $ea
	+	nop
		nop
		inx
		cpx VIC+$12
	bne +				; we should now be right at the start of line #251

; add a 59-cycle delay to put us a few cycles before the end of the next line.

+	+DELAY_LOOP X, 10	; 49 cycles
	nop					; 2 cycles
	nop					; 2 cycles
	nop					; 2 cycles
	sta CIA1+$0f		; 4 cycles

	!ifndef c128 {
		lda disable_screen_on_playback
		bpl +
		jsr disable_screen
	}
rts

interrupts_lockout   rti ; exit any interrupt that gets here, unacknowledged 

!macro ISR_ENTRY {
	inc VIC+$20			; 6 cycles / just so we can see it running.
	dec VIC+$20			; 6 cycles

	sta isr_accu		; 3 cycles
	stx isr_regx
	sty isr_regy
}

!macro ISR_EXIT {
	ldy isr_regy
	ldx isr_regx
	lda isr_accu		; 3 cycles
	bit CIA1+$0d		; 4 cycles / acknowledge Timer B interrupt
	rti					; 6 cycles
}
