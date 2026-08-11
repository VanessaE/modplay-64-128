program_version
	!text version_major+$30,".",version_minor+$30,0

	!ifdef scpu {
		program_title
			!text NOSHIFTCOM,CLR,YEL,"Modplay",LGRN,"64",RED," v",LRED,0
		program_title_b
			!text WHT," - ",LBLU,"Amiga",CYAN," mod",GRN," player"
			!text LRED,"[",PUR,"SCPU",LRED,"]"
			!fill 6,LEFT
			!byte INST,RETURN,0
	} else ifdef c64u {
		program_title
			!text NOSHIFTCOM,CLR,YEL,"Modplay",LGRN,"64",RED," v",LRED,0
		program_title_b
			!text WHT," - ",LBLU,"Amiga",CYAN," mod",GRN," player",0
		program_title_edition_c64u
			!text LRED,"[",CYAN,"C64U",LRED,"]"
			!fill 6,LEFT
			!byte INST,RETURN,0
		program_title_edition_u64
			!text LRED," [",YEL,"U64",LRED,"]",RETURN,0
	} else {
		program_title
			!text NOSHIFTCOM,CLR,YEL," Modplay",LGRN," 64",RED," v",LRED,0
		program_title_b
			!text WHT," - ",LBLU,"Amiga",CYAN," module",GRN," player",RETURN,0	}

; these are all RLE-encoded for the print_msg_rle* function

line_2
	!byte $81,WHT
	!byte 17,RIGHT
	!byte $81,$b0
	!byte 21,$60
	!byte $81,$ae
	!byte 0

line_3
	!byte $81,$b0
	!byte 16,$60
	!byte $81,$b3
	!byte 21,RIGHT
	!byte $81,$7d
	!byte 0

lines_4_to_17_and_22
	!byte $81,$7d
	!byte 16,RIGHT
	!byte $81,$7d
	!byte 21,RIGHT
	!byte $81,$7d
	!byte 0

lines_18_and_20
	!byte $81,$7d
	!byte 16,RIGHT
	!byte $81,$ab
	!byte 21,$60
	!byte $81,$b3
	!byte 0

line_19
	!byte $81,$7d
	!byte 16,RIGHT
	!byte $80+28
		!byte $7d
		!text GRN,RIGHT,RIGHT,"[",YEL,"C=",GRN,"]",LGRY," Switch pages"
		!byte RIGHT,RIGHT,WHT,$7d
	!byte 0

line_21
	!byte $81,$ab
	!byte 16,$60
	!byte $81,$b3
	!byte 21,RIGHT
	!byte $81,$7d
	!byte 0

line_23
	!byte $81,$ad
	!byte 16,$60
	!byte $81,$b3
	!byte 21,RIGHT
	!byte $81,$7d
	!byte 0

line_24
	!byte 17,RIGHT
	!byte $81,$ad
	!byte 21,$60
	!byte $81,$bd
	!byte 0

prepend_right_margin
	!byte 18,RIGHT
	!byte 0

prepend_top_margin
	!byte HOME,DOWN,DOWN
	!byte 0

;##### Menu page A

menu_text_up_down
	!text GRN,"[",YEL,"CRSR",GRN,"]"
	!text LGRY," Scroll list",RETURN,0
menu_text_load_and_play
	!text GRN,"[",YEL,"Rtrn",GRN,"]",LGRY," Load & Play",RETURN,0
menu_text_or_change_dir
	!fill 7,RIGHT
	!text GRN,LGRY,"or change dir.",RETURN,0
menu_text_play_loaded
	!fill 3,RIGHT
	!text GRN,"[",YEL,"P",GRN,"]",LGRY," Play currently",RETURN,0
menu_text_play_loaded_b
	!fill 7,RIGHT
	!text LGRY,"loaded file",RETURN,0
menu_text_add_to_list
	!text GRN,RIGHT,"[",YEL,"Spc",GRN,"]",LGRY," Add to playlst",RETURN,0
