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

	; free: $c9 through $cb

	; C128 KERNAL indirect routines from $02a2 to $02ff
	; System vectors and variables from $0300 to $03ff

	PKYBUF							= $1000
	PKYDEF							= $100a

; ----------------------------------------------------------------------------
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

	FAST_SERIAL_FLAG				= $0a1c ; the KERNAL sets bit 6 when the device it
												; talked to last uses fast serial

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
	C128_EXTRA_KEYS					= $d02f ; Esc, Alt, Help, 10-key pad, etc.

	; KERNAL/editor routines and jump table

	WINDOW							= $c02d
	FULLW							= $ca24
	DISPLY							= $cc34

	COLORS_TABLE					= $ce4c ; 16-byte PETSCII color code table

	RESET							= $e000

}

; the bank that the KERNAL is told (with SETBNK) to read filenames from, and to
; load and save data in.  the KERNAL switches to that bank's configuration, with
; interrupts enabled, for every byte it reads or writes that way.  bank 0 is all
; RAM, so an interrupt that lands in one of those moments is taken through the
; RAM under the KERNAL, where this program keeps its own vectors and code
; instead of what the KERNAL expects to find there.
;
; bank 12 (configuration $06 in the KERNAL's table at $f7f0) is RAM bank 0 up
; to $7fff, with the KERNAL ROM and I/O in.  the KERNAL stays mapped the whole
; time, so that can't happen, but anything given to it has to be below $8000.

KERNAL_FILE_BANK = 12

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
