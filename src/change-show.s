; this file handles changing and showing settings in the main menu

!ifndef c128 {
	rpt_row			= 9
	rpt_col			= 34
	dev_row			= 8
	dev_col			= 34
	adrv_row		= 3
	adrv_col		= 23
	stereo_row		= 4
	stereo_col		= 30
	sidaddr_row		= 6
	sidaddr_col		= 31
	dacaddr_row		= 6
	dacaddr_col		= 31
	filter_row		= 9
	filter_col		= 33
	dith_en_row		= 7
	dith_en_col		= 33
	scr_en_row		= 9
	scr_en_col		= 30
	info_anykey_row	= 20
	info_anykey_col	= 14
	info_plat_row	= 7
	info_plat_col	= 13
	info_expram_row	= 8
	info_expram_col	= 23
	info_lsid_row	= 9
	info_lsid_col	= 13
	info_rsid_row	= 10
	info_rsid_col	= 14
	info_files_row	= 11
	info_files_col	= 26
	info_ram_use_row = 12
	info_ram_use_col = 24
	build_no_row	= 18
	build_no_col	= 13
} else {
	rpt_row			= 6
	rpt_col			= 31
	dev_row			= 4
	dev_col			= 32
	adrv_row		= 1
	adrv_col		= 5
	stereo_row		= 2
	stereo_col		= 19
	sidaddr_row		= 3
	sidaddr_col		= 31
	dacaddr_row		= 3
	dacaddr_col		= 32
	filter_row		= 4
	filter_col		= 24
	dith_en_row		= 4
	dith_en_col		= 22
	info_anykey_row	= 15
	info_anykey_col	= 14
	info_plat_row	= 2
	info_plat_col	= 13
	info_expram_row	= 3
	info_expram_col	= 23
	info_lsid_row	= 4
	info_lsid_col	= 13
	info_rsid_row	= 5
	info_rsid_col	= 14
	info_files_row	= 6
	info_files_col	= 26
	info_ram_use_row = 7
	info_ram_use_col = 24
	build_no_row	= 13
	build_no_col	= 13
}

show_repeat_mode
	lda current_menu_page
	beq +
	clc
	rts

+	clc
	ldx #rpt_row
	ldy #rpt_col
	jsr PLOT
	lda #0
	ldx playlist_length
	bne +

	lda #0
	ldx #<na_msg
	ldy #>na_msg
	jmp ++

+	bit repeat_mode
	bpl +

	ldx #<mode_on_txt
	ldy #>mode_on_txt
	jmp ++

+	ldx #<mode_off_txt
	ldy #>mode_off_txt

++	sec
	jsr print_msg
rts

toggle_repeat
	lda repeat_mode
	eor #$80
	sta repeat_mode
	jsr show_repeat_mode
+ rts

choose_audio_driver
	jsr gray_out
	clc
	jsr draw_mini_popup

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

	lda #GRN
	jsr CHROUT
	lda #"1"
	jsr CHROUT
	lda #")"
	jsr CHROUT
	lda #" "
	jsr CHROUT
	lda #LGRN
	jsr CHROUT

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

	jsr CHROUT
	lda #GRN
	jsr CHROUT
	lda #"2"
	jsr CHROUT
	lda #")"
	jsr CHROUT
	lda #" "
	jsr CHROUT
	lda #LGRN
	jsr CHROUT

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

	jsr CHROUT
	lda #GRN
	jsr CHROUT
	lda #"3"
	jsr CHROUT
	lda #")"
	jsr CHROUT
	lda #" "
	jsr CHROUT
	lda #LGRN
	jsr CHROUT

	lda #0
	ldx #<audio_driver_3_txt
	ldy #>audio_driver_3_txt
	sec
	jsr print_msg

-	jsr GETIN
	beq -

	cmp #$31
	bcc -

	cmp #$34
	bcs -

	and #$03
	sta audio_driver
	lda current_menu_page
	cmp #2
	bne +
	lda #0
	sta main_menu_cache_is_valid
  +
rts

show_input_device
	lda current_menu_page
	cmp #1
	beq +
	clc
	rts

+	clc
	ldx #dev_row
	ldy #dev_col
	jsr PLOT
	lda #GRN
	jsr CHROUT
	lda #"("
	jsr CHROUT
	lda #WHT
	jsr CHROUT
	ldx #9
	cpx load_device
	bmi +
	lda #$20	; print a leading space if dev 8 or 9
	jsr CHROUT

