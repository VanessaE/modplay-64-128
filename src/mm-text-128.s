
line_1
	!text LOWER,NOSHIFTCOM,HOME,TAB,TAB,RIGHT,YEL," Modplay"
	!text LGRN," 128",RED," version",LRED," 2.0",WHT," - "
	!text LBLU,"Amiga",CYAN," module",GRN," player",RETURN,0

line_2
	!byte WHT
	!fill 4,TAB
	!byte $b0
	!fill 41,$60
	!byte $ae,RETURN
	!byte 0

line_3
	!fill 5,RIGHT
	!byte $b0
	!fill 24,$60
	!byte $ae," ",$7d
	!fill 5,TAB
	!byte RIGHT,RIGHT
	!byte $7d,RETURN
	!byte 0

lines_4_to_17_and_22
	!fill 5,RIGHT
	!byte $7d
	!byte TAB,TAB,TAB
	!fill 6,RIGHT
	!byte $7d," ",$7d
	!fill 5,TAB
	!byte RIGHT,RIGHT
	!byte $7d,RETURN
	!byte 0

lines_18_and_20
	!fill 5,RIGHT
	!byte $7d
	!byte TAB,TAB,TAB
	!fill 6,RIGHT
	!byte $7d," ",$ab
	!fill 41,$60
	!byte $b3,RETURN
	!byte 0

line_19
	!fill 5,RIGHT
	!byte $7d
	!byte TAB,TAB,TAB
	!fill 6,RIGHT
	!byte $7d," ",$7d
	!fill 5,TAB
	!byte RIGHT,RIGHT
	!byte $7d,RETURN
	!byte 0

line_21
	!fill 5,RIGHT
	!byte $ab
	!fill 24,$60
	!byte $b3," ",$7d
	!fill 5,TAB
	!byte RIGHT,RIGHT
	!byte $7d,RETURN
	!byte 0

line_23
	!fill 5,RIGHT
	!byte $ad
	!fill 24,$60
	!byte $bd," ",$7d
	!fill 5,TAB
	!byte RIGHT,RIGHT
	!byte $7d,RETURN
	!byte 0

line_24
	!fill 4,TAB
	!byte $ad
	!fill 41,$60
	!byte $bd,RETURN
	!byte 0

rt_txt_a_1
	!byte HOME,RIGHT
	!text GRN,"[",YEL,"Home",GRN,"/",YEL,"Clr",GRN,"]"
	!text LGRY," Top/bottom of file list",RETURN,0
rt_txt_a_2
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"Up",GRN,"/",YEL,"Down",GRN,"]"
	!text LGRY," Scroll file list by 1 item",RETURN,0
rt_txt_a_3
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F1",GRN,"]",LGRY," Load and play file",RETURN,0
rt_txt_a_4
	!fill 8,RIGHT
	!text GRN,"[",YEL,"L",GRN,"]",LGRY," Load file (but do not play)",RETURN,0
rt_txt_a_5
	!fill 4,RIGHT
	!text GRN,"[",YEL,"Shf-L",GRN,"]",LGRY," Load by filename",RETURN,0
rt_txt_a_6
	!fill 8,RIGHT
	!text GRN,"[",YEL,"P",GRN,"]",LGRY," Play currently-loaded file",RETURN,0
rt_txt_a_7
	!fill 8,RIGHT
	!text GRN,"[",YEL,"S",GRN,"]",LGRY," Single-sample player mode",RETURN,0
rt_txt_a_8
	!fill 3,RIGHT
	!text GRN,"[",YEL,"Return",GRN,"]"
	!text LGRY," Add highlighted to playlist",RETURN,0
rt_txt_a_9
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F2",GRN,"]",LGRY," Play all items in playlist",RETURN,0
rt_txt_a_10
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F3",GRN,"]",LGRY," Play all items in directory",RETURN,0
rt_txt_a_11
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F4",GRN,"]",LGRY," Toggle song repeat "
	!text GRN,"(",RIGHT,RIGHT,RIGHT,")",RETURN,0
rt_txt_a_12
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F5",GRN,"]",LGRY," Read new directory",RETURN,0
rt_txt_a_13
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F6",GRN,"]",LGRY," Clear selections/playlist",RETURN,0
rt_txt_a_14
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F7",GRN,"]",LGRY," Play all from highlighted",RETURN,0
rt_txt_a_15
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F8",GRN,"]",LGRY," Exit",0


rt_txt_b_1
	!byte HOME
	!text GRN,"[",YEL,"+",GRN,"/",YEL,"-",GRN,"]"
	!text LGRY," Scroll file list one page",RETURN,0
rt_txt_b_2
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"#",GRN,"]",LGRY," Change input device "
	!text GRN,"(",RIGHT,RIGHT,")",RETURN,0
rt_txt_b_3
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"D",GRN,"]",LGRY," Change audio driver",RETURN,0
rt_txt_b_4
	!fill 6,RIGHT
	!text GRN,"("
	!fill 30,RIGHT
	!text ")",RETURN,0
