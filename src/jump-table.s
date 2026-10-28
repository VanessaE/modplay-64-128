; Jump table for the routines that the program calls indirectly.  Each entry is a
; JMP whose operand gets pointed at the real routine by init, so a call is just a
; JSR to the entry (like the KERNAL's own jump table).  The audio drivers aren't in
; here:  they have fixed entry points of their own (see drv-audio-common.s).
; To set an entry, store the target's low byte at ENTRY+1 and its high byte at ENTRY+2.
;
; This has to live in the early part of the program, because it must be visible while
; ROMs are banked in (and on the C128, anything beyond $4000 can end up under BASIC-LOW).
; A, X, Y and the flags all reach the target routine as they were at the call.

do_selfmod_pitch_vec
	jmp $1234		; do the selfmods for a pitch change (ram driver)
do_selfmod_instrument_vec
	jmp $1234		; do the selfmods for an instrument change (ram driver)
fetch_block_vec
	jmp $1234		; fetch a block from expansion memory
stash_block_vec
	jmp $1234		; stash a block to expansion memory
ram_driver_set_cycle_counts_vec
	jmp $1234		; set the ram driver's cycle counts