menu_text_play_list
	!fill 2,RIGHT
	!text GRN,"[",YEL,"F2",GRN,"]",LGRY," Run playlist",RETURN,0
menu_text_play_all
	!fill 2,RIGHT
	!text GRN,"[",YEL,"F3",GRN,"]",LGRY," Play all files",RETURN,0
menu_text_repeat
	!fill 2,RIGHT
	!text GRN,"[",YEL,"F4",GRN,"]",LGRY," Repeat",RETURN,0
menu_text_read_dir
	!fill 2,RIGHT
	!text GRN,"[",YEL,"F5",GRN,"]",LGRY," Reload file",RETURN,0
menu_text_read_dir_b
	!fill 7,RIGHT
	!text LGRY,"list",RETURN,0
menu_text_clear_playlist
	!fill 2,RIGHT
	!text GRN,"[",YEL,"F6",GRN,"]",LGRY," Clear playlist",RETURN,0
menu_text_play_from_here
	!fill 2,RIGHT
	!text GRN,"[",YEL,"F7",GRN,"]",LGRY," Play all from",RETURN,0
menu_text_play_from_here_b
	!fill 7,RIGHT
	!text LGRY,"highlighted",RETURN,0
menu_text_exit
	!fill 2,RIGHT
	!text GRN,"[",YEL,"F8",GRN,"]",LGRY," Quit",RETURN,0

;##### Menu page B

menu_txt_home_clr
	!text GRN,"[",YEL,"Hm",GRN,"/",YEL,"Clr",GRN,"]"
	!text LGRY," Top/bottom",RETURN,0
menu_text_page_up_down
	!text GRN,"   [",YEL,"+",GRN,"/",YEL,"-",GRN,"]",LGRY," Page up/down",RETURN,0
menu_text_load_only
	!fill 5,RIGHT
	!text GRN,"[",YEL,"L",GRN,"]",LGRY," Load only",RETURN,0
menu_text_load_filename
	!text GRN,RIGHT,"[",YEL,"Shf-L",GRN,"]",LGRY," Load by file",RETURN,0
menu_text_load_filename_b
	!fill 9,RIGHT
	!text LGRY,"name/pattern",RETURN,0
menu_text_device_number
	!byte RIGHT,RIGHT
	!text GRN,"   [",YEL,"#",GRN,"]",LGRY," Change input",RETURN,0
menu_text_device_number_b
	!fill 9,RIGHT
	!text LGRY,"device",RETURN,0
menu_text_view_dir
	!byte RIGHT,RIGHT
	!text GRN,"   [",YEL,"$",GRN,"]",LGRY," View disk",RETURN,0
menu_text_view_dir_b
	!fill 9,RIGHT
	!text LGRY,"directory",RETURN,0
menu_text_dos_cmd
	!byte RIGHT,RIGHT
	!text GRN,"   [",YEL,"@",GRN,"]",LGRY," Send DOS",RETURN,0
menu_text_dos_cmd_b
	!fill 9,RIGHT
	!text LGRY,"commands",RETURN,0
menu_text_info_popup
	!fill 4,RIGHT
	!text RIGHT,GRN,"[",YEL,"I",GRN,"]",LGRY," System and",RETURN,0
menu_text_info_popup_b
	!fill 9,RIGHT
	!text LGRY,"Song Info",RETURN,0

;##### Menu page C

menu_text_audio_driver
	!text RIGHT,GRN,"[",YEL,"D",GRN,"]",LGRY," Audio driver",RETURN,RETURN,0
menu_text_sid_addr
	!text RIGHT,GRN,"[",YEL,"A",GRN,"]",LGRY," Stereo SID",RETURN,0
menu_text_sid_addr_b
	!fill 5,RIGHT
	!text LGRY,"address",RETURN,0
menu_text_dac_addr
	!text RIGHT,GRN,"[",YEL,"A",GRN,"]",LGRY," DigiMAX/DAC",RETURN,0
