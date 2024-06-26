; This file defines all of the non-machine-specific constants used througout the program.

program_start						= $1700

!addr {
	; KERNAL zero-page variables

	STATUS							= $90
	MSGFLG							= $9d
	EAL								= $ae
	FA								= $ba

	; ####################################################
	; ###  Zero Page WHEN BACKED-UP
	; e.g. only when player is running and no KERNAL
	; or BASIC is needed

	tempzpbk_g						= $02 ; 4 bytes

	; free: $06 through $23

	; because they're needed both inside and outside of the player, multiply
	; and divide routines' zero page variables have to be in the same places
	; within the "backup-mode" as they are outside of it.

	; for 16/16 or 24/24 divide:
	; dividend/quotient uses $24 to $26
	; divisor uses $27 to $29

	; for 32/16 divide:
	; dividend32/quotient32 uses $24 to $27
	; divisor16 uses $28 and $29

	; the various multiples of 8 bytes below are in order by track number

	; free: $24 through $33

	pattern_address					= $35 ; 3 bytes
	pattern_break_target_row		= $38
	seq_current_pattern_number		= $39
	seq_current_row					= $3a
	seq_current_track				= $3b
	seq_tempo_bpm					= $3c
	seq_ticks_per_division			= $3d
	seq_ticks_counter				= $3e
	current_song_pos				= $3f
	glissando_flag					= $40
	vibrato_waveform				= $41
	tremolo_waveform				= $42
	delay_pattern_divisions			= $43
	audio_in_buf_index				= $44
	audio_out_buf_index				= $45
	mixer_loops_per_tick_fract		= $46
	mixer_loops_per_tick			= $47
	mixer_countdown_fract			= $48
	mixer_countdown					= $49
	sequencer_temp_x				= $4a
	sequencer_temp_y				= $4b
	sequencer_temp_a				= $4c ; 2 bytes \__ these can also be used
	sequencer_temp_b				= $4e ; 2 bytes /   as one 4-byte temp
	current_sample_volume_levels	= $50 ; 8 bytes
	portamento_to_note_rates		= $58 ; 8 bytes

	; division remainder uses $59 to $5b
	; multiply product uses $5c and $5d

	song_speed						= $5e

	; divide24_tmp uses $5f

	pitch_slide_up_rates			= $60 ; 8 bytes
	pitch_slide_down_rates			= $68 ; 8 bytes
	track_current_loop_flags		= $70 ; 8 bytes
	fine_tune_values				= $78 ; 8 bytes
	retrigger_rates					= $80 ; 8 bytes
	cut_sample_ticks				= $88 ; 8 bytes
	delay_sample_ticks				= $90 ; 8 bytes
	current_sample_numbers			= $98 ; 8 bytes
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

	; ### End of Zero Page backup
	; ####################################################

	; The rest of these Zero Page addrs can be the same on both C64 and C128
	; and are for use when Zero Page is not backed-up.

	dividend						= $24 ; to $26
	divisor							= $27 ; to $29

	remainder						= $59 ; to $5b
	quotient = dividend

	dividend32						= $24 ; to $27
	divisor16						= $28 ; and $29
	quotient32 = dividend32

	rle_mode_flag					= $24 ; safe to overwrite - math ops aren't used
	rle_byte_count					= $25 ; at the same time as RLE printing

	load_pointer					= $59 ; and $60
	filename_addr					= $59 ; and $60

	product							= $5c ; and $5d / the product from multiply routine

	stash_pointer					= $5c ; to $5e, expansion RAM stash target addr
										  ; only used within the loader

	print_msg_addr					= $5f ; and $60
	save_addr						= $5f ; and $60
	divide24_tmp					= $5f

	tempzp_f						= $50 ; through $52

	; free: $fa through $ff

}

; =================================================================
; From here on down are hard-coded KERNAL/system variables common
; to all machines

