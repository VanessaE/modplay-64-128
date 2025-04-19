program_version
	!text " ",version_major+$30,".",version_minor+$30,0

	!ifndef scpu {
		program_title
			!text NOSHIFTCOM,HOME,TAB,TAB,RIGHT,YEL," Modplay"
			!text LGRN," 128",RED," version",LRED,0
		program_title_b
			!text WHT," - ",LBLU,"Amiga",CYAN," module",GRN," player",RETURN,0
	} else {
		program_title
			!text NOSHIFTCOM,HOME
			!fill 6,RIGHT
			!text YEL," Modplay",LGRN," 128",RED," version",LRED,0
		program_title_b
			!text WHT," - ",LBLU,"Amiga",CYAN," module",GRN," player"
			!text LRED,"   [",PUR,"SuperCPU",DPUR," edition",LRED,"]",RETURN,0
	}

; these are all RLE-encoded for the print_msg_rle* functions

line_2
	!byte $81,WHT
	!byte 3,TAB
	!byte 9,RIGHT
	!byte $81,$b0
	!byte 41,$60
	!byte $82,$ae,RETURN
	!byte 0

line_3
	!byte 4,RIGHT
	!byte $81,$b0
	!byte 26,$60
	!byte $83,$ae," ",$7d
	!byte 5,TAB
	!byte 3,RIGHT
	!byte $82,$7d,RETURN
	!byte 0

lines_4_to_17_and_21_to_22
	!byte 4,RIGHT
	!byte $81,$7d
	!byte 3,TAB
	!byte 7,RIGHT
	!byte $83,$7d," ",$7d
	!byte 5,TAB
	!byte 3,RIGHT
	!byte $82,$7d,RETURN
	!byte 0

lines_18_and_20
	!byte 4,RIGHT
	!byte $81,$7d
	!byte 3,TAB
	!byte 7,RIGHT
	!byte $83,$7d," ",$ab
	!byte 41,$60
	!byte $82,$b3,RETURN
	!byte 0

line_19
	!byte 4,RIGHT
	!byte $81,$7d
	!byte 3,TAB
	!byte 7,RIGHT
	!byte $80+38
		!byte $7d," ",$7d
		!text LGRY,TAB,"  Press",GRN," [",YEL,"C=",GRN,"]",LGRY," to switch pages"
		!byte TAB
	!byte 3,RIGHT
	!byte $83,WHT,$7d,RETURN
	!byte 0

line_23
	!byte 4,RIGHT
	!byte $81,$ad
	!byte 26,$60
	!byte $83,$bd," ",$7d
	!byte 5,TAB
	!byte 3,RIGHT
	!byte $82,$7d,RETURN
	!byte 0

line_24
	!byte 4,TAB
	!byte $82,RIGHT,$ad
	!byte 41,$60
	!byte $82,$bd,RETURN
	!byte 0


;##### Menu page A

menu_text_up_down
	!byte RIGHT,RIGHT
	!text GRN,"[",YEL,"Up",GRN,"/",YEL,"Down",GRN,"]"
	!text LGRY," Scroll file list by 1 item",RETURN,0
menu_text_load_and_play
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F1",GRN,"]",LGRY," Load and play file",RETURN,0
menu_text_play_loaded
	!fill 8,RIGHT
	!text GRN,"[",YEL,"P",GRN,"]",LGRY," Play currently-loaded file",RETURN,0
menu_text_add_to_list
	!fill 3,RIGHT
	!text GRN,"[",YEL,"Return",GRN,"]"
	!text LGRY," Add highlighted to playlist",RETURN,0
menu_text_play_list
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F2",GRN,"]",LGRY," Play all items in playlist",RETURN,0
menu_text_play_all
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F3",GRN,"]",LGRY," Play all items in directory",RETURN,0
menu_text_repeat
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F4",GRN,"]",LGRY," Toggle song repeat",RETURN,0
menu_text_read_dir
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F5",GRN,"]",LGRY," Load new directory",RETURN,0
menu_text_clear_playlist
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F6",GRN,"]",LGRY," Clear selections/playlist",RETURN,0
menu_text_play_from_here
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F7",GRN,"]",LGRY," Play all from highlighted",RETURN,0
menu_text_exit
	!fill 7,RIGHT
	!text GRN,"[",YEL,"F8",GRN,"]",LGRY," Exit",0


