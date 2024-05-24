; Modplay 64/128 v2.0 -- Copright 2024 Vanessa Dannenberg
;
; This code and related resources are released under Creative Commons license
; CC-By-NC-SA v4.0 -- see license.txt for all the legal mumbo-jumbo
;
; To build this project, you will need GNU Make (probably part of your
; operating system's "build essential" package), Acme Assembler, xxd, and the
; c1541 tool from VICE.
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

!source "src/constants.h"
!source "src/misc-macros.s"

!convtab pet
!cpu 6510

!ifndef c128 {
	* = $0801
} else {
	* = $1301
}

start
	jsr init

	jmp show_main_menu ; and away we go!

; macro calls, as needed

+STRING_OPS
+SCREEN_ONOFF
+ROM_SWITCHING
+ZERO_PAGE_OPS
+NUMERIC_OPS
+MATH_OPS

!ifdef c128 {
	+VDC_OPS
	+C128_CPU_FREQ
}

; additional code goes here

!source "src/init.s"
!source "src/main-menu.s"
!source "src/player.s"
!source "src/directory.s"
!source "src/load-file-exp.s"
!source "src/file-ops.s"

!source "src/drv-reu.s"
!source "src/isr-common.s"
!source "src/drv-sid-4b.s"

; text/PETSCII stuff goes here

!ifndef  c128 {
	!source "src/mm-text-64.s"
} else {
	!source "src/mm-text-128.s"
}

!macro SPLASH_STATUS_LINE {
	!byte HOME
	!ifndef c128 {
		!fill 14,DOWN
		!fill 12,RIGHT
	} else {
		!fill 14,DOWN
		!fill 29,RIGHT
	}
}

!ifndef c128 {
	initializing_msg
		+SPLASH_STATUS_LINE
		!text CYAN,  "Initializing..."
		!byte 0

	detect_hw_msg
		+SPLASH_STATUS_LINE
		!text YEL,"Detect hardware"
		!byte 0
} else {
	initializing_msg
		+SPLASH_STATUS_LINE
		!text CYAN,  "   Initializing...    "
		!byte 0
}

press_key_msg
	!text "Press any key",0


!ifndef c128 {
	config_filename_len !byte 8
	config_filename     !text "mp64.cfg",0
} else {
	config_filename_len !byte 9
	config_filename     !text "mp128.cfg",0
}

; this area is used to temporarily store portions the contents of zero page
; the player is running, since the player needs a lot of it and the KERNAL
; and BASIC will be switched-off anyway.

	!align 255,0,$ff

zp_backup
	!fill 256,0