!addr {

	; System vectors

	CHROUT_vec						= $0326
	CINV_vec						= $0314
	KERNAL_NMI_vec					= $0318
	CHRIN_vec						= $0324
	STOP_vec						= $0328

	; I/O

	VIC_COLOR_RAM					= $d800

	VIC								= $d000
; C128 only note:  in $D030, only bits 1 & 0 matter, so "test" and 1/2 MHz mode
; switches will work with any stored value as long as those two bits are correct.

	SID								= $d400
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

	RAMLINK_REG_ENABLE				= $df7e
	RAMLINK_REG_DISABLE				= $df7f
	RAMLINK_8255_PORT_C				= $df42

	; KERNAL

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

header15_seek_to_pt					= 20+15*(22+2+1+1+2+2)+1+1 ; (472)
header31_seek_to_pt					= 20+31*(22+2+1+1+2+2)+1+1 ; (952)
header_first_inst_meta_offset		= 20
instrument_metadata_size			= 22+2+1+1+2+2 ; (30)

one_ten_thou_pal = int(985248 / 10000) - 1
one_ten_thou_ntsc = int(1022727 / 10000) - 1

pitch_fine_adjust_constant = 57
tempo_fine_adjust_constant = 159778

!addr {

	; sequencer/player variables -- most of these are 8 bytes each
	; these are placed in areas of memory where it's okay if they get trashed,
	; so long as the area is stable while the player/seqencer is running.

	current_note_periods_lows		= low_memory_area
	current_note_periods_highs		= low_memory_area+$08
	current_node_period_offsets		= low_memory_area+$10
	track_current_enable_flags		= low_memory_area+$18

	seq_current_row_data			= low_memory_area+$20 ; this one's 64 bytes
	seq_commands					= low_memory_area+$60
	seq_prev_commands				= low_memory_area+$68
	seq_command_arguments			= low_memory_area+$70
	seq_prev_command_arguments		= low_memory_area+$78

	current_pitch_slide_flags		= low_memory_area+$80
	seq_pitch_slide_stop_point_lows	= low_memory_area+$88
	seq_pitch_slide_stop_point_highs = low_memory_area+$90

	; the above zone must not exceed low_memory_area+$a1
	; otherwise it'll stomp on C128 indirect routines.

	load_buffer						= $0400 ; 5*254 bytes, plus the rest of the
	load_buffer_end					= $08f5 ; for overflow

	; All of the various tables, buffers, etc. that fit into 
	; the $0400-and-up area (both C64 and C128)

	main_variables_zone				= $0900

	config_space					= $0900 ; 16 bytes

	one_ten_thousandth_second		= $0910 ; 2 bytes
	number_of_song_positions		= $0912
	number_of_patterns				= $0913

	audio_driver_isr_cycle_count	= $0914
	ram_driver_cycle_count			= $0915
	isr_trigger_interval			= $0916
	last_isr_trigger_interval		= $0917
	playlist_length					= $0918
	playlist_scroll_pos				= $0919
	playlist_print_file_counter		= $091a
	screen_row_to_print_at			= $091b
	rasters_lo						= $091c
	raster_len						= $091d
	pal_flag						= $091e
	boot_device						= $091f

	string_buffer					= $0920 ; 48 bytes
	uint16_string_buffer			= $0950 ; 7 bytes (of 8)
	uint16_string_buf_trim			= $0958 ; 7 bytes (of 8)

	current_dir_name				= $0960 ; 16 bytes plus a null
	current_file_name				= $0971 ; 16 bytes plus a null
	current_file_title				= $0982 ; 21 bytes (plus a bunch of nulls)
	current_file_size				= $09a0 ; 2 bytes
	current_file_size_in_kb			= $09a2 ; 2 bytes
	current_file_type				= $09a4
	current_file_tracks				= $09a5

	current_menu_page				= $09a6
	clear_menu_screen_flag			= $09a7

	file_to_load_name_len			= $09a8
	file_to_load_size				= $09a9 ; 2 bytes
	file_size_in_kb					= $09ab ; 2 bytes
	header_loaded					= $09ad

	reu_highest_bank				= $09ae
	ramlink_detect					= $09af
	main_memory_free_pages			= $09b0

	old_STOP_vec					= $09b1 ; 2 bytes
	parse_header_sample_pointer		= $09b3 ; 3 bytes
	arpeggio_extra_note_first		= $09b6 ; \___ 16 bytes
	arpeggio_extra_note_second		= $09be ; /

	repeat_mode						= $09c6
	volume_tables_resolution		= $09c7
	last_volume_tables_resolution	= $09c8
	allow_regen_msg					= $09c9

	free_memory_start				= $09ca ; 3 bytes

	; various program vectors
	; more vectors can go in this space, $09cb through $09ef

	stash_block_vec					= $09f0 ; 2 bytes

	print_vec						= $09f2 ; 2 bytes

	audio_set_resolution_vec		= $09f4 ; 2 bytes
	audio_init_vec					= $09f6 ; 2 bytes
	audio_start_vec					= $09f8 ; 2 bytes
	audio_stop_vec					= $09fa ; 2 bytes

	audio_driver_set_cycle_count_vec = $09fc ; 2 bytes
	ram_driver_set_cycle_counts_vec	= $09fe ; 2 bytes

	; C64 has the blurring table at $0a00 through $0a7f, free through $0aff
	; C128 has system variables and such in that space

	multablo						= $0b00 ; 2 pages
	multabhi						= $0d00 ; 2 pages

	and_f0_table					= $0f00 ; 1 page

	; on C128, $1000-$101f is used for F-key defs, required by the KERNAL,
	; but the rest is free.

	; free: $1020 through $105f -- on C64, $1000-$101f is free also.

	semitones_table_fracts			= $1060
	semitones_table_lows			= $1070

	pattern_table					= $1080

	clear_main_memory				= pattern_table

	; on C128, these next two pages can only be used by transient stuff
	; so that's a good place for the two audio buffers

	audio_buffer_left				= $1100 ; 1 page
	audio_buffer_right				= $1200 ; 1 page

	multab2lo						= $1300 ; 2 pages
	multab2hi						= $1500 ; 2 pages

	; main program code starts here, followed by free mem
	; then comes all the "high-memory" stuff

	divide_by_16_table				= $8a00

	playlist_file_sizes_lows		= $8b00 ; \___ 2 bytes * 192 files
	playlist_file_sizes_highs		= $8c00 ; /    (128 bytes unused but will be zeroed)
	playlist_file_flags				= $8d00 ; 1 byte * 192
											; (48 bytes unused but will be zeroed)

	playlist_filenames				= $8e00 ; 16 bytes * 192 (3 kB)
	playlist_filenames_end			= $9a00

	volume_table_lower				= $9a00 ; 46 pages \__ 65 pages/16.25 kB, split
	volume_table_upper				= $e000 ; 19 pages /   between two memory areas

	; on C64, $c800-$cfff are screens, sample data buffer on C128

	; other under-KERNAL-ROM stuff

	pitch_table_fracts				= $f300 ; 7 pages
	pitch_table_lows				= $fa00 ; 3 pages

	tempo_table_fracts				= $fd00 ; 1 page
	tempo_table_lows				= $fe00 ; 1 page
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
