program_title
	!ifndef scpu {
		!text NOSHIFTCOM,CLR,YEL," Modplay",LGRN," 64",RED," v"
		!text LRED,version_major+$30,".",version_minor+$30
		!text WHT," - ",LBLU,"Amiga",CYAN," module",GRN," player",RETURN,0
	} else {
		!text NOSHIFTCOM,CLR,YEL,"Modplay",LGRN,"64",RED," v"
		!text LRED,version_major+$30,".",version_minor+$30
		!text WHT," - ",LBLU,"Amiga",CYAN," mod",GRN," player"
		!text LRED,"[",PUR,"SCPU",LRED,"]"
		!fill 6,LEFT
		!byte INST,RETURN,0
	}

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
	!text RIGHT,GRN,"[",YEL,"Up",GRN,"/",YEL,"Dn",GRN,"]"
	!text LGRY," Scroll list",RETURN,0
menu_text_load_and_play
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F1",GRN,"]",LGRY," Load & Play",RETURN,0
menu_text_play_loaded
	!fill 5,RIGHT
	!text GRN,"[",YEL,"P",GRN,"]",LGRY," Play current",RETURN,0
menu_text_play_loaded_b
	!fill 9,RIGHT
	!text "loaded file",RETURN,0
menu_text_add_to_list
	!text GRN,"[",YEL,"Return",GRN,"]",LGRY," Add to list",RETURN,0
menu_text_play_list
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F2",GRN,"]",LGRY," Play list",RETURN,0
menu_text_play_all
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F3",GRN,"]",LGRY," Play all",RETURN,0
menu_text_repeat
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F4",GRN,"]",LGRY," Repeat",RETURN,0
menu_text_read_dir
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F5",GRN,"]",LGRY," Load new",RETURN,0
menu_text_read_dir_b
	!fill 9,RIGHT
	!text "directory",RETURN,0
menu_text_clear_playlist
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F6",GRN,"]",LGRY," Clear list",RETURN,0
menu_text_play_from_here
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F7",GRN,"]",LGRY," Play from",RETURN,0
menu_text_play_from_here_b
	!fill 9,RIGHT
	!text "highlighted",RETURN,0
menu_text_exit
	!fill 4,RIGHT
	!text GRN,"[",YEL,"F8",GRN,"]",LGRY," Exit",RETURN,0


menu_text_up_down_gray
	!text DGRY,RIGHT,"[Up/Dn] Scroll list",RETURN,0
menu_text_load_gray
	!fill 4,RIGHT
	!text DGRY,"[F1] Load & Play",RETURN,0
menu_text_play_loaded_gray
	!fill 5,RIGHT
	!text DGRY,"[P] Play current",RETURN,0
menu_text_play_loaded_gray_b
	!fill 9,RIGHT
	!text "loaded file",RETURN,0
menu_text_add_to_list_gray
	!text DGRY,"[Return] Add to list",RETURN,0
menu_text_play_list_gray
	!fill 4,RIGHT
	!text DGRY,"[F2] Play list",RETURN,0
menu_text_play_all_gray
	!fill 4,RIGHT
	!text DGRY,"[F3] Play all",RETURN,0
menu_text_repeat_gray
	!fill 4,RIGHT
	!text DGRY,"[F4] Repeat",RETURN,0
menu_text_clear_playlist_gray
	!fill 4,RIGHT
	!text DGRY,"[F6] Clear list",RETURN,0
menu_text_play_from_here_gray
	!fill 4,RIGHT
	!text DGRY,"[F7] Play from",RETURN,0
menu_text_play_from_here_gray_b
	!fill 9,RIGHT
	!text "highlighted",RETURN,0

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
	!text "name/pattern",RETURN,0
menu_text_sample_mode
	!text GRN,RIGHT,"[",YEL,"Shf-P",GRN,"]",LGRY," Sngl sample",RETURN,0
menu_text_sample_mode_b
	!fill 9,RIGHT
	!text "player mode",RETURN,0
menu_text_device_number
	!byte RIGHT,RIGHT
	!text GRN,"   [",YEL,"#",GRN,"]",LGRY," Change input",RETURN,0