menu_text_up_down_gray
	!byte RIGHT,RIGHT
	!text DGRY,"[Up/Down] Scroll file list by 1 item",RETURN,0
menu_text_load_gray
	!fill 7,RIGHT
	!text DGRY,"[F1] Load and play file",RETURN,0
menu_text_play_loaded_gray
	!fill 8,RIGHT
	!text DGRY,"[P] Play currently-loaded file",RETURN,0
menu_text_add_to_list_gray
	!fill 3,RIGHT
	!text DGRY,"[Return] Add highlighted to playlist",RETURN,0
menu_text_play_list_gray
	!fill 7,RIGHT
	!text DGRY,"[F2] Play all items in playlist",RETURN,0
menu_text_play_all_gray
	!fill 7,RIGHT
	!text DGRY,"[F3] Play all items in directory",RETURN,0
menu_text_repeat_gray
	!fill 7,RIGHT
	!text DGRY,"[F4] Toggle song repeat",RETURN,0
menu_text_clear_playlist_gray
	!fill 7,RIGHT
	!text DGRY,"[F6] Clear selections/playlist",RETURN,0
menu_text_play_from_here_gray
	!fill 7,RIGHT
	!text DGRY,"[F7] Play all from highlighted",RETURN,0


;##### Menu page B

menu_txt_home_clr
	!text RIGHT,GRN,"[",YEL,"Home",GRN,"/",YEL,"Clr",GRN,"]"
	!text LGRY," Top/bottom of file list",RETURN,0
menu_text_page_up_down
	!fill 6,RIGHT
	!text GRN,"[",YEL,"+",GRN,"/",YEL,"-",GRN,"]"
	!text LGRY," Scroll file list one page",RETURN,0
menu_text_load_only
	!fill 8,RIGHT
	!text GRN,"[",YEL,"L",GRN,"]",LGRY," Load file (but do not play)",RETURN,0
menu_text_load_filename
	!fill 2,RIGHT
	!text GRN,"[",YEL,"Shift-L",GRN,"]",LGRY," Load by filename/pattern",RETURN,0
menu_text_sample_mode
	!fill 2,RIGHT
	!text GRN,"[",YEL,"Shift-P",GRN,"]",LGRY," Single-sample player mode",RETURN,0
menu_text_device_number
	!fill 8,RIGHT
	!text GRN,"[",YEL,"#",GRN,"]",LGRY," Change input device",RETURN,0
menu_text_view_dir
	!fill 8,RIGHT
	!text GRN,"[",YEL,"$",GRN,"]",LGRY," View disk directory",RETURN,0
menu_text_dos_cmd
	!fill 8,RIGHT
	!text GRN,"[",YEL,"@",GRN,"]",LGRY," Send DOS commands",RETURN,0
menu_text_info_popup
	!fill 8,RIGHT
	!text GRN,"[",YEL,"I",GRN,"]",LGRY," System Info",RETURN,0

menu_txt_home_clr_gray
	!byte RIGHT
	!text DGRY,"[Home/Clr] Top/bottom of file list",RETURN,0
menu_text_page_up_down_gray
	!fill 6,RIGHT
	!text DGRY,"[+/-] Scroll file list one page",RETURN,0
menu_text_load_only_gray
	!fill 8,RIGHT
	!text DGRY,"[L] Load file (but do not play)",RETURN,0
menu_text_sample_mode_gray
	!fill 2,RIGHT
	!text DGRY,"[Shift-P] Single-sample player mode",RETURN,0


;##### Menu page C

menu_text_audio_driver
	!text RIGHT,GRN,"[",YEL,"D",GRN,"]",LGRY," Change audio driver",RETURN,RETURN,0
menu_text_sid_addr
	!text RIGHT,GRN,"[",YEL,"A",GRN,"]",LGRY," Change stereo SID address",RETURN,0
menu_text_dac_addr
	!text RIGHT,GRN,"[",YEL,"A",GRN,"]",LGRY," Change DigiMAX/DAC address",RETURN,0
