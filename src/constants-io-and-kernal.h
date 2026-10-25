; This file contains all of the I/O, KERNAL calls, and under-KERNAL-ROM stuff

!addr {

	viz_note_number_lookup_table		= $e000 ; 7 pages
	divide_by_16_table					= $e700
	and_f0_table						= $e800
	mah_table_6581						= $e900
	mah_table_8580						= $ea00
	tempo_table_fracts					= $eb00
	tempo_table_lows					= $ec00

	under_kernal_code					= $ed00

	; C128 MMU occupies $ff00 through $ff04, REU can watch $ffxx also.
	; and CPU vectors of course start at $fffa.

	note_names_table					= $ff06; 244 bytes, through $fff9
	nnt_end								= note_names_table + 243

	; KERNAL/System vectors

	CHROUT_vec							= $0326
	CINV_vec							= $0314
	KERNAL_NMI_vec						= $0318
	CHRIN_vec							= $0324
	STOP_vec							= $0328

	; I/O devices

	VIC_COLOR_RAM						= $d800

	VIC_CONTROL_A						= $d011
	VIC_RASTER_LOW						= $d012
	VIC_MEM_CTRL						= $d018
	VIC_IRQ_FLAGS						= $d019
	VIC_IRQ_MASK						= $d01a
	VIC_BORDER							= $d020
	VIC_BACKGROUND						= $d021

	C128_VIC_CLOCK_SPEED				= $d030
	; C128 only note:  in $D030, only bits 1 & 0 matter, so "test" and 1/2 MHz
	; mode switching will work with any stored value as long as those two bits
	; are correct.

	!ifdef scpu {
		SCPU_TURBO_ON					= $d07b
		SCPU_ENABLE_HW_REGS				= $d07e
		SCPU_DISABLE_HW_REGS			= $d07f
		SCPU_OPTIMIZATION_MODE			= $d0b3
		SCPU_JD_TURBO_SWITCH			= $d0b5

		SCPU_RAM_FIRST_PAGE				= $d27c
		SCPU_RAM_FIRST_BANK				= $d27d
		SCPU_RAM_LAST_PAGE				= $d27e
		SCPU_RAM_LAST_BANK				= $d27f
	}

	SCPU_TURBO_OFF						= $d07a
	SCPU_PRESENT						= $d0bc

	SID									= $d400
	SID_VOICE1_CR						= $d404
	SID_VOICE1_ENV_AD					= $d405
	SID_VOICE1_ENV_SR					= $d406

	SID_VOICE2_CR						= $d40b
	SID_VOICE2_ENV_AD					= $d40c
	SID_VOICE2_ENV_SR					= $d40d

	SID_VOICE3_FREQ_LOW					= $d40e
	SID_VOICE3_FREQ_HIGH				= $d40f
	SID_VOICE3_CR						= $d412
	SID_VOICE3_ENV_AD					= $d413
	SID_VOICE3_ENV_SR					= $d414

	SID_FILT_CUTOFF_LOW					= $d415
	SID_FILT_CUTOFF_HIGH				= $d416
	SID_FILT_VOICE_SEL					= $d417
	SID_VOLUME							= $d418

	SID_VOICE3_OSC_OUT					= $d41b

	MMU_CR1								= $d500 ; C128 only

	VDC_ADDR							= $d600 ; C128 only
	VDC_DATA							= $d601 ; C128 only

	CIA1_PORT_A							= $dc00
	CIA1_PORT_B							= $dc01
	CIA1_DDR_A							= $dc02
	CIA1_DDR_B							= $dc03
	CIA1_TIMER_A_LOW					= $dc04
	CIA1_TIMER_A_HIGH					= $dc05
	CIA1_TIMER_B_LOW					= $dc06
	CIA1_TIMER_B_HIGH					= $dc07
	CIA1_TOD_TENTHS						= $dc08
	CIA1_TOD_SECONDS					= $dc09
	CIA1_TOD_MINUTES					= $dc0a
	CIA1_TOD_HOURS						= $dc0b
	CIA1_SDR							= $dc0c
	CIA1_ICR							= $dc0d
	CIA1_CRA							= $dc0e
	CIA1_CRB							= $dc0f

	CIA2_PORT_A							= $dd00
	CIA2_PORT_B							= $dd01
	CIA2_DDR_A							= $dd02
	CIA2_DDR_B							= $dd03
	CIA2_TIMER_A_LOW					= $dd04
	CIA2_TIMER_A_HIGH					= $dd05
	CIA2_TIMER_B_LOW					= $dd06
	CIA2_TIMER_B_HIGH					= $dd07
	CIA2_TOD_TENTHS						= $dd08
	CIA2_TOD_SECONDS					= $dd09
	CIA2_TOD_MINUTES					= $dd0a
	CIA2_TOD_HOURS						= $dd0b
	CIA2_SDR							= $dd0c
	CIA2_ICR							= $dd0d
	CIA2_CRA							= $dd0e
	CIA2_CRB							= $dd0f

	DMA_CMD								= $df01

	DMA_LOCAL_LO						= $df02		; local address
	DMA_LOCAL_HI						= $df03

	DMA_EXTERNAL_LO						= $df04		; REU address
	DMA_EXTERNAL_HI						= $df05
	DMA_EXTERNAL_BANK					= $df06

	DMA_LENGTH_LO						= $df07		; transfer length
	DMA_LENGTH_HI						= $df08

	DMA_ADDR_CONTROL					= $df0a

	; 1541U-specific registers

	UCI_OUR_DEVICE						= $DF1B
	UCI_CMD_IF_CONTROL					= $DF1C
	UCI_CMD_IF_COMMAND					= $DF1D
	UCI_CMD_IF_RESULT					= $DF1E

	; KERNAL calls

	SWAPPER								= $ff5f ; C128 only
	DLCHR								= $ff62 ; C128 only
	SETBNK								= $ff68 ; C128 only

	CINT								= $ff81
	IOINIT								= $ff84
	RESTOR								= $ff8a
	READST								= $ffb7

	SECND								= $ff93
	TKSA								= $ff96
	ACPTR								= $ffa5
	CIOUT								= $ffa8
	UNTLK								= $ffab
	UNLSN								= $ffae
	LISTN								= $ffb1
	TALK								= $ffb4

	SETLFS								= $ffba
	SETNAM								= $ffbd
	LOAD								= $ffd5
	SAVE								= $ffd8

	OPEN								= $ffc0
	CLRCH								= $ffcc
	CLOSE								= $ffc3

	CHKIN								= $ffc6
	CHKOUT								= $ffc9
	CHRIN								= $ffcf
	CHROUT								= $ffd2
	STOP								= $ffe1
	GETIN								= $ffe4
	CLALL								= $ffe7

	PLOT								= $fff0

	; CPU vectors

	CPU_NMI_vector						= $fffa
	CPU_IRQ_vector						= $fffe
}
