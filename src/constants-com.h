; This file defines all of the non-machine-specific constants used througout
; the program.

; This file MUST be "assembled" separately, and exporting a symbol table

; Then, use that symbol table to assemble the rest of the project.

; Now link-in the machine-specific constants

!ifndef c128 {
	!source "src/constants-64.h"
} else {
	!source "src/constants-128.h"
}

!source "src/constants-zero-page.h"
!source "src/constants-io-and-kernal.h"

!addr {

; ----------------------------------------------------------------------------
	; LOW-MEMORY TABLES, BUFFERS, VARIABLES

	!ifndef c128 {
		* = $0334
	} else {
		* = $0200
	}

	; anything stored in this first section will not be wiped with zeroes by
	; init, so only use it for stuff that is initialized explicitly, or which
	; needs to be passed along from the booter.

	low_memory_area = *

	sixteenth_semitones_table_lows		!skip 16
	sixteenth_semitones_table_highs		!skip 16

	expansion_memory_start_page			!skip 1
	exp_instr_names_start_page			!skip 1
	exp_petscii_filenames_start_page	!skip 1
	exp_screencode_filenames_start_page	!skip 1
	exp_menu_start_page					!skip 1
	exp_loader_bg_start_page			!skip 1
	exp_player_bg_start_page			!skip 1
	exp_file_data_start_page			!skip 1
	highest_exp_addresss_used			!skip 3

	c64u_detect							!skip 1

	UCI_LAST_SA							!skip 1
	UCI_LAST_CMD						!skip 1
	UCI_PENDING_CMD						!skip 1

	string_buffer						!skip 48
	string_buffer_backup				!skip 48
	uint16_string_buffer				!skip 8 ; (1 unused byte)
	uint16_string_buf_trim				!skip 8 ; (1 unused byte)

	raster_len							!skip 1
	pal_flag							!skip 1

	; there's about 43 bytes free here on C64 (on C128 it's all full).

; ----------------------------------------------------------------------------

	lma_cur_end = *

	multablo							= $0400 ; 2 pages
	multabhi							= $0600 ; 2 pages
	multab2lo							= $0800 ; 2 pages

	; C64 has the ASCII translation table at $0a00 through $0aff
	; C128 has system variables and such in that space

	* = $0b00

