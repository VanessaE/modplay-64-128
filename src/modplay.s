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

start
	sei
	jsr enable_kernal_only
	jsr init

	!ifndef c128 {
		jsr disable_screen
		jsr erase_file_list
		jsr set_normal_screen
		lda #CLR
		jsr CHROUT
		jsr enable_screen
	}

	jmp show_main_menu ; and away we go!

; additional code goes here

; functions and macro calls used as functions must be placed here at the
; start, otherwise they'll end up under BASIC-LOW ROM on the C128

!source "src/misc-macros.s"
!source "src/misc-functions.s"

+PRINT_MSG
+PRINT_MSG_RLE
+SCREEN_ONOFF

!source "src/loader-common.s"
!source "src/decode-mod.s"

!source "src/disk-ops.s"
!source "src/directory.s"

!source "src/main-menu.s"
!source "src/change-show.s"
!source "src/playlist.s"

!source "src/isr-common.s"
!source "src/driver-reu.s"
!source "src/driver-sid-4b.s"
!source "src/driver-sid-d4b.s"
!source "src/driver-sid-mah.s"
!source "src/driver-dac.s"

!source "src/player.s"
!source "src/sequencer.s"
!source "src/viz-common.s"
!source "src/viz-row-data.s"

!source "src/mixer.s"

!source "src/screen-fx.s"
!source "src/windowing.s"

!source "src/tables.s"

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

!align 255,0

main_mem_free_start

!source "src/init.s"

!ifndef c128 {
charset_64
	!binary "etc/charset-64a.bin"
	!binary "etc/charset-64p.bin"
} else {
charset_128_alt
	!binary "etc/charset-128a.bin"
}
