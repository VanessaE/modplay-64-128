; display the main menu

show_main_menu
	!ifdef c128 { ; restore screen/window dimensions
		jsr set_dim_full_screen
		bit clear_menu_screen_flag
		bpl +
		lda #CLR
		jsr CHROUT
	+	lda #$80
		sta clear_menu_screen_flag
	}

	+PRINT_MSG_BATCH 24, mm_lo, mm_hi

	!ifndef c128 { ; restore the screen line links to 40 chars apiece.
		ldx #24
	-	lda screen_line_link_table,x
		sta LDTB1,x
		dex
		bpl -
	}

	ldx #<rt_press_com_key_msg
	ldy #>rt_press_com_key_msg
	jsr print_msg

	!ifdef c128 {
		jsr set_dim_right_pane
	}

	bit current_page
	bmi +

	jsr draw_right_pane_a
	jmp main_loop

+	jsr draw_right_pane_b


main_loop
	jsr GETIN	; returns $0 if nothing is pressed/buf empty
	beq check_com_key

	cmp #$4c ; "l"
	bne +
	jsr load_file_to_expansion
	jmp show_main_menu

	cmp #$50 ; "p"
	bne +
	jsr start_playback
	jmp show_main_menu

+	cmp #$8a ; "F4"
	bne +
	jsr toggle_repeat
	jmp main_loop

+	cmp #$23; "#"
	bne +
	jsr change_input_device
	jmp main_loop

+	cmp #$41; "a"
	bne +
	jsr change_sid_addr
	jmp main_loop
 
+	cmp #$46; "f"
	bne +
	jsr change_filter_setting
	jmp main_loop

+	cmp #$52; "r"
	bne +
	jsr change_resonance_setting
	jmp main_loop

+	cmp #$24 ; "$"
	bne +
	jsr show_directory
	jmp show_main_menu

+	cmp #$5f ; "←"
	bne +
	jsr save_config

+	jmp main_loop

check_com_key ; that is, the "C=" key
	lda #$7f
	sta CIA1

	lda #$df
	cmp CIA1+$01
	bne main_loop
	jsr switch_pages

	lda #$df
-	cmp CIA1+$01 ; wait for release
	beq -
	jmp main_loop

rp_start = SCREEN+(2*40)+19

switch_pages
	!ifdef c128 {
		jsr set_dim_right_pane
		lda #CLR
		jsr CHROUT

	} else {
		ldy #0
		lda #$20
	-	sta SCREEN + 2*40  + 19,y
		sta SCREEN + 3*40  + 19,y
		sta SCREEN + 4*40  + 19,y
		sta SCREEN + 5*40  + 19,y
		sta SCREEN + 6*40  + 19,y
		sta SCREEN + 7*40  + 19,y
		sta SCREEN + 8*40  + 19,y
		sta SCREEN + 9*40  + 19,y
		sta SCREEN + 10*40 + 19,y
		sta SCREEN + 11*40 + 19,y
		sta SCREEN + 12*40 + 19,y
		sta SCREEN + 13*40 + 19,y
		sta SCREEN + 14*40 + 19,y
		sta SCREEN + 15*40 + 19,y
		sta SCREEN + 16*40 + 19,y
		iny
		cpy #20
		bne -
	}

	lda current_page
	eor #$80
	sta current_page
	bmi +
	jmp draw_right_pane_a
+	jmp draw_right_pane_b

draw_right_pane_a
	+PRINT_MSG_BATCH 15, rp_a_lo, rp_a_hi
	jsr show_repeat_mode
rts

draw_right_pane_b
	+PRINT_MSG_BATCH 12, rp_b_lo, rp_b_hi
	jsr show_input_device
	jsr show_sid_addr
	jsr show_filter_setting
	jsr show_resonance_setting
rts

toggle_repeat
	lda repeat_mode
	eor #$80
	sta repeat_mode
	bit current_page
	bmi +
	jsr show_repeat_mode
+ rts

show_repeat_mode
	bit repeat_mode
	bpl +

	ldx #<rpt_mode_on_txt
	ldy #>rpt_mode_on_txt
	jsr print_msg
	rts

+	ldx #<rpt_mode_off_txt
	ldy #>rpt_mode_off_txt
	jsr print_msg
rts

show_input_device
	ldx #<idev_pos
	ldy #>idev_pos
	jsr print_msg

	ldx #9
	cpx load_device
	bmi +
	lda #$20	; print a leading space if dev 8 or 9
	jsr CHROUT

+	ldx load_device
	ldy #0
	jsr print_uint16
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

	bit current_page
	bpl +
	jsr show_input_device
+ rts

show_sid_addr
	ldx #<sid_addr_pos
	ldy #>sid_addr_pos
	jsr print_msg

	lda stereo_sid_addr+1
	and #$0f
	jsr to_hex
	jsr CHROUT
	lda stereo_sid_addr
	lsr
	lsr
	lsr
	lsr
	jsr to_hex
	jsr CHROUT
	lda #$30 ; "0"
	jsr CHROUT
rts

change_sid_addr
	clc
	lda stereo_sid_addr
	adc #$20
	sta stereo_sid_addr
	bne .show2

	lda stereo_sid_addr+1
	cmp #$d4
	bne +
	!ifndef c128 {			; $d500-$d6ff reserved on C128
		lda #$d5
	} else {
		lda #$d7
	}
	bne .show

	!ifndef c128 {
	+ 	cmp #$d5
		bne +
		lda #$d6
		bne .show

	+ 	cmp #$d6
		bne +
		lda #$d7
		bne .show
	}

+ 	cmp #$d7
	bne +
	lda #$de
	bne .show

+ 	cmp #$de
	bne +
	lda #$20
	sta stereo_sid_addr		; $df00-$df1f is reserved for REU
	lda #$df
	bne .show