; ----------------------------------------------------------------------------

	main_variables_zone = *

	; config file declarations

	config_space						!skip 5 ; will contain the config "header"

	load_device							!skip 1
	stereo_sid_addr						!skip 2
	dac_addr							!skip 2
	; for the audio driver: 1 = 4-bit SID, 2 = Mahoney,
	; 3 = mono 8-bit DAC, 4 = DigiMAX Mk1, 5 = DigiMAX Mk2
	audio_driver						!skip 1 
	ram_driver							!skip 1
	; Stereo enable is only used with SIDs.  With DAC or DigiMAX
	; mono or stereo is enforced according to the device. 
	stereo_enable						!skip 1
	filter_setting						!skip 1 ; sample filter:  0 = None, $40 = Good ([1,1]/2), $80 = Best ([1,2,1]/4)
	visualizer_mode						!skip 1 ; 0=row data, 1=waveforms
	dither_enable						!skip 1
	enable_screen_on_playback			!skip 1 ; $80 = enabled (C64 only)

	cfg_data_end						!skip 1 ; one byte past the real end

	stereo_enable_temp					!skip 1

	mixer_cycle_count					!skip 1
	audio_driver_isr_cycle_count		!skip 1
	ram_driver_fetch_cycle_count		!skip 1
	isr_trigger_interval				!skip 2
	last_isr_trigger_interval			!skip 2
	cia_cra_startup_val					!skip 1

	boot_device							!skip 1

	current_dir_name					!skip 17
	current_file_name					!skip 17
	current_file_title					!skip 22
	current_file_size					!skip 2
	current_file_size_in_kb				!skip 2
	current_file_type					!skip 1
	current_file_tracks					!skip 1

	current_menu_page					!skip 1

	file_to_load_name_len				!skip 1
	file_to_load_size					!skip 2
	file_size_in_kb						!skip 2
	loaded_bytes_count					!skip 3
	header_loaded						!skip 1
	load_device_can_use_uci				!skip 1
	load_device_supports_dirs			!skip 1

	main_memory_free_pages				!skip 1

	old_STOP_vec						!skip 2
	parse_header_sample_pointer			!skip 3

	progress_bar_row					!skip 1
	progress_bar_column					!skip 1
	progress_bar_max_length				!skip 1
	progress_bar_segments_to_draw		!skip 1
	progress_bar_bytes_per_segment		!skip 3
	progress_bar_color					!skip 1

	visualizer_base_address				!skip 2
	viz_waveforms_shift_for_8_bit		!skip 1

	pattern_conv_pat_counter			!skip 1
	pattern_conv_row_counter			!skip 1
	pattern_conv_trk_counter			!skip 1

	print_msg_colors_flag				!skip 1
	char_table_select					!skip 1 ; only used on C64
	print_msg_char_limit				!skip 1

	repeat_mode							!skip 1 ; $80 = enabled
	volume_tables_resolution			!skip 1
	last_volume_tables_resolution		!skip 1
	allow_regen_msg						!skip 1

	top_row_pos							!skip 1
	bottom_row_pos						!skip 1
	left_column_pos						!skip 1

	right_column_pos					!skip 1
	num_rows							!skip 1
	num_columns							!skip 1

	supercpu_detected					!skip 1

	multirate_is_allowed				!skip 1 ; user setting:  0 = off, 1 = on (refuse files that
												; won't fit), 2 = on (play such files in striding mode)
	multirate_enable					!skip 1 ; set by the loader for each file:  $80 = this file is
												; using multirate, 0 = striding mode

	multiplicand_a						!skip 2 ; these first two are only
	multiplicand_b						!skip 2 ; used by 16x16 multiply
	product								!skip 4 ; 8x8 uses this one also.

	remainder							!skip 3

	temp_abs_a							!skip 1
	temp_abs_b							!skip 1
	temp_abs_c							!skip 1
	temp_abs_x							!skip 1
	temp_abs_y							!skip 1
	temp_abs_y2							!skip 1
	temp_carry							!skip 1
	temp_counter						!skip 3
	temp_counter_b						!skip 3
	utility_counter						!skip 3

	exp_target_ptr_temp					!skip 3
	exp_local_ptr_temp					!skip 2
	exp_stash_size_temp					!skip 2

	stash_size							!skip 2

	scroll_area_target_addr				!skip 2
	scroll_area_width					!skip 1
	scroll_area_height					!skip 1
	scroll_area_blank_last_line_flag	!skip 1

	erase_screen_area_row_count			!skip 1

	number_of_song_positions			!skip 1
	number_of_patterns					!skip 1

	sid_type_left						!skip 1 ; $80 = 8580, 0 = 6581.
	sid_type_right						!skip 1
	ultisid_detect_left					!skip 1 ; $80 = detected UltiSID, 0 = assume real SID(s)
	ultisid_detect_right				!skip 1

	match_header						!skip 1

	disk_free_space						!skip 2

	nybble_x10							!skip 16

	vol_cnt								!skip 1
	bval_cnt							!skip 1

	progress_bar_segments				!skip 8

	mod_magic_numbers					!skip 29

	num_samples_to_load					!skip 1

	supercpu_last_free_page				!skip 1
	supercpu_last_free_bank				!skip 1

	TOD_clock_temps						!skip 4 ; used by song pause to keep
												; the time right

	profiler_temp						!skip 1

	; various program indirect JMP/JSR vectors

	!align 1,0  ; vectors need to avoid crossing $xxff

	do_selfmod_pitch_vec				!skip 2
	do_selfmod_instrument_vec			!skip 2

	fetch_block_vec						!skip 2
	stash_block_vec						!skip 2

	print_vec							!skip 2

	audio_set_resolution_vec			!skip 2
	audio_driver_set_cycle_count_vec	!skip 2
	audio_start_vec						!skip 2
	audio_mute_vec						!skip 2
	audio_stop_vec						!skip 2
	audio_isr_vec						!skip 2

	ram_driver_set_cycle_counts_vec		!skip 2

	initial_playlist_loaded				!skip 1
	playlist_length						!skip 1
	playlist_scroll_pos					!skip 1
	playlist_iterate_mode				!skip 1 ; 0 = not iterating; 1=play everything, $80=play selected
	playlist_num_files_in_selection		!skip 1
	playlist_pos_within_selection		!skip 1
	playlist_print_file_counter			!skip 1
	screen_row_to_print_at				!skip 1
	playlist_file_sizes_lows			!skip 256
	playlist_file_sizes_highs			!skip 256

	playlist_file_flags					!skip 256

	; flags explanation:
	; 0 = empty
	; 1 = there's "something" here, but what? 🙂
	; $20 = this item is the parent dir option
	; $40 = this item is a directory
	; $80 = this is an enqueued file

	seq_current_row_data				!skip 32
	seq_commands						!skip 8
	seq_prev_commands					!skip 8
	seq_command_arguments				!skip 8

	seq_abort_flag						!skip 1

	last_vibrato_rates					!skip 8
	last_vibrato_amplitudes				!skip 8

	current_cut_sample_ticks			!skip 8
	current_delay_sample_ticks			!skip 8

	current_volume_slide_rates			!skip 8

	current_sample_numbers				!skip 8
	enqueued_sample_numbers				!skip 8
	track_current_enable_flags			!skip 8

	current_multirate_levels			!skip 8
	current_loop_start_lows				!skip 8
	current_loop_start_mids				!skip 8
	current_loop_start_highs			!skip 8

	current_arp_extra_note_1st_fracts	!skip 8
	current_arp_extra_note_1st_ints		!skip 8
	current_arp_extra_note_2nd_fracts	!skip 8
	current_arp_extra_note_2nd_ints		!skip 8

	current_tremolo_step_sizes			!skip 8

	current_retrigger_rates				!skip 8

	current_pitch_slide_target_lows		!skip 8
	current_pitch_slide_target_highs	!skip 8

	last_seconds						!skip 1
	do_viz_plot							!skip 1
	seq_key_debounce					!skip 1

	; about 72 bytes free here on both machines

; ------------------------------------------------------------------------

	mv_end = *

	; on C128, $1000-$101f is used for F-key defs, required by the KERNAL.
	; on C64, $1000-$101f is free space

	current_note_periods_fracts			= $1020 ; 8x3 bytes, 
	current_note_periods_lows			= $1028 ; ¯¯\ fracts only used by vibrato,
	current_note_periods_highs			= $1030 ;    \__ otherwise it's ignored

	fine_tuning_table					= $1038 ; 32 bytes
	current_fine_tune_values			= $1058 ; 8 bytes

	semitones_table						= $1060
	pattern_table						= $1080

	; on C128, these next two pages can only be used by transient stuff
	; so that's a good place for the two audio buffers (C64 doesn't care)

	audio_buffer_left					= $1100 ; 1 page
	audio_buffer_right					= $1200 ; 1 page

	multab2hi							= $1300 ; 2 pages
	program_load_decrunch_stub			= multab2hi

	zero_page_swap_area					= $1500

	; these are only used at load time, during the loop-unroll-or-don't
	; code when they're compared and/or updated, then they're discarded

	sample_loop_end_addresses_lows		= zero_page_swap_area
	sample_loop_end_addresses_mids		= zero_page_swap_area + 32
	sample_loop_end_addresses_highs		= zero_page_swap_area + 64

	program_start						= $1600

	; main program code starts here, followed by more tables and buffers

	!ifndef c128 {
		main_mem_free_end				= $cc00
		VIC_SCREEN						= main_mem_free_end
	} else {
		main_mem_free_end				= $d000
	}


