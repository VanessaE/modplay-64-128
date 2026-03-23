; Audio driver for SID chip, using the "Mahoney method": gives just a hair
; over 7 bits of resolution on the 6581, and a hair less than 6 bits on 8580.
;
; This is audio driver #2

!zone sid_mahoney_driver {

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

	lda #<reset_sids
	sta audio_stop_vec
	lda #>reset_sids
	sta audio_stop_vec+1

	bit stereo_enable
	bmi +

	lda #<sid_isr_mahoney_mono
	sta audio_isr_vec
	lda #>sid_isr_mahoney_mono
	sta audio_isr_vec+1
	rts

+	lda #<sid_isr_mahoney_stereo
	sta audio_isr_vec
	lda #>sid_isr_mahoney_stereo
	sta audio_isr_vec+1

	jsr reset_sids
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
		lda #7
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
	jsr reset_sids

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
+	sta .mah_mono_tbl+2

	bit stereo_enable
	bmi +
	rts

+	sta .mah_stereo_tl+2

	jsr mah_setup_right_sid_addrs

	lda #$0f
.mah_v1r_ad		sta $1234
.mah_v2r_ad		sta $1234
.mah_v3r_ad		sta $1234

	lda #$ff
.mah_v1r_sr		sta $1234
.mah_v2r_sr		sta $1234
.mah_v3r_sr		sta $1234

	lda #$49
.mah_v1r_cr		sta $1234
.mah_v2r_cr		sta $1234
.mah_v3r_cr		sta $1234

	lda #$ff
.mah_flr		sta $1234
.mah_fhr		sta $1234

	lda #$03
.mah_fvsr		sta $1234

	lda #>mah_table_6581
	bit sid_type_right
	bpl +
	lda #>mah_table_8580
+	sta .mah_stereo_tr+2
rts

sid_mahoney_mute
rts

mah_setup_right_sid_addrs
	; low bytes vary

	clc

	lda stereo_sid_addr
	adc #5
	sta .mah_v1r_ad+1
	adc #7
	sta .mah_v2r_ad+1
	adc #7
	sta .mah_v3r_ad+1

	lda stereo_sid_addr
	adc #6
	sta .mah_v1r_sr+1
	adc #7
	sta .mah_v2r_sr+1
	adc #7
	sta .mah_v3r_sr+1

	lda stereo_sid_addr
	adc #4
	sta .mah_v1r_cr+1
	adc #7
	sta .mah_v2r_cr+1
	adc #7
	sta .mah_v3r_cr+1

	lda stereo_sid_addr
	adc #$15
	sta .mah_flr+1
	adc #1
	sta .mah_fhr+1

	lda stereo_sid_addr
	adc #$17
	sta .mah_fvsr+1

	; high bytes are all the same
	lda stereo_sid_addr+1

	sta .mah_v1r_ad+2
	sta .mah_v2r_ad+2
	sta .mah_v3r_ad+2

	sta .mah_v1r_sr+2
	sta .mah_v2r_sr+2
	sta .mah_v3r_sr+2

	sta .mah_v1r_cr+2
	sta .mah_v2r_cr+2
	sta .mah_v3r_cr+2

	sta .mah_flr+2
	sta .mah_fhr+2

	sta .mah_fvsr+2

	sta .mah_s2a+2
	lda stereo_sid_addr
	adc #$18
	sta .mah_s2a+1
rts

sid_isr_mahoney_mono			; 7 cycles coming in
	+IRQ_SAVE_AX				; 6

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3
	clc							; 2
	lda audio_buffer_left,x		; 4
	adc audio_buffer_right,x	; 4
	tax							; 2
.mah_mono_tbl
	lda $6400,x					; 4 / will be reset to the addr of the proper
	sta SID_VOLUME				; 4 / table, below.

	+IRQ_RESTORE_AX				; 6
+IRQ_EXIT						; 9 cycles to exit on stock C64, 11 on C128
								; 26 on SCPU


sid_isr_mahoney_stereo			; 7 cycles coming in
	+IRQ_SAVE_AXY				; 9

	inc audio_out_buf_index		; 5
	ldx audio_out_buf_index		; 3

	ldy audio_buffer_left,x		; 4
.mah_stereo_tl
	lda $6400,y					; 4
	sta SID_VOLUME				; 4

	ldy audio_buffer_right,x	; 4
.mah_stereo_tr
	lda $6400,y					; 4
.mah_s2a
	sta $1234					; 4 / will be set to right SID addr + $18, above

	+IRQ_RESTORE_AXY			; 9
+IRQ_EXIT						; 9, 11, or 26

}
