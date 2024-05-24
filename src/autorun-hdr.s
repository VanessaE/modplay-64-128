; Autoload header, "stop wedge" + ready trap version,
; shamelessly imported from
; https://codebase64.org/doku.php?id=base:autostarting_disk_files
; modified to load the program in parts so that a splash can be shown
; while the main code is loading

!source "src/constants.h"

!convtab pet
!cpu 6510

!ifndef c128 {
	* = $0000
	load_addr = stop_vector_trap-(stop_vector_trap_entry-basic_header)
	!word load_addr
	stop_vector_trap		= $02ed
} else {
	* = $0200
	load_addr				= $0200
	!word $0200
	stop_vector_trap		= $026e
}

; BASIC header -- this is only present to remind the user to LOAD ,xx,1
; if they tried to load it normally.

basic_header
	!word program_start_addr+6 ; pointer to next line
	!word $000a		; line number 10
	!byte $8f		; "REM"
	!text " nope!"
	!byte 0,0,0

splash_loader
	ldy #0
--	lda #3
	sta zero_countdown
-	jsr ACPTR
	sta (load_pointer),y
	iny
	bne +
	inc load_pointer+1
+	and #$ff
	bne --
	dec zero_countdown
	bne -

splash_start
	jsr program_start_addr		; by the time we get here, the splash code is
	lda #<program_start_addr	; loaded, so execute that, then reset the load
	sta kernal_loading_addr		; address back to the start, since main.s etc.
	sta chrout_vec				; will load there as usual also, ...
	lda #>program_start_addr
	sta kernal_loading_addr+1
	sta chrout_vec+1
!ifndef c128 {					; ...and let the KERNAL finish loading.
	jmp $f6ed
} else {
	jmp $f66e
	!fill $0270-*, 0
}

; stop_vector_trap enters right here.
stop_vector_trap_entry
	lda #$f6				;repair stop check vector right away (only the
	sta $329				;hi-byte was altered, that's why *=$02ed or $026e)
	lda #<program_start_addr
	sta load_pointer
	lda #>program_start_addr
	sta load_pointer+1
	bne splash_loader

; We are at $300 now.  The system vectors from here to $327 must remain
; intact to allow normal basic/kernal operation and therefore the autorunner
; must contain the proper bytes for these:

!ifdef c128 {
	!fill $02a4-*, 0

; The C128 has some copied -from-ROM code here that must be preserved

	lda $ff00
	stx $ff00
	tax
	lda ($bb),y
	stx $ff00
	rts
	pha
	lda $ff00
	stx $ff00
	tax
	pla
	sta ($ac),y
	stx $ff00
	rts
	pha
	lda $ff00
	stx $ff00
	tax
	pla
	cmp ($ff),y
	stx $ff00
	rts
	jsr $02e3
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
	ldx #$00
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

	!word $e904		;$300 vector: print basic error message
	!word $4dc6		;$302 vector: basic warm start
	!word $eed1		;$304 vector: tokenize basic text
	!word $5151		;$306 vector: basic text list
	!word $4aa2		;$308 vector: basic char. dispatch
	!word $78da		;$30a vector: basic token evaluation
	!byte $21,$43,$cd,$51 ;$30c temp storage cpu registers

	!byte $a9, $4b	;$310 usr function, jmp+address
	!byte $ff, $ff	;$312 unused

	!word $fa65		;$314 Vector: Hardware Interrupt
	!word $b003		;$316 Vector: BRK Instr. Interrupt
	!word $fa40		;$318 Vector: Non-Maskable Interrupt
	!word $efbd		;$31a kernal open routine vector
	!word $f188		;$31c kernal close routine vector
	!word $f106		;$31e kernal chkin routine
	!word $f14c		;$320 kernal chkout routine
	!word $f226		;$322 kernal clrchn routine vector
	!word $ef06		;$324 kernal chrin routine
	!word $ef79		;$326 kernal chrout routine
	!word stop_vector_trap ;$328: kernal stop routine Vector ($f66e)
} else {
	!fill 4,0

	!word $e38b		;$300 vector: print basic error message
	!word $a483		;$302 vector: basic warm start
	!word $a57c		;$304 vector: tokenize basic text
	!word $a71a		;$306 vector: basic text list
	!word $a7e4		;$308 vector: basic char. dispatch
	!word $ae86		;$30a vector: basic token evaluation
	!byte 0,0,0,0	;$30c temp storage cpu registers

	jmp $b248		;$310 usr function, jmp+address
	!byte 0			;$313 unused

	!word $ea31		;$314 Vector: Hardware Interrupt
	!word $fe66		;$316 Vector: BRK Instr. Interrupt
	!word $fe47		;$318 Vector: Non-Maskable Interrupt
	!word $f34a		;$31a kernal open routine vector
	!word $f291		;$31c kernal close routine vector
	!word $f20e		;$31e kernal chkin routine
	!word $f250		;$320 kernal chkout routine
	!word $f333		;$322 kernal clrchn routine vector
	!word $f157		;$324 kernal chrin routine
	!word $f1ca		;$326 kernal chrout routine
	!word stop_vector_trap ;$328: kernal stop routine Vector ($f6ed)
	}
