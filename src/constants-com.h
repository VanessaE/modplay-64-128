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

; KERNAL zero-page variables

!addr {
	STATUS								= $90
	MSGFLG								= $9d
	EAL									= $ae
	FA									= $ba

	; These Zero Page addrs can be the same on both C64 and C128
	; and are for use when Zero Page is not backed-up.

	dividend							= $24 ; to $27
	quotient = dividend
	divisor								= $59 ; through $5b

	rle_mode_flag						= dividend ; safe to overwrite - math ops aren't used
	rle_byte_count						= rle_mode_flag + 1 ; at the same time as RLE printing

	load_pointer						= divisor ; 2 bytes
	filename_addr						= divisor ; 2 bytes

	expansion_memory_target_pointer		= $5c ; to $5e, expansion RAM stash target addr

	divide_tmp							= $5f ; and $60
	print_msg_addr						= divide_tmp
	save_addr							= divide_tmp

	binsearch_low						= dividend ; 2 bytes
	binsearch_mid						= binsearch_low + 2
	binsearch_high						= binsearch_mid + 2
	binsearch_value						= divisor ; 2 bytes

	utility_pointer_c					= $24 ; through $26

	; these Zero Page variables have the same addresses both inside of and
	; outside of the ZP-backup space, so they can be used in either mode, but
	; when used inside of the backup, thier values can't be carried back out.

	utility_pointer_b					= $50 ; through $52

	utility_pointer						= $fa ; and $fb
	fill_copy_source					= utility_pointer + 2
	fill_copy_target					= fill_copy_source + 2

	; END OF ZERO PAGE

	multablo							= $0400 ; 2 pages
	multabhi							= $0600 ; 2 pages
	multab2lo							= $0800 ; 2 pages

	; C64 has the ASCII translation table at $0a00 through $0aff
	; C128 has system variables and such in that space

}

	; on C128, $1000-$101f is used for F-key defs, required by the KERNAL.
	; on C64, $1000-$101f is free space

