; Autoload header, "stop wedge" + ready trap version,
; shamelessly imported from
; https://codebase64.org/doku.php?id=base:autostarting_disk_files
;
; modified to load the program in parts so that a splash can be shown
; while the main code is loading

!source "src/constants.h"

!convtab pet
!cpu 6510

; this is a binary save of C128 mem from $0200 to $03fa
; after waiting for the machine to finish startup.
;
; this is needed because there's a bunch of binary data that
; can't easily be represented in source form (plus some overlap to ensure
; that the code below can safely overwrite one byte of it).

* = $0200

!binary "etc/low-mem-128.bin"

* = $0200
!word $0200

; BASIC header -- this is only present to remind
; the user if they loaded wrong

basic_header
	!word $1307	; pointer to next line (relative to $1301)
	!word $000a		; line number 10
	!byte $8f		; "REM"
	!text " nope!"
	!byte 0,0,0


; if the KERNAL uses BURST mode to get the load started, it will load exactly
; two full disk blocks, because the STOP vector we're overwriting is a bit
; over one disk block past the load address.  In so doing, it'll replace the
; 0 normally found at $03f7 with the $55 written into the binary save by the
; !byte pseudo-op at the bottom of this file.  If FAST mode is used, the
; KERNAL will stop cold at $0328 and the 0 remains intact, so we have to
; displace the load address for the splash segment downward to effectively
; discard the remainder of the "binary save" that it didn't load.


splash_loader
	lda $03f7
	cmp #$55
	beq +

	lda #<(program_start-$d0)
	sta EAL
	lda #>(program_start-$d0)
	sta EAL+1
	bne splash_loader_run

+	lda #<program_start
	sta EAL
	lda #>program_start
	sta EAL+1

splash_loader_run
	lda splash_128_end_check	; when the splash has finished loading
	bne +						; there will be a zone of non-0's in this area
	jmp $f66e					; which overwrites the 0 stored below.

; by the time we get here, the splash code is loaded, so execute that, then
; reset the load address back to the start, since main prg will load there as
; usual also, ...

+	lda #$6e					;repair stop check vector right away
	sta STOP_vec
	lda #$f6
	sta STOP_vec+1
	jsr program_start
	lda #<program_start			; now re-point the load address so that the
	sta EAL						; main program segment can load.
	sta CHROUT_vec
	lda #>program_start
	sta EAL+1
	sta CHROUT_vec+1
	jmp $f66e					; now let the KERNAL finish loading.

; The real splash data ends at around program_start + $0570, and there'll be a
; block of NOP's at the end to give some room for expansion, aligned to fill
; the last BURST block.

; stop_vector_trap enters right here

* = $026e

!byte 0,0 ; move PC +2

stop_vector_trap_entry
	lda #<(splash_loader_run-2)
	sta STOP_vec
	lda #>(splash_loader_run-2)
	sta STOP_vec+1
	lda #0
	sta splash_128_end_check
	beq splash_loader

end_of_entry

	!fill $02a2-end_of_entry+2, 0

; We are at $0300 now.  The system vectors from here to $0327 must remain
; intact to allow normal BASIC/KERNAL operation

; The C128 has some copied-from-ROM code here that must be preserved

	lda $ff00	; FETCH
	stx $ff00
	tax
	lda ($bb),y
	stx $ff00
	rts

	pha			; STASH
	lda $ff00
	stx $ff00
	tax
	pla
	sta ($ac),y
	stx $ff00
	rts

	pha			; CMPARE
	lda $ff00
	stx $ff00
	tax
	pla
	cmp ($ff),y
	stx $ff00
	rts

	jsr $02e3	; JSRFAR
	sta $06
	stx $07
	sty $08
	php
	pla
	sta $05
	tsx
	stx $09
	lda #$00
	sta $ff00
	rts

	ldx #$00	; JMPFAR
	lda $03,x
	pha
	inx
	cpx #$03
	bcc $02e5
	ldx $02
	jsr $ff6b
	sta $ff00
	lda $06
	ldx $07
	ldy $08
	rti

	sei
	jmp $0000

	!word $e904		; $300 vector: print BASIC error message
	!word $4dc6		; $302 vector: BASIC warm start
	!word $eed1		; $304 vector: tokenize BASIC text
	!word $5151		; $306 vector: BASIC text list
	!word $4aa2		; $308 vector: BASIC char. dispatch
	!word $78da		; $30a vector: BASIC token evaluation
	!byte $21,$43,$cd,$51 ;$30c temp storage CPU registers

	!byte $a9, $4b	; $310 USR function, JMP+address
	!byte $ff, $ff	; $312 unused

	!word $fa65		; $314 Vector: Hardware Interrupt
	!word $b003		; $316 Vector: BRK Instr. Interrupt
	!word $fa40		; $318 Vector: Non-Maskable Interrupt
	!word $efbd		; $31a KERNAL OPEN routine vector
	!word $f188		; $31c KERNAL CLOSE routine vector
	!word $f106		; $31e KERNAL CHKIN routine
	!word $f14c		; $320 KERNAL CHKOUT routine
	!word $f226		; $322 KERNAL CLRCH routine vector
	!word $ef06		; $324 KERNAL CHRIN routine
	!word $ef79		; $326 KERNAL CHROUT routine
	!word $026e		; $328 KERNAL STOP routine Vector (was $f66e)

* = $03f9
!byte $55 ; note that it'll actually be at $03f7 once loaded