menu_text_device_number_b
	!fill 9,RIGHT
	!text "device",RETURN,0
menu_text_view_dir
	!byte RIGHT,RIGHT
	!text GRN,"   [",YEL,"$",GRN,"]",LGRY," View disk",RETURN,0
menu_text_view_dir_b
	!fill 9,RIGHT
	!text "directory",RETURN,0
menu_text_dos_cmd
	!byte RIGHT,RIGHT
	!text GRN,"   [",YEL,"@",GRN,"]",LGRY," Send DOS",RETURN,0
menu_text_dos_cmd_b
	!fill 9,RIGHT
	!text "commands",RETURN,0

menu_txt_home_clr_gray
	!text DGRY,"[Hm/Clr] Top/bottom",RETURN,0
menu_text_page_up_down_gray
	!text DGRY,"   [+/-] Page up/down",RETURN,0
menu_text_load_only_gray
	!fill 5,RIGHT
	!text DGRY,"[L] Load only",RETURN,0
menu_text_sample_mode_gray
	!text DGRY,RIGHT,"[Shf-P] Sngl sample",RETURN,0
menu_text_sample_mode_gray_b
	!fill 8,RIGHT
	!text DGRY,RIGHT,"player mode",RETURN,0

;##### Menu page C

menu_text_audio_driver
	!text RIGHT,GRN,"[",YEL,"D",GRN,"]",LGRY," Audio driver",RETURN,RETURN,0
menu_text_ram_driver
	!text RIGHT,GRN,"[",YEL,"M",GRN,"]",LGRY," RAM driver",RETURN,RETURN,0
menu_text_sid_addr
	!text RIGHT,GRN,"[",YEL,"A",GRN,"]",LGRY," Stereo SID",RETURN,0
menu_text_sid_addr_b
	!fill 5,RIGHT
	!text "address",RETURN,0
menu_text_dac_addr
	!text RIGHT,GRN,"[",YEL,"A",GRN,"]",LGRY," DigiMAX/DAC",RETURN,0
menu_text_dac_addr_b
	!fill 5,RIGHT
	!text "address",RETURN,0
menu_text_stereo
	!text RIGHT,GRN,"[",YEL,"S",GRN,"]",LGRY," Stereo",RETURN,0
menu_text_filter
	!text RIGHT,GRN,"[",YEL,"F",GRN,"]",LGRY," Filter",RETURN,0
menu_text_dithering
	!text RIGHT,GRN,"[",YEL,"T",GRN,"]",LGRY," Dithering",RETURN,0
menu_text_enable_screen
	!text RIGHT,GRN,"[",YEL,"E",GRN,"]",LGRY," Enable player",RETURN,0
menu_text_enable_screen_b
	!fill 5,RIGHT
	!text "screen",RETURN,0
menu_text_save_config
	!text RIGHT,GRN,"[",YEL,"_",GRN,"]",LGRY," Save config",RETURN,0  ; "🠜"

menu_text_sid_addr_gray
	!text RIGHT,DGRY,"[A] Stereo SID",RETURN,0
menu_text_sid_addr_gray_b
	!fill 5,RIGHT
	!text "address (N/A)",RETURN,0

; ##### Menu etc.

mode_on_txt
	!text GRN,"(",WHT,"On ",GRN,")",0
mode_off_txt
	!text GRN,"(",LGRY,"Off",GRN,")",0
na_msg
	!text DGRY,"(N/A)",0

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

mini_popup_next_line
	!byte $81,RETURN
	!byte 11,RIGHT
	!byte 0

loading_msg
	!text LGRN,"    Loading...",0

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

audio_driver_1_txt
	!text "SID 4-bit",0
audio_driver_2_txt
	!text "SID Mahoney",0
audio_driver_3_txt
	!text "DAC 8-bit",0

ram_driver_0_txt
	!text "17xx REU",0

user_msg
	!text "UserP",0

pl_size_msg
	!TEXT LGRN,"Size: ",0

kb_msg
	!text "kB",0

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
	!text DOWN,RIGHT,RIGHT,RIGHT,RED,"Unknown file",RETURN,0

dirname_background
	!byte $82,RVSON,CYAN
	!byte 16," "
	!byte 16,LEFT
	!byte 0