!addr {
	semitones_table						= $1020

	control_code_flags_table_low		= $1040
	control_code_flags_table_high		= $1060
	pattern_table						= $1080

	; on C128, these next two pages can only be used by transient stuff
	; so that's a good place for the two audio buffers (C64 doesn't care)

	audio_buffer_left					= $1100 ; 1 page
	audio_buffer_right					= $1200 ; 1 page

	clear_main_memory					= audio_buffer_left

	; it's safe to reuse the audio bufs for this since it's only needed once.

	multab2hi							= $1300 ; 2 pages

	mah_table_6581						= $1500
	mah_table_8580						= $1600

	zp_backup							= $1700

	program_load_decrunch_stub			= multab2hi

	program_start						= $1800

	; main program code starts here, followed by more tables and buffers,
	; then comes all the "high-memory" stuff -- see below and
	; constants-64/128.h

	; Under-KERNAL-ROM stuff

	note_names_table					= $fa00 ; 240 bytes + waste

	divide_by_16_table					= $fb00 ; 1 page

	; 1 page, used by dither driver, or-$80 cuts-off voice 3 from audio path
	divide16_or80_table					= $fc00 

	tempo_table_fracts					= $fd00 ; 1 page
	tempo_table_lows					= $fe00 ; 1 page

	; KERNAL/System vectors

	CHROUT_vec							= $0326
	CINV_vec							= $0314
	KERNAL_NMI_vec						= $0318
	CHRIN_vec							= $0324
	STOP_vec							= $0328

	; I/O devices

	VIC_COLOR_RAM						= $d800

	VIC_CONTROL_A						= $d011
	VIC_RASTER_LOW						= $d012
	VIC_MEM_CTRL						= $d018
	VIC_IRQ_FLAGS						= $d019
	VIC_IRQ_MASK						= $d01a
	VIC_BORDER							= $d020
	VIC_BACKGROUND						= $d021

	VIC_2_MHZ							= $d030
	; C128 only note:  in $D030, only bits 1 & 0 matter, so "test" and 1/2 MHz
	; mode switching will work with any stored value as long as those two bits
	; are correct.

	!ifdef scpu {
		SCPU_TURBO_OFF					= $d07a
		SCPU_TURBO_ON					= $d07b
		SCPU_ENABLE_HW_REGS				= $d07e
		SCPU_DISABLE_HW_REGS			= $d07f
		SCPU_OPTIMIZATION_MODE			= $d0b3
		SCPU_JD_TURBO_SWITCH			= $d0b5

		SCPU_RAM_FIRST_PAGE				= $d27c
		SCPU_RAM_FIRST_BANK				= $d27d
		SCPU_RAM_LAST_PAGE				= $d27e
		SCPU_RAM_LAST_BANK				= $d27f
	}

	SCPU_PRESENT						= $d0bc

	SID									= $d400
	SID_VOICE1_CR						= $d404
	SID_VOICE1_ENV_AD					= $d405
	SID_VOICE1_ENV_SR					= $d406

	SID_VOICE2_CR						= $d40b
	SID_VOICE2_ENV_AD					= $d40c
	SID_VOICE2_ENV_SR					= $d40d

	SID_VOICE3_FREQ_LOW					= $d40e
	SID_VOICE3_FREQ_HIGH				= $d40f
	SID_VOICE3_CR						= $d412
	SID_VOICE3_ENV_AD					= $d413
	SID_VOICE3_ENV_SR					= $d414

	SID_FILT_CUTOFF_LOW					= $d415
	SID_FILT_CUTOFF_HIGH				= $d416
	SID_FILT_VOICE_SEL					= $d417
	SID_VOLUME							= $d418

	SID_VOICE3_OSC_OUT					= $d41b

	CIA1_PORT_A							= $dc00
	CIA1_PORT_B							= $dc01
	CIA1_TIMER_B_LOW					= $dc06
	CIA1_TIMER_B_HIGH					= $dc07
	CIA1_TOD_TENTHS						= $dc08
	CIA1_TOD_SECONDS					= $dc09
	CIA1_TOD_MINUTES					= $dc0a
	CIA1_TOD_HOURS						= $dc0b
	CIA1_SDR							= $dc0c
	CIA1_ICR							= $dc0d
	CIA1_CRA							= $dc0e
	CIA1_CRB							= $dc0f

	CIA2_PORT_A							= $dd00
	CIA2_PORT_B							= $dd01
	CIA2_DDR_A							= $dd02
	CIA2_DDR_B							= $dd03
	CIA2_TIMER_A_LOW					= $dd04
	CIA2_TIMER_A_HIGH					= $dd05
	CIA2_ICR							= $dd0d
	CIA2_CRA							= $dd0e

	DMA_CMD								= $df01

	DMA_ADL								= $df02		; local address
	DMA_ADH								= $df03

	DMA_LO								= $df04		; REU address
	DMA_HI								= $df05
	DMA_BANK							= $df06

	DMA_DAL								= $df07		; transfer length
	DMA_DAH								= $df08

	RAMLINK_REG_ENABLE					= $df7e
	RAMLINK_REG_DISABLE					= $df7f
	RAMLINK_8255_PORT_C					= $df42

	; KERNAL calls

	CINT								= $ff81
	IOINIT								= $ff84
	RESTOR								= $ff8a
	READST								= $ffb7

	SECND								= $ff93
	TKSA								= $ff96
	ACPTR								= $ffa5
	CIOUT								= $ffa8
	UNTLK								= $ffab
	UNLSN								= $ffae
	LISTN								= $ffb1
	TALK								= $ffb4

	SETLFS								= $ffba
	SETNAM								= $ffbd
	LOAD								= $ffd5
	SAVE								= $ffd8

	OPEN								= $ffc0
	CLRCH								= $ffcc
	CLOSE								= $ffc3

	CHKIN								= $ffc6
	CHKOUT								= $ffc9
	CHRIN								= $ffcf
	CHROUT								= $ffd2
	STOP								= $ffe1
	GETIN								= $ffe4
	CLALL								= $ffe7

	PLOT								= $fff0

	; CPU vectors

	CPU_NMI_vector						= $fffa
	CPU_IRQ_vector						= $fffe
}

