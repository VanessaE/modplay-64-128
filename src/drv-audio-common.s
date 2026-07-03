; Various helper routines common to most audio drivers

!zone audio_driver_common {

!ifdef c128 {
	adrv_row		= 1
	adrv_col		= 5
} else {
	adrv_row		= 3
	adrv_col		= 23
}

choose_audio_driver
	jsr gray_out
	clc
	jsr draw_audio_popup

	lda #0
	ldx #<choose_audio_msg
	ldy #>choose_audio_msg
	sec
	jsr print_msg_rle

	lda #0
	ldx #<choose_aud_driver_pos
	ldy #>choose_aud_driver_pos
	sec
	jsr print_msg

	lda #1
	jsr print_num_paren

	lda #0
	ldx #<audio_driver_1_txt
	ldy #>audio_driver_1_txt
	sec
	jsr print_msg

	lda #0
	ldx #<choose_aud_driver_pos
	ldy #>choose_aud_driver_pos
	sec
	jsr print_msg

	lda #2
	jsr print_num_paren

	lda #0
	ldx #<audio_driver_2_txt
	ldy #>audio_driver_2_txt
	sec
	jsr print_msg

	lda #0
	ldx #<choose_aud_driver_pos
	ldy #>choose_aud_driver_pos
	sec
	jsr print_msg

	lda #3
	jsr print_num_paren

	lda #0
	ldx #<audio_driver_3_txt
	ldy #>audio_driver_3_txt
	sec
	jsr print_msg

	lda #0
	ldx #<choose_aud_driver_pos
	ldy #>choose_aud_driver_pos
	sec
	jsr print_msg

	lda #4
	jsr print_num_paren

	lda #0
	ldx #<audio_driver_4_txt
	ldy #>audio_driver_4_txt
	sec
	jsr print_msg

-	jsr GETIN
	beq -

	cmp #$31
	bcc -

	cmp #$35
	bcs -

	and #$07
	sta audio_driver

	cmp #3
	bne +

	lda #0
	sta stereo_enable
	jmp ++

+	cmp #4
	bne ++

	lda #$80
	sta stereo_enable

++	lda current_menu_page
	cmp #2
	bne +
	lda #0
	sta main_menu_cache_is_valid
  +
rts

show_audio_driver
	lda current_menu_page
	cmp #2
	beq +
	clc
	rts

+	clc
	ldx #adrv_row
	ldy #adrv_col
	jsr PLOT
	lda #GRN
	jsr CHROUT
	lda #"("
	jsr CHROUT
	lda #WHT
	jsr CHROUT
	lda audio_driver
	cmp #1
	bne +

	lda #0
	ldx #<audio_driver_1_txt
	ldy #>audio_driver_1_txt
	sec
	jsr print_msg
	jmp .adrv_app

+	cmp #2
	bne +
	lda #0
	ldx #<audio_driver_2_txt
	ldy #>audio_driver_2_txt
	sec
	jsr print_msg
	jmp .adrv_app

+	cmp #3
	bne +
	lda #0
	ldx #<audio_driver_3_txt
	ldy #>audio_driver_3_txt
	sec
	jsr print_msg
	jmp .adrv_app

+	cmp #4
	bne .adrv_app
	lda #0
	ldx #<audio_driver_4_txt
	ldy #>audio_driver_4_txt
	sec
	jsr print_msg

.adrv_app
	lda #GRN
	jsr CHROUT
	lda #")"
	jsr CHROUT
	sec
rts

print_num_paren
	pha
	lda #GRN
	jsr CHROUT
	pla
	ora #$30
	jsr CHROUT
	lda #")"
	jsr CHROUT
	lda #" "
	jsr CHROUT
	lda #LGRN
jmp CHROUT

reset_sids
	lda #0
	ldy #$18

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
	ldy #$18

-	sta (utility_pointer),y
	dey
	bpl -
rts

; Detect SID type, based on code by SounDemon.

check_sid_type_left
	!ifdef scpu {
		sta SCPU_TURBO_OFF
	} else ifdef c64u {
		lda #0
		sta c64u_speed_select
	}

	!ifdef c128 {
		lda #0
		sta C128_VIC_CLOCK_SPEED
	}

	sei						;No disturbing interrupts
	lda #0
	sta CIA2_CRA
	sta CIA2_CRB

	lda #$03
	sta CIA2_ICR
	bit CIA2_ICR

	jsr reset_sids

	lda #$ff
-	cmp VIC_RASTER_LOW		;Don't run it on a badline.
	bne -

	lda #$ff				;Set frequency in voice 3 to $ffff 
	sta SID_VOICE3_CR		;...and set testbit (other bits don't matter) in VCREG3 ($d412) to disable oscillator
	sta SID_VOICE3_FREQ_LOW
	sta SID_VOICE3_FREQ_HIGH
	lda #$20				;Sawtooth wave and gatebit OFF to start oscillator again.
	sta SID_VOICE3_CR
	lda SID_VOICE3_OSC_OUT	;Accu now has different value depending on sid model (6581=3/8580=2)
	ldx SID					; Read the very first SID register - UltiSID will
	cpx #$20				; return $20 or $21 from this otherwise unreadable
	beq left_sid_is_ultisid	; register, while real SID and VICE/resid don't.
	cpx #$21
	beq left_sid_is_ultisid

	lsr						;...that is: Carry flag is set for 6581, and clear for 8580.
	lda #0
	sta ultisid_detect_left

	ror
	eor #$80
	sta sid_type_left
	jmp .ls_not_ultisid

left_sid_is_ultisid
	lda #0
	sta sid_type_left
	lda #$80
	sta ultisid_detect_left

.ls_not_ultisid
	!ifdef scpu {
		sta SCPU_TURBO_ON
	} else ifdef c64u {
		lda #15+128
		sta c64u_speed_select
	}

	!ifdef c128 {
		inc C128_VIC_CLOCK_SPEED
	}

rts

; this routine sets up the addresses the right-SID-check routine will
; need to use, so that it can use the same base code, thus keeping the
; timings the same as the left-SID check.

setup_right_sid_check
	clc

	lda stereo_sid_addr
	sta .s2_base+1
	adc #$12
	sta .s2_v3_cr_1+1
	sta .s2_v3_cr_2+1

	lda stereo_sid_addr
	adc #$0e
	sta .s2_v3_fl+1
	adc #1
	sta .s2_v3_fh+1

	lda stereo_sid_addr
	adc #$1b
	sta .s2_osc3_1+1

	; all high bytes are the same

	lda stereo_sid_addr+1
	sta .s2_base+2
	sta .s2_v3_cr_1+2
	sta .s2_v3_cr_2+2
	sta .s2_v3_fl+2
	sta .s2_v3_fh+2
	sta .s2_osc3_1+2
rts

check_sid_type_right
	php							; back-up the state of the I flag

	!ifdef scpu {
		sta SCPU_TURBO_OFF
	} else ifdef c64u {
		lda #0
		sta c64u_speed_select
	}

	!ifdef c128 {
		lda #0
		sta C128_VIC_CLOCK_SPEED
	}

	sei
	lda #0
	sta CIA2_CRA
	sta CIA2_CRB

	lda #$0f
	sta CIA2_ICR
	bit CIA2_ICR

	jsr reset_sids

	lda #$ff					; make sure left SID osc 3 is stopped
	sta SID_VOICE3_CR

	jsr setup_right_sid_check

	lda #$ff
-	cmp VIC_RASTER_LOW
	bne -

	lda #$ff					; max frequency
.s2_v3_cr_1		sta $1234		; (set testbit)
.s2_v3_fl		sta $1234		; (set frequency)
.s2_v3_fh		sta $1234

	lda #$20					; sawtooth wave, gate OFF
.s2_v3_cr_2		sta $1234

.s2_osc3_1		lda $1234		; read right osc 3

.s2_base		ldx $1234		; and right sid reg 0
	sta temp_abs_a

	plp							; restores the I flag in case interrupts were
								; enabled (other flags, don't care)

	!ifdef scpu {
		sta SCPU_TURBO_ON
	} else ifdef c64u {
		lda #15+128
		sta c64u_speed_select
	}

	!ifdef c128 {
		inc C128_VIC_CLOCK_SPEED
	}

	cpx #$20
	beq right_sid_is_ultisid
	cpx #$21
	beq right_sid_is_ultisid

	lda #0
	sta ultisid_detect_right

	lda SID_VOICE3_OSC_OUT		; did the right-SID test cause the left SID
	bne right_sid_is_echo		; osc 3 to start?  if so, there's only an I/O
								; echo at the configured right SID addr.

	lda temp_abs_a
	cmp #2						; if the right SID osc 3 value in .A wasn't
	beq has_right_sid			; 2 or 3, then it's not an I/O echo, but
	cmp #3						; whatever IS there probably isn't a SID
	bne no_right_sid

has_right_sid
	lsr							; otherwise use the same carry trick as in
	lda #0						; the left SID type check
	ror
	eor #$80
	sta sid_type_right
rts

no_right_sid
	ora #$40
	sta sid_type_right
rts

right_sid_is_echo
	lda #$ff
	sta sid_type_right
rts

right_sid_is_ultisid
	lda #0
	sta sid_type_right
	lda #$80
	sta ultisid_detect_right
rts

force_mono_if_no_second_sid
	lda audio_driver			; do second SID check only on drivers 1 and 2
	cmp #3
	bcs +

	lda stereo_enable
	sta stereo_enable_temp

	jsr check_sid_type_right	; if this returns with .A being some value
	beq +						; other than 0 or $80, there's no right SID
	cmp #$80					; at the configured address
	beq +

	lda #0
	sta stereo_enable
  +
rts

sid_apply_digi_boost
	bit sid_type_left
	bpl +
	lda #$ff
	sta SID_VOICE1_ENV_SR
	sta SID_VOICE2_ENV_SR

	lda #$49
	sta SID_VOICE1_CR
	sta SID_VOICE2_CR
	rts

+	bit stereo_enable
	bpl +
	bit sid_type_right
	bpl +

	lda stereo_sid_addr
	sta utility_pointer
	lda stereo_sid_addr+1
	sta utility_pointer+1

	lda #$ff
	ldy #$06
	sta (utility_pointer),y
	ldy #$0d
	sta (utility_pointer),y

	lda #$49
	ldy #$04
	sta (utility_pointer),y
	ldy #$0b
	sta (utility_pointer),y
  +
rts

init_audio_driver
	lda audio_driver

	cmp #4
	bne +
	jmp digimax_mk1_driver_init

+	cmp #3
	bne +
	jmp dac_driver_init

+	cmp #2
	bne +
	jmp sid_mahoney_driver_init

+	bit dither_enable
	bpl +

	jmp sid_4bit_dithered_driver_init

  +
jmp sid_4bit_driver_init

}
