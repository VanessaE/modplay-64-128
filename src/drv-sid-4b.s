; Audio driver for SID chip, 4-bit mode
;
; This is audio driver #1

!zone sid_4bit_driver {

; TRANSIENT IMAGE: init, start and stop.  it's assembled to run from the start of
; the load buffer, but it is stored in the PRG (and then in expansion memory) as
; plain data, and fetched into place whenever it is needed.  it only runs when
; the driver is selected, when playback starts, and when it ends, never while the
; audio ISR is live, and nothing in the resident image may refer to it.  its
; entry jumps are at audio_transient_init, _start and _stop.

sid_4bit_transient_image = *

!pseudopc audio_transient_base {

	jmp sid_4bit_driver_init
	jmp sid_4bit_start
	jmp reset_sids

; init_audio_driver calls this through the first entry of the transient image.
; it points audio_isr_vec at the right ISR and patches the ISRs' operands.

sid_4bit_driver_init
	bit stereo_enable
	bmi +

	lda #<sid_isr_4b_mono
	sta audio_isr_vec
	lda #>sid_isr_4b_mono
	sta audio_isr_vec+1
	rts

+	clc
	lda stereo_sid_addr
	adc #$18
	sta .s2a+1
	lda stereo_sid_addr+1
	adc #0
	sta .s2a+2

	lda #<sid_isr_4b_stereo
	sta audio_isr_vec
	lda #>sid_isr_4b_stereo
	sta audio_isr_vec+1

jmp reset_sids

sid_4bit_start
	jsr reset_sids
jmp sid_apply_digi_boost

sid_4bit_transient_end

}

; RESIDENT IMAGE: the ISRs, and the routines that the table generator calls.
; it runs from the reserved page under the KERNAL, whose first two entries are
; the cycle count and volume table resolution setters.  the transient image
; patches operands in the ISRs here.

sid_4bit_resident_image = *

!pseudopc audio_resident_page {

	jmp sid_4bit_set_isr_cycle_count
	jmp sid_4bit_set_volume_table_resolution

; This sets the audio ISR's cycle count, in 1 MHz units.

; For faster CPUs, divide the raw count by the CPU MHz and round up to the
; next whole 1 MHz equivalent count.  Don't forget to account for clock
; stretching and cache misses.
;
; on SCPU, the count could be as low as 6, but we're fudging it for now.

sid_4bit_set_isr_cycle_count

	!ifndef scpu {
		!ifndef c128 {
			lda #52
		} else {
			lda #56 / 2
		}
	} else {
		lda #7
	}

	sta audio_driver_isr_cycle_count
rts

sid_4bit_set_volume_table_resolution
	lda #3
	sta volume_tables_resolution
rts

sid_isr_4b_mono					; 7 cycles coming in
	+NMI_SAVE_AX				; 6

	ldx audio_out_buf_index		; 3
	clc							; 2
	lda audio_buffer_left,x		; 4
	adc audio_buffer_right,x	; 4
	ror							; 2
	sta SID_VOLUME				; 4
	inc audio_out_buf_index		; 5

	+NMI_RESTORE_AX				; 6
+NMI_EXIT						; 9 cycles to exit on stock C64, 11 on C128
								; 26 on SCPU

sid_isr_4b_stereo				; 7 cycles coming in
	+NMI_SAVE_AX				; 6

	ldx audio_out_buf_index		; 3
	lda audio_buffer_left,x		; 4
	sta SID_VOLUME				; 4
	lda audio_buffer_right,x	; 4
.s2a sta $1234					; 4 / will be set to right SID addr + $18, above
	inc audio_out_buf_index		; 5

	+NMI_RESTORE_AX				; 6
+NMI_EXIT						; 9, 11, or 26

sid_4bit_resident_end

}

}
