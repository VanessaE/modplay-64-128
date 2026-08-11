; this file handles changing and showing settings in the main menu

!ifdef c128 {
	rpt_row			= 6
	rpt_col			= 31
	dev_row			= 4
	dev_col			= 32
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
	info_plat_row	= 2
	info_plat_col	= 13
	info_expram_row	= 6
	info_expram_col	= 23
	info_lsid_row	= 3
	info_lsid_col	= 13
	info_rsid_row	= 4
	info_rsid_col	= 14
	info_files_row	= 5
	info_files_col	= 26
	info_ram_use_row = 7
	info_ram_use_col = 24
	build_no_row	= 16
	build_no_col	= 13
	info_anykey_row	= 18
	info_anykey_col	= 14
	info_instlist_row = 0
	info_instlist_col = 13
} else ifdef c64u {
	rpt_row			= 9
	rpt_col			= 32
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
	filter_row		= 7
	filter_col		= 33
	dith_en_row		= 7
	dith_en_col		= 33
	scr_en_row		= 9
	scr_en_col		= 30
	info_plat_row	= 5
	info_plat_col	= 13
	info_expram_row	= 9
	info_expram_col	= 23
	info_lsid_row	= 6
	info_lsid_col	= 13
	info_rsid_row	= 7
	info_rsid_col	= 14
	info_files_row	= 8
	info_files_col	= 26
	info_ram_use_row = 10
	info_ram_use_col = 24
	build_no_row	= 19
	build_no_col	= 13
	info_anykey_row	= 21
	info_anykey_col	= 14
	info_instlist_row = 3
	info_instlist_col = 13
} else {
	rpt_row			= 9
	rpt_col			= 32
	dev_row			= 8
	dev_col			= 34
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
	info_plat_row	= 5
	info_plat_col	= 13
	info_expram_row	= 9
	info_expram_col	= 23
	info_lsid_row	= 6
	info_lsid_col	= 13
	info_rsid_row	= 7
	info_rsid_col	= 14
	info_files_row	= 8
	info_files_col	= 26
	info_ram_use_row = 10
	info_ram_use_col = 24
	build_no_row	= 19
	build_no_col	= 13
	info_anykey_row	= 21
	info_anykey_col	= 14
	info_instlist_row = 3
	info_instlist_col = 13
}

show_repeat_mode
	lda current_menu_page
	beq +
	clc
	rts

+	clc
	ldx #rpt_row

	bit load_device_supports_dirs
	bpl +
	inx

+	ldy #rpt_col
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

	ldx #<mode_on_msg
	ldy #>mode_on_msg
	jmp ++

+	ldx #<mode_off_msg
	ldy #>mode_off_msg

++	sec
jmp print_msg

toggle_repeat
	lda repeat_mode
	eor #$80
	sta repeat_mode
	jsr show_repeat_mode
+ rts

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
jmp show_input_device

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

	lda audio_driver
	cmp #3
	beq .menu_st_unavail

	cmp #4
	beq .menu_st_always_on

	cmp #5
	beq .menu_st_always_on

	bit stereo_enable
	bpl .menu_st_off

.menu_st_on
	lda #0
	ldx #<mode_on_msg
	ldy #>mode_on_msg
	sec
jmp print_msg

.menu_st_off
	lda #0
	ldx #<mode_off_msg
	ldy #>mode_off_msg
	sec
jmp print_msg

.menu_st_always_on
	lda #DGRY
	jsr CHROUT

	lda #0
	ldx #<mode_always_on_msg
	ldy #>mode_always_on_msg
	clc
jmp print_msg

.menu_st_unavail
	lda #DGRY
	jsr CHROUT

	lda #0
	ldx #<na_msg
	ldy #>na_msg
	clc
jmp print_msg

toggle_stereo_mode
	lda audio_driver
	cmp #3
	bcc +
	rts

+	lda stereo_enable
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
	bcc +
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
	bcs +
	rts

+	cpx #5									; Except on DigiMAX Mk2 (always
	bne +									; on the User Port)
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
	bcs +
	jmp change_sid_addr

+	cmp #4
	beq .ch_dac_addr
	rts

  .ch_dac_addr
jmp change_dac_addr

change_sid_addr
	clc
	lda stereo_sid_addr
	adc #$20
	sta stereo_sid_addr
	php
	lda stereo_sid_addr+1
	plp
	bne .set_sid_dac_addr

	cmp #$d4
	bne .ck_d5_or_d6

	!ifndef c128 {			; $d500-$d6ff reserved on C128
		lda #$d5
		bne .set_sid_dac_addr
	} else {
		lda #$d7
		bne .set_sid_dac_addr
	}

	.ck_d5_or_d6

	!ifndef c128 {
		cmp #$d5
		bne .ck_d6
		lda #$d6
		bne .set_sid_dac_addr
	.ck_d6
		cmp #$d6
		bne .ck_d7
		lda #$d7
		bne .set_sid_dac_addr
	}

