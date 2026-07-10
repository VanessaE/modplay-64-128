; Audio driver for DigiMAX Mk2.
;
; This is audio driver #5

!zone digimax_mk2_driver {

!ifdef scpu {
	need_cia_delays = 1
} else ifdef c128 {
	need_cia_delays = 1
}

; ISR-common will call this function to set up the various vectors to the
; routines below.

digimax_mk2_driver_init
	lda #$80
	sta stereo_enable

	lda #<digimax_mk2_set_vol_tab_resolution
	sta audio_set_resolution_vec
	lda #>digimax_mk2_set_vol_tab_resolution
	sta audio_set_resolution_vec+1

	lda #<digimax_mk2_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec
	lda #>digimax_mk2_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec+1

	lda #<digimax_mk2_start
	sta audio_start_vec
	lda #>digimax_mk2_start
	sta audio_start_vec+1

	lda #<digimax_mk2_mute
	sta audio_mute_vec
	lda #>digimax_mk2_mute
	sta audio_mute_vec+1

	lda #<digimax_mk2_stop
	sta audio_stop_vec
	lda #>digimax_mk2_stop
	sta audio_stop_vec+1

	lda #<digimax_isr_mk2
	sta audio_isr_vec
	lda #>digimax_isr_mk2
	sta audio_isr_vec+1
	rts
rts

digimax_mk2_set_isr_cycle_count
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

digimax_mk2_set_vol_tab_resolution
	lda #7
	sta volume_tables_resolution
rts

digimax_mk2_start
	lda CIA2_DDR_A				; PA2 and /PA3 are outputs
	ora #%00001100
	sta CIA2_DDR_A

	lda #$ff					; all of port B set to output
	sta CIA2_DDR_B

	lda CIA2_PORT_A				; lower both PA2 and /PA3
	and #%11111011
	ora #%00001000
	sta CIA2_PORT_A

	lda #0						; Timer A fastest possible interval
	sta CIA2_TIMER_A_HIGH
	lda #2
	sta CIA2_TIMER_A_LOW

	lda cia_cra_startup_val		; start timer A
	sta CIA2_CRA

	jsr digimax_mk2_sp_wait		; Wait for any "garbage" to cycle through SP2

	lda CIA2_PORT_A				; Raise PA2
	ora #%00001100
	sta CIA2_PORT_A

	lda #%11100111				; send a low pulse out through the SP line
	sta CIA2_SDR

	jsr digimax_mk2_sp_wait		; Wait for the write to cycle through

	; Preset both DACs to their midpoints and leave the auto-switcher set to
	; the left audio channel.  The delays are added on C128 to ensure that
	; the clock is stretched far enough between writes so that they all
	; conform to the CIA's minimum interval.

	lda #$80
	sta CIA2_PORT_B
	!ifdef need_cia_delays {
		bit $dd00
	}
	sta CIA2_PORT_B
	!ifdef need_cia_delays {
		bit $dd00
	}
	sta CIA2_PORT_B
rts

digimax_mk2_mute
rts

digimax_mk2_stop				; just set PA2 low, /PA3 high
	lda CIA2_PORT_A
	and #%11110011
	sta CIA2_PORT_A
rts

digimax_isr_mk2					; 7 cycles coming in
	+NMI_SAVE_AX				; 6

	ldx audio_out_buf_index		; 3
	lda audio_buffer_left,x		; 4
	sta CIA2_PORT_B				; 4
	lda audio_buffer_right,x	; 4
	sta CIA2_PORT_B				; 4
	inc audio_out_buf_index		; 5

	+NMI_RESTORE_AX				; 6
+NMI_EXIT						; 9, 11, or 26


digimax_mk2_sp_wait
	ldx #254				; spin-wait for raster line 254
-	cpx VIC_RASTER_LOW
	bne -
-	ldx VIC_RASTER_LOW		; now wait for it to roll over to 0.
	bne -
rts

}