; ----------------------------------------------------------------------------
; PETSCII COLOR/CONTROL CODES

BLK									= $90
WHT									= $05
RED									= $1c
CYAN								= $9f
PUR									= $9c
GRN									= $1e
BLUE								= $1f
YEL									= $9e
BRN									= $95
LRED								= $96
LGRN								= $99
LBLU								= $9a
LGRY								= $9b

HOME								= $13
CLR									= $93

DEL									= $14
INST								= $94

UP									= $91
DOWN								= $11
LEFT								= $9d
RIGHT								= $1d

RETURN								= $0d

LOWER								= $0e
UPPER								= $8e

RVSON								= $12
RVSOFF								= $92

QUOTE								= $22


; ----------------------------------------------------------------------------
; MISC STUFF

X = "X" ; so that the delay routine doesn't
Y = "Y" ; need to be called with X or Y in quotes.

header_first_inst_meta_offset	= 20
instrument_metadata_size		= 22+2+1+1+2+2 ; (30)

header15_seek_to_pat_tbl		= 20+15*(22+2+1+1+2+2)+1+1 ; (472)
header31_seek_to_pat_tbl		= 20+31*(22+2+1+1+2+2)+1+1 ; (952)

header15_seek_to_pat_data = header15_seek_to_pat_tbl + 128
header31_seek_to_pat_data = header31_seek_to_pat_tbl + 132

; size of the load/sample data buffer, in pages.  the floor is the 1084-byte
; 31-sample header (5 pages).  the loop unroller works in chunks of this size,
; because it has to hold a whole loop, and the sample data buffer has to hold
; striding mode's four cache pages.

LOAD_BUFFER_PAGES = 5

pal_clock = 985248
ntsc_clock = 1022727

}
