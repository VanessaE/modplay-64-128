; C128 boot sector. (T1, S0)
; from https://c-128.freeforums.net/thread/130/c128-autoboot

!convtab pet
!cpu 6510

* = $0b00

	!text "cbm"							; Autoboot signature.

	!word $0000							; Load address for additional sectors. (T1, S1)
	!byte $00							; Bank number for additional sectors.
	!byte $00							; Number of sectors to load.

	!text "modplay 128 v"
	!text version_major+$30,".",version_minor+$30
	!byte 0				; Boot message: "BOOTING..."

	!text "", 0							; Program to load on boot.

start
	ldx #<cmd-1							; Lo-byte of cmd - 1
	ldy #>cmd							; Hi-byte of cmd
	jmp $afa5							; Execute BASIC command.

cmd
	!ifndef scpu {
		!text "run ", $22, "mp128", $22, ",u8"
	} else {
		!text "run ", $22, "mp128-scpu", $22, ",u8"
	}

	!align 255,0,0						; Fill remaining bytes with 0