menu_text_dac_addr_b
	!fill 5,RIGHT
	!text LGRY,"address",RETURN,0
menu_text_stereo
	!text RIGHT,GRN,"[",YEL,"S",GRN,"]",LGRY," Stereo",RETURN,0
menu_text_filter
	!text RIGHT,GRN,"[",YEL,"F",GRN,"]",LGRY," Filter",RETURN,0
menu_text_dithering
	!text RIGHT,GRN,"[",YEL,"T",GRN,"]",LGRY," Dithering",RETURN,0

!ifdef badlines_exist {
	menu_text_enable_screen
		!text RIGHT,GRN,"[",YEL,"E",GRN,"]",LGRY," Enable player",RETURN,0
	menu_text_enable_screen_b
		!fill 5,RIGHT
		!text LGRY,"screen",RETURN,0
}

menu_text_enable_filter
	!text RIGHT,GRN,"[",YEL,"F",GRN,"]",LGRY," Filtering",RETURN,0
menu_text_save_config
	!text RIGHT,GRN,"[",YEL,"_",GRN,"]",LGRY," Save config",RETURN,0  ; "🠜"

; ##### System info popup

info_popup_msg
	!fill 9,RIGHT
	!text YEL,"System Information",RETURN,RETURN
	!text RIGHT,RIGHT,RIGHT,"Platform:",RETURN
	!text RIGHT,RIGHT,RIGHT,"Left SID:",RETURN
	!text RIGHT,RIGHT,RIGHT,"Right SID:",RETURN
	!text RIGHT,RIGHT,RIGHT,"Files in current list:",RETURN
	!text RIGHT,RIGHT,RIGHT,"Expansion RAM size:",RETURN
	!text RIGHT,RIGHT,RIGHT,"Expansion RAM usage:",RETURN
	!fill 8,DOWN
	!text RIGHT,RIGHT,RIGHT,"Build ID:",0

!ifdef c64u {
	info_popup_platform_computer_c64u
		!text LGRN,"C64 Ultimate",0
	info_popup_platform_computer_u64
		!text LGRN,"Ultimate64",0
} else ifdef scpu {
	info_popup_platform_computer
		!text LGRN,"C64 + SuperCPU ",0
} else {
	info_popup_platform_computer
		!text LGRN,"C64",0
}

info_popup_6581_msg
	!text LGRN,"6581",0

info_popup_8580_msg
	!text LGRN,"8580",0

; ##### Menu misc.

mode_on_msg
	!text GRN,"(",WHT,"On",GRN,") ",0
mode_off_msg
	!text GRN,"(",LGRY,"Off",GRN,")",0

mode_always_on_msg
	!text "(Always)",0
na_msg
	!text DGRY,"(N/A)",0

not_present_msg
	!text DGRY,"not present",0
kb_msg
	!text "kB",0

; others

saving_msg
	!fill 5,RIGHT
	!text DOWN,LGRN,"Saving",RETURN,0
saving_msg_b
	!text RIGHT,"configuration...",0

screen_line_link_table
	!byte $84,$84,$84,$84,$84
	!byte $84,$84,$85,$85,$85
	!byte $85,$85,$85,$86,$86
	!byte $86,$86,$86,$86,$86
	!byte $87,$87,$87,$87,$87,$87

mini_popup_top_line
	!byte $81,HOME
	!byte 8,DOWN
	!byte 0

mini_popup_next_line
	!byte $81,RETURN
	!byte 11,RIGHT
	!byte 0

medium_popup_top_line
	!byte $81,HOME
	!byte 4,DOWN
	!byte 0

player_popup_top_line
	!byte $81,HOME
	!byte 3,DOWN
	!byte 0

medium_popup_next_line
	!byte $81,RETURN
	!byte 2,RIGHT
	!byte 0

player_popup_next_line
	!byte $81,RETURN
	!byte 2,RIGHT
	!byte 0

