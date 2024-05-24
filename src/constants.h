; This file defines all the various constants used througout the program.

!addr {

	; KERNAL zero-page variables

	STATUS							= $90
	MSGFLG							= $9d
	EAL								= $ae
	FA								= $ba

	!ifndef c128 {
		print_msg_char_limit		= $22

		TIME						= $a0

		cursor_pointer_text			= $d1
		cursor_col_on_current_line	= $d3
		cursor_pointer_color		= $f3

		FAC							= $61 ; BASIC floating accumulator area
		LDTB1						= $d9 ; screen line link table
		HIBASE						= $0288 ; KERNAL base address for screen

	} else {
		print_msg_char_limit		= $2c

		FAC							= $63
		kernal_4080_mode			= $d7

		indstash_addr				= $ae ; same as EAL
		indfetch_addr				= $bb

		cursor_pointer_text			= $e0
		cursor_pointer_color		= $e2
		cursor_col_on_current_line	= $ec

		SCBOT						= $e4 ; bottom, top, left, right edges
		SCTOP						= $e5 ; of screen/window, C128 only
		SCLF						= $e6
		SCRT						= $e7
		TBLX						= $eb ; cursor line
		PNTR						= $ec ; cursor column
		LINES						= $ed
		COLUMNS						= $ee

		CHAR_COLOR					= $f1 ; current char color for KERNAL prints
	}

	bcd = FAC
	int16 = FAC+4

	; The rest of these Zero Page addrs can be the same on both C64 and C128

	divisor							= $24 ; to $26
	dividend						= $27 ; to $29
	remainder						= $59 ; to $5b
	quotient = dividend ;save memory by reusing dividend to store the result

	product							= $5c ; and $5d / the product from multiply routine

	stash_pointer					= $5c ; to $5e, expansion RAM stash target addr
										  ; only used within the loader

	print_msg_addr					= $5f ; and $60
	save_addr						= $5f ; and $60

	tempzp_c						= $2a
	tempzp_d						= $50 ; and $51
	tempzp_e						= $52 ; and $53
	tempzp_f						= $fa ; through $fd

	load_pointer					= $fe ; and $ff
	filename_addr					= $fe ; and $ff

	; ####################################################
	; ###  Zero page WHEN BACKED-UP
	; e.g. only when player is running and no KERNAL
	; or BASIC is needed

	; these various multiples of 8 bytes are in order by track number

	volume_table_vectors			= $02 ; 16 bytes
	current_sample_volume_levels	= $12 ; 8 bytes
	track_byte_to_mix				= $1a ; 8 bytes
	audio_in_buf_index				= $22
	audio_out_buf_index				= $23

	; because they're needed both inside and outside of the player, multiply
	; and divide routines' zero page variables have to be in the same places
	; within the "backup-mode" as they are outside of it.

	; for divide, divisor uses $24 to $26
	; dividend/quotient uses $27 to $29

	pitch_slide_up_rates			= $3a ; 8 bytes
	pitch_slide_down_rates			= $42 ; 8 bytes
	pitch_slide_to_note_rates		= $4a ; 8 bytes

	glissando_flag					= $52
	vibrato_waveform				= $53
	tremolo_waveform				= $54
	delay_pattern_divisions			= $55
	song_speed						= $56
	current_song_pos				= $57
	number_of_song_positions		= $58

	; division remainder uses $59 to $5b
	; multiply product uses $5c and $5d

	seq_current_pattern_number		= $5e
	number_of_patterns				= $5f
	pattern_address					= $60 ; 3 bytes
	pattern_break_target_row		= $63
	tempzp_g						= $64 ; 4 bytes

	; free: $68 through $6d

	mixer_output_countdown			= $6e ; 2 bytes
	track_current_loop_flags		= $70 ; 8 bytes
	fine_tune_values				= $78 ; 8 bytes
	retrigger_rates					= $80 ; 8 bytes
	cut_sample_ticks				= $88 ; 8 bytes
	delay_sample_ticks				= $90 ; 8 bytes
	current_sample_numbers			= $98
	vibrato_rates					= $a0 ; 8 bytes
	tremolo_rates					= $a8 ; 8 bytes
	volume_slide_rates				= $b0 ; 8 bytes
	current_steprates_fract			= $b8 ; \___ 16 bytes
	current_steprates_lows			= $c0 ; /
	sample_pointers_fract			= $c8 ; ¯|
	sample_pointers_lows			= $d0 ;  |___32 bytes
	sample_pointers_mids			= $d8 ;  |
	sample_pointers_highs			= $e0 ; _|
	current_sample_end_addr_lows	= $e8 ; ¯|
	current_sample_end_addr_mids	= $f0 ;  |-- 24 bytes, through $ff
	current_sample_end_addr_highs	= $f8 ; _|

	; ### End of zero-page backup
	; ####################################################

	; Other stuff, "low memory area"

	!ifndef c128 {

		CHAR_COLOR					= $0286 ; current char color for KERNAL prints

		; free memory -- $02a7 to $02af

		config_space				= $02b0 ; 16 bytes

		string_buffer				= $02c0 ; 48 bytes
		uint16_string_buffer		= $02f0 ; 7 bytes (of 8)
		uint16_string_buf_trim		= $02f8 ; 7 bytes (of 8)

		; System vectors from $0300 to $0333

		low_mem_zone				= $0334

		rasters_lo					= $0334
		raster_len					= $0335
		pal_flag					= $0336
		isr_cycle_time				= $0337
		isr_cycle_time_alt			= $0338

		repeat_mode					= $0339
		volume_tables_resolution	= $033a

		playlist_length				= $033b
		playlist_scroll_pos			= $033c
		playlist_print_file_counter	= $033d
		screen_row_to_print_at		= $033e

		boot_device					= $033f

		current_dir_name			= $0340 ; 16 bytes plus a null
		current_file_name			= $0351 ; 16 bytes plus a null
		current_file_title			= $0362 ; 21 bytes (plus a bunch of nulls)
		current_file_size			= $0380 ; 2 bytes
		current_file_size_in_kb		= $0382 ; 2 bytes
		current_file_type			= $0384
		current_file_tracks			= $0385

		current_menu_page			= $0386
		clear_menu_screen_flag		= $0387

		file_to_load_name_len		= $0388
		file_to_load_size			= $0389 ; 2 bytes
		file_size_in_kb				= $038b ; 2 bytes
		stash_block_vec				= $038d ; 2 bytes
		audio_timing_res_vec		= $038f ; 2 bytes
		audio_init_vec				= $0391 ; 2 bytes
		audio_start_vec				= $0393 ; 2 bytes
		audio_stop_vec				= $0395 ; 2 bytes
		print_vec					= $0397 ; 2 bytes
		fetch_row_vec				= $0399 ; 2 bytes
		run_mixer_vec				= $039b ; 2 bytes

		; more vectors can go here

		free_memory_start			= $03ad ; 3 bytes
		main_memory_free_pages		= $03a0
		reu_highest_bank			= $03a1
		parse_header_sample_pointer = $03a2 ; 3 bytes

		; free memory through $03ee
		arpeggio_extra_note_first	= $03ed ; \___ 16 bytes
		arpeggio_extra_note_second	= $03f5 ; /

		header_loaded				= $03fd
		rle_mode_flag				= $03fe
		rle_byte_count				= $03ff

		audio_buffer_left			= $0400 ; 256 bytes
		audio_buffer_right			= $0500 ; 256 bytes
		playlist_file_sizes_lows	= $0600 ; \___ 2 bytes * 192 files
		playlist_file_sizes_highs	= $0700 ; /    (128 bytes unused)

		program_start				= $0801 

		; putting the end of free memory at the end of the load buffer allows
		; the program to reclaim it when using the main memory driver.

		free_memory_end				= $9000

		;log_table_base				= ???? ; will need 2k

		load_buffer					= $8b00 ; 5 pages
		load_buffer_end				= $9000
		divide_by_16_table			= $9000

		playlist_file_flags			= $9100 ; 1 byte * 192 (64 bytes unused)
		playlist_filenames			= $9200 ; 16 bytes * 192 (3 kB)
		playlist_filenames_end		= $9e00

		multablo					= $9e00 ; 512 bytes
		multabhi					= $a000 ; 512 bytes
		multab2lo					= $a200 ; 512 bytes
		multab2hi					= $a400 ; 512 bytes

		volume_tables_low			= $a600 ; 34 pages \__ 16.25 kB, split between
		volume_tables_high			= $e000 ; 31 pages /   two memory areas

		secondary_screen			= $c800 ; 1k
		; primary screen is at $cc00-cfff

		clear_main_memory			= $c800 ; same as secondary screen, since it'll
											;  be wiped the first time a file is played

		blurring_table				= $ff00 ; 128 bytes

	} else {

		low_mem_zone				= $0200

		rasters_lo					= $0200
		raster_len					= $0201
		pal_flag					= $0202
		isr_cycle_time				= $0203
		isr_cycle_time_alt			= $0204

		repeat_mode					= $0205
		volume_tables_resolution	= $0206

		playlist_length				= $0207
		playlist_scroll_pos			= $0208
		playlist_print_file_counter	= $0209
		screen_row_to_print_at		= $020a

		boot_device					= $020b

		current_dir_name			= $0210 ; 16 bytes plus a null
		current_file_name			= $0221 ; 16 bytes plus a null
		current_file_title			= $0232 ; 21 bytes (plus a bunch of nulls)
		current_file_size			= $0250 ; 2 bytes
		current_file_size_in_kb		= $0252 ; 2 bytes
		current_file_type			= $0254
		current_file_tracks			= $0255

		current_menu_page			= $0256
		clear_menu_screen_flag		= $0257

		file_to_load_name_len		= $0258
		file_to_load_size			= $0259 ; 2 bytes
		file_size_in_kb				= $025b ; 2 bytes
		stash_block_vec				= $025d ; 2 bytes
		audio_timing_res_vec		= $0261 ; 2 bytes
		audio_init_vec				= $0263 ; 2 bytes
		audio_start_vec				= $0265 ; 2 bytes
		audio_stop_vec				= $0267 ; 2 bytes
		print_vec					= $0269 ; 2 bytes
		fetch_row_vec				= $026a ; 2 bytes
		run_mixer_vec				= $026c ; 2 bytes

		; more vectors can go here

		free_memory_start			= $027e ; 3 bytes
		main_memory_free_pages		= $0281 ; refers to bank 0
		c128_highest_bank			= $0282
		reu_highest_bank			= $0283
		parse_header_sample_pointer = $0284 ; 3 bytes
		arpeggio_counters			= $0287 ; 8 bytes
		arpeggio_extra_note_first	= $028f ; \___ 16 bytes
		arpeggio_extra_note_second	= $0297 ; /
		header_loaded				= $029f
		rle_mode_flag				= $02a0
		rle_byte_count				= $02a1

		; C128 KERNAL indirect routines from $02a2 to $02ff
		; System vectors and variables from $0300 to $03ff

		playlist_file_sizes_lows	= $0400 ; \___ 2 bytes * 192 files
		playlist_file_sizes_highs	= $0500 ; /    (128 bytes unused but will be zeroed)

		multablo					= $0600 ; 512 bytes
		multabhi					= $0800 ; 512 bytes

		; System variables and such from $0a00 to $0aff

		multab2lo					= $0b00 ; 512 bytes
		multab2hi					= $0d00 ; 512 bytes

		playlist_file_flags			= $0f00 ; 1 byte * 192
											; (48 bytes unused but will be zeroed)

		PKYBUF						= $1000
		PKYDEF						= $100a

		config_space				= $1020 ; 16 bytes

		string_buffer				= $1030 ; 48 bytes
		uint16_string_buffer		= $1060 ; 7 bytes (of 8)
		uint16_string_buf_trim		= $1068 ; 7 bytes (of 8)

		; free memory -- $1070 to $10ff

		audio_buffer_left			= $1100 ; 256 bytes
		audio_buffer_right			= $1200 ; 256 bytes
		; those two pages are only safe to use when KERNAL is switched-out

		clear_main_memory			= $1100

		program_start				= $1301

		; this is the very last byte that'll be loaded in any serial mode,
		; accounting for load addr, plus one disk block for expansion sake.
		splash_128_end_check = program_start + (254*6) - 1

		free_memory_end				= $a000 ; this allows to reclaim the load buf
											; when using the main mem driver

		load_buffer					= $9a00 ; 5*254 bytes (plus some waste)
		load_buffer_end				= $9ef5 ; plus one page for overflow

		;log_table_base				= ???? ; will need 2k

		divide_by_16_table			= $a000

		blurring_table				= $a100 ; 128 bytes

		playlist_filenames			= $a200 ; 16 bytes * 192 (3 kB)
		playlist_filenames_end		= $ae00

		volume_tables_low			= $ae00 ; 34 pages \__ 16.25 kB, split between
		volume_tables_high			= $e000 ; 31 pages /   two memory areas

	}

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

	; System variables/vectors
	!ifdef c128 {
		IND_FETCH					= $02a2
		IND_STASH					= $02af

		IOINIT_MODE					= $0a04
		RPTFLAG						= $0a22
	}

	CHROUT_vec						= $0326
	CINV_vec						= $0314
	CHRIN_vec						= $0324
	STOP_vec						= $0328

	; I/O

	!ifdef c128 {
		VIC_SCREEN					= $0400
		VDC_SCREEN					= $0000
		VDC_ATTRIBUTES				= $0800
		vdc_secondary_screen		= $1000
		VDC_CHARSETS				= $2000
		VDC_VM3						= $0a2e ; base of VDC screen mem
	} else {
		VIC_SCREEN					= $cc00
		VIC_CHARSETS				= $d000
	}

	VIC_COLOR_RAM					= $d800

	VIC								= $d000
	SID								= $d400
	MMU								= $d500		; C128 only, of course
	VDC								= $d600		; ditto :)
	CIA1							= $dc00
	CIA2							= $dd00

	DMA_CMD							= $df01

	DMA_ADL							= $df02		; local address
	DMA_ADH							= $df03

	DMA_LO							= $df04		; REU address
	DMA_HI							= $df05
	DMA_BANK						= $df06

	DMA_DAL							= $df07		; transfer length
	DMA_DAH							= $df08

	; KERNAL routines/jump table

	!ifndef c128 {
		DISPLY						= $ea1c
	} else {
		DISPLY						= $cc34
	}

	SWAPPER							= $ff5f ; C128 only
	SETBNK							= $ff68 ; C128 only

	CINT							= $ff81
	IOINIT							= $ff84
	RESTOR							= $ff8a
	READST							= $ffb7

	SECND							= $ff93
	TKSA							= $ff96
	ACPTR							= $ffa5
	CIOUT							= $ffa8
	UNTLK							= $ffab
	UNLSN							= $ffae
	LISTN							= $ffb1
	TALK							= $ffb4

	SETLFS							= $ffba
	SETNAM							= $ffbd
	LOAD							= $ffd5
	SAVE							= $ffd8

	OPEN							= $ffc0
	CLRCH							= $ffcc
	CLOSE							= $ffc3

	CHKIN							= $ffc6
	CHKOUT							= $ffc9
	CHRIN							= $ffcf
	CHROUT							= $ffd2
	STOP							= $ffe1
	GETIN							= $ffe4
	CLALL							= $ffe7

	PLOT							= $fff0

	; CPU vectors

	CPU_NMI_vector					= $fffa
	CPU_IRQ_vector					= $fffe

}