choose_audio_msg
	!byte $81,HOME
	!byte 10,DOWN
	!byte 14,RIGHT
	!byte $80+14
		!text CYAN,"Choose audio",RETURN
	!byte 17,RIGHT
	!byte $89
		!text "driver:",RETURN
	!byte 0

choose_memory_msg
	!byte $81,HOME
	!byte 10,DOWN
	!byte 13,RIGHT
	!byte $80+15
		!text CYAN,"Choose memory",RETURN
	!byte 17,RIGHT
	!byte $89
		!text "driver:",RETURN,RETURN
	!byte 0

choose_aud_driver_pos
	!byte RETURN
	!fill 13,RIGHT
	!byte 0

choose_mem_driver_pos
	!byte RETURN
	!fill 14,RIGHT
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

!ct raw {
	sample_player_msg_ascii
		!fill 3,RIGHT
		!text CYAN,"Sample player goes here",RETURN,RETURN
		!fill 13,RIGHT
		!byte 0

	between_songs_msg_ascii
		!text CYAN,"Loader here",RETURN,RETURN
		!fill 20,RIGHT
		!byte 0

	main_player_now_playing_msg_ascii
		!fill 10,RIGHT
		!text CYAN,"Now playing:",RETURN,RETURN
		!byte 0

	main_player_file_msg_ascii
		!fill 6,RIGHT
		!text "Filename: ",LBLU
		!byte 0

	main_player_title_msg_ascii
		!fill 9,RIGHT
		!text CYAN,"Title: ",LBLU
		!byte 0

	tracker_name_msg_soundtracker_ascii
		!text "Soundtracker",0

	tracker_name_msg_protracker_ascii
		!text "Protracker",0

	tracker_name_msg_startrekker_ascii
		!text "StarTrekker",0

	tracker_name_msg_fasttracker_ascii
		!text "FastTracker",0

	main_player_hline_ascii
		!fill 2,RIGHT
		!fill 36,$02
		!byte RETURN
		!byte 0

	main_player_song_pos_pat_msg_ascii
		!fill 5,RIGHT
		!text CYAN,"Song Pos: ",LBLU,"  ",CYAN,"/",LBLU,"  "
		!text BLUE," -- "
		!text CYAN,"Pattern: ",LBLU,"  ",RETURN
		!byte 0

	main_player_row_speed_time_ascii
		!fill 2,RIGHT
		!text CYAN,"Row: ",LBLU,"   ",BLUE,"- "
		!text CYAN,"Speed: ",LBLU,"  ",CYAN,"/",LBLU,"   ",BLUE,"- "
		!text CYAN,"Time: ",LBLU,"00",CYAN,":",LBLU,"00",RETURN
		!byte 0

	main_player_regen_tables_msg_ascii
		!byte HOME
		!fill 14,DOWN
		!fill 8,RIGHT
		!text YEL,"A player setting altered",RETURN
		!fill 5,RIGHT
		!text "the sample rate, re-generating",RETURN
		!fill 8,RIGHT
		!text "pitch and tempo tables...",RETURN,0

	main_player_keys_msg_ascii
		!fill 3,RIGHT
		!text LBLU,"[",CYAN,"Spc",LBLU,"] ",CYAN,"Skip  "
		!text LBLU,"[",CYAN,"F7",LBLU,"] ",CYAN,"Quit  "
		!text LBLU,"[",CYAN,"1",LBLU,"-",CYAN,"4",LBLU,"] ",CYAN,"Mute"
		!byte 0
}

main_player_regen_erase_tables_msg
	!byte 3,UP
	!byte 2,RIGHT
	!byte 36," "
	!byte $80+1,RETURN
	!byte 2,RIGHT
	!byte 36," "
	!byte $80+1,RETURN
	!byte 2,RIGHT
	!byte 36," "
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

main_player_regen_tables_msg
	!byte RETURN
	!fill 8,RIGHT
	!text YEL,"A player setting altered",RETURN
	!fill 5,RIGHT
	!text "the sample rate, re-generating",RETURN
	!fill 8,RIGHT
	!text "pitch and tempo tables...",RETURN,0

build_no_msg
	!text GRN,"[Build #",0

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
