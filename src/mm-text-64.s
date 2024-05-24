line_1
	!text LOWER,NOSHIFTCOM,CLR,YEL," Modplay",LGRN," 64",RED," v",LRED,"2.0"
	!text WHT," - ",LBLU,"Amiga",CYAN," module",GRN," player",RETURN,0

line_2
	!byte WHT
	!fill 18," "
	!byte $b0
	!fill 20,$60
	!byte $ae
	!byte 0

line_3
	!byte $b0
	!fill 16,$60
	!byte $ae
	!byte $7d
	!fill 20," "
	!byte $7d
	!byte 0

lines_4_to_17_and_22
	!byte $7d
	!fill 16," "
	!byte $7d
	!byte $7d
	!fill 20," "
	!byte $7d
	!byte 0

lines_18_and_20
	!byte $7d
	!fill 16," "
	!byte $7d
	!byte $ab
	!fill 20,$60
	!byte $b3
	!byte 0

line_19
	!byte $7d
	!fill 16," "
	!byte $7d
	!byte $7d
	!fill 20," "
	!byte $7d
	!byte 0

line_21
	!byte $ab
	!fill 16,$60
	!byte $b3
	!byte $7d
	!fill 20," "
	!byte $7d
	!byte 0

line_23
	!byte $ad
	!fill 16,$60
	!byte $bd
	!byte $7d
	!fill 20," "
	!byte $7d
	!byte 0

line_24
	!fill 18," "
	!byte $ad
	!fill 20,$60
	!byte $bd
	!byte 0

!macro RT_PANE_MARGIN {
	!fill 19,RIGHT
}

rt_txt_a_1
	!byte HOME,DOWN,DOWN
	+RT_PANE_MARGIN
	!text GRN,"[",YEL,"Hm",GRN,"/",YEL,"Clr",GRN,"]"
	!text LGRY," Top/bottom",RETURN,0
rt_txt_a_2
	+RT_PANE_MARGIN
	!text RIGHT,GRN,"[",YEL,"Up",GRN,"/",YEL,"Dn",GRN,"]"
	!text LGRY," Scroll list",RETURN,0
rt_txt_a_3
	+RT_PANE_MARGIN
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F1",GRN,"]",LGRY," Load & Play",RETURN,0
rt_txt_a_4
	+RT_PANE_MARGIN
	!fill 5,RIGHT
	!text GRN,"[",YEL,"L",GRN,"]",LGRY," Load only",RETURN,0
rt_txt_a_5
	+RT_PANE_MARGIN
	!text GRN,RIGHT,"[",YEL,"Shf-L",GRN,"]",LGRY," By filename",RETURN,0
rt_txt_a_6
	+RT_PANE_MARGIN
	!fill 5,RIGHT
	!text GRN,"[",YEL,"P",GRN,"]",LGRY," Play cur.",RETURN,0
rt_txt_a_7
	+RT_PANE_MARGIN
	!fill 5,RIGHT
	!text GRN,"[",YEL,"S",GRN,"]",LGRY," Sample mode",RETURN,0
rt_txt_a_8
	+RT_PANE_MARGIN
	!text GRN,"[",YEL,"Return",GRN,"]",LGRY," Add to list",RETURN,0
rt_txt_a_9
	+RT_PANE_MARGIN
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F2",GRN,"]",LGRY," Play list",RETURN,0
rt_txt_a_10
	+RT_PANE_MARGIN
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F3",GRN,"]",LGRY," Play all",RETURN,0
rt_txt_a_11
	+RT_PANE_MARGIN
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F4",GRN,"]",LGRY," Repeat ",GRN,"(",RIGHT,")",RETURN,0
rt_txt_a_12
	+RT_PANE_MARGIN
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F5",GRN,"]",LGRY," Read dir.",RETURN,0
rt_txt_a_13
	+RT_PANE_MARGIN
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F6",GRN,"]",LGRY," Clear list",RETURN,0
rt_txt_a_14
	+RT_PANE_MARGIN
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F7",GRN,"]",LGRY," Here & down",RETURN,0
rt_txt_a_15
	+RT_PANE_MARGIN
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F8",GRN,"]",LGRY," Exit",RETURN,0


rt_txt_b_1
	!byte HOME,DOWN,DOWN
	+RT_PANE_MARGIN
	!text GRN,"[",YEL,"+",GRN,"/",YEL,"-",GRN,"]",LGRY," Page up/down",RETURN,0
rt_txt_b_2
	+RT_PANE_MARGIN
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"#",GRN,"]",LGRY," Device # "
	!text GRN,"(",RIGHT,RIGHT,")",RETURN,0