+	sec
	ldx load_device
	ldy #0
	jsr print_uint16
	lda #GRN
	jsr CHROUT
	lda #")"
	jsr CHROUT
	sec
rts

change_input_device
	inc load_device
	lda load_device
	cmp #31
	bne +
	lda #8
	sta load_device

+	jsr check_drive_presence
	bne change_input_device

	jsr show_input_device
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
	jmp adrv_app

+	cmp #2
	bne +
	lda #0
	ldx #<audio_driver_2_txt
	ldy #>audio_driver_2_txt
	sec
	jsr print_msg
	jmp adrv_app

+	cmp #3
	bne adrv_app
	lda #0
	ldx #<audio_driver_3_txt
	ldy #>audio_driver_3_txt
	sec
	jsr print_msg

adrv_app
 	lda #GRN
	jsr CHROUT
	lda #")"
	jsr CHROUT
	sec
rts

show_stereo_mode
	lda current_menu_page
	cmp #2
	beq +
	clc
	rts

+	clc
	ldx #stereo_row
	ldy #stereo_col
	jsr PLOT
	bit stereo_enable
	bpl +

	lda #0
	ldx #<mode_on_txt
	ldy #>mode_on_txt
	sec
	jsr print_msg
	rts

+	lda #0
	ldx #<mode_off_txt
	ldy #>mode_off_txt
	sec
	jsr print_msg
rts

toggle_stereo_mode
	lda stereo_enable
	eor #$80
	sta stereo_enable
rts

show_sid_addr
	lda current_menu_page
	cmp #2
	beq +
	clc
	rts

+	clc
	ldx #sidaddr_row
	ldy #sidaddr_col
	jsr PLOT
	ldx audio_driver
	cpx #3
	bne +
	rts

+	bit stereo_enable
	bmi +
	rts

+	lda #GRN
	jsr CHROUT
	lda #"("
	jsr CHROUT
	lda #WHT
	jsr CHROUT
	lda #"$"
	jsr CHROUT
	lda #"D"
	jsr CHROUT
	lda stereo_sid_addr+1
	jsr to_hex_caps
	jsr CHROUT
	lda stereo_sid_addr
	lsr
	lsr
	lsr
	lsr
	jsr to_hex_caps
	jsr CHROUT
	lda #"0"
	jsr CHROUT
	lda #GRN
	jsr CHROUT
	lda #")"
	jsr CHROUT
	sec
rts

show_dac_addr
	lda current_menu_page
	cmp #2
	beq +
	clc
	rts

+	clc
	ldx #dacaddr_row
	ldy #dacaddr_col
	jsr PLOT

	ldx audio_driver						; allow changing DAC address
	cpx #3
	beq +
	rts

+	lda #GRN
	jsr CHROUT
	lda #"("
	jsr CHROUT
	lda #WHT
	jsr CHROUT

	lda dac_addr+1
	cmp #$dd
	bne +
	lda #0
	ldx #<user_msg
	ldy #>user_msg
	sec
	jsr print_msg
	jmp ++

+	lda #"$"
	jsr CHROUT
	lda #"D"
	jsr CHROUT
	lda dac_addr+1
	jsr to_hex_caps
	jsr CHROUT
	lda dac_addr
	lsr
	lsr
	lsr
	lsr
	jsr to_hex_caps
	jsr CHROUT
	lda #"0"
	jsr CHROUT

++	lda #GRN
	jsr CHROUT
	lda #")"
	jsr CHROUT
	sec
rts

change_audio_addr
	lda audio_driver
	cmp #3
	beq +
	jsr change_sid_addr
	jsr check_sid_type_right
	rts

+	jsr change_dac_addr
rts

change_sid_addr
	clc
	lda stereo_sid_addr
	adc #$20
	sta stereo_sid_addr
	php
	lda stereo_sid_addr+1
	plp
	bne .ck_dac

	cmp #$d4
	bne +
	!ifndef c128 {			; $d500-$d6ff reserved on C128
		lda #$d5
	} else {
		lda #$d7
	}
	bne .ck_dac

	!ifndef c128 {
	+	cmp #$d5
		bne +
		lda #$d6
		bne .ck_dac

	+	cmp #$d6
		bne +
		lda #$d7
		bne .ck_dac
	}

