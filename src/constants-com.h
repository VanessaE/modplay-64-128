; This file defines all of the non-machine-specific constants used througout the program.

program_start							= $2000

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

	tempzpbk_g							= $02 ; 4 bytes
	tempzpbk_h							= $06
	tempzpbk_j							= $07
	visualizer_address_tempzpbk_a		= $08 ; and $09
	visualizer_address_tempzpbk_b		= $0a ; and $0b

	; free: $0d through $23

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

	; free: $2a

	pattern_break_target_row			= $2b
	seq_current_pattern_number			= $2c
	seq_current_row						= $2d
	seq_current_track					= $2e
	seq_ticks_counter					= $2f
	current_song_pos					= $30
	glissando_flag						= $31
	vibrato_waveform					= $32
	tremolo_waveform					= $33
	delay_pattern_divisions				= $34
	audio_in_buf_index					= $35
	audio_out_buf_index					= $36
	mixer_loops_per_tick_fract			= $37
	mixer_loops_per_tick				= $38
	mixer_countdown_fract				= $39
	mixer_countdown						= $3a
	sequencer_temp_x					= $3b
	sequencer_temp_y					= $3c
	sequencer_temp_a					= $3d ; 2 bytes \__ these can also be used
	sequencer_temp_b					= $3f ; 2 bytes /   as one 4-byte temp
	current_sample_volume_levels		= $41 ; 8 bytes
	portamento_to_note_rates			= $49 ; 8 bytes
	pitch_slide_up_rates				= $51 ; 8 bytes

	; division remainder uses $59 through $5b
	; multiply product uses $5c/$5d
	; binary search binsearch_value is at $59/$5a

	song_speed							= $5e

	; divide24_tmp uses $5f

	seq_tempo_bpm						= $60
	seq_ticks_per_division				= $61
	pitch_slide_down_rates				= $62 ; 8 bytes
	track_current_loop_flags			= $6a ; 8 bytes
	fine_tune_values					= $72 ; 8 bytes
	retrigger_rates						= $7a ; 8 bytes
	cut_sample_ticks					= $82 ; 8 bytes
	delay_sample_ticks					= $8a ; 8 bytes
	current_sample_numbers				= $92 ; 8 bytes
	vibrato_rates						= $9a ; 8 bytes
	tremolo_rates						= $a2 ; 8 bytes
	volume_slide_rates					= $aa ; 8 bytes
	current_steprates_fract				= $b2 ; \___ 16 bytes
	current_steprates_lows				= $ba ; /
	sample_pointers_fract				= $c2 ; ¯|
	sample_pointers_lows				= $ca ;  |___32 bytes
	sample_pointers_mids				= $d2 ;  |
	sample_pointers_highs				= $da ; _|
	current_sample_end_addr_lows		= $e2 ; ¯|
	current_sample_end_addr_mids		= $ea ;  |-- 24 bytes, through $ff
	current_sample_end_addr_highs		= $f2 ; _|

	; utility_pointer uses $fa/$fb
	; and $fc through $ff are reserved for more dual ZP-backup/no-backup
	; allowed vars

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

	tempzp_f							= $50 ; through $52

	binsearch_low						= $24 ; and $25
	binsearch_mid						= $26 ; and $27
	binsearch_high						= $28 ; and $29
	binsearch_value						= $59 ; and $5a

	fill_copy_src						= $24 ; and $25
	write_fill_copy_target				= $26 ; and $27

	utility_pointer						= $fa ; and $fb

	; free: $fc through $ff

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
	track_current_enable_flags			= low_memory_area+$18

	seq_current_row_data				= low_memory_area+$20 ; this one's 64 bytes
	seq_commands						= low_memory_area+$60
	seq_prev_commands					= low_memory_area+$68
	seq_command_arguments				= low_memory_area+$70
	seq_prev_command_arguments			= low_memory_area+$78

	current_pitch_slide_flags			= low_memory_area+$80
	seq_pitch_slide_stop_point_lows		= low_memory_area+$88
	seq_pitch_slide_stop_point_highs	= low_memory_area+$90

	; the above zone must not exceed low_memory_area+$a1
	; otherwise it'll stomp on C128 indirect routines.

	load_buffer							= $0400 ; 5*254 bytes, plus the rest of the
	load_buffer_end						= $08f5 ; for overflow

	and_f0_table						= $0900 ; 1 page

	; C64 has the blurring table at $0a00 through $0a7f, free through $0aff
	; C128 has system variables and such in that space

	multablo							= $0b00 ; 2 pages
	multabhi							= $0d00 ; 2 pages

	zp_backup							= $0f00 ; 1 page (duh. 😛)

	; on C128, $1000-$101f is used for F-key defs, required by the KERNAL.
	; C64, $1000-$101f holds a windowing.s table

	control_code_flags_table_low		= $1020
	control_code_flags_table_high		= $1040
	semitones_table_fracts				= $1060
	semitones_table_lows				= $1070

	pattern_table						= $1080

	clear_main_memory					= pattern_table

	; on C128, these next two pages can only be used by transient stuff
	; so that's a good place for the two audio buffers

	audio_buffer_left					= $1100 ; 1 page
	audio_buffer_right					= $1200 ; 1 page

	multab2lo							= $1300 ; 2 pages
	multab2hi							= $1500 ; 2 pages

	; All of the various tables, buffers (both C64 and C128)

	main_variables_zone					= $1700

	config_space						= $1700 ; 16 bytes

	one_ten_thousandth_second			= $1710 ; 2 bytes
	number_of_song_positions			= $1712
	number_of_patterns					= $1713

	audio_driver_isr_cycle_count		= $1714
	ram_driver_cycle_count				= $1715
	isr_trigger_interval				= $1716
	last_isr_trigger_interval			= $1717
	playlist_length						= $1718
	playlist_scroll_pos					= $1719
	playlist_print_file_counter			= $171a
	screen_row_to_print_at				= $171b
	rasters_lo							= $171c
	raster_len							= $171d
	pal_flag							= $171e
	boot_device							= $171f

	string_buffer						= $1720 ; 48 bytes
	uint16_string_buffer				= $1750 ; 7 bytes (of 8)
	uint16_string_buf_trim				= $1758 ; 7 bytes (of 8)

	current_dir_name					= $1760 ; 16 bytes plus a null
	current_file_name					= $1771 ; 16 bytes plus a null
	current_file_title					= $1782 ; 21 bytes (plus a bunch of nulls)
	current_file_size					= $17a0 ; 2 bytes
	current_file_size_in_kb				= $17a2 ; 2 bytes
	current_file_type					= $17a4
	current_file_tracks					= $17a5

	current_menu_page					= $17a6
	clear_menu_screen_flag				= $17a7

	file_to_load_name_len				= $17a8
	file_to_load_size					= $17a9 ; 2 bytes
	file_size_in_kb						= $17ab ; 2 bytes
	header_loaded						= $17ad

	reu_highest_bank					= $17ae
	ramlink_detect						= $17af
	main_memory_free_pages				= $17b0

	old_STOP_vec						= $17b1 ; 2 bytes
	parse_header_sample_pointer			= $17b3 ; 3 bytes
	arpeggio_extra_note_first			= $17b6 ; \___ 16 bytes
	arpeggio_extra_note_second			= $17be ; /

	repeat_mode							= $17c6
	volume_tables_resolution			= $17c7
	last_volume_tables_resolution		= $17c8
	allow_regen_msg						= $17c9

	seq_abort_flag						= $17ca

	top_row_pos							= $17cb
	bottom_row_pos						= $17cc
	left_column_pos						= $17cd
	right_column_pos					= $17ce
	num_rows							= $17cf
	num_columns							= $17d0

	match_header						= $17d1
	stash_size							= $17d2 ; 2 bytes

	expansion_memory_start_address		= $17d4 ; 3 bytes
	temp_abs_a							= $17d7
	temp_abs_b							= $17d8
	temp_abs_c							= $17d9
	temp_abs_x							= $17da
	temp_abs_y							= $17db
	scroll_area_target_addr				= $17dc ; 2 bytes
	scroll_area_width					= $17de
	scroll_area_height					= $17df
	scroll_area_blank_last_line_flag	= $17e0

	progress_bar_row					= $17e1
	progress_bar_column					= $17e2
	progress_bar_max_length				= $17e3
	progress_bar_segments_to_draw		= $17e4
	progress_bar_bytes_per_segment		= $17e5 ; 3 bytes

	visualizer_mode						= $17e8
	visualizer_base_address				= $17e9 ; 2 bytes

	pattern_conv_pat_counter			= $17eb
	pattern_conv_row_counter			= $17ec
	pattern_conv_trk_counter			= $17ed

	; free: $17ee through $1827

	; various program vectors

	fetch_block_vec						= $1828 ; 2 bytes
	stash_block_vec						= $183a ; 2 bytes

	print_vec							= $183c ; 2 bytes

	audio_set_resolution_vec			= $183e ; 2 bytes
	audio_init_vec						= $1840 ; 2 bytes
	audio_start_vec						= $1842 ; 2 bytes
	audio_stop_vec						= $1844 ; 2 bytes

	audio_driver_set_cycle_count_vec	= $1846 ; 2 bytes
	ram_driver_set_cycle_counts_vec		= $1848 ; 2 bytes

	note_period_table					= $184a ; 120 bytes
	steprate_table						= $18c2 ; 120 bytes

	note_names_table					= $193a ; 240 bytes

	loader_compatibility_table			= $1a2a ; 22 bytes - devices 8 through 30.

	; mods' lengths are big-endian, but addrs and lengths here are little-
	; endian. each of these is 32 bytes, except the first byte of each one is
	; unused.

	sample_start_addresses_lows			= $1a40
	sample_start_addresses_mids			= $1a60
	sample_start_addresses_highs		= $1a80
	sample_end_addresses_lows			= $1aa0
	sample_end_addresses_mids			= $1ac0
	sample_end_addresses_highs			= $1ae0
	sample_loop_start_addresses_lows	= $1b00
	sample_loop_start_addresses_mids	= $1b20
	sample_loop_start_addresses_highs	= $1b40
	sample_loop_end_addresses_lows		= $1b60
	sample_loop_end_addresses_mids		= $1b80
	sample_loop_end_addresses_highs		= $1ba0
	sample_default_loop_flags			= $1bc0
	sample_default_fine_tunes			= $1be0
	sample_default_volume_levels		= $1c00
	mod_instrument_names				= $1c20 ; 32 * 31 bytes, through $1fff

	; main program code starts here, followed by free mem
	; then comes all the "high-memory" stuff

	divide_by_16_table					= $8a00

	playlist_file_sizes_lows			= $8b00 ; \___ 2 bytes * 192 files
	playlist_file_sizes_highs			= $8c00 ; /    (128 bytes unused but will be zeroed)
	playlist_file_flags					= $8d00 ; 1 byte * 192
												; (48 bytes unused but will be zeroed)

	playlist_filenames					= $8e00 ; 16 bytes * 192 (3 kB)
	playlist_filenames_end				= $9a00

	volume_table_lower					= $9a00 ; 46 pages \__ 65 pages/16.25 kB, split
	volume_table_upper					= $e000 ; 19 pages /   between two memory areas

	; on C64, $c800-$cfff are screens, sample data buffer on C128

	; other under-KERNAL-ROM stuff

	; free: $f300through $feff

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
