; Modplay 64/128 -- Copright 1996-2024 Vanessa Dannenberg
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

; main program code

!ifndef c128 {
	!ifndef c64u {
		badlines_exist = 1
	}
}

!ifdef scpu {
	turbo_available = 1
} else ifdef c64u {
	turbo_available = 1
}

!convtab pet
!cpu 6510

* = program_start

start
	jsr init							; the ROMs were disabled at init end
	jsr regenerate_tables_if_needed		; this goes here because it'll
										; overwrite the init code.

	jsr enable_kernal_only

	!ifndef c128 {
		!ifdef scpu {
			bit SCPU_PRESENT
			bmi +

			sta SCPU_TURBO_ON
			sta SCPU_ENABLE_HW_REGS
			lda #%01000100				; optimize:  only echo $c000-$ffff to
			sta SCPU_OPTIMIZATION_MODE	; local RAM
			sta SCPU_DISABLE_HW_REGS
		  +
		}

		jsr disable_vic_screen
		jsr erase_file_list
		jsr set_standard_charset
		lda #CLR
		jsr CHROUT
		jsr enable_vic_screen
	}

	jmp show_main_menu ; and away we go!

; additional code goes here

; functions, macro calls used as functions, and code used at init time must
; be placed here at the start, otherwise they could end up under BASIC-LOW
; ROM on the C128

!source "src/misc-macros.s"
!source "src/misc-functions.s"
!source "src/tables.s"

!ifdef use_profiler {
	!source "src/profiler.s"
}

check_color_flag
	+CHECK_COLOR_FLAG
rts

print_msg
	+PRINT_MSG
rts

print_msg_rle
	+PRINT_MSG_RLE
rts

enable_vic_screen
	+ENABLE_VIC_SCREEN
rts

disable_vic_screen
	+DISABLE_VIC_SCREEN
rts

lockout_interrupts ; any interrupt that gets here exits unacknowledged
rti

!source "src/loader-common.s"
!source "src/loader-standard.s"
!source "src/loader-uci.s"
!source "src/decode-mod.s"

!ifndef turbo_available {
	!source "src/multirate.s"
}

!source "src/disk-ops.s"
!source "src/directory.s"

!source "src/main-menu.s"
!source "src/main-menu-keys.s"
!source "src/change-show.s"
!source "src/playlist.s"

!source "src/screen-fx.s"
!source "src/windowing.s"

!source "src/drv-reu-blockops.s"
!source "src/drv-reu-musicops.s"

!source "src/player.s"

!source "src/isr-common.s"

!source "src/drv-audio-common.s"
!source "src/mixer-common.s"

!source "src/viz-common.s"
!source "src/sequencer-ui.s"

!source "src/fxcmd-set-volume.s"
!source "src/fxcmd-set-sample-offset.s"
!source "src/fxcmd-extended-misc.s"

; see under-kernal.s for the rest of the code

!ifdef c64u {
	!source "src/viz-row-data-64.s"
	!source "src/viz-waveforms-c64u.s"
} else ifdef c128 {
	!source "src/viz-row-data-128.s"
	!source "src/viz-waveforms-128.s"
} else {
	!source "src/viz-row-data-64.s"
	!source "src/viz-waveforms-64.s"
}

; generic text/PETSCII stuff that's used by multiple functions goes here

!ifndef c128 {
	!source "src/strings-64.s"
} else {
	!source "src/strings-128.s"
}

!ifndef c128 {
	config_filename_len !byte 8
	config_filename     !text "mp64.cfg",0
} else {
	config_filename_len !byte 9
	config_filename     !text "mp128.cfg",0
}

dirname
		!text "$"

; File list flags
;
; file entries are stored one after the other in 20-byte increments:
;
; bit 7: set if this item is selected for the playlist
; bit 0: set if this file is 15-sample MOD, or is unrecognized

; --------------------------------------------------------------------------
; from here on down are transient tables and buffers and whatnot. the init
; code and under-KERNAL stuff take about 10 kB, but the volume table alone is
; 16 kB, so almost the entire init and under-kernal code will be overwritten
; the first time that's generated (the first bit gets nuked when a file is
; loaded).

; careful with the table/vars placement, C128 KERNAL-low starts at $c000
; so anything that needs it banked-in has to come early in this section.

sample_start_addresses_mids			!skip 32
sample_start_addresses_highs		!skip 32
sample_end_addresses_lows			!skip 32
sample_end_addresses_mids			!skip 32
sample_end_addresses_highs			!skip 32
sample_lengths_lows					!skip 32
sample_lengths_mids					!skip 32
sample_lengths_highs				!skip 32
sample_loop_start_addresses_lows	!skip 32
sample_loop_start_addresses_mids	!skip 32
sample_loop_start_addresses_highs	!skip 32
sample_default_loop_flags			!skip 32
sample_default_fine_tunes			!skip 32
sample_default_volume_levels		!skip 32

!align 255,0,0

init_begin
!source "src/init.s"
!source "src/under-kernal.s"

; volume table is a whopping 64 pages (16 kB)

volume_table						= init_begin

; load/sample buffer is LOAD_BUFFER_PAGES pages (1.25 kB), overlapped
load_buffer							= volume_table + 64*256
sample_data_buffer					= load_buffer

ascii_to_petscii_table				= load_buffer + LOAD_BUFFER_PAGES*256
steprate_lookup_table				= ascii_to_petscii_table + 256

end_of_mid_mem_tables				= steprate_lookup_table + 14*256

; ----------------------------------------------------------------------
; constants that depend on the addresses pointed to by the symbols above

magic_number_location = load_buffer + header31_seek_to_pat_tbl + 128

!source "src/assemble-errs.s"