+	cmp #$d7
	bne +
	lda #$de
	bne .ck_dac

+	cmp #$de
	bne +
	lda #$20
	sta stereo_sid_addr		; $df00-$df1f is reserved for REU
	lda #$df
	bne .ck_dac

+	cmp #$df
	bne .ck_dac
	lda #$20
	sta stereo_sid_addr		; obviously, $d400-$d420 is reserved also :P
	lda #$d4

.ck_dac
	sta stereo_sid_addr+1
	cmp dac_addr+1
	bne .show
	lda stereo_sid_addr
	cmp dac_addr
	beq change_sid_addr		; skip forward again if the new SID addr matches the DAC addr

.show
	jsr show_sid_addr
+ rts

change_dac_addr
	lda dac_addr+1
	cmp #$dd			; if $ddxx, don't add $20 -- $dd01 only, or skip to $dexx
	bne +
	lda #0
	sta dac_addr
	lda #$de
	bne .ck_sid

+	clc
	lda dac_addr
	adc #$20
	sta dac_addr
	php
	lda dac_addr+1
	plp
	bne .ck_sid

+	cmp #$de
	bne +
	lda #$20
	sta dac_addr		; $df00-$df1f is reserved for REU
	lda #$df
	bne .ck_sid

+	cmp #$df
	bne +
	lda #$01
	sta dac_addr
	lda #$dd

.ck_sid
	sta dac_addr+1
	cmp stereo_sid_addr+1
	bne .show2
	lda dac_addr
	cmp stereo_sid_addr
	beq change_dac_addr		; skip forward again if the new DAC addr matches the stereo SID addr

.show2
	jsr show_dac_addr
+ rts

show_filter_setting
	lda current_menu_page
	cmp #2
	beq +
	clc
	rts

+	lda audio_driver
	cmp #2
	beq +
	clc
	rts

+	clc
	ldx #filter_row
	ldy #filter_col
	jsr PLOT

	bit filter_setting
	bpl +

	lda #0
	ldx #<mode_on_txt
	ldy #>mode_on_txt
	sec
	jsr print_msg
	rts

+	lda #0
	ldx #<mode_off_txt
	ldy #>mode_off_txt
	sec
	jsr print_msg
rts

change_filter_setting
	lda filter_setting
	eor #$80
	sta filter_setting
	jsr show_filter_setting
rts

show_dithering_setting
	lda current_menu_page
	cmp #2
	beq +
	clc
	rts

+	lda audio_driver
	cmp #1
	beq +
	rts

+	clc
	ldx #dith_en_row
	ldy #dith_en_col
	jsr PLOT

	bit dither_enable
	bpl +

	ldx #<mode_on_txt
	ldy #>mode_on_txt
	jmp ++

+	ldx #<mode_off_txt
	ldy #>mode_off_txt
++	sec
	jsr print_msg
rts

change_dithering_setting
	lda audio_driver
	cmp #1
	beq +
	rts

+	lda dither_enable
	eor #$80
	sta dither_enable
	jsr show_dithering_setting
+ rts

!ifndef c128 {
	toggle_screen_enable
		lda enable_screen_on_playback
		eor #$80
		sta enable_screen_on_playback
		jsr show_screen_enable
	rts

	show_screen_enable
		lda current_menu_page
		cmp #2
		beq +
		clc
		rts

	+	ldx #scr_en_row
		!ifndef c128 {
			lda audio_driver
			cmp #1
			beq ++
			dex
		}

	++	clc
		ldy #scr_en_col
		jsr PLOT
		lda #0

		bit enable_screen_on_playback
		bpl +

		ldx #<mode_on_txt
		ldy #>mode_on_txt
		jmp ++

	+	ldx #<mode_off_txt
		ldy #>mode_off_txt

	++	sec
		jsr print_msg
	rts
}

