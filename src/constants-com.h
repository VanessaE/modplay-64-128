; This file defines all of the non-machine-specific constants used througout the program.

!addr {
	; KERNAL zero-page variables

	STATUS							= $90
	MSGFLG							= $9d
	EAL								= $ae
	FA								= $ba

	; ####################################################
	; ###  Zero Page WHEN BACKED-UP
	; e.g. only when player is running and no KERNAL
	; or BASIC is needed

	; these various multiples of 8 bytes are in order by track number

	volume_table_vectors			= $02 ; 16 bytes
	current_sample_volume_levels	= $12 ; 8 bytes
	track_byte_to_mix				= $1a ; 8 bytes
	audio_in_buf_index				= $22
	audio_out_buf_index				= $23

	; because they're needed both inside and outside of the player, multiply
	; and divide routines' zero page variables have to be in the same places
	; within the "backup-mode" as they are outside of it.

	; for divide, divisor uses $24 to $26
	; dividend/quotient uses $27 to $29

	; free $2a

	tempo_dividend_precalc			= $2b ; 2 bytes
	stepper_dividend_precalc		= $2d ; 2 bytes
	pattern_address					= $2f ; 3 bytes
	pattern_break_target_row		= $32
	seq_current_pattern_number		= $33
	seq_current_row					= $34
	seq_current_track				= $35
	seq_tempo_bpm					= $36
	seq_ticks_per_division			= $37
	seq_ticks_counter				= $38
	; free: $39
 	pitch_slide_up_rates			= $3a ; 8 bytes
	pitch_slide_down_rates			= $42 ; 8 bytes
	pitch_slide_to_note_rates		= $4a ; 8 bytes

	glissando_flag					= $52
	vibrato_waveform				= $53
	tremolo_waveform				= $54
	delay_pattern_divisions			= $55
	song_speed						= $56
	current_song_pos				= $57
	; free: $58

	; division remainder uses $59 to $5b
	; multiply product uses $5c and $5d

	; free: $5e
	; divide24_tmp uses $5f
	; free: $60, $61

	tempzpbk_g						= $62 ; 4 bytes
	mixer_loops_per_tick_fract		= $66
	mixer_loops_per_tick			= $67 
	mixer_countdown_fract			= $68
	mixer_countdown					= $69
	sequencer_temp_x				= $6a
	sequencer_temp_y				= $6b
	sequencer_temp_a				= $6c ; 4 bytes
	track_current_loop_flags		= $70 ; 8 bytes
	fine_tune_values				= $78 ; 8 bytes
	retrigger_rates					= $80 ; 8 bytes
	cut_sample_ticks				= $88 ; 8 bytes
	delay_sample_ticks				= $90 ; 8 bytes
	current_sample_numbers			= $98 ; 8 bytes
	vibrato_rates					= $a0 ; 8 bytes
	tremolo_rates					= $a8 ; 8 bytes
	volume_slide_rates				= $b0 ; 8 bytes
	current_steprates_fract			= $b8 ; \___ 16 bytes
	current_steprates_lows			= $c0 ; /
	sample_pointers_fract			= $c8 ; ¯|
	sample_pointers_lows			= $d0 ;  |___32 bytes
	sample_pointers_mids			= $d8 ;  |
	sample_pointers_highs			= $e0 ; _|
	current_sample_end_addr_lows	= $e8 ; ¯|
	current_sample_end_addr_mids	= $f0 ;  |-- 24 bytes, through $ff
	current_sample_end_addr_highs	= $f8 ; _|

	; ### End of Zero Page backup
	; ####################################################

	; The rest of these Zero Page addrs can be the same on both C64 and C128
	; and are for use when Zero Page is not backed-up.

	divisor							= $24 ; to $26
	dividend						= $27 ; to $29
	remainder						= $59 ; to $5b
	quotient = dividend ;save memory by reusing dividend to store the result

	divide24_tmp					= $5f 

	product							= $5c ; and $5d / the product from multiply routine

	stash_pointer					= $5c ; to $5e, expansion RAM stash target addr
										  ; only used within the loader

	print_msg_addr					= $5f ; and $60
	save_addr						= $5f ; and $60

	tempzp_c						= $2a
	tempzp_d						= $50 ; and $51
	tempzp_e						= $52 ; and $53
	tempzp_f						= $fa ; through $fd

	load_pointer					= $fe ; and $ff
	filename_addr					= $fe ; and $ff
}

; =================================================================
; From here on down are hard-coded KERNAL/system variables common
; to all machines

!addr {

	; System vectors

	CHROUT_vec						= $0326
	CINV_vec						= $0314
	CHRIN_vec						= $0324
	STOP_vec						= $0328

	; I/O

	VIC_COLOR_RAM					= $d800

	VIC								= $d000
; C128 only note:  in $D030, only bits 1 & 0 matter, so "test" and 1/2 MHz mode
; switches will work with any stored value as long as those two bits are correct.

	SID								= $d400
	CIA1							= $dc00
	CIA2							= $dd00

	DMA_CMD							= $df01

	DMA_ADL							= $df02		; local address
	DMA_ADH							= $df03

	DMA_LO							= $df04		; REU address
	DMA_HI							= $df05
	DMA_BANK						= $df06

	DMA_DAL							= $df07		; transfer length
	DMA_DAH							= $df08

	; KERNAL

	CINT							= $ff81
	IOINIT							= $ff84
	RESTOR							= $ff8a
	READST							= $ffb7

	SECND							= $ff93
	TKSA							= $ff96
	ACPTR							= $ffa5
	CIOUT							= $ffa8
	UNTLK							= $ffab
	UNLSN							= $ffae
	LISTN							= $ffb1
	TALK							= $ffb4

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

	PLOT							= $fff0

	; CPU vectors

	CPU_NMI_vector					= $fffa
	CPU_IRQ_vector					= $fffe

}

; PETSCII color/control codes

BLK									= $90
WHT									= $05
RED									= $1c
CYAN								= $9f
PUR									= $9c
GRN									= $1e
BLUE								= $1f
YEL									= $9e
BRN									= $95
LRED								= $96
LGRN								= $99
LBLU								= $9a
LGRY								= $9b

HOME								= $13
CLR									= $93
DEL									= $14

UP									= $91
DOWN								= $11
LEFT								= $9d
RIGHT								= $1d

RETURN								= $0d

LOWER								= $0e
UPPER								= $8e

RVSON								= $12
RVSOFF								= $92

; Misc stuff not specific to the machine's OS

X = "X" ; so that the delay routine doesn't
Y = "Y" ; need to be called with X or Y in quotes.

header15_seek_to_pt					= 20+15*(22+2+1+1+2+2)+1+1 ; (472)
header31_seek_to_pt					= 20+31*(22+2+1+1+2+2)+1+1 ; (952)
header_first_inst_meta_offset		= 20
instrument_metadata_size			= 22+2+1+1+2+2 ; (30)

one_ten_thou_pal = int(985248 / 10000) - 1
one_ten_thou_ntsc = int(1022727 / 10000) - 1


; this value is around 16x higher than "proper", for the sake of precision
pitch_fine_adjust_constant = 100

; and this one ...well... it's big 😛
tempo_fine_adjust_constant = 156000

