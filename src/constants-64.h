; This file defines the C64-specific constants used througout the program.

!addr {

	default_start					= $0801

	; Zero Page

	progress_bar_char_pointer		= $22 ; and $23

	; free: $4e, $4f
	; free: $57

	expansion_transfer_local_addr	= $f7 ; through $f9
	; the third byte will always be 0, but SCPU RAM driver will need this later.

	; low memory area -- duh 😛

	; free: $02a7 through $02ff

	; System vectors from $0300 to $0333

	low_memory_area					= $0334

	; the first $98 bytes are used by player vars - see constants-com.h
	; free: $03cc through $03ff.

	blurring_table					= $0a00 ; 128 bytes

	; free: $0a80 through $0aff

	window_edge_tables				= $1000

	main_mem_free_end				= $8600 ; overlaps the load buffer intentionally

	load_buffer						= $7e00 ; 2 kB

	mod_instrument_names			= $8600 ; 32 * 31 bytes, through $afef

	playlist_file_sizes_lows		= $8a00 ; \___ 2 bytes * 192 files
	playlist_file_sizes_highs		= $8b00 ; /    (128 bytes unused but will be zeroed)
	playlist_file_flags				= $8c00 ; 1 byte * 192
											; (48 bytes unused but will be zeroed)

	playlist_filenames				= $8d00 ; 16 bytes * 192 (3 kB)
	playlist_filenames_end			= $9900

	volume_table_lower				= $9900 ; 47 pages \__ 64 pages/16 kB, split
	volume_table_upper				= $e000 ; 17 pages /   between two memory areas

	VIC_SCREEN						= $c800
	secondary_screen				= $cc00

	; ========================================================================
	; From here on down are hard-coded KERNAL/system variables and such

	; KERNAL zero-page variables

	TIME							= $a0

	cursor_current_line				= $d6

	FAC								= $61 ; BASIC floating accumulator area
	LDTB1							= $d9 ; screen line link table
	HIBASE							= $0288 ; KERNAL base address for screen

	bcd = FAC
	int16 = FAC+4

	; Other stuff, "low memory area"

	CHAR_COLOR						= $0286 ; current char color for KERNAL prints

	; I/O

	VIC_CHARSETS					= $d000

	; KERNAL routines/jump table

	RESET							= $fce2

	DISPLY							= $ea1c
}

NOSHIFTCOM							= $08

ORG									= $81
MGRY								= $98
DGRY								= $97

splash_ver_pos_col					= 23
splash_ver_pos_row					= 8

screen_width						= 40
screen_base_addr					= VIC_SCREEN
color_mem_base_addr					= VIC_COLOR_RAM

visualizer_area_width				= 36
visualizer_area_height				= 6

visualizer_screen_column			= 2
visualizer_screen_row				= 13