show_system_info_popup
	jsr draw_medium_popup
	lda #0
	ldx #<info_popup_msg
	ldy #>info_popup_msg
	sec
	jsr print_msg

	clc
	ldx #info_plat_row
	ldy #info_plat_col
	jsr PLOT
	lda #0
	ldx #<info_popup_platform_computer
	ldy #>info_popup_platform_computer
	sec
	jsr print_msg

	!ifdef scpu {
		bit supercpu_detected
		bpl +

		lda #0
		ldx #<info_popup_plus_scpu_msg
		ldy #>info_popup_plus_scpu_msg
		sec
		jsr print_msg
	  +
	}

	clc
	ldx #info_expram_row
	ldy #info_expram_col
	jsr PLOT

	clc
	lda reu_highest_bank
	adc #1
	sta utility_pointer
	lda #0
	rol

	asl utility_pointer
	rol 
	asl utility_pointer
	rol 
	asl utility_pointer
	rol 
	asl utility_pointer
	rol 
	asl utility_pointer
	rol 
	asl utility_pointer
	rol 

	sec
	ldx utility_pointer
	tay
	jsr print_uint16

	!ifndef c128 {
		lda #32
		jsr CHROUT
	}

	lda #0
	ldx #<kb_msg
	ldy #>kb_msg
	sec
	jsr print_msg

;	!ifdef scpu {
;
;		lda supercpu_last_free_page
;		ora supercpu_last_free_bank
;		bne +
;
;		lda #0
;		ldx #<not_present_msg
;		ldy #>not_present_msg
;		sec
;		jsr print_msg
;		jmp ++
;
;	+	clc
;		lda supercpu_last_free_bank
;		adc #1
;		sta utility_pointer
;		lda #0
;		rol
;
;		asl utility_pointer
;		rol 
;		asl utility_pointer
;		rol 
;		asl utility_pointer
;		rol 
;		asl utility_pointer
;		rol 
;		asl utility_pointer
;		rol 
;		asl utility_pointer
;		rol 
;
;		sec
;		ldx utility_pointer
;		tay
;		jsr print_uint16
;
;		!ifndef c128 {
;			lda #32
;			jsr CHROUT
;		}
;
;		lda #0
;		ldx #<kb_msg
;		ldy #>kb_msg
;		sec
;		jsr print_msg
;
;	} else {
;		lda #0
;		ldx #<na_msg
;		ldy #>na_msg
;		sec
;		jsr print_msg
;	}

	clc
	ldx #info_lsid_row
	ldy #info_lsid_col
	jsr PLOT

	bit sid_type_left
	bmi + ; 8580
	ldx #<info_popup_6581_msg
	ldy #>info_popup_6581_msg
	jmp ++

+	ldx #<info_popup_8580_msg
	ldy #>info_popup_8580_msg

++	lda #0
	sec
	jsr print_msg

	clc
	ldx #info_rsid_row
	ldy #info_rsid_col
	jsr PLOT

	lda sid_type_right
	cmp #$ff
	bne +
	ldx #<not_present_msg
	ldy #>not_present_msg
	jmp ++

+	bmi +
	ldx #<info_popup_6581_msg
	ldy #>info_popup_6581_msg
	jmp ++

+	ldx #<info_popup_8580_msg
	ldy #>info_popup_8580_msg

++	lda #0
	sec
	jsr print_msg

	lda #LGRN
	jsr CHROUT

	clc
	ldx #info_files_row
	ldy #info_files_col
	jsr PLOT

	sec
	ldx playlist_length
	ldy #0
	jsr print_uint16

	lda highest_exp_addresss_used+1
	sta utility_pointer
	lda highest_exp_addresss_used+2
	sta utility_pointer+1

	lsr utility_pointer+1
	ror utility_pointer
	lsr utility_pointer+1
	ror utility_pointer

	clc
	ldx #info_ram_use_row
	ldy #info_ram_use_col
	jsr PLOT

	sec
	ldx utility_pointer
	ldy utility_pointer+1
	jsr print_uint16

	!ifndef c128 {
		lda #32
		jsr CHROUT
	}

	lda #0
	ldx #<kb_msg
	ldy #>kb_msg
	sec
	jsr print_msg

	clc
	ldx #build_no_row
	ldy #build_no_col
	jsr PLOT

	lda #0
	ldx #<program_version
	ldy #>program_version
	sec
	jsr print_msg

	lda #"-"
	jsr CHROUT

	sec
	ldx #<build_no
	ldy #>build_no
	jsr print_uint16

	clc
	ldx #info_anykey_row
	ldy #info_anykey_col
	jsr PLOT
	jsr press_any_key
rts