loading_msg
	!text LGRN,"    Loading...",0

file_too_large_msg
	!text RIGHT,RED,"This file needs",RETURN
	!fill 11,RIGHT
	!text "more expansion RAM",RETURN
	!fill 11,RIGHT
	!text "than is available.",RETURN,RETURN
	!fill 13,RIGHT
	!text "Load aborted.",RETURN,RETURN
	!fill 13,RIGHT
	!byte 0

blocks_msg
	!text " blocks/",0

dos_command_msg
	!fill 6,RIGHT
	!text CYAN,"Enter DOS command:",0

filename_req_msg
	!fill 3,RIGHT
	!text CYAN,"Enter filename/pattern:",0

scanning_dir_msg
	!fill 5,RIGHT
	!text DOWN,LGRN,"Scanning",RETURN
	!fill 14,RIGHT
	!text "directory...",RETURN,RETURN
	!fill 15,RIGHT
	!text "found #",0

choose_audio_msg
	!byte $81,HOME
	!byte 9,DOWN
	!byte 14,RIGHT
	!byte $80+14
		!text CYAN,"Choose audio",RETURN
	!byte 17,RIGHT
	!byte $89
		!text "driver:",RETURN
	!byte 0

choose_aud_driver_pos
	!byte RETURN
	!fill 13,RIGHT
	!byte 0

audio_driver_1_txt
	!text "SID 4-bit",0
audio_driver_2_txt
	!text "SID Mahoney",0
audio_driver_3_txt
	!text "8-bit DAC",0
audio_driver_4_txt
	!text "DigiMAX Mk1",0
audio_driver_5_txt
	!text "DigiMAX Mk2",0

ram_driver_0_txt
	!text "17xx REU",0

user_msg
	!text "UserP",0

pl_size_msg
	!TEXT LGRN,"Size: ",0

erase_size_field_msg
	!byte 16," "
	!byte 16,LEFT
	!byte 0

no_list_loaded_msg
	!byte $81,HOME
	!byte 11,DOWN
	!byte $80+18
		!text RIGHT,PUR,"[No list loaded]"
	!byte 0

no_file_loaded_msg
	!byte $81,HOME
	!byte 21,DOWN
	!byte 19,RIGHT
	!byte $80+20
		!text LBLU,"[No file is loaded]"
	!byte 0

for_instr_list_msg
	!text " for i"
instr_list_msg
	!text "nstrument list"
	!byte 0

more_msg
	!text RETURN,RETURN
	!fill 16,RIGHT
	!text LGRN,"* More *",0

current_file_tracks_msg
	!text LBLU," tracks / ",CYAN,0

current_file_samples_msg
	!text LBLU," samples",0

current_file_song_pos_msg
	!text LBLU," song pos / ",CYAN,0

current_file_patterns_msg
	!text LBLU," patterns ",0

tracker_name_msg_soundtracker
	!text "Soundtracker",0

tracker_name_msg_protracker
	!text "Protracker",0

tracker_name_msg_startrekker
	!text "StarTrekker",0

tracker_name_msg_fasttracker
	!text "FastTracker",0

drive_loader_check_msg
	!byte $81,HOME
	!byte 11,DOWN
	!byte 14,RIGHT
	!byte $80+14
		!text LGRN,"One moment,",RETURN,RETURN
	!byte 12,RIGHT
	!byte $80+17
		!text "testing loader..."
	!byte 0

unknown_file_msg
	!text RED,"Unknown file",0

dirname_background
	!byte $82,RVSON,CYAN
	!byte 16," "
	!byte 16,LEFT
	!byte 0

between_songs_msg
	!byte 20,RIGHT
	!byte $80+14
		!text CYAN,"Loader here",RETURN,RETURN
	!byte 20,RIGHT
	!byte 0

loader_erase_kbs_msg
	!byte GRN
	!fill 11," "
	!fill 11,LEFT
	!byte 0

loader_kbs_msg
	!text LGRN," kB/sec",0

