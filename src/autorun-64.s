; Autoload header, "stop wedge" + ready trap version,
; shamelessly imported from
; https://codebase64.org/doku.php?id=base:autostarting_disk_files
;
; modified to load the program in parts so that a splash can be shown
; while the main code is loading

!source "src/constants.h"

!convtab pet
!cpu 6510

* = $0000
load_addr = stop_vector_trap-(stop_vector_trap_entry-basic_header)
!word load_addr
stop_vector_trap		= $02ed

; BASIC header -- this is only present to remind
; the user if they loaded wrong

basic_header
	!word $0807 ; pointer to next line
	!word $000a		; line number 10
	!byte $8f		; "REM"
	!text " nope!"
	!byte 0,0,0

	zero_countdown	!byte 0

splash_loader
	ldy #0
--	lda #3
	sta zero_countdown
-	jsr ACPTR
	sta (load_pointer),y
	iny
	bne +
	inc load_pointer+1
+	and #$ff					; check if the received byte was a $0
	bne --
	dec zero_countdown			; three $0's in a row means end of splash data
	bne -

splash_start
	jsr program_start			; by the time we get here, the splash code is
	lda #<program_start			; loaded, so execute that, then reset the load
	sta EAL						; address back to the start, since main prg
	sta CHROUT_vec				; will load there as usual also, ...
	lda #>program_start
	sta EAL+1
	sta CHROUT_vec+1
	jmp $f6ed 					; ...and let the KERNAL finish loading.

; stop_vector_trap enters right here.
stop_vector_trap_entry
	lda #$f6					;repair stop check vector right away (only the
	sta STOP_vec+1				;hi-byte was altered, that's why *=$02ed)
	lda #<program_start
	sta load_pointer
	lda #>program_start
	sta load_pointer+1
	bne splash_loader

; We are at $0300 now.  The system vectors from here to $0327 must remain
; intact to allow normal BASIC/KERNAL operation and therefore the autorunner
; must contain the proper bytes for these:

	!fill 4,0

	!word $e38b		; $300 vector: print BASIC error message
	!word $a483		; $302 vector: BASIC warm start
	!word $a57c		; $304 vector: tokenize BASIC text
	!word $a71a		; $306 vector: BASIC text list
	!word $a7e4		; $308 vector: BASIC char. dispatch
	!word $ae86		; $30a vector: BASIC token evaluation
	!byte 0,0,0,0	; $30c temp storage CPU registers

	jmp $b248		; $310 USR function, JMP+address
	!byte 0			; $313 unused

	!word $ea31		; $314 Vector: Hardware Interrupt
	!word $fe66		; $316 Vector: BRK Instr. Interrupt
	!word $fe47		; $318 Vector: Non-Maskable Interrupt
	!word $f34a		; $31a KERNAL OPEN routine vector
	!word $f291		; $31c KERNAL CLOSE routine vector
	!word $f20e		; $31e KERNAL CHKIN routine
	!word $f250		; $320 KERNAL CHKOUT routine
	!word $f333		; $322 KERNAL CLRCH routine vector
	!word $f157		; $324 KERNAL CHRIN routine
	!word $f1ca		; $326 KERNAL CHROUT routine
	!word stop_vector_trap ; $328: KERNAL stop routine Vector ($f6ed)