; PETSCII color/control codes

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

; Misc stuff not specific to the machine's OS

X = "X" ; so that the delay routine doesn't
Y = "Y" ; need to be called with X or Y in quotes.

header_first_inst_meta_offset	= 20
instrument_metadata_size		= 22+2+1+1+2+2 ; (30)

header15_seek_to_pat_tbl		= 20+15*(22+2+1+1+2+2)+1+1 ; (472)
header31_seek_to_pat_tbl		= 20+31*(22+2+1+1+2+2)+1+1 ; (952)

header15_seek_to_pat_data = header15_seek_to_pat_tbl + 128
header31_seek_to_pat_data = header31_seek_to_pat_tbl + 132

one_ten_thou_pal = int(985248 / 10000) - 1
one_ten_thou_ntsc = int(1022727 / 10000) - 1

; the pitch value sets the step rate table values that the mixer code adds to
; update its fetch pointers. the lookaheads will be based on 1/16 those rates.
pitch_fine_adjust_constant = 57

tempo_fine_adjust_constant = 159778


; ############################################################################
; FROM HERE ON DOWN ARE VARIABLES THAT CAN BE FREELY PLACED AND/OR REARRANGED
;
; They are used to create a "dummy" object so that the assembler will
; generate a symbol table that's then used to assemble the program
; ############################################################################