dir_window_left_margin
	!fill 5,RIGHT
	!byte 0

status_line_pos
	!text HOME
	!fill 24,DOWN
	!byte 0

sample_player_msg
	!fill 3,RIGHT
	!text CYAN,"Sample player goes here",RETURN,RETURN
	!fill 13,RIGHT
	!byte 0

main_player_now_playing_msg
	!text LGRN,"Now playing"
	!byte 0

main_player_of_msg
	!text " of "
	!byte 0

main_player_file_msg
	!fill 6,RIGHT
	!text CYAN,"Filename: ",LBLU
	!byte 0

main_player_title_msg
	!fill 9,RIGHT
	!text CYAN,"Title: ",LBLU
	!byte 0

main_player_hline
	!fill 2,RIGHT
	!fill 36,$60
	!byte RETURN
	!byte 0

main_player_song_pos_pat_msg
	!fill 3,RIGHT
	!text CYAN,"Song Pos: ",LBLU,"  ",BLUE,"/",LBLU,"   "
	!text CYAN,"Patt: ",LBLU,"   "
	!text CYAN,"Trks: ",LBLU," ",BLUE,"/",LBLU,"4",RETURN
	!byte 0

main_player_row_speed_time
	!fill 2,RIGHT
	!text CYAN,"Row: ",LBLU,"   ",BLUE,"- "
	!text CYAN,"Speed: ",LBLU,"  ",BLUE,"/",LBLU,"   ",BLUE,"- "
	!text CYAN,"Time: ",LBLU,"00",BLUE,":",LBLU,"00",RETURN
	!byte 0

main_player_regen_tables_msg
	!byte RETURN
	!fill 8,RIGHT
	!text YEL,"A player setting altered",RETURN
	!fill 5,RIGHT
	!text "the sample rate, re-generating",RETURN
	!fill 8,RIGHT
	!text "pitch and tempo tables...",RETURN,0

main_player_keys_msg
	!fill 4,RIGHT
	!text LBLU,"[",LGRN,"F7",LBLU,"] ",CYAN,"Skip "
	!text LBLU,"[",LGRN,"Stop",LBLU,"] ",CYAN,"Quit "
	!text LBLU,"[",LGRN,"1",GRN,"-",LGRN,"4",LBLU,"] ",CYAN,"Mute",RETURN
	!fill 2,RIGHT
	!text LBLU,"[",LGRN,"Spc",LBLU,"] ",CYAN,"Pause "
	!text LBLU,"[",LGRN,"P",GRN,"/",LGRN,"N",LBLU,"] "
	!text CYAN,"Pr",LBLU,"/",CYAN,"Nx Pat "
	!text LBLU,"[",LGRN,"V",LBLU,"] ",CYAN,"Viz."
	!byte 0

paused_msg
	!byte $81,HOME
	!byte visualizer_screen_row+1, DOWN
	!byte visualizer_screen_column+13, RIGHT
	!byte $80+2,WHT,$ac
	!byte 8,$60
	!byte $80+2,$bb,RETURN
	!byte visualizer_screen_column+13, RIGHT
	!byte $80+13
		!text $7d,YEL," Paused ",MGRY,$7d,RETURN
	!byte visualizer_screen_column+13, RIGHT
	!byte $80+2,MGRY,$bc
	!byte 8,$60
	!byte $81,$be
	!byte 0

!ifdef scpu {
	turn_turbo_on_msg
		!byte DOWN
		!fill 4,RIGHT
		!text YEL,"Please flip",RETURN
		!fill 11,RIGHT
		!text " the turbo switch",RETURN
		!fill 11,RIGHT
		!text "to the ON position"
		!byte 0
}

dir_check_string
	!text "cd:blahdeblah",0

syntax_err_string
	!text "syntax error",0

up_to_parent_dir_string
	!text "[Up, parent dir]",0

item_is_directory_msg
	!text LBLU,"  [Directory]",0

mm_lo
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
