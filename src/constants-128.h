; This file defines the C128-specific constants used througout the program.

!addr {

	; Zero Page

	tempzp_c						= $2a
	tempzp_d						= $2b ; and $2c
	tempzp_e						= $54 ; and $55

	progress_bar_addr				= $61 ; and $62

	print_msg_char_limit			= $c8

	; free: $c9 through $cb

	; low memory area -- duh 😛

	low_memory_area					= $0200
	; the first $98 bytes are used by player vars - see constants-com.h
	; free: $0298 through $02a0

	c128_highest_bank				= $02a1

	; C128 KERNAL indirect routines from $02a2 to $02ff
	; System vectors and variables from $0300 to $03ff

	PKYBUF							= $1000
	PKYDEF							= $100a

	main_mem_free_end				= $8a00 ; the divide-16 table starts here

	sample_data_buffer				= $c800 ; 8 * 256 bytes

	; =================================================================
	; From here on down are hard-coded KERNAL/system variables and such

	; KERNAL zero-page variables

	FAC								= $63
	kernal_4080_mode				= $d7

	indstash_addr					= $ae ; same as EAL
	indfetch_addr					= $bb

	cursor_pointer_text				= $e0
	cursor_pointer_color			= $e2
	cursor_current_line				= $eb
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

; this is the very last byte that'll be loaded in any serial mode,
; accounting for load addr, plus one disk block for expansion sake.
splash_128_end_check = program_start + (254*6) - 1

screen_width						= 80
screen_base_addr					= VDC_SCREEN
color_mem_base_addr					= VDC_ATTRIBUTES

visualizer_area_width				= 38
visualizer_area_height				= 6

visualizer_screen_column			= 21
visualizer_screen_row				= 14