.ck_d7
	cmp #$d7
	bne .ck_de
	lda #$de
	bne .set_sid_dac_addr

.ck_de
	cmp #$de
	bne .ck_df
	lda #$20
	sta stereo_sid_addr		; $df00-$df1f is reserved for REU
	lda #$df
	bne .set_sid_dac_addr

.ck_df
	cmp #$df
	bne .set_sid_dac_addr
	lda #$20
	sta stereo_sid_addr		; obviously, $d400-$d420 is reserved also :P
	lda #$d4

.set_sid_dac_addr
	sta stereo_sid_addr+1
	cmp dac_addr+1
	bne .show
	lda stereo_sid_addr
	cmp dac_addr
	beq change_sid_addr		; skip forward again if the new SID addr matches the DAC addr

  .show
jmp show_sid_addr


change_dac_addr
	lda dac_addr+1
	cmp #$dd			; if $ddxx, don't add $20 -- $dd01 only, or skip to $dexx
	bne .da_add_20
	lda #0
	sta dac_addr
	lda #$de
	bne .ck_sid

.da_add_20
	clc
	lda dac_addr
	adc #$20
	sta dac_addr
	php
	lda dac_addr+1
	plp
	bne .ck_sid

	cmp #$de
	bne .da_ck_df
	lda #$20
	sta dac_addr		; $df00-$df1f is reserved for REU
	lda #$df
	bne .ck_sid

.da_ck_df
	cmp #$df
	bne .da_no_chg
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

.da_no_chg
rts

show_filter_setting
	lda current_menu_page
	cmp #2
	beq +
	sec
	rts

+	ldx #filter_row

	lda audio_driver
	cmp #1
	bne +
	inx
+	ldy #filter_col
	clc
	jsr PLOT

	bit filter_setting
	bpl +

	lda #0
	ldx #<mode_on_msg
	ldy #>mode_on_msg
	sec
	jmp print_msg

+	lda #0
	ldx #<mode_off_msg
	ldy #>mode_off_msg
	sec
jmp print_msg

change_filter_setting
	lda filter_setting
	eor #$80
	sta filter_setting
jmp show_filter_setting


show_dithering_setting
	lda current_menu_page
	cmp #2
	beq +
	sec
	rts

+	lda audio_driver
	cmp #1
	beq +
	sec
	rts

+	clc
	ldx #dith_en_row
	ldy #dith_en_col
	jsr PLOT

	bit dither_enable
	bpl +

	ldx #<mode_on_msg
	ldy #>mode_on_msg
	jmp ++

+	ldx #<mode_off_msg
	ldy #>mode_off_msg
++	sec
jmp print_msg


change_dithering_setting
	lda audio_driver
	cmp #1
	beq +
	sec
	rts

+	lda dither_enable
	eor #$80
	sta dither_enable
	jsr show_dithering_setting
	sec
rts

!ifdef badlines_exist {
	toggle_screen_enable
		lda enable_screen_on_playback
		eor #$80
		sta enable_screen_on_playback
	jmp show_screen_enable

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
			beq +
			dex
		  +
		}

		clc
		ldy #scr_en_col
		jsr PLOT
		lda #0

		bit enable_screen_on_playback
		bpl +

		ldx #<mode_on_msg
		ldy #>mode_on_msg
		jmp ++

	+	ldx #<mode_off_msg
		ldy #>mode_off_msg

	++	sec
	jmp print_msg
}

show_system_info_popup
	jsr check_sid_type_right

	jsr draw_info_popup

	lda #0
	ldx #<info_popup_msg
	ldy #>info_popup_msg
	sec
	jsr print_msg

	clc
	ldx #info_plat_row
	ldy #info_plat_col
	jsr PLOT

	!ifdef c64u {
		lda #0
		bit c64u_detect
		bmi +

		ldx #<info_popup_platform_computer_u64
		ldy #>info_popup_platform_computer_u64
		sec
		jsr print_msg
		jmp ++

	+	ldx #<info_popup_platform_computer_c64u
		ldy #>info_popup_platform_computer_c64u
		sec
		jsr print_msg
	  ++
	} else {
		lda #0
		ldx #<info_popup_platform_computer
		ldy #>info_popup_platform_computer
		sec
		jsr print_msg
	}

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

	lda #YEL
	jsr CHROUT

	ldx current_file_type
	beq .wait_key_after_instr_names

	clc
	ldx #info_anykey_row
	ldy #info_anykey_col-11 ; "Press any key for instrument list"
	jsr PLOT

	lda #0
	ldx #<press_key_msg
	ldy #>press_key_msg
	jsr print_msg

	lda #0
	ldx #<for_instr_list_msg
	ldy #>for_instr_list_msg
	jsr print_msg

	jsr wait_key

	jsr list_instrument_names

	.wait_key_after_instr_names

	!ifdef c128 {
		lda #info_anykey_col

		ldx current_file_type
		cpx #2
		bcc +

		clc
		adc #8
	+	tay
	} else {
		ldy #info_anykey_col
		clc
	}

	ldx #info_anykey_row
	jsr PLOT

	lda #YEL
	jsr CHROUT

