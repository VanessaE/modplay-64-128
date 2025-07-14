; This file defines the C128-specific constants used througout the program.

; Any zero-page addresses defined here are only usable when zero page is NOT
; backed-up.

!addr {

	; Zero Page

	progress_bar_char_pointer		= $2b ; and $2c

	reu_highest_bank				= $54
	c128_highest_bank				= $55
	c128_vdc_has_64k				= $61
	main_menu_cache_is_valid		= $62

	expansion_transfer_local_addr	= $c9 ; through $cb
	; the third byte will always be 0, but SCPU RAM driver will need this later.

	; C128 KERNAL indirect routines from $02a2 to $02ff
	; System vectors and variables from $0300 to $03ff

	PKYBUF							= $1000
	PKYDEF							= $100a

	main_mem_free_end				= $a800

	reu_driver						= $a800

	ascii_to_petscii_table			= $a900 ; 1 page

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
	cursor_current_column			= $ec

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
	VDC_64K_CACHE_MENU_TEXT			= $4000 ; only used on 64k VRAM machines
	VDC_64K_CACHE_MENU_ATTRS		= $5000
	VDC_64K_CACHE_LDR_BG_TEXT		= $6000
	VDC_64K_CACHE_LDR_BG_ATTRS		= $7000
	VDC_64K_CACHE_PLYR_BG_TEXT		= $8000
	VDC_64K_CACHE_PLYR_BG_ATTRS		= $9000

	VDC_filename_cache				= $1000

	VDC_CHARSETS					= $2000
	VDC_VM3							= $0a2e ; base of VDC screen mem

	MMU_CR1							= $d500

	VDC_ADDR						= $d600
	VDC_DATA						= $d601

	; KERNAL/editor routines and jump table

	WINDOW							= $c02d
	FULLW							= $ca24
	DISPLY							= $cc34

	COLORS_TABLE					= $ce4c ; 16-byte PETSCII color code table

	RESET							= $e000

	SWAPPER							= $ff5f
	DLCHR							= $ff62
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
visualizer_screen_row				= 12
