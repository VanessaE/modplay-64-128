; This file defines the C128-specific constants used througout the program.

!addr {

	; Zero page

	print_msg_char_limit			= $2c

	; "low memory area"

	low_mem_zone					= $0200

	rasters_lo						= $0200
	raster_len						= $0201
	pal_flag						= $0202

	repeat_mode						= $0203
	volume_tables_resolution		= $0204
	last_volume_tables_resolution	= $0205
	allow_regen_msg					= $0206
	playlist_length					= $0207
	playlist_scroll_pos				= $0208
	playlist_print_file_counter		= $0209
	screen_row_to_print_at			= $020a

	boot_device						= $020b

	current_dir_name				= $0210 ; 16 bytes plus a null
	current_file_name				= $0221 ; 16 bytes plus a null
	current_file_title				= $0232 ; 21 bytes (plus a bunch of nulls)
	current_file_size				= $0250 ; 2 bytes
	current_file_size_in_kb			= $0252 ; 2 bytes
	current_file_type				= $0254
	current_file_tracks				= $0255

	current_menu_page				= $0256
	clear_menu_screen_flag			= $0257

	file_to_load_name_len			= $0258
	file_to_load_size				= $0259 ; 2 bytes
	file_size_in_kb					= $025b ; 2 bytes

	; free memory through $0273

	one_ten_thousandth_second		= $0274
	number_of_song_positions		= $0275
	number_of_patterns				= $0276

	audio_driver_isr_cycle_count	= $0277
	ram_driver_cycle_count			= $0278
	isr_trigger_interval			= $0279
	last_isr_trigger_interval		= $027a

	; free: $027b to $027d

	free_memory_start				= $027e ; 3 bytes
	main_memory_free_pages			= $0281 ; refers to bank 0
	c128_highest_bank				= $0282
	reu_highest_bank				= $0283
	parse_header_sample_pointer		= $0284 ; 3 bytes
	arpeggio_counters				= $0287 ; 8 bytes
	arpeggio_extra_note_first		= $028f ; \___ 16 bytes
	arpeggio_extra_note_second		= $0297 ; /
	header_loaded					= $029f
	rle_mode_flag					= $02a0
	rle_byte_count					= $02a1

	; C128 KERNAL indirect routines from $02a2 to $02ff
	; System vectors and variables from $0300 to $03ff

	playlist_file_sizes_lows		= $0400 ; \___ 2 bytes * 192 files
	playlist_file_sizes_highs		= $0500 ; /    (128 bytes unused but will be zeroed)

	multablo						= $0600 ; 512 bytes
	multabhi						= $0800 ; 512 bytes

	; System variables and such from $0a00 to $0aff

	multab2lo						= $0b00 ; 512 bytes
	multab2hi						= $0d00 ; 512 bytes

	playlist_file_flags				= $0f00 ; 1 byte * 192
										; (48 bytes unused but will be zeroed)

	PKYBUF							= $1000
	PKYDEF							= $100a

	config_space					= $1020 ; 16 bytes

	string_buffer					= $1030 ; 48 bytes
	uint16_string_buffer			= $1060 ; 7 bytes (of 8)
	uint16_string_buf_trim			= $1068 ; 7 bytes (of 8)

	stash_block_vec					= $1070 ; 2 bytes

	print_vec						= $1072 ; 2 bytes

	audio_set_resolution_vec		= $1074 ; 2 bytes
	audio_init_vec					= $1076 ; 2 bytes
	audio_start_vec					= $1078 ; 2 bytes
	audio_stop_vec					= $107a ; 2 bytes

	audio_driver_set_cycle_count_vec = $107c ; 2 bytes
	ram_driver_set_cycle_counts_vec	= $107e ; 2 bytes

	; more vectors can go here
	; free memory through $10ff

	audio_buffer_left				= $1100 ; 256 bytes
	audio_buffer_right				= $1200 ; 256 bytes
	; those two pages are only safe to use when KERNAL is switched-out

	clear_main_memory				= $1100

	program_start					= $1301

	; this is the very last byte that'll be loaded in any serial mode,
	; accounting for load addr, plus one disk block for expansion sake.
	splash_128_end_check = program_start + (254*6) - 1

	free_memory_end					= $9400 ; this allows to reclaim the load buf
											; when using the main mem driver

	load_buffer						= $8e00 ; 5*254 bytes, plus the rest of the
	load_buffer_end					= $92f5 ; next 2 pages for overflow
	and_f0_table					= $9400
	divide_by_16_table				= $9500

	pitch_table_fracts				= $9600 ; 7 pages
	pitch_table_lows				= $9d00 ; 3 pages

	tempo_table_fracts				= $a000
	tempo_table_lows				= $a100

	playlist_filenames				= $a200 ; 16 bytes * 192 (3 kB)
	playlist_filenames_end			= $ae00

	volume_table_lower				= $ae00 ; 34 pages \__ 16.25 kB, split between
	volume_table_upper				= $e000 ; 31 pages /   two memory areas

	; config file declarations - the actual file gets loaded/saved as above

	load_device						= config_space+5 ; config header is first 5 bytes
	stereo_sid_addr					= load_device+1
	dac_addr						= stereo_sid_addr+2
	audio_driver					= dac_addr+2
	ram_driver						= audio_driver+1
	stereo_enable					= ram_driver+1
	filter_setting					= stereo_enable+1
	resonance_setting				= filter_setting+1
	cfg_data_end					= resonance_setting+1 ; one byte past the real end
}

; =================================================================
; From here on down are hard-coded KERNAL/system variables and such

!addr {

	; KERNAL zero-page variables

	FAC								= $63
	kernal_4080_mode				= $d7

	indstash_addr					= $ae ; same as EAL
	indfetch_addr					= $bb

	cursor_pointer_text				= $e0
	cursor_pointer_color			= $e2
	cursor_col_on_current_line		= $ec

	SCBOT							= $e4 ; bottom, top, left, right edges
	SCTOP							= $e5 ; of screen/window
	SCLF							= $e6
	SCRT							= $e7
	TBLX							= $eb ; cursor line
	PNTR							= $ec ; cursor column
	LINES							= $ed
	COLUMNS							= $ee

	CHAR_COLOR						= $f1 ; current char color for KERNAL prints

	bcd = FAC
	int16 = FAC+4

	; System variables/vectors

	IND_FETCH						= $02a2
	IND_STASH						= $02af

	IOINIT_MODE						= $0a04
	RPTFLAG							= $0a22

	; I/O

	VIC_SCREEN						= $0400
	VDC_SCREEN						= $0000
	VDC_ATTRIBUTES					= $0800
	VDC_CHARSETS					= $2000
	VDC_VM3							= $0a2e ; base of VDC screen mem

	MMU								= $d500
	VDC								= $d600

	; KERNAL routines/jump table

	DISPLY							= $cc34

	SWAPPER							= $ff5f
	SETBNK							= $ff68

}

ORG									= LRED
MGRY								= DGRY
DGRY								= $98
DPUR								= $81
DCYN								= $97

TAB									= $09

NOSHIFTCOM							= $0b ; C128 PRG says $0c but that's wrong
ESC									= $1b

FLASHON								= $0f
FLASHOFF							= $8f