menu_text_stereo
	!text RIGHT,GRN,"[",YEL,"S",GRN,"]",LGRY," Stereo output",RETURN,0
menu_text_filter
	!text RIGHT,GRN,"[",YEL,"F",GRN,"]",LGRY," Change filter cutoff",RETURN,0
menu_text_dithering
	!text RIGHT,GRN,"[",YEL,"T",GRN,"]",LGRY," Enable Dithering",RETURN,0
menu_text_save_config
	!text RIGHT,GRN,"[",YEL,"_",GRN,"]",LGRY," Save configuration",RETURN,0  ; "🠜"

menu_text_sid_addr_gray
	!text RIGHT,DGRY,"[A] Change stereo SID address (N/A)",RETURN,0

; ##### System info popup

info_popup_msg
	!fill 12,RIGHT
	!text YEL,"System Information",RETURN,RETURN
	!text RIGHT,RIGHT,RIGHT,"Platform:",RETURN
	!text RIGHT,RIGHT,RIGHT,"Expansion RAM size:",RETURN
	!text RIGHT,RIGHT,RIGHT,"Left SID:",RETURN
	!text RIGHT,RIGHT,RIGHT,"Right SID:",RETURN
	!text RIGHT,RIGHT,RIGHT,"Files in current list:",RETURN
	!text RIGHT,RIGHT,RIGHT,"Expansion RAM usage:",RETURN
	!fill 5,DOWN
	!text RIGHT,RIGHT,RIGHT,"Build ID:",0

info_popup_platform_computer
	!text LGRN,"C128",0

!ifdef scpu {
	info_popup_plus_scpu_msg
		!text " + SuperCPU ",0
}

info_popup_6581_msg
	!text LGRN,"6581",0

info_popup_8580_msg
	!text LGRN,"8580",0

; ##### Menu misc.

mode_on_txt
	!text GRN,"(",WHT,"On ",GRN,")",0
mode_off_txt
	!text GRN,"(",LGRY,"Off",GRN,")",0
na_msg
	!text DGRY,"(N/A)",0
not_present_msg
	!text DGRY,"not present",0
kb_msg
	!text " kB",0

; others

saving_msg
	!text DOWN,DOWN,LGRN,"   Saving configuration...",0

loading_msg
	!fill 10,RIGHT
	!text LGRN,"Loading...",0

file_too_large_msg
	!fill 7,RIGHT
	!text RED,"This file needs",RETURN
	!fill 6,RIGHT
	!text "more expansion RAM",RETURN
	!fill 6,RIGHT
	!text "than is available.",RETURN,RETURN
	!fill 8,RIGHT
	!text "Load aborted.",RETURN,RETURN
	!fill 8,RIGHT
	!byte 0

blocks_msg
	!text " blocks / ",0

dos_command_msg
	!fill 11,RIGHT
	!text CYAN,"Enter DOS command:",0

filename_req_msg
	!fill 8,RIGHT
	!text CYAN,"Enter filename/pattern:",0

scanning_dir_msg
	!byte LGRN,RETURN,RETURN
	!fill 4,RIGHT
	!text LGRN,"Scanning directory...",RETURN,RETURN
	!fill 10,RIGHT
	!text "found #",0

audio_driver_1_txt
	!text "SID 4-bit",0
audio_driver_2_txt
	!text "SID Mahoney method",0
audio_driver_3_txt
	!text "DAC/DigiMAX 8-bit",0

user_msg
	!text "UserP",0

erase_size_field_msg
	!byte 16," "
	!byte 16,LEFT
	!byte 0

no_list_loaded_msg
	!text DPUR,"[No list loaded yet]",0

no_file_loaded_msg
	!text LBLU,"[No file has been loaded yet]",0

current_file_msg
	!text LBLU,"Current file: ",0

current_file_tracks_msg
	!text LBLU," tracks / ",CYAN,0

current_file_samples_msg
	!text LBLU," samples",0

current_file_song_pos_msg
	!text LBLU," song pos. / ",CYAN,0

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
	!byte $81,DOWN
	!byte 9,RIGHT
	!byte $80+14
		!text LGRN,"One moment,",RETURN,RETURN
	!byte 7,RIGHT
	!byte $80+17
		!text "testing loader..."
	!byte 0

