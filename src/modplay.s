; Modplay 64/128 v2.0 -- Copright 2024 Vanessa Dannenberg
;
; This code and related resources are released under Creative Commons license
; CC-By-NC-SA v4.0 -- see license.txt for all the legal mumbo-jumbo
;
; To build this project, you will need GNU Make (probably part of your
; operating system's "build essential" package), Acme Assembler, xxd, and the
; cc1541 tool from https://bitbucket.org/ptv_claus/cc1541/src/master/
;
; Just enter the top directory and type 'make'.  By default, it builds
; everything, but you can specify targets such as "c64" or "c128" to limit
; it to just one machine.
;
; The Geany project file included in this package has a command already
; set-up in the "Build" menu.  Just click Build -> Assemble, or the "Compile
; current file" icon.
;
; Look in 'bin/' for the final builds, or if you prefer, there are ready-to-
; use disk images in the 'disk-images/' directory (obviously ;-) ).
;
; Run with LOAD"<whatever>",x,1

; main program code

!source "src/constants-com.h"

!ifndef c128 {
	!source "src/constants-64.h"
} else {
	!source "src/constants-128.h"
}
!convtab pet
!cpu 6510

* = program_start

	jmp start

; extra macro calls used as functions should be placed here
; so that they don't end up under BASIC-LOW ROM on the C128

!source "src/misc-macros.s"

+ROM_SWITCHING
+SCREEN_ONOFF

print_msg
	+PRINT_MSG
rts

print_msg_rle
	+PRINT_MSG_RLE
rts

start
	php
	sei
	jsr enable_kernal_only
	jsr init
	jsr enable_kernal_only
	plp

	!ifndef c128 {
		jsr disable_screen
		jsr erase_file_list
		jsr switch_to_primary_screen
		lda #CLR
		jsr CHROUT
		jsr enable_screen
	}

	jmp show_main_menu ; and away we go!


; additional code goes here

!source "src/main-menu.s"
!source "src/change-show.s"
!source "src/file-ops.s"
!source "src/directory.s"
!source "src/playlist.s"
!source "src/isr-common.s"

!source "src/driver-reu.s"
!source "src/driver-sid.s"

!source "src/player.s"
!source "src/sequencer.s"

!source "src/loader-exp.s"

!source "src/screen-fx.s"
!source "src/windowing.s"

!source "src/misc-functions.s"

!source "src/tables.s"

; generic text/PETSCII stuff that's used by multiple functions goes here

!ifndef  c128 {
	!source "src/mm-text-64.s"
} else {
	!source "src/mm-text-128.s"
}

!ifndef c128 {
	config_filename_len !byte 13
	config_filename     !text "modplay64.cfg",0
} else {
	config_filename_len !byte 14
	config_filename     !text "modplay128.cfg",0
}

dirname
		!text "$"

bittable
 !byte $01, $02, $04, $08, $10, $20, $40, $80

; this area is used to temporarily store the contents of zero page when
; the player is running, since the player needs a lot of it and the KERNAL
; and BASIC will be switched-off anyway.

zp_backup
	!fill 256,0

; Audio and RAM driver assignments
;
; RAM:
; 0 = system memory -- C128 only
; 1 = REU
; 2 = GeoRAM
; 3 = RAMLink DACC
; 4 = SuperCPU expansion RAM
;
; Audio:
; 0 = SID 4-bit volume register
; 1 = SID 4-bit volume reg with dithering
; 2 = SID 4-bit volume reg with interpolating -- C128 or accel only
; 3 = SID 8-bit PWM
; 4 = SID 8-bit PWM with interpolating -- C128 or accel only
; 5 = DAC/DigiMAX
; 6 = DAC/DigiMAX with interpolating -- C128 or accel only


; File list flags
;
; file entries are stored one after the other in 20-byte increments:
;
; bit 7: set if this item is selected for the playlist
; bit 0: set if this file is 15-sample MOD, or is unrecognized

; anything appended after this point will be wiped-out after program init,
; and must either be one-time-use stuff, or must be something that'll be
; copied to another part of memory for runtime use, or which reserves memory
; via the program counter.

!text "free mem",0,0,0

wipe_memory_start

!source "src/init.s"

!align 255,0

!ifndef c128 {
charset_64
	!binary "etc/charset-64a.bin"
} else {
charset_128_alt
	!binary "etc/charset-128a.bin"
}

; mods' lengths are big-endian, but addrs and lengths here are little-endian

pattern_table						= wipe_memory_start
mod_instrument_names				= pattern_table + 128
sample_start_addresses_lows			= mod_instrument_names + 32*31
sample_start_addresses_mids			= sample_start_addresses_lows + 32
sample_start_addresses_highs		= sample_start_addresses_mids + 32
sample_end_addresses_lows			= sample_start_addresses_highs + 32
sample_end_addresses_mids			= sample_end_addresses_lows + 32
sample_end_addresses_highs			= sample_end_addresses_mids + 32
sample_loop_start_addresses_lows	= sample_end_addresses_highs + 32
sample_loop_start_addresses_mids	= sample_loop_start_addresses_lows + 32
sample_loop_start_addresses_highs	= sample_loop_start_addresses_mids + 32
sample_loop_end_addresses_lows		= sample_loop_start_addresses_highs + 32
sample_loop_end_addresses_mids		= sample_loop_end_addresses_lows + 32
sample_loop_end_addresses_highs		= sample_loop_end_addresses_mids + 32
sample_default_loop_flags			= sample_loop_end_addresses_mids + 32
sample_default_fine_tunes			= sample_default_loop_flags + 32
sample_default_volume_levels		= sample_default_fine_tunes + 32

current_note_periods_lows			= sample_default_volume_levels + 32
current_note_periods_highs			= current_note_periods_lows + 8
current_node_period_offsets			= current_note_periods_highs + 8

track_current_enable_flags			= current_node_period_offsets + 8

seq_current_row_data				= track_current_enable_flags + 8

seq_commands						= seq_current_row_data + 64
seq_prev_commands					= seq_commands + 8
seq_command_arguments				= seq_prev_commands + 8
seq_prev_command_arguments			= seq_command_arguments + 8

current_pitch_slide_flags			= seq_prev_command_arguments + 8
seq_pitch_slide_stop_point_lows		= current_pitch_slide_flags + 8
seq_pitch_slide_stop_point_highs	= seq_pitch_slide_stop_point_lows + 8

; the lookahead buffer is arranged as track number * 8 plus byte number
sample_data_buffer					= seq_pitch_slide_stop_point_highs + 8
sample_data_lookahead_indexes		= sample_data_buffer + 64; indexes are 64 bytes also

main_mem_free_start					= ((>sample_data_lookahead_indexes) + 1) * 256

; anything appended after this point will be overwritten by the loaded file
; when using main memory driver
