; This file defines all of the non-machine-specific constants used througout the program.

!addr {

	program_start							= $1500

	; KERNAL zero-page variables

	STATUS								= $90
	MSGFLG								= $9d
	EAL									= $ae
	FA									= $ba

	; ####################################################
	; ###  Zero Page WHEN BACKED-UP

	; e.g. this area may only be used when player is running
	; or at least, when no KERNAL or BASIC is needed
	; must be restored after any such use.

	utility_zpbk_counter				= $02 ; 3 bytes
	temp_zpbk_a							= $05 ; 3 bytes

	track_current_enable_flags			= $08 ; 8 bytes, through $0f
	last_seconds						= $10

	track_current_loop_flags			= $11 ; 8 bytes

	; free: $19 through $23

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

	; free: $2a through $2c

	; $2a is available as an in/out-of-ZP-backup common addr

	ram_drv_fetch_addr_table_pointer	= $2d
	seq_key_debounce					= $2f
	pattern_break_target_row			= $30
	seq_current_pattern_number			= $31
	seq_current_row						= $32
	seq_current_track					= $33
	seq_ticks_counter					= $34
	current_song_pos					= $35
	glissando_flag						= $36
	vibrato_waveform					= $37
	tremolo_waveform					= $38
	delay_pattern_divisions				= $39
	audio_in_buf_index					= $3a
	audio_out_buf_index					= $3b
	mixer_loops_per_tick_fract			= $3c
	mixer_loops_per_tick				= $3d
	mixer_countdown_fract				= $3e
	mixer_countdown						= $3f
	isr_minimum_times_before_fetch		= $40 ; 8 bytes
	current_sample_volume_levels		= $48 ; 8 bytes

	; utility_pointer_b uses $50 through $52

	sequencer_temp_x					= $53
	sequencer_temp_y					= $54
	sequencer_temp_a					= $55 ; 2 bytes \__ these can also be used
	sequencer_temp_b					= $57 ; 2 bytes /   as one 4-byte temp

	; remainder, load pointer and other random stuff uses $59 through $5b
	; expansion_memory_target_pointer uses $5c/$5d
	; binary search binsearch_value is at $59/$5a

	song_speed							= $5e

	; divide_tmp uses $5f

	seq_tempo_bpm						= $60
	seq_ticks_per_division				= $61
	current_pitch_slide_rates			= $62 ; 8 bytes
	current_slide_to_note_dir			= $6a ; 8 bytes
	arpeggio_counters					= $72 ; 8 bytes -- zero page is mandatory (STX $ZP,Y)
	fine_tune_values					= $7a ; 8 bytes
	cut_sample_ticks					= $82 ; 8 bytes
	delay_sample_ticks					= $8a ; 8 bytes
	current_sample_numbers				= $92 ; 8 bytes
	vibrato_rates						= $9a ; 8 bytes
	tremolo_rates						= $a2 ; 8 bytes
	volume_slide_rates					= $aa ; 8 bytes
	current_steprates_fracts			= $b2 ; \___ 16 bytes
	current_steprates_ints				= $ba ; /
	sample_pointers_fracts				= $c2 ; ¯|
	sample_pointers_lows				= $ca ;  |___32 bytes
	sample_pointers_mids				= $d2 ;  |
	sample_pointers_highs				= $da ; _|
	current_sample_end_addr_lows		= $e2 ; ¯|
	current_sample_end_addr_mids		= $ea ;  |-- 24 bytes, through $f9
	current_sample_end_addr_highs		= $f2 ; _|

	; in-/out-of-Zero-Page-backup dual-mode variables in $fa through $ff,
	; see below.

	; ### End of Zero Page backup
	; ####################################################

	; The rest of these Zero Page addrs can be the same on both C64 and C128
	; and are for use when Zero Page is not backed-up.

	dividend							= $24 ; to $27
	; free: $27 through $29
	quotient = dividend
	divisor								= $59 ; through $5b

	rle_mode_flag						= $24 ; safe to overwrite - math ops aren't used
	rle_byte_count						= $25 ; at the same time as RLE printing

	load_pointer						= $59 ; and $5a
	filename_addr						= $59 ; and $5a

	expansion_memory_target_pointer		= $5c ; to $5e, expansion RAM stash target addr

	print_msg_addr						= $5f ; and $60
	save_addr							= $5f ; and $60
	divide_tmp							= $5f ; and $60

	binsearch_low						= $24 ; and $25
	binsearch_mid						= $26 ; and $27
	binsearch_high						= $28 ; and $29
	binsearch_value						= $59 ; and $5a

	; these Zero Page variables have the same addresses both inside of and
	; outside of the ZP-backup space, so they can be used in either mode, but
	; when used inside of the backup, thier values can't be carried back out.

	utility_pointer_b					= $50 ; through $52

	utility_pointer						= $fa ; and $fb
	fill_copy_source					= $fc ; and $fd
	fill_copy_target					= $fe ; and $ff

	; END OF ZERO PAGE

	; System vectors

	CHROUT_vec							= $0326
	CINV_vec							= $0314
	KERNAL_NMI_vec						= $0318
	CHRIN_vec							= $0324
	STOP_vec							= $0328

	; sequencer/player variables -- most of these are 8 bytes each
	; these are placed in areas of memory where it's okay if they get trashed,
	; so long as the area is stable while the player/seqencer is running.

	string_buffer_backup				= low_memory_area ; 48 bytes

	current_note_periods_lows			= low_memory_area
	current_note_periods_highs			= low_memory_area+$08
	seq_current_row_data				= low_memory_area+$10 ; this one's 32 bytes
	seq_commands						= low_memory_area+$30
	seq_prev_commands					= low_memory_area+$38
	seq_command_arguments				= low_memory_area+$40
	seq_prev_command_arguments			= low_memory_area+$48
	seq_pitch_slide_target_period_lows = low_memory_area+$50
	seq_pitch_slide_target_period_highs = low_memory_area+$58

	; free: low_memory_area+$60 through low_memory_area+$a1
	; the above zone must not exceed +$a1
	; otherwise it'll stomp on C128 indirect routines.

	multablo							= $0400 ; 2 pages
	multabhi							= $0600 ; 2 pages
	multab2lo							= $0800 ; 2 pages

	; C64 has the blurring table at $0a00 through $0a7f, free through $0aff
	; C128 has system variables and such in that space

	; All of the various tables, buffers (both C64 and C128)

	main_variables_zone					= $0b00

	; config file declarations

	config_space						= $0b00 ; first 5 bytes is the config "header"

	load_device							= $0b05
	stereo_sid_addr						= $0b06 ; 2 bytes
	dac_addr							= $0b08 ; 2 bytes
	audio_driver						= $0b0a
	ram_driver							= $0b0b
	stereo_enable						= $0b0c
	filter_setting						= $0b0d
	; unused: $0b0e
	dither_enable						= $0b0f
	enable_screen_on_playback			= $0b10

	cfg_data_end						= $0b11 ; one byte past the real end

	; free: $0b12, $0b13

	audio_driver_isr_cycle_count		= $0b12
	ram_driver_fetch_cycle_count		= $0b13
	isr_trigger_interval				= $0b14 ; 2 bytes
	last_isr_trigger_interval			= $0b16 ; 2 bytes
	playlist_length						= $0b18
	playlist_scroll_pos					= $0b19
	playlist_print_file_counter			= $0b1a
	screen_row_to_print_at				= $0b1b
	; free: $0b1c
	raster_len							= $0b1d
	pal_flag							= $0b1e
	boot_device							= $0b1f

	string_buffer						= $0b20 ; 48 bytes
	uint16_string_buffer				= $0b50 ; 7 bytes (of 8)
	uint16_string_buf_trim				= $0b58 ; 7 bytes (of 8)

	current_dir_name					= $0b60 ; 16 bytes plus a null
	current_file_name					= $0b71 ; 16 bytes plus a null
	current_file_title					= $0b82 ; 21 bytes (plus a bunch of nulls)
	current_file_size					= $0ba0 ; 2 bytes
	current_file_size_in_kb				= $0ba2 ; 2 bytes
	current_file_type					= $0ba4
	current_file_tracks					= $0ba5

	current_menu_page					= $0ba6
	clear_menu_screen_flag				= $0ba7

	file_to_load_name_len				= $0ba8
	file_to_load_size					= $0ba9 ; 2 bytes
	file_size_in_kb						= $0bab ; 2 bytes
	header_loaded						= $0bad

	reu_highest_bank					= $0bae
	ramlink_detect						= $0baf
	main_memory_free_pages				= $0bb0

	old_STOP_vec						= $0bb1 ; 2 bytes
	parse_header_sample_pointer			= $0bb3 ; 3 bytes

	highest_exp_addresss_used			= $0bb6 ; 3 bytes

	arpeggio_extra_note_first_fracts	= $0bb9 ; \___ 16 bytes
	arpeggio_extra_note_first_ints		= $0bc1 ; /
	arpeggio_extra_note_second_fracts	= $0bc9 ; \___ 16 bytes
	arpeggio_extra_note_second_ints		= $0bd1 ; /
	retrigger_rates						= $0bd9 ; 8 bytes

	progress_bar_row					= $0be1
	progress_bar_column					= $0be2
	progress_bar_max_length				= $0be3
	progress_bar_segments_to_draw		= $0be4
	progress_bar_bytes_per_segment		= $0be5 ; 3 bytes

	visualizer_mode						= $0be8
	visualizer_base_address				= $0be9 ; 2 bytes

	pattern_conv_pat_counter			= $0beb
	pattern_conv_row_counter			= $0bec
	pattern_conv_trk_counter			= $0bed

	expansion_memory_start_page			= $0bee
	expansion_memory_start_bank			= $0bef
	supercpu_last_free_page				= $0bf0
	supercpu_last_free_bank				= $0bf1
	; free; $0bf2

	char_table_select					= $0bf3 ; C64-only
	print_msg_char_limit				= $0bf4

	repeat_mode							= $0bf5
	volume_tables_resolution			= $0bf6
	last_volume_tables_resolution		= $0bf7
	allow_regen_msg						= $0bf8

	seq_abort_flag						= $0bf9

	top_row_pos							= $0bfa
	bottom_row_pos						= $0bfb
	left_column_pos						= $0bfc

	right_column_pos					= $0bfd
	num_rows							= $0bfe
	num_columns							= $0bff

	supercpu_detected					= $0c00
	supercpu_turbo_available			= $0c01

	multiplicand_a						= $0c02 ; 2 bytes / these first two are only
	multiplicand_b						= $0c04 ; 2 bytes / used by 16x16 multiply
	product								= $0c06 ; 4 bytes / 8x8 uses this one also.

	remainder							= $0c0a ; through $0c0c

	temp_abs_a							= $0c0d
	temp_abs_b							= $0c0e
	temp_abs_c							= $0c0f
	temp_abs_x							= $0c10
	temp_abs_y							= $0c11
	temp_abs_y2							= $0c12
	temp_counter						= $0c13 ; 3 bytes
	utility_counter						= $0c16 ; 3 bytes

	stash_size							= $0c19 ; 2 bytes

	scroll_area_target_addr				= $0c1b ; 2 bytes
	scroll_area_width					= $0c1d
	scroll_area_height					= $0c1e
	scroll_area_blank_last_line_flag	= $0c1f

	number_of_song_positions			= $0c20
	number_of_patterns					= $0c21

	sid_type_left						= $0c22 ; $80 = 8580, 0 = 6581.
	sid_type_right						= $0c23

	match_header						= $0c24

	disk_free_space						= $0c25 ; 2 bytes

	; free: $0c27 through $0ca7

	; various program vectors

	do_selfmod_pitch_vec				= $0ca8 ; 2 bytes
	do_selfmod_instrument_vec			= $0caa ; 2 bytes

	fetch_block_vec						= $0cac ; 2 bytes
	stash_block_vec						= $0cae ; 2 bytes

	print_vec							= $0cb0 ; 2 bytes

	audio_set_resolution_vec			= $0cb2 ; 2 bytes
	audio_driver_set_cycle_count_vec	= $0cb4 ; 2 bytes
	audio_start_vec						= $0cb6 ; 2 bytes
	audio_mute_vec						= $0cb8 ; 2 bytes
	audio_stop_vec						= $0cba ; 2 bytes
	audio_isr_vec						= $0cbc ; 2 bytes

	ram_driver_set_cycle_counts_vec		= $0cbe ; 2 bytes

	; mods' lengths are big-endian, but addrs and lengths here are little-
	; endian. each of these is 32 bytes, except the first byte of each one is
	; unused.

	; free: $0cc0 through $0cdf
	
	sample_start_addresses_mids			= $0ce0
	sample_start_addresses_highs		= $0d00
	sample_end_addresses_lows			= $0d20
	sample_end_addresses_mids			= $0d40
	sample_end_addresses_highs			= $0d60
	sample_lengths_lows					= $0d80
	sample_lengths_mids					= $0da0
	sample_lengths_highs				= $0dc0
	sample_loop_start_addresses_lows	= $0de0
	sample_loop_start_addresses_mids	= $0e00
	sample_loop_start_addresses_highs	= $0e20
	sample_loop_end_addresses_lows		= $0e40
	sample_loop_end_addresses_mids		= $0e60
	sample_loop_end_addresses_highs		= $0e80
	sample_default_loop_flags			= $0ea0
	sample_default_fine_tunes			= $0ec0
	sample_default_volume_levels		= $0ee0

	zp_backup							= $0f00 ; 1 page (duh. 😛)

	; on C128, $1000-$101f is used for F-key defs, required by the KERNAL.
	; C64, $1000-$101f holds a windowing.s table

	semitones_table						= $1020

	control_code_flags_table_low		= $1040
	control_code_flags_table_high		= $1060
	pattern_table						= $1080

	; on C128, these next two pages can only be used by transient stuff
	; so that's a good place for the two audio buffers

	audio_buffer_left					= $1100 ; 1 page
	audio_buffer_right					= $1200 ; 1 page

	clear_main_memory					= audio_buffer_left
	program_loader						= audio_buffer_left

	; it's safe to reuse the audio bufs for this since it's only needed once.

	multab2hi							= $1300 ; 2 pages

	; main program code starts here at $1500, followed by free mem
	; then comes all the "high-memory" stuff -- see constants-64/128.h

	; Under-KERNAL-ROM stuff

	note_names_table					= $fa00 ; 240 bytes + waste

	divide_by_16_table					= $fb00 ; 1 page

	; 1 page, used by dither driver, or-$80 cuts-off voice 3 from audio path
	divide16_or80_table					= $fc00 

	tempo_table_fracts					= $fd00 ; 1 page
	tempo_table_lows					= $fe00 ; 1 page

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

	SCPU_PRESENT						= $d0b7

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

; if there's a tag at all, it'll always be here (because otherwise, it's a
; 15 sample mod)

magic_number_location = load_buffer + header31_seek_to_pat_tbl + 128

one_ten_thou_pal = int(985248 / 10000) - 1
one_ten_thou_ntsc = int(1022727 / 10000) - 1

; the pitch value sets the step rate table values that the mixer code adds to
; update its fetch pointers. the lookaheads will be based on 1/16 those rates.
pitch_fine_adjust_constant = 57

tempo_fine_adjust_constant = 159778