; Zero Page WHEN BACKED-UP
; This area may only be used when player is running, or at least, when no
; KERNAL or BASIC calls are needed.  Must be restored after any such use.

	* = $02

	utility_zpbk_counter				!skip 3
	temp_zpbk_a							!skip 3
	temp_zpbk_b							!skip 1

	track_current_enable_flags			!skip 8
	track_current_loop_flags			!skip 8

	last_seconds						!skip 1
	do_viz_plot							!skip 1
	seq_key_debounce					!skip 1

	!if * > $0023 {
			!error "Backed-up-zero-page variables, lower part exceeds $0023 by ", * - $0023, " bytes!"
	}

	; because they're needed both inside and outside of the player, multiply
	; divide, and binary search routines' zero page variables have to be in
	; the same places within the "backup-mode" as they are outside of it.

	; for 16/16 or 24/24 divide:
	; dividend/quotient uses $24 through $26
	; divisor uses $27 through $29

	; for 32/16 divide:
	; dividend/quotient uses $24 through $27
	; divisor uses $28/$29

	; for the binary search:
	; binsearch_low is at $24/$25
	; binsearch_mid is at $26/27
	; binsearch_high is at $28/$29

	; the various multiples of 8 bytes below are in order by track number

	; $2a is also available as an in/out-of-ZP-backup common addr

	* = $2a

	pattern_break_target_row			!skip 1
	seq_current_pattern_number			!skip 1
	seq_current_row						!skip 1
	seq_current_track					!skip 1
	seq_ticks_counter					!skip 1
	current_song_pos					!skip 1
	glissando_flag						!skip 1
	vibrato_waveform					!skip 1
	tremolo_waveform					!skip 1
	delay_pattern_divisions				!skip 1
	audio_in_buf_index					!skip 1
	audio_out_buf_index					!skip 1

	song_speed							!skip 1
	seq_tempo_bpm						!skip 1
	seq_ticks_per_division				!skip 1

	mixer_loops_per_tick_fract			!skip 1
	mixer_loops_per_tick				!skip 1
	mixer_countdown_fract				!skip 1
	mixer_countdown						!skip 1
	isr_minimum_times_before_fetch		!skip 8
	current_sample_volume_levels		!skip 8

	!if * > $0050 {
			!error "Backed-up-zero-page variables, first middle part exceeds $0050 by ", * - $0050, " bytes!"
	}

	; utility_pointer_b uses $50 through $52

	* = $53

	sequencer_temp_x					!skip 1
	sequencer_temp_y					!skip 1
	sequencer_temp_a					!skip 2 ; \__ these can also be used
	sequencer_temp_b					!skip 2 ; /   as one 4-byte temp

	!if * > $0059 {
			!error "Backed-up-zero-page variables, second middle part exceeds $0059 by ", * - $0059, " bytes!"
	}

	; remainder, load pointer and other random stuff uses $59 through $5b
	; expansion_memory_target_pointer uses $5c/$5d
	; binary search binsearch_value is at $59/$5a

	; unused: $5e

	; divide_tmp uses $5f

	* = $60

	current_pitch_slide_rates			!skip 8
	current_pitch_slide_dirs			!skip 8 ; 0=pitching down, $80=pitching up
	arpeggio_counters					!skip 8 ; zero page is mandatory (STX $ZP,Y)
	fine_tune_values					!skip 8
	cut_sample_ticks					!skip 8
	delay_sample_ticks					!skip 8
	current_sample_numbers				!skip 8
	vibrato_rates						!skip 8
	tremolo_rates						!skip 8
	volume_slide_rates					!skip 8
	current_steprates_fracts			!skip 8
	current_steprates_ints				!skip 8
	sample_pointers_fracts				!skip 8
	sample_pointers_lows				!skip 8
	sample_pointers_mids				!skip 8
	sample_pointers_highs				!skip 8
	current_sample_end_addr_lows		!skip 8
	current_sample_end_addr_mids		!skip 8
	current_sample_end_addr_highs		!skip 8

	!if * > $00f9 {
			!error "Backed-up-zero-page variables, upper part exceeds $00f9 by ", * - $00f9, " bytes!"
	}

	; in-/out-of-Zero-Page-backup dual-use variables in $fa through $ff,
	; see above.
	; ### End of Zero Page backup


	; ####################################################
	; low memory area

	!ifndef c128 {
		* = $0334
	} else {
		* = $0200
	}

	; sequencer/player variables -- most of these are 8 bytes each
	; these are placed in areas of memory where it's okay if they get trashed,
	; so long as the area is stable while the player/seqencer is running.

	low_memory_area = *
	string_buffer_backup				= low_memory_area ; 48 bytes

	current_note_periods_lows			!skip 8
	current_note_periods_highs			!skip 8
	seq_current_row_data				!skip 32
	seq_commands						!skip 8
	seq_prev_commands					!skip 8
	seq_command_arguments				!skip 8
	seq_prev_command_arguments			!skip 8
	seq_pitch_slide_target_period_lows	!skip 8
	seq_pitch_slide_target_period_highs !skip 8

	!ifndef c128 {
		!if * > $03ff {
				!error "Low memory area exceeds overlaps `multablo` by ", * - $03ff, " bytes!"
		}
	} else {
		!if * > $02a1 {
				!error "Low memory area overlaps C128 indirect routines by ", * - $02a1, " bytes!"
		}
	}

	; All of the various tables, buffers (both C64 and C128)

	* = $0b00

	main_variables_zone = *

	; config file declarations

	config_space						!skip 5 ; will contain the config "header"

	load_device							!skip 1
	stereo_sid_addr						!skip 2
	dac_addr							!skip 2
	audio_driver						!skip 1 ; 1=4-bit SID, 2=Mahoney, 3=DAC
	ram_driver							!skip 1
	stereo_enable						!skip 1
	filter_setting						!skip 1 ; 0=none, $80=lowpass
	visualizer_mode						!skip 1 ; 0=row data, 1=waveforms
	dither_enable						!skip 1
	enable_screen_on_playback			!skip 1

	cfg_data_end						!skip 1 ; one byte past the real end

	mixer_cycle_count					!skip 1
	audio_driver_isr_cycle_count		!skip 1
	ram_driver_fetch_cycle_count		!skip 1
	isr_trigger_interval				!skip 2
	last_isr_trigger_interval			!skip 2

	raster_len							!skip 1
	pal_flag							!skip 1
	boot_device							!skip 1

	string_buffer						!skip 48
	uint16_string_buffer				!skip 8 ; (1 unused byte)
	uint16_string_buf_trim				!skip 8 ; (1 unused byte)

	current_dir_name					!skip 17
	current_file_name					!skip 17
	current_file_title					!skip 22
	current_file_size					!skip 2
	current_file_size_in_kb				!skip 2
	current_file_type					!skip 1
	current_file_tracks					!skip 1

	current_menu_page					!skip 1
	clear_menu_screen_flag				!skip 1

	file_to_load_name_len				!skip 1
	file_to_load_size					!skip 2
	file_size_in_kb						!skip 2
	loaded_bytes_count					!skip 3
	header_loaded						!skip 1

	ramlink_detect						!skip 1
	main_memory_free_pages				!skip 1

	old_STOP_vec						!skip 2
	parse_header_sample_pointer			!skip 3

	arpeggio_extra_note_first_fracts	!skip 8
	arpeggio_extra_note_first_ints		!skip 8
	arpeggio_extra_note_second_fracts	!skip 8
	arpeggio_extra_note_second_ints		!skip 8
	retrigger_rates						!skip 8

	progress_bar_row					!skip 1
	progress_bar_column					!skip 1
	progress_bar_max_length				!skip 1
	progress_bar_segments_to_draw		!skip 1
	progress_bar_bytes_per_segment		!skip 3

	visualizer_base_address				!skip 2
	viz_waveforms_shift_for_8_bit		!skip 1

	pattern_conv_pat_counter			!skip 1
	pattern_conv_row_counter			!skip 1
	pattern_conv_trk_counter			!skip 1

	print_msg_colors_flag				!skip 1
	char_table_select					!skip 1 ; only used on C64
	print_msg_char_limit				!skip 1

	repeat_mode							!skip 1
	volume_tables_resolution			!skip 1
	last_volume_tables_resolution		!skip 1
	allow_regen_msg						!skip 1

	seq_abort_flag						!skip 1

	top_row_pos							!skip 1
	bottom_row_pos						!skip 1
	left_column_pos						!skip 1

	right_column_pos					!skip 1
	num_rows							!skip 1
	num_columns							!skip 1

	supercpu_detected					!skip 1
	supercpu_turbo_available			!skip 1

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
	utility_counter						!skip 3

	stash_size							!skip 2

	scroll_area_target_addr				!skip 2
	scroll_area_width					!skip 1
	scroll_area_height					!skip 1
	scroll_area_blank_last_line_flag	!skip 1

	number_of_song_positions			!skip 1
	number_of_patterns					!skip 1

	sid_type_left						!skip 1 ; $80 = 8580, 0 = 6581.
	sid_type_right						!skip 1

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

	expansion_memory_start_page			!skip 1

	exp_instr_names_start_page			!skip 1
	exp_petscii_filenames_start_page	!skip 1
	exp_screencode_filenames_start_page	!skip 1
	exp_loader_bg_start_page			!skip 1
	exp_player_bg_start_page			!skip 1
	exp_file_data_start_page			!skip 1
	highest_exp_addresss_used			!skip 3

	; various program indirect JMP/JSR vectors

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
	playlist_iterate_mode				!skip 1 ; 0=play everything, $80=play selected
	playlist_print_file_counter			!skip 1
	screen_row_to_print_at				!skip 1
	playlist_file_sizes_lows			!skip 256
	playlist_file_sizes_highs			!skip 256
	playlist_file_flags					!skip 256

	!if * > $0fff {
			!error "Main variables zone exceeds $0fff by ", * - $0fff, " bytes!"
	}