jmp press_any_key


list_instrument_names
	!ifdef c128 {
		ldx current_file_type
		cpx #1
		beq +
		lda #31
		sta temp_abs_b
		jsr draw_info_wide_popup
		jmp ++

	+	lda #15
		sta temp_abs_b
		jsr draw_info_popup
	  ++
	} else {
		ldx current_file_type
		lda #15
		cpx #1
		beq +

		lda #31
	+	sta temp_abs_b

		jsr draw_info_popup
	}

	jsr print_instr_list_msg

	lda #1
	sta temp_abs_x

	lda #<string_buffer
	sta expansion_transfer_local_addr
	lda #>string_buffer
	sta expansion_transfer_local_addr+1

	lda #0
	sta expansion_memory_target_pointer
	sta expansion_memory_target_pointer+2
	sta stash_size+1
	lda exp_instr_names_start_page
	sta expansion_memory_target_pointer+1

	lda #32
	sta stash_size

.inst_cnt
	+JSR_INDIRECT (fetch_block_vec)

	lda #RETURN
	jsr CHROUT
	lda #RIGHT
	jsr CHROUT

	!ifndef c128 {
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		lda #LBLU
	} else {
		ldx current_file_type
		cpx #1
		bne +

		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT

	+	lda #DCYN
	}

	jsr CHROUT

	!ifdef c128 {
		ldx temp_abs_x
		cpx #17
		bcc .inscnt_lft_col
		beq +
		bcs ++

	+	lda #HOME
		jsr CHROUT
		lda #DOWN
		jsr CHROUT
		jsr CHROUT
		lda #RIGHT
		jsr CHROUT

	++	ldy #26
		lda #RIGHT
	-	jsr CHROUT
		dey
		bne -

		lda #$aa ; "|" graphic, but at the right edge
		jsr CHROUT
		lda #" "
		jsr CHROUT
	}

.inscnt_lft_col
	ldx temp_abs_x
	cpx #10
	bcs +

	lda #" "
	jsr CHROUT
	ldx temp_abs_x
	sec

+	ldy #0
	jsr print_uint16

	lda #":"
	jsr CHROUT
	lda #" "
	jsr CHROUT

	lda #CYAN
	jsr CHROUT

	ldx #<string_buffer
	ldy #>string_buffer
	jsr get_string_length
	sty temp_abs_y

	lda #22
	ldx #<string_buffer
	ldy #>string_buffer
	jsr print_msg_ascii

	sec
	lda #22
	sbc temp_abs_y
	beq +

	tay

	lda #LBLU
	jsr CHROUT

	lda #"."
-	jsr CHROUT
	dey
	bne -

+	clc
	lda expansion_memory_target_pointer
	adc #32
	sta expansion_memory_target_pointer
	bcc +
	inc expansion_memory_target_pointer+1

+	inc temp_abs_x

	!ifndef c128 {
		lda current_file_type
		cmp #1
		beq +

		ldx temp_abs_x
		cpx #16
		bne +

		lda #0
		ldx #<more_msg
		ldy #>more_msg
		jsr print_msg

		jsr wait_key

		jsr draw_info_popup
		jsr print_instr_list_msg
	 +
	}

	dec temp_abs_b
	beq +
	jmp .inst_cnt
  +
rts

print_instr_list_msg

	!ifdef c128 {
		lda #info_instlist_col

		ldx current_file_type
		cpx #1
		clc
		beq +

		adc #8
	+	tay
	} else {
		ldy #info_instlist_col
		clc
	}

	ldx #info_instlist_row
	jsr PLOT

	lda #LGRN
	jsr CHROUT
	lda #"I"
	jsr CHROUT

	lda #0
	ldx #<instr_list_msg
	ldy #>instr_list_msg
	jsr print_msg

	lda #RETURN
jmp CHROUT