rt_txt_b_5
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"M",GRN,"]",LGRY," Change RAM driver",RETURN,0
rt_txt_b_6
	!fill 6,RIGHT
	!text GRN,"("
	!fill 30,RIGHT
	!text ")",RETURN,0
rt_txt_b_7
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"A",GRN,"]",LGRY," Change stereo SID address "
	!text GRN,"(",WHT,"$",RIGHT,RIGHT,RIGHT,RIGHT,GRN,")",RETURN,0
rt_txt_b_8
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"C",GRN,"]",LGRY," Change DigiMAX/DAC address "
	!text GRN,"(",WHT,"$",RIGHT,RIGHT,RIGHT,RIGHT,GRN,")",RETURN,0
rt_txt_b_9
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"F",GRN,"]",LGRY," Change filter setting "
	!text GRN,"(",RIGHT,RIGHT,")",RETURN,0
rt_txt_b_10
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"R",GRN,"]",LGRY," Change resonance setting "
	!text GRN,"(",RIGHT,RIGHT,")",RETURN,0
rt_txt_b_11
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"$",GRN,"]",LGRY," View disk directory",RETURN,0
rt_txt_b_12
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"@",GRN,"]",LGRY," Send DOS commands",RETURN,0
rt_txt_b_13
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"_",GRN,"]",LGRY," Save configuration",RETURN,0  ; "←"

rt_press_com_key_msg
	!byte HOME
	!fill 18,DOWN
	!fill 34,RIGHT
	!text LGRY,TAB," Press",GRN," [",YEL,"C=",GRN,"]",LGRY," to switch pages",0

rpt_mode_on_txt
	!byte HOME
	!fill 10,DOWN
	!fill 3,TAB
	!fill 9,RIGHT
	!text WHT,"On ",0

rpt_mode_off_txt
	!byte HOME
	!fill 10,DOWN
	!fill 3,TAB
	!fill 9,RIGHT
	!text LGRY,"Off",0

idev_pos
	!byte HOME,DOWN
	!fill 3,TAB
	!fill 4,RIGHT
	!byte WHT,0

sid_addr_pos
	!byte HOME
	!fill 6,DOWN
	!fill 4,TAB
	!fill 3,RIGHT
	!text WHT,"D",0

filter_setting_pos
	!byte HOME
	!fill 8,DOWN
	!fill 3,TAB
	!fill 6,RIGHT
	!byte WHT,0

resonance_setting_pos
	!byte HOME
	!fill 9,DOWN
	!fill 4,TAB
	!byte RIGHT,WHT,0

status_line_pos
	!byte HOME
	!fill 24,DOWN
	!byte 0

saving_msg
	!text LGRN,"Saving configuration...",0

clear_status_line
	!fill 79," "
	!byte 0

dir_popup_top
	!byte HOME,WHT
	!fill 2,DOWN
	!byte TAB,TAB,TAB
	!byte $ac
	!fill 30,$60
	!byte $bb,RETURN,0

dir_popup_mid
	!byte TAB,TAB,TAB
	!text WHT,$a1
	!fill 30,RIGHT
	!byte DGRY,RVSON,$a1,RETURN,0

dir_popup_bot
	!byte TAB,TAB,TAB
	!byte WHT,$bc,DGRY
	!fill 30,$60
	!byte $be,RETURN,0

loading_popup_top
	!byte HOME,WHT
	!fill 7,DOWN
	!byte TAB,TAB,TAB
	!byte RIGHT,$ac
	!fill 30,$60
	!byte $bb," ",RETURN,0

loading_popup_mid
	!byte TAB,TAB,TAB
	!text WHT," ",$a1,"  "
	!fill 4,TAB
	!byte DGRY,RVSON,$a1,RVSOFF," ",RETURN,0

loading_popup_bot
	!byte TAB,TAB,TAB
	!byte RIGHT,WHT,$bc,DGRY
	!fill 30,$60
	!byte $be," ",RETURN,0

loading_popup_top_left_inside
	!byte HOME
	!fill 8,DOWN
	!fill 29,RIGHT
	!byte 0

loading_popup_next_line
	!byte RETURN
	!fill 29,RIGHT
	!byte 0

loading_msg
	!fill 8,RIGHT
	!text DOWN,LGRN,"Loading...",0

blocks_msg
	!text " blocks / ",0

progress_bar_pos
	!byte HOME
	!fill 13,DOWN
	!fill 33,RIGHT
	!byte 0

progress_bar_frame
	!byte HOME,LGRY
	!fill 12,DOWN
	!fill 33,RIGHT
	!fill 16,$a4
	!byte RETURN
	!fill 32,RIGHT
	!byte $aa
	!fill 16,RIGHT
	!byte $a5,RETURN
	!fill 33,RIGHT
	!fill 16,$a3
	!byte 0
