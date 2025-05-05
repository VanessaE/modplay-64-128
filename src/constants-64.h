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

	main_mem_free_end				= $a600

	volume_table_lower				= $a600 ; 38 pages \__ 64 pages/16 kB, split
	volume_table_upper				= $e000 ; 26 pages /   between two memory areas

	VIC_SCREEN						= $cc00

	; ========================================================================
	; From here on down are hard-coded KERNAL/system variables and such

	; KERNAL zero-page variables

	TIME							= $a0

	cursor_current_line				= $d6
	cursor_current_column			= $d3

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

	COLORS_TABLE					= $e8da ; 16-byte PETSCII color code table

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
