; This file defines all of the non-machine-specific constants used througout the program.

program_start							= $1f00

!addr {
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

	; free: $10 through $23

	; because they're needed both inside and outside of the player, multiply
	; divide, and binary search routines' zero page variables have to be in
	; the same places within the "backup-mode" as they are outside of it.

	; for 16/16 or 24/24 divide:
	; dividend/quotient uses $24 through $26
	; divisor uses $27 through $29

	; for 32/16 divide:
	; dividend32/quotient32 uses $24 through $27
	; divisor16 uses $28/$29

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

	; division remainder uses $59 through $5b
	; multiply product uses $5c/$5d
	; binary search binsearch_value is at $59/$5a

	song_speed							= $5e

	; divide24_tmp uses $5f

	seq_tempo_bpm						= $60
	seq_ticks_per_division				= $61
	pitch_slide_rates					= $62 ; 8 bytes
	track_current_loop_flags			= $6a ; 8 bytes
	fine_tune_values					= $72 ; 8 bytes
	retrigger_rates						= $7a ; 8 bytes
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

	dividend							= $24 ; to $26
	divisor								= $27 ; to $29

	remainder							= $59 ; to $5b
	quotient = dividend

	dividend32							= $24 ; to $27
	divisor16							= $28 ; and $29
	quotient32 = dividend32

	rle_mode_flag						= $24 ; safe to overwrite - math ops aren't used
	rle_byte_count						= $25 ; at the same time as RLE printing

	load_pointer						= $59 ; and $5a
	filename_addr						= $59 ; and $5a

	product								= $5c ; and $5d / the product from multiply routine

	expansion_memory_target_pointer		= $5c ; to $5e, expansion RAM stash target addr
											  ; only used within the loader

	print_msg_addr						= $5f ; and $60
	save_addr							= $5f ; and $60
	divide24_tmp						= $5f

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
	current_node_period_offsets			= low_memory_area+$10
	seq_current_row_data				= low_memory_area+$18 ; this one's 32 bytes
	seq_commands						= low_memory_area+$38
	seq_prev_commands					= low_memory_area+$40
	seq_command_arguments				= low_memory_area+$48
	seq_prev_command_arguments			= low_memory_area+$50
	current_pitch_slide_flags			= low_memory_area+$58
	seq_pitch_slide_stop_point_lows		= low_memory_area+$60
	seq_pitch_slide_stop_point_highs	= low_memory_area+$68

	; free: low_memory_area+$70 through low_memory_area+$a1
	; the above zone must not exceed +$a1
	; otherwise it'll stomp on C128 indirect routines.

	multablo							= $0400 ; 2 pages
	multabhi							= $0600 ; 2 pages
	multab2lo							= $0800 ; 2 pages

	; C64 has the blurring table at $0a00 through $0a7f, free through $0aff
	; C128 has system variables and such in that space

	load_buffer							= $0b00 ; 5*254 bytes, plus the rest
	load_buffer_end						= $0ff5 ; of the 5th page for overflow

	clear_main_memory					= load_buffer

	; on C128, $1000-$101f is used for F-key defs, required by the KERNAL.
	; C64, $1000-$101f holds a windowing.s table

	semitones_table_fracts				= $1020
	semitones_table_lows				= $1030

	control_code_flags_table_low		= $1040
	control_code_flags_table_high		= $1060
	pattern_table						= $1080

	; on C128, these next two pages can only be used by transient stuff
	; so that's a good place for the two audio buffers

	audio_buffer_left					= $1100 ; 1 page
	audio_buffer_right					= $1200 ; 1 page

	multab2hi							= $1300 ; 2 pages

	; All of the various tables, buffers (both C64 and C128)

	main_variables_zone					= $1500

	config_space						= $1500 ; 16 bytes

	one_ten_thousandth_second			= $1510 ; 2 bytes
	number_of_song_positions			= $1512
	number_of_patterns					= $1513

	audio_driver_isr_cycle_count		= $1514
	ram_driver_fetch_cycle_count		= $1515
	isr_trigger_interval				= $1516
	last_isr_trigger_interval			= $1517
	playlist_length						= $1518
	playlist_scroll_pos					= $1519
	playlist_print_file_counter			= $151a
	screen_row_to_print_at				= $151b
	rasters_lo							= $151c
	raster_len							= $151d
	pal_flag							= $151e
	boot_device							= $151f

	string_buffer						= $1520 ; 48 bytes
	uint16_string_buffer				= $1550 ; 7 bytes (of 8)
	uint16_string_buf_trim				= $1558 ; 7 bytes (of 8)

	current_dir_name					= $1560 ; 16 bytes plus a null
	current_file_name					= $1571 ; 16 bytes plus a null
	current_file_title					= $1582 ; 21 bytes (plus a bunch of nulls)
	current_file_size					= $15a0 ; 2 bytes
	current_file_size_in_kb				= $15a2 ; 2 bytes
	current_file_type					= $15a4
	current_file_tracks					= $15a5

	current_menu_page					= $15a6
	clear_menu_screen_flag				= $15a7

	file_to_load_name_len				= $15a8
	file_to_load_size					= $15a9 ; 2 bytes
	file_size_in_kb						= $15ab ; 2 bytes
	header_loaded						= $15ad

	reu_highest_bank					= $15ae
	ramlink_detect						= $15af
	main_memory_free_pages				= $15b0

	old_STOP_vec						= $15b1 ; 2 bytes
	parse_header_sample_pointer			= $15b3 ; 3 bytes
	arpeggio_extra_note_first			= $15b6 ; \___ 16 bytes
	arpeggio_extra_note_second			= $15be ; /

	repeat_mode							= $15c6
	volume_tables_resolution			= $15c7
	last_volume_tables_resolution		= $15c8
	allow_regen_msg						= $15c9

	seq_abort_flag						= $15ca

	top_row_pos							= $15cb
	bottom_row_pos						= $15cc
	left_column_pos						= $15cd
	right_column_pos					= $15ce
	num_rows							= $15cf
	num_columns							= $15d0

	stash_size							= $15d1 ; 2 bytes

	temp_abs_a							= $15d3
	temp_abs_b							= $15d4
	temp_abs_c							= $15d5
	temp_abs_x							= $15d6
	temp_abs_y							= $15d7
	temp_abs_y2							= $15d8
	temp_counter						= $15d9 ; 3 bytes
	scroll_area_target_addr				= $15dc ; 2 bytes
	scroll_area_width					= $15de
	scroll_area_height					= $15df
	scroll_area_blank_last_line_flag	= $15e0

	progress_bar_row					= $15e1
	progress_bar_column					= $15e2
	progress_bar_max_length				= $15e3
	progress_bar_segments_to_draw		= $15e4
	progress_bar_bytes_per_segment		= $15e5 ; 3 bytes

	visualizer_mode						= $15e8
	visualizer_base_address				= $15e9 ; 2 bytes

	pattern_conv_pat_counter			= $15eb
	pattern_conv_row_counter			= $15ec
	pattern_conv_trk_counter			= $15ed

	expansion_memory_start_address		= $15ee ; 3 bytes
	match_header						= $15f1

	disk_free_space						= $15f2 ; 2 bytes

	char_table_select					= $15f4 ; C64-only
	print_msg_char_limit				= $15f5

	; free: $15f6 through $1627

	; various program vectors

	fetch_block_vec						= $1628 ; 2 bytes
	stash_block_vec						= $163a ; 2 bytes

	print_vec							= $163c ; 2 bytes

	audio_set_resolution_vec			= $163e ; 2 bytes
	audio_init_vec						= $1640 ; 2 bytes
	audio_start_vec						= $1642 ; 2 bytes
	audio_stop_vec						= $1644 ; 2 bytes

	audio_driver_set_cycle_count_vec	= $1646 ; 2 bytes
	ram_driver_set_cycle_counts_vec		= $1648 ; 2 bytes

	; $free: $164a through $16e9

	loader_compatibility_table			= $16ea ; 22 bytes - devices 8 through 30.

	; mods' lengths are big-endian, but addrs and lengths here are little-
	; endian. each of these is 32 bytes, except the first byte of each one is
	; unused.

	sample_start_addresses_lows			= $1700
	sample_start_addresses_mids			= $1720
	sample_start_addresses_highs		= $1740
	sample_end_addresses_lows			= $1760
	sample_end_addresses_mids			= $1780
	sample_end_addresses_highs			= $17a0
	sample_loop_start_addresses_lows	= $17c0
	sample_loop_start_addresses_mids	= $1800
	sample_loop_start_addresses_highs	= $1820
	sample_loop_end_addresses_lows		= $1840
	sample_loop_end_addresses_mids		= $1860
	sample_loop_end_addresses_highs		= $1880
	sample_default_loop_flags			= $18a0
	sample_default_fine_tunes			= $18c0
	sample_default_volume_levels		= $1900
	mod_instrument_names				= $1920 ; 32 * 31 bytes, through $1dff

	zp_backup							= $1e00 ; 1 page (duh. 😛)
	
	; main program code starts here, followed by free mem
	; then comes all the "high-memory" stuff, beginning at $a900 on C64 or
	; $b100 on C128 -- see constants-64/128.h

	; Under-KERNAL-ROM stuff

	sample_data_buffer					= $f100 ; 8 * 256 bytes

	note_period_table					= $f900 ; 120 bytes + waste
	steprate_table						= $f980 ; 120 bytes + waste

	note_names_table					= $fa00 ; 240 bytes + waste

	divide_by_16_table					= $fb00 ; 1 page

	and_f0_table						= $fc00 ; 1 page

	tempo_table_fracts					= $fd00 ; 1 page
	tempo_table_lows					= $fe00 ; 1 page

	; I/O devices

	VIC_COLOR_RAM						= $d800

	VIC									= $d000
	; C128 only note:  in $D030, only bits 1 & 0 matter, so "test" and 1/2 MHz
	; mode switching will work with any stored value as long as those two bits
	; are correct.

	SID									= $d400
	CIA1								= $dc00
	CIA2								= $dd00

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

; config file declarations - the actual file gets loaded/saved as above

load_device						= config_space+5 ; config header is first 5 bytes
stereo_sid_addr					= load_device+1
dac_addr						= stereo_sid_addr+2
audio_driver					= dac_addr+2
ram_driver						= audio_driver+1
stereo_enable					= ram_driver+1
filter_setting					= stereo_enable+1
resonance_setting				= filter_setting+1
enable_screen_on_playback		= resonance_setting+1
cfg_data_end					= enable_screen_on_playback+2 ; one byte past the real end
