; This file defines the C128-specific constants used througout the program.

!addr {

	default_start					= $1c01

	; Zero Page

	progress_bar_char_pointer		= $2b ; and $2c

	; free: $54, $55
	; free: $61, $62

	expansion_transfer_local_addr	= $c9 ; through $cb
	; the third byte will always be 0, but SCPU RAM driver will need this later.

	; low memory area -- duh 😛

	low_memory_area					= $0200

	; the first $98 bytes are used by player vars - see constants-com.h
	; free: $0298 through $02a0

	c128_highest_bank				= $02a1

	; C128 KERNAL indirect routines from $02a2 to $02ff
	; System vectors and variables from $0300 to $03ff

	PKYBUF							= $1000
	PKYDEF							= $100a

	main_mem_free_end				= $8100 ; overlaps the load/sample buffers intentionally

	load_buffer						= $7900			; \__  2 kB
	sample_data_buffer				= load_buffer	; /

	and_f0_table					= $8100 ; 1 page

	viz_note_number_lookup_table	= $8200 ; 1712 bytes plus some waste

	steprate_lookup_table			= $8900 ; 1712 * 2 bytes, plus some waste

	mod_instrument_names			= $9700 ; 32 * 31 bytes pls some waste

	playlist_file_sizes_lows		= $9b00 ; \___ 2 bytes * 192 files
	playlist_file_sizes_highs		= $9c00 ; /    (128 bytes unused but will be zeroed)
	playlist_file_flags				= $9d00 ; 1 byte * 192
											; (48 bytes unused but will be zeroed)

	playlist_filenames				= $9e00 ; 16 bytes * 192 (3 kB)
	playlist_filenames_end			= $aa00

	volume_table_lower				= $aa00 ; 38 pages \__ 64 pages/16 kB, split
	volume_table_upper				= $e000 ; 26 pages /   between two memory areas

	; =================================================================
	; From here on down are hard-coded KERNAL/system variables and such

	; KERNAL zero-page variables

	FAC								= $63
	kernal_4080_mode				= $d7

	indstash_addr					= $ae ; same as EAL
	indfetch_addr					= $bb

	cursor_current_line				= $eb

	CHAR_COLOR						= $f1 ; current char color for KERNAL prints

	bcd = FAC
	int16 = FAC+4

	; System variables/vectors

	IND_FETCH						= $02a2
	IND_STASH						= $02af

	RPTFLAG							= $0a22

	; I/O

	VIC_SCREEN						= $0400
	VDC_SCREEN						= $0000
	VDC_ATTRIBUTES					= $0800
	VDC_CHARSETS					= $2000
	VDC_VM3							= $0a2e ; base of VDC screen mem

	MMU_CR1							= $d500

	VDC_ADDR						= $d600
	VDC_DATA						= $d601

	; KERNAL/editor routines and jump table

	WINDOW							= $c02d
	FULLW							= $ca24
	DISPLY							= $cc34

	RESET							= $e000

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

splash_ver_pos_col					= 48
splash_ver_pos_row					= 9

screen_width						= 80
screen_base_addr					= VDC_SCREEN
color_mem_base_addr					= VDC_ATTRIBUTES

visualizer_area_width				= 38
visualizer_area_height				= 6

visualizer_screen_column			= 21
visualizer_screen_row				= 13