+ 	cmp #$df
	bne .show
	lda #$20
	sta stereo_sid_addr		; obviously, $d400-$d420 is reserved also :P
	lda #$d4

.show
	sta stereo_sid_addr+1
.show2
	bit current_page
	bpl +
	jsr show_sid_addr
+ rts

show_filter_setting
	ldx #<filter_setting_pos
	ldy #>filter_setting_pos
	jsr print_msg

	ldx #9
	cpx filter_setting
	bmi +
	lda #$20	; print a leading space if 0-9
	jsr CHROUT

+	ldx filter_setting
	ldy #0
	jsr print_uint16
rts

change_filter_setting
	inc filter_setting
	lda filter_setting
	cmp #16
	bne +
	lda #0
+	sta filter_setting
	bit current_page
	bpl +
	jsr show_filter_setting
+ rts

show_resonance_setting
	ldx #<resonance_setting_pos
	ldy #>resonance_setting_pos
	jsr print_msg

	ldx #9
	cpx resonance_setting
	bmi +
	lda #$20	; print a leading space if 0-9
	jsr CHROUT

+	ldx resonance_setting
	ldy #0
	jsr print_uint16
rts

change_resonance_setting
	inc resonance_setting
	lda resonance_setting
	cmp #16
	bne +
	lda #0
+	sta resonance_setting
	bit current_page
	bpl +
	jsr show_resonance_setting
+ rts

save_config
	!ifdef c128 {
		jsr set_dim_full_screen
	}

	ldx #<status_line_pos
	ldy #>status_line_pos
	jsr print_msg

	ldx #<saving_msg
	ldy #>saving_msg
	jsr print_msg

	lda config_filename_len
	ldx #<config_filename
	ldy #>config_filename
	jsr SETNAM
	!ifdef c128 {
		lda #0
		ldx #0
		jsr SETBNK
	}
	lda #0
	ldx boot_device
	ldy #0
	jsr SETLFS

	lda #<config_space
	sta save_addr
	lda #>config_space
	sta save_addr+1

	lda #save_addr
	ldx #<cfg_data_end
	ldy #>cfg_data_end
	jsr SAVE

	ldx #<status_line_pos
	ldy #>status_line_pos
	jsr print_msg

	ldx #<clear_status_line
	ldy #>clear_status_line
	jsr print_msg
rts

!ifdef c128 {
	set_dim_full_screen
		lda #0
		sta SCTOP
		lda #24
		sta SCBOT
		lda #0
		sta SCLF
		lda #79
		sta SCRT
	rts

	set_dim_left_pane
		lda #3
		sta SCTOP
		lda #19
		sta SCBOT
		lda #6
		sta SCLF
		lda #29
		sta SCRT
	rts

	set_dim_right_pane
		lda #2
		sta SCTOP
		lda #16
		sta SCBOT
		lda #33
		sta SCLF
		lda #73
		sta SCRT
	rts
}

mm_lo
	!byte <line_1
	!byte <line_2
	!byte <line_3
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_4_to_17_and_22
	!byte <lines_18_and_20
	!byte <line_19
	!byte <lines_18_and_20
	!byte <line_21
	!byte <lines_4_to_17_and_22
	!byte <line_23
	!byte <line_24

mm_hi
	!byte >line_1
	!byte >line_2
	!byte >line_3
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_4_to_17_and_22
	!byte >lines_18_and_20
	!byte >line_19
	!byte >lines_18_and_20
	!byte >line_21
	!byte >lines_4_to_17_and_22
	!byte >line_23
	!byte >line_24

rp_a_lo
	!byte <rt_txt_a_1
	!byte <rt_txt_a_2
	!byte <rt_txt_a_3
	!byte <rt_txt_a_4
	!byte <rt_txt_a_5
	!byte <rt_txt_a_6
	!byte <rt_txt_a_7
	!byte <rt_txt_a_8
	!byte <rt_txt_a_9
	!byte <rt_txt_a_10
	!byte <rt_txt_a_11
	!byte <rt_txt_a_12
	!byte <rt_txt_a_13
	!byte <rt_txt_a_14
	!byte <rt_txt_a_15

rp_a_hi
	!byte >rt_txt_a_1
	!byte >rt_txt_a_2
	!byte >rt_txt_a_3
	!byte >rt_txt_a_4
	!byte >rt_txt_a_5
	!byte >rt_txt_a_6
	!byte >rt_txt_a_7
	!byte >rt_txt_a_8
	!byte >rt_txt_a_9
	!byte >rt_txt_a_10
	!byte >rt_txt_a_11
	!byte >rt_txt_a_12
	!byte >rt_txt_a_13
	!byte >rt_txt_a_14
	!byte >rt_txt_a_15

rp_b_lo
	!byte <rt_txt_b_1
	!byte <rt_txt_b_2
	!byte <rt_txt_b_3
	!byte <rt_txt_b_4
	!byte <rt_txt_b_5
	!byte <rt_txt_b_6
	!byte <rt_txt_b_7
	!byte <rt_txt_b_8
	!byte <rt_txt_b_9
	!byte <rt_txt_b_10
	!byte <rt_txt_b_11
	!byte <rt_txt_b_12
	!byte <rt_txt_b_13

rp_b_hi
	!byte >rt_txt_b_1
	!byte >rt_txt_b_2
	!byte >rt_txt_b_3
	!byte >rt_txt_b_4
	!byte >rt_txt_b_5
	!byte >rt_txt_b_6
	!byte >rt_txt_b_7
	!byte >rt_txt_b_8
	!byte >rt_txt_b_9
	!byte >rt_txt_b_10
	!byte >rt_txt_b_11
	!byte >rt_txt_b_12
	!byte >rt_txt_b_13
