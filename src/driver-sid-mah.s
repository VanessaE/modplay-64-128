; Audio driver for SID chip, using the "Mahoney method": gives just a hair
; over 7 bits of resolution on the 6581, and a hair less than 6 bits on 8580.
;
; This is audio driver #2

!zone sid_mahoney_driver {

!text "sid mahoney driver",0

sid_mahoney_driver_init
	lda #<sid_mahoney_set_volume_table_resolution
	sta audio_set_resolution_vec
	lda #>sid_mahoney_set_volume_table_resolution
	sta audio_set_resolution_vec+1

	lda #<sid_mahoney_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec
	lda #>sid_mahoney_set_isr_cycle_count
	sta audio_driver_set_cycle_count_vec+1

	lda #<sid_mahoney_start
	sta audio_start_vec
	lda #>sid_mahoney_start
	sta audio_start_vec+1

	lda #<sid_mahoney_mute
	sta audio_mute_vec
	lda #>sid_mahoney_mute
	sta audio_mute_vec+1

	lda #<sid_mahoney_stop
	sta audio_stop_vec
	lda #>sid_mahoney_stop
	sta audio_stop_vec+1

	bit stereo_enable
	bmi +

	lda #<sid_isr_mahoney_mono
	sta audio_isr_vec
	lda #>sid_isr_mahoney_mono
	sta audio_isr_vec+1
	rts

+	clc
	lda stereo_sid_addr
	adc #$18
	sta .s2a+1
	lda stereo_sid_addr+1
	adc #0
	sta .s2a+2

	lda #<sid_isr_mahoney_stereo
	sta audio_isr_vec
	lda #>sid_isr_mahoney_stereo
	sta audio_isr_vec+1
rts

sid_mahoney_set_isr_cycle_count
	!ifndef scpu {
		!ifndef c128 {
			lda #56
			bit stereo_enable
			bpl +
			lda #66
		  +
		} else {
			lda #58 / 2
			bit stereo_enable
			bpl +
			lda #(69 + 1) / 2
		  +
		}
	} else {
		lda #8
	}

	sta audio_driver_isr_cycle_count
rts

sid_mahoney_set_volume_table_resolution
	lda #7
	bit stereo_enable
	bmi +
	lda #6
+	sta volume_tables_resolution
rts

sid_mahoney_start
	jsr sid_mahoney_stop		; clears the SID(s).

	lda #$0f					;Setup attack=0 and decay=15
	sta SID_VOICE1_ENV_AD
	sta SID_VOICE2_ENV_AD
	sta SID_VOICE3_ENV_AD
	lda #$ff					;Setup all sustain&release to 15
	sta SID_VOICE1_ENV_SR
	sta SID_VOICE2_ENV_SR
	sta SID_VOICE3_ENV_SR
	lda #$49					;Waveform is square, test bit set
	sta SID_VOICE1_CR
	sta SID_VOICE2_CR
	sta SID_VOICE3_CR
	lda #$ff					;Filter cutoff as high as possible
	sta SID_FILT_CUTOFF_LOW
	sta SID_FILT_CUTOFF_HIGH
	lda #$03					;Enable voice 1 and 2 through filter
	sta SID_FILT_VOICE_SEL

	lda #>mah_table_6581
	bit sid_type_left
	bpl +
	lda #>mah_table_8580
+	sta .mt_mono+2

	bit stereo_enable
	bmi +
	rts

+	sta .mt_stereo_l+2

	lda stereo_sid_addr
	sta utility_pointer
	lda stereo_sid_addr+1
	sta utility_pointer+1

	lda #$0f
	ldy #$05
	sta (utility_pointer),y
	ldy #$0c
	sta (utility_pointer),y
	ldy #$13
	sta (utility_pointer),y

	lda #$ff
	ldy #$06
	sta (utility_pointer),y
	ldy #$0d
	sta (utility_pointer),y
	ldy #$14
	sta (utility_pointer),y

	lda #$49
	ldy #$04
	sta (utility_pointer),y
	ldy #$0b
	sta (utility_pointer),y
	ldy #$12
	sta (utility_pointer),y

	lda #$ff
	ldy #$15
	sta (utility_pointer),y
	ldy #$16
	sta (utility_pointer),y

	lda #$03
	ldy #$17
	sta (utility_pointer),y

	lda #>mah_table_6581
	bit sid_type_right
	bpl +
	lda #>mah_table_8580
+	sta .mt_stereo_r+2
rts

sid_mahoney_mute
rts

sid_mahoney_stop
	lda #0
	ldy #$1f

-	sta SID,y
	dey
	bpl -

	bit stereo_enable
	bmi +
	rts

+	lda stereo_sid_addr
	sta utility_pointer
	lda stereo_sid_addr+1
	sta utility_pointer+1

	lda #0
	ldy #$1f

-	sta (utility_pointer),y
	dey
	bpl -
rts

sid_isr_mahoney_mono			; 7 cycles coming in
	sta .iam + 1				; 4
	stx .ixm + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
	clc							; 2
	lda audio_buffer_left,x		; 4
	adc audio_buffer_right,x	; 4
	tax							; 2
.mt_mono
	lda $6400,x					; 4 / will be reset to the addr of the proper
	sta SID_VOLUME				; 4 / table, below.

.iam lda #00					; 2
.ixm ldx #00					; 2
!ifndef scpu {
	jmp CIA1_SDR				; 3+6 cycles to exit (does an implicit read of CIA1_ICR)
} else {
	bit CIA1_ICR				; 4 / acknowledge CIA#1 timer B interrupt
	rti							; 6 cycles to exit
}


sid_isr_mahoney_stereo			; 7 cycles coming in
	sta .ias + 1				; 4
	stx .ixs + 1				; 4
	sty .iys + 1				; 4

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3

	ldy audio_buffer_left,x		; 4
.mt_stereo_l
	lda $6400,y					; 4
	sta SID_VOLUME				; 4

	ldy audio_buffer_right,x	; 4
.mt_stereo_r
	lda $6400,y					; 4
.s2a
	sta $1234					; 4 / will be set to right SID addr + $18, above

.ias lda #00					; 2
.ixs ldx #00					; 2
.iys ldy #00					; 2
!ifndef scpu {
	jmp CIA1_SDR				; 3+6 cycles to exit
} else {
	bit CIA1_ICR				; 4
	rti							; 6 cycles to exit
}

}

!align 255,0

mah_table_6581
	!source "src/mah-table-6581.s"

mah_table_8580
	!source "src/mah-table-8580.s"
