; This file defines all the various constants used througout the program.

!addr {
	!ifndef c128 {
			program_start_addr		= $0801
		} else {
			program_start_addr		= $1301
	}

; Zero page
	!ifndef c128 {
		isr_cycle_time				= $29
		isr_cycle_time_alt			= $2a

		track_1_vol_tab_vec			= $22
		track_4_vol_tab_vec			= $24
		track_2_vol_tab_vec			= $26
		track_3_vol_tab_vec			= $28

		track_1_volume				= $4e
		track_4_volume				= $4f
		track_2_volume				= $50
		track_3_volume				= $51
										; $52, $53 used for temp stuff below
		track_1_data				= $57
		track_4_data				= $58
		track_2_data				= $59
		track_3_data				= $5a
	} else { 

		isr_cycle_time				= $29
		isr_cycle_time_alt			= $2a

		track_1_vol_tab_vec			= $22
		track_4_vol_tab_vec			= $24
		track_2_vol_tab_vec			= $26
		track_3_vol_tab_vec			= $28

		track_1_volume				= $4e
		track_4_volume				= $4f
		track_2_volume				= $50
		track_3_volume				= $51

		track_1_data				= $57
		track_4_data				= $58
		track_2_data				= $59
		track_3_data				= $5a

		kernal_4080_mode			= $d7
		SCBOT						= $e4 ; bottom, top, left, right edges
		SCTOP						= $e5 ; of screen
		SCLF						= $e6
		SCRT						= $e7
		TBLX						= $eb ; cursor line
		PNTR						= $ec ; cursor column
		LINES						= $ed
		COLUMNS						= $ee
	}

	; The rest of these Zero Page addrs can be the same on both C64 and C128

	load_pointer					= $fb ; these two are only used once by the
	zero_countdown					= $fd ; autorunner to look for splash EOF

	isr_accu						= $fb ; then the ISR overwrites them.
	isr_regx						= $fc
	isr_regy						= $fd ; these can, in turn, ...

	vol_tab_gen_vec					= $fb ; ...be overwritten, if the ISR is idle.

	tempzp_c						= $fb


	product							= $5c ; and $5d / the product from multiply routine
	audio_in_buf_index				= $5e
	audio_out_buf_index				= $5d

	print_msg_addr					= $fe ; and $ff

	; these can be used between runs of the sample output loop
	; as long as it's before the sequencer routine.  max 8 bytes.
	
	is_rle_encoded					= track_1_vol_tab_vec  ; print_msg: $80+ if RLE-encoded.
	rle_byte_count					= track_1_vol_tab_vec+1 ; number of bytes left to decode
	rle_mode_flag					= track_1_vol_tab_vec+2 ; zero for a run, non-zero if it's a data chunk
	rle_fill_byte					= track_1_vol_tab_vec+3
	rle_fill_byte_is_set			= track_1_vol_tab_vec+4 ; $80 means it's set

	tempzp_d						= $5c ; through $60 as long as multiply
										  ; routine isn't needed at the moment.

	; these are safe to re-use for random storage when music isn't playing

	tempzp_e						= track_1_vol_tab_vec ; 4 bytes
	tempzp_f						= track_1_volume ; *10* bytes
	tempzp_g						= track_1_data ; 4 bytes


	kernal_status					= $90
	kernal_loading_addr				= $ae

	; Other

	!ifndef c128 {
		free_low_mem1				= $02a7 ; through $2ff
		reu_num_banks				= $0334 ; and $0335
		rasters_lo					= $0336
		raster_len					= $0337
		pal_flag					= $0338 ; 1 = PAL
		disable_screen_on_playback	= $0339
		vol_cnt						= $033a
		bval_cnt					= $033b


		free_low_mem2				= $033c ; tape buffer, through $03ff
	} else {
		free_low_mem1				= $0200 ; through $02a1
		reu_num_banks				= $0b00 ; and $0b01
		rasters_lo					= $0b02
		raster_len					= $0b03
		pal_flag					= $0b04 ; 1 = PAL
		disable_screen_on_playback	= $0b05
		vol_cnt						= $0b06
		bval_cnt					= $0b07

		free_low_mem2				= $0b08 ; tape & RS232 bufs, sprites, through $0fff
	}

	; System variables/vectors

	chrout_vec						= $0326
	cinv_vec						= $0314

	; I/O

	screen							= $0400
	color_ram						= $d800

	VIC								= $d000
	SID								= $d400
	MMU_C128						= $d500
	VDC_C128						= $d600
	CIA1							= $dc00
	CIA2							= $dd00

	DMA_CMD							= $df01
	DMA_ADL							= $df02
	DMA_ADHhi						= $df03
	DMA_LO							= $df04
	DMA_HI							= $df05
	DMA_BANK						= $df06
	DMA_DAL							= $df07
	DMA_DAH							= $df08

	; KERNAL jump table
	SWAPPER							= $ff5f ; C128 only

	SETNAM							= $ffbd
	SETLFS							= $ffba
	SECOND							= $ff93
	READST							= $ffb7

	LOAD							= $ffd5
	SAVE							= $ffd8

	OPEN							= $ffc0
	CLOSE							= $ffc3
	CLALL							= $ffe7

	CHKIN							= $ffc6
	CHKOUT							= $ffc9
	CHRIN							= $ffcf
	CHROUT							= $ffd2
	ACPTR							= $ffa5
	CIOUT							= $ffa8

	; CPU vectors

	cpu_nmi_vector					= $fffa
	cpu_irq_vector					= $fffe

; Tables and buffers

	!ifndef c128 {
		volume_tables_base			= $8800 ; 64 * 256b = 16 kB
		load_buffer					= $c800 ; 1k
	} else {
		volume_tables_base			= $8c00 ; 64 * 256b = 16 kB
		load_buffer					= $0400 ; 1k
	}

	audio_buffer_left				= $e000 ; 256 bytes
	audio_buffer_right				= $e100 ; 256 bytes

	multablo						= $e200 ; 512 bytes
	multabhi						= $e400 ; 512 bytes
	multab2lo						= $e600 ; 512 bytes
	multab2hi						= $e800 ; 512 bytes

	log_table_base					= $ea00 ; 2k

	; Log table ends at $f200 - 3.5 kB remaining, minus the vectors at $fff0 of
	; course.  On C128, avoid everything above $FF00, MMU sits there.
}

; PETSCII color/control codes

BLACK							= $90
WHITE							= $05
RED								= $1c
CYAN							= $9f
PURPLE							= $9c
GREEN							= $1e
BLUE							= $1f
YELLOW							= $9e
ORANGE							= $81
BROWN							= $95
LRED							= $96
DGRAY							= $97
MGRAY							= $98
LGREEN							= $99
LBLUE							= $9a
LGRAY							= $9b

HOME							= $13
CLEAR							= $93

UP								= $91
DOWN							= $11
LEFT							= $9d
RIGHT							= $1d

RETURN							= $0d

LOWER							= $0e
UPPER							= $8e

; Misc

X = "X" ; so that the delay routine doesn't
Y = "Y" ; need to be called with X or Y in quotes.