unknown_file_msg
	!byte $81,DOWN
	!byte 6,RIGHT
	!byte $80+20
	!text RED,"Unknown file type",RETURN,RETURN
	!byte 0

dirname_background
	!byte $83,RVSON,CYAN,"["
	!byte 16," "
	!byte $81,"]"
	!byte 17,LEFT
	!byte 0

playlist_filename_background
	!byte 22," "
	!byte $83,ESC,"j",RIGHT
	!byte 0

choose_audio_msg
	!byte 5,RIGHT
	!byte $80+24
		!text DOWN,CYAN,"Choose audio driver:",RETURN
	!byte 0

choose_aud_driver_pos
	!byte RETURN
	!fill 4,RIGHT
	!byte 0

sample_player_msg
	!fill 4,RIGHT
	!text CYAN,"Sample player goes here",RETURN,RETURN
	!fill 9,RIGHT
	!byte 0

between_songs_msg
	!byte $80+19
		!text CYAN,"Loader goes here",RETURN,RETURN
	!byte 7,RIGHT
	!byte 0

main_player_now_playing_msg
	!fill 13,RIGHT
	!text CYAN,"Now playing:",RETURN,RETURN
	!byte 0

main_player_file_msg
	!fill 8,RIGHT
	!text "Filename: ",LBLU
	!byte 0

main_player_title_msg
	!fill 11,RIGHT
	!text CYAN,"Title: ",LBLU
	!byte 0

main_player_hline
	!byte 40,$60
	!byte $81,RETURN
	!byte 0

main_player_song_pos_pat_msg
	!fill 5,RIGHT
	!text CYAN,"Song Pos: ",LBLU,"  ",CYAN,"/",LBLU,"  "
	!text DCYN," -- "
	!text CYAN,"Pattern: ",LBLU,"  ",RETURN
	!byte 0

main_player_row_speed_time
	!text CYAN,"  Row: ",LBLU,"   ",DCYN,"- "
	!text CYAN,"Speed: ",LBLU,"  ",CYAN,"/",LBLU,"   ",DCYN,"- "
	!text CYAN,"Time: ",LBLU,"00",CYAN,":",LBLU,"00",RETURN
	!byte 0

main_player_regen_tables_msg
	!byte UP,HOME
	!fill 9,DOWN
	!byte YEL
	!text "      A player setting changed", RETURN
	!text "    that altered the sample rate,",RETURN
	!text "        re-generating pitch",RETURN
	!text "        and tempo tables..."
	!byte 0

	main_player_keys_msg
		!fill 3,RIGHT
		!text LBLU,"[",CYAN,"Spc",LBLU,"] ",CYAN,"Skip  "
		!text LBLU,"[",CYAN,"F7",LBLU,"] ",CYAN,"Quit  "
		!text LBLU,"[",CYAN,"1",LBLU,"-",CYAN,"4",LBLU,"] ",CYAN,"Mute"
		!byte 0

main_player_regen_erase_tables_msg
	!fill 4,UP
	!byte RETURN,ESC,"@",0

loader_erase_kbs_msg
	!byte GRN
	!fill 12," "
	!fill 12,LEFT
	!byte 0

loader_kbs_msg
	!text LGRN," kB/sec",0

status_line_pos
	!text HOME,HOME
	!fill 24,DOWN
	!byte 0

!ifdef scpu {
	turn_turbo_on_msg
		!byte DOWN
		!fill 9,RIGHT
		!text YEL,"Please flip",RETURN
		!fill 7,RIGHT
		!text "the turbo switch",RETURN
		!fill 6,RIGHT
		!text "to the ON position"
		!byte 0
}

mm_lo
	!byte <line_2
	!byte <line_3
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_18_and_20
	!byte <line_19
	!byte <lines_18_and_20
	!byte <lines_4_to_17_and_21_to_22
	!byte <lines_4_to_17_and_21_to_22
	!byte <line_23
	!byte <line_24

mm_hi
	!byte >line_2
	!byte >line_3
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_18_and_20
	!byte >line_19
	!byte >lines_18_and_20
	!byte >lines_4_to_17_and_21_to_22
	!byte >lines_4_to_17_and_21_to_22
	!byte >line_23
	!byte >line_24