rt_txt_b_3
	+RT_PANE_MARGIN
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"D",GRN,"]",LGRY," Audio driver",RETURN,0
rt_txt_b_4
	+RT_PANE_MARGIN
	!fill 6,RIGHT
	!byte GRN,"("
	!fill 12,RIGHT
	!byte ")",RETURN,0
rt_txt_b_5
	+RT_PANE_MARGIN
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"M",GRN,"]",LGRY," RAM driver",RETURN,0
rt_txt_b_6
	+RT_PANE_MARGIN
	!fill 6,RIGHT
	!byte GRN,"("
	!fill 12,RIGHT
	!byte ")",RETURN,0
rt_txt_b_7
	+RT_PANE_MARGIN
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"A",GRN,"]",LGRY," SID adr ",GRN,"("
	!fill 4,RIGHT
	!byte ")",RETURN,0
rt_txt_b_8
	+RT_PANE_MARGIN
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"C",GRN,"]",LGRY," DAC adr ",GRN,"("
	!fill 4,RIGHT
	!byte ")",RETURN,0
rt_txt_b_9
	+RT_PANE_MARGIN
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"F",GRN,"]",LGRY," Filter "
	!text GRN,"(",RIGHT,RIGHT,")",RETURN,0
rt_txt_b_10
	+RT_PANE_MARGIN
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"R",GRN,"]",LGRY," Resonance "
	!text GRN,"(",RIGHT,RIGHT,")",RETURN,0
rt_txt_b_11
	+RT_PANE_MARGIN
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"$",GRN,"]",LGRY," View directory",RETURN,0
rt_txt_b_12
	+RT_PANE_MARGIN
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"@",GRN,"]",LGRY," DOS command",RETURN,0
rt_txt_b_13
	+RT_PANE_MARGIN
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"_",GRN,"]",LGRY," Save config",RETURN,0  ; "←"

rt_press_com_key_msg
	!byte HOME
	!fill 18,DOWN
	+RT_PANE_MARGIN
	!text GRN," [",YEL,"C=",GRN,"]",LGRY," Switch pages",0

rpt_mode_on_txt
	!byte HOME
	!fill 12,DOWN
	!fill 36,RIGHT
	!text WHT,"Y",0

rpt_mode_off_txt
	!byte HOME
	!fill 12,DOWN
	!fill 36,RIGHT
	!text LGRY,"N",0

idev_pos
	!byte HOME,DOWN,DOWN,DOWN
	!fill 35,RIGHT
	!byte WHT,0

sid_addr_pos
	!byte HOME
	!fill 8,DOWN
	!fill 34,RIGHT
	!text WHT,"D",0

filter_setting_pos
	!byte HOME
	!fill 10,DOWN
	!fill 33,RIGHT
	!byte WHT,0

resonance_setting_pos
	!byte HOME
	!fill 11,DOWN
	!fill 36,RIGHT
	!byte WHT,0

status_line_pos
	!byte HOME
	!fill 24,DOWN
	!byte 0

saving_msg
	!text LGRN,"Saving configuration...",0

clear_status_line
	!fill 39," "
	!byte 0

screen_line_link_table
	!byte $84,$84,$84,$84,$84
	!byte $84,$84,$85,$85,$85
	!byte $85,$85,$85,$86,$86
	!byte $86,$86,$86,$86,$86
	!byte $87,$87,$87,$87,$87,$87

loading_popup_top
	!byte HOME,WHT
	!fill 7,DOWN
	!fill 10,RIGHT
	!byte $ac
	!fill 18,$60
	!byte $bb,RETURN,0

loading_popup_mid
	!fill 10,RIGHT
	!text WHT,$7d
	!fill 18," "
	!byte DGRY,$7d,RETURN,0
	
loading_popup_bot
	!fill 10,RIGHT
	!byte WHT,$bc,DGRY
	!fill 18,$60
	!byte $be,RETURN,0

loading_popup_top_left_inside
	!byte HOME
	!fill 8,DOWN
	!fill 11,RIGHT
	!byte 0

loading_popup_next_line
	!byte RETURN
	!fill 11,RIGHT
	!byte 0

loading_msg
	!text DOWN,LGRN,"    Loading...",0

blocks_msg
	!text " blocks/",0

progress_bar_pos
	!byte HOME
	!fill 13,DOWN
	!fill 12,RIGHT
	!byte 0

progress_bar_frame
	!byte HOME,LGRY
	!fill 12,DOWN
	!fill 12,RIGHT
	!fill 16,$af
	!byte RETURN
	!fill 11,RIGHT
	!byte $aa
	!fill 16,RIGHT
	!byte $a5,RETURN
	!fill 12,RIGHT
	!fill 16,$b7
	!byte 0

