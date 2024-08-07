; This file defines the C64-specific constants used througout the program.

!addr {

	; Zero Page

	; free: $22, $23
	; free: $4e, $4f
	; free: $57
	; free: $f7

	progress_bar_char_pointer		= $f8 ; and $f9

	; low memory area -- duh 😛

	; free: $02a7 through $02ff

	; System vectors from $0300 to $0333

	low_memory_area					= $0334

	; the first $98 bytes are used by player vars - see constants-com.h
	; free: $03cc through $03ff.

	blurring_table					= $0a00 ; 128 bytes

	; free: $0a80 through $0aff

	window_edge_tables				= $1000

	main_mem_free_end				= $a900

	playlist_file_sizes_lows		= $a900 ; \___ 2 bytes * 192 files
	playlist_file_sizes_highs		= $aa00 ; /    (128 bytes unused but will be zeroed)
	playlist_file_flags				= $ab00 ; 1 byte * 192
											; (48 bytes unused but will be zeroed)

	playlist_filenames				= $ac00 ; 16 bytes * 192 (3 kB)
	playlist_filenames_end			= $b800

	volume_table_lower				= $b800 ; 16 pages \__ 33 pages/8 kB, split
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
visualizer_screen_row				= 14
