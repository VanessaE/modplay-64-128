; This file defines the C64-specific constants used througout the program.

!addr {

	; Zero page

	print_msg_char_limit			= $22

	one_ten_thousandth_second		= $02a7 ; 2 bytes
	number_of_song_positions		= $02a9
	number_of_patterns				= $02aa
	; free: $02ab, $02ac
	ram_driver_mixer_cycle_count	= $02ad
	playback_speed_fine_tune		= $02ae ; 2 bytes
	config_space					= $02b0 ; 16 bytes

	string_buffer					= $02c0 ; 48 bytes
	uint16_string_buffer			= $02f0 ; 7 bytes (of 8)
	uint16_string_buf_trim			= $02f8 ; 7 bytes (of 8)

	; System vectors from $0300 to $0333

	low_mem_zone					= $0334

	rasters_lo						= $0334
	raster_len						= $0335
	pal_flag						= $0336
	isr_trigger_interval			= $0337 ; 2 bytes
	repeat_mode						= $0339
	volume_tables_resolution		= $033a

	playlist_length					= $033b
	playlist_scroll_pos				= $033c
	playlist_print_file_counter		= $033d
	screen_row_to_print_at			= $033e

	boot_device						= $033f

	current_dir_name				= $0340 ; 16 bytes plus a null
	current_file_name				= $0351 ; 16 bytes plus a null
	current_file_title				= $0362 ; 21 bytes (plus a bunch of nulls)
	current_file_size				= $0380 ; 2 bytes
	current_file_size_in_kb			= $0382 ; 2 bytes
	current_file_type				= $0384
	current_file_tracks				= $0385

	current_menu_page				= $0386
	clear_menu_screen_flag			= $0387

	file_to_load_name_len			= $0388
	file_to_load_size				= $0389 ; 2 bytes
	file_size_in_kb					= $038b ; 2 bytes
	stash_block_vec					= $038d ; 2 bytes
	audio_timing_vec				= $038f ; 2 bytes
	audio_resolution_vec			= $0391 ; 2 bytes
	audio_init_vec					= $0393 ; 2 bytes
	audio_start_vec					= $0395 ; 2 bytes
	audio_stop_vec					= $0397 ; 2 bytes
	print_vec						= $0399 ; 2 bytes
	fetch_row_vec					= $039b ; 2 bytes
	run_mixer_vec					= $039d ; 2 bytes
	mixer_set_timings_vec			= $039f ; 2 bytes

	; more vectors can go here
	; free memory through $03e4

	free_memory_start				= $03e5 ; 3 bytes
	main_memory_free_pages			= $03e8
	reu_highest_bank				= $03e9
	parse_header_sample_pointer		= $03ea ; 3 bytes
	arpeggio_extra_note_first		= $03ed ; \___ 16 bytes
	arpeggio_extra_note_second		= $03f5 ; /

	header_loaded					= $03fd
	rle_mode_flag					= $03fe
	rle_byte_count					= $03ff

	audio_buffer_left				= $0400 ; 256 bytes
	audio_buffer_right				= $0500 ; 256 bytes
	playlist_file_sizes_lows		= $0600 ; \___ 2 bytes * 192 files
	playlist_file_sizes_highs		= $0700 ; /    (128 bytes unused)

	program_start					= $0801 

	; putting the end of free memory at the end of the load buffer allows
	; the program to reclaim it when using the main memory driver.

	free_memory_end					= $8f00

	load_buffer						= $8a00 ; 5 pages
	load_buffer_end					= $8f00
	divide_by_16_table				= $8f00

	blurring_table					= $9000 ; 128 bytes

	playlist_file_flags				= $9100 ; 1 byte * 192 (64 bytes unused)
	playlist_filenames				= $9200 ; 16 bytes * 192 (3 kB)
	playlist_filenames_end			= $9e00

	multablo						= $9e00 ; 512 bytes
	multabhi						= $a000 ; 512 bytes
	multab2lo						= $a200 ; 512 bytes
	multab2hi						= $a400 ; 512 bytes

	volume_tables_low				= $a600 ; 34 pages \__ 16.25 kB, split between
	volume_tables_high				= $e000 ; 31 pages /   two memory areas

	secondary_screen				= $c800 ; 1k
	; primary screen is at $cc00-cfff

	clear_main_memory				= $c800 ; same as secondary screen, since it'll
											;  be wiped the first time a file is played

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
}

; ========================================================================
; From here on down are hard-coded KERNAL/system variables and such

!addr {

	; KERNAL zero-page variables

	TIME							= $a0

	cursor_pointer_text				= $d1
	cursor_col_on_current_line		= $d3
	cursor_pointer_color			= $f3

	FAC								= $61 ; BASIC floating accumulator area
	LDTB1							= $d9 ; screen line link table
	HIBASE							= $0288 ; KERNAL base address for screen

	bcd = FAC
	int16 = FAC+4

	; Other stuff, "low memory area"

	CHAR_COLOR						= $0286 ; current char color for KERNAL prints

	; I/O

	VIC_SCREEN						= $cc00
	VIC_CHARSETS					= $d000

	; KERNAL routines/jump table

	DISPLY							= $ea1c
}

NOSHIFTCOM							= $08

ORG									= $81
MGRY								= $98
DGRY								= $97

lookahead_track_offset = 64