; PETSCII color/control codes

BLK								= $90
WHT								= $05
RED								= $1c
CYAN							= $9f
PUR								= $9c
GRN								= $1e
BLUE							= $1f
YEL								= $9e
BRN								= $95
LRED							= $96
LGRN							= $99
LBLU							= $9a
LGRY							= $9b

!ifndef c128 {
	ORG							= $81
	MGRY						= $98
	DGRY						= $97

	DPUR						= PUR
	DCYN						= CYAN
} else {
	DPUR						= $81
	DGRY						= $98
	DCYN						= $97

	ORG							= LRED
	MGRY						= DGRY

	TAB							= $09
}

HOME							= $13
CLR								= $93

DEL								= $14

UP								= $91
DOWN							= $11
LEFT							= $9d
RIGHT							= $1d

RETURN							= $0d

LOWER							= $0e

RVSON							= $12
RVSOFF							= $92

!ifndef c128 {
	NOSHIFTCOM					= $08
} else {
	NOSHIFTCOM					= $0b ; C128 PRG says $0c but that's wrong
	ESC							= $1b

	FLASHON						= $0f
	FLASHOFF					= $8f
}

; Misc

X = "X" ; so that the delay routine doesn't
Y = "Y" ; need to be called with X or Y in quotes.

header15_seek_to_pt				= 20+15*(22+2+1+1+2+2)+1+1 ; (472)
header31_seek_to_pt				= 20+31*(22+2+1+1+2+2)+1+1 ; (952)
header_first_inst_meta_offset	= 20
instrument_metadata_size		= 22+2+1+1+2+2 ; (30)
