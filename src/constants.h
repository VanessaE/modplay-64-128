; This file defines all the various constants used througout the program.

!addr {

; Zero page
	!ifndef c128 {

		FAC							= $61 ; BASIC floating accumulator area
		LDTB1						= $d9 ; screen line link table
	} else { 

		FAC							= $63
		kernal_4080_mode			= $d7
		SCBOT						= $e4 ; bottom, top, left, right edges
		SCTOP						= $e5 ; of screen/window, C128 only
		SCLF						= $e6
		SCRT						= $e7
		TBLX						= $eb ; cursor line
		PNTR						= $ec ; cursor column
		LINES						= $ed
		COLUMNS						= $ee
	}

	bcd = FAC
	int16 = FAC+4

	; The rest of these Zero Page addrs can be the same on both C64 and C128

	load_pointer					= $fb
	zero_countdown					= $fd ; only used by autorunner to look for splash EOF

	product							= $5c ; and $5d / the product from multiply routine
	audio_in_buf_index				= $5e
	audio_out_buf_index				= $5d

	print_msg_addr					= $fe ; and $ff
	save_addr						= $fe ; and $ff

	rle_byte_count					= $24 ; number of bytes left to decode
	rle_mode_flag					= $25 ; zero for a run, non-zero if it's a data chunk

	; these are safe to re-use for random storage

	tempzp_c						= $24
	tempzp_d						= $50 ; and $51

	divisor							= $25 ; to $27
	dividend						= $28 ; to $2a
	remainder						= $59 ; to $5b
	quotient = dividend ;save memory by reusing dividend to store the result
	stash_pointer					= $5c ; to $5e, expansion RAM stash target addr

	tempzp_e						= $5f ; and $60

	; KERNAL zero-page variables

	STATUS							= $90
	MSGFLG							= $9d
	EAL								= $ae
	FA								= $ba

	; Zero page WHEN BACKED-UP e.g. only when player is running and no KERNAL
	; or BASIC is needed

	track_1_vol_tab_vec				= $02
	track_4_vol_tab_vec				= $04
	track_2_vol_tab_vec				= $06
	track_3_vol_tab_vec				= $08

	track_1_volume					= $0a
	track_4_volume					= $0b
	track_2_volume					= $0c
	track_3_volume					= $0d

	track_1_data					= $0e
	track_4_data					= $0f
	track_2_data					= $10
	track_3_data					= $11

	track_1_ram_ptr					= $12
	track_4_ram_ptr					= $16
	track_2_ram_ptr					= $1a
	track_3_ram_ptr					= $1e

	isr_accu						= $1f
	isr_regx						= $20
	isr_regy						= $21

	; Other

; the config is saved and loaded from this area

	!ifndef c128 {
		free_low_mem1				= $02a7 ; through $2ff
		reu_num_banks				= $0334 ; and $0335
		rasters_lo					= $0336
		raster_len					= $0337
		pal_flag					= $0338 ; 1 = PAL
		disable_screen_on_playback	= $0339
		vol_cnt						= $033a
		bval_cnt					= $033b
		repeat_mode					= $033c
		isr_cycle_time				= $033d
		isr_cycle_time_alt			= $033e
		current_page				= $033f
		boot_device					= $0340
		string_16_bit				= $0341 ; 7 bytes
		string_16_bit_trimmed		= $0348 ; 7 bytes
		string_buffer				= $034f ; 40 bytes
		file_size_in_kb				= $0377 ; 2 bytes
		config_space				= $0379

		; free_low_mem2 -- tape & RS232 bufs, sprites -- continues to $03ff
	} else {
		free_low_mem1				= $0200 ; through $02a1
		reu_num_banks				= $0b00 ; and $0b01
		rasters_lo					= $0b02
		raster_len					= $0b03
		pal_flag					= $0b04 ; 1 = PAL
		disable_screen_on_playback	= $0b05
		vol_cnt						= $0b06
		bval_cnt					= $0b07
		repeat_mode					= $0b08
		isr_cycle_time				= $0b09
		isr_cycle_time_alt			= $0b0a
		current_page				= $0b0b
		boot_device					= $0b0c
		string_16_bit				= $0b0d ; 7 bytes
		string_16_bit_trimmed		= $0b14 ; 7 bytes
		string_buffer				= $0b1b ; 40 bytes
		file_size_in_kb				= $0b43 ; 2 bytes
		clear_menu_screen_flag		= $0b45
		config_space				= $0b46 

		; free_low_mem2 -- tape & RS232 bufs, sprites -- continues to $0fff

		PKYBUF						= $1000
		PKYDEF						= $100a
	}

	load_device						= config_space+5 ; config header is first 5 bytes
	stereo_sid_addr					= load_device+1
	dac_addr						= stereo_sid_addr+2
	audio_driver					= dac_addr+2
	ram_driver						= audio_driver+1
	filter_setting					= ram_driver+1
	resonance_setting				= filter_setting+1
	cfg_data_end					= resonance_setting+2 ; one byte past the real end


	; System variables/vectors

	IOINIT_MODE						= $0a04 ; C128 only

	CHROUT_vec						= $0326
	CINV_vec						= $0314

	STOP_vec						= $0328

	; I/O

	SCREEN							= $0400
	COLOR_RAM						= $d800

	VIC								= $d000
	SID								= $d400
	MMU_C128						= $d500
	VDC_C128						= $d600
	CIA1							= $dc00
	CIA2							= $dd00

	DMA_CMD							= $df01

	DMA_ADL							= $df02
	DMA_ADH							= $df03

	DMA_LO							= $df04
	DMA_HI							= $df05
	DMA_BANK						= $df06

	DMA_DAL							= $df07
	DMA_DAH							= $df08

	; KERNAL jump table
	SWAPPER							= $ff5f ; C128 only
	SETBNK							= $ff68 ; C128 only

	CINT							= $ff81
	IOINIT							= $ff84
	RESTOR							= $ff8a
	SECND							= $ff93
	TKSA							= $ff96
	ACPTR							= $ffa5
	CIOUT							= $ffa8
	UNTLK							= $ffab
	UNLSN							= $ffae
	LISTN							= $ffb1
	TALK							= $ffb4
	READST							= $ffb7
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

	; CPU vectors

	cpu_nmi_vector					= $fffa
	cpu_irq_vector					= $fffe

; Tables and buffers

	file_list_buffer				= $8000
	volume_tables_base				= $9000 ; 64 * 256b = 16 kB

	audio_buffer_left				= $e000 ; 256 bytes
	audio_buffer_right				= $e100 ; 256 bytes

	multablo						= $e200 ; 512 bytes
	multabhi						= $e400 ; 512 bytes
	multab2lo						= $e600 ; 512 bytes
	multab2hi						= $e800 ; 512 bytes

	log_table_base					= $ea00 ; 2k

	load_buffer						= $f200 ; 1k
	load_buffer_end					= $f6ff ; on C128, $f600-f6ff will get
											; used also, when in BURST mode

	; 2.5 kB remaining, minus the vectors at $fff0 of course
	; On C128, avoid everything above $FF00, the MMU has an echo there.
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
} else {
	DPUR						= $81
	DGRY						= $98
	DCYN						= $97

	TAB							= $09

}

HOME							= $13
CLR								= $93

UP								= $91
DOWN							= $11
LEFT							= $9d
RIGHT							= $1d

RETURN							= $0d

LOWER							= $0e
UPPER							= $8e

RVSON							= $12
RVSOFF							= $92

!ifndef c128 {
	NOSHIFTCOM					= $08
} else {
	NOSHIFTCOM					= $0b ; C128 PRG says $0c but that's wrong
}

; Misc

X = "X" ; so that the delay routine doesn't
Y = "Y" ; need to be called with X or Y in quotes.
