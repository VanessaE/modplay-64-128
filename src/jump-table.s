; Jump table for the routines that the program calls indirectly.  Each entry is a
; JMP whose operand gets pointed at the real routine by init, or by the audio driver
; setup code, so a call is just a JSR to the entry (like the KERNAL's own jump table).
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
audio_set_resolution_vec
	jmp $1234		; set the volume tables resolution for the audio driver
audio_driver_set_cycle_count_vec
	jmp $1234		; set the audio driver's ISR cycle count
audio_start_vec
	jmp $1234		; start the audio driver
audio_stop_vec
	jmp $1234		; stop the audio driver
ram_driver_set_cycle_counts_vec
	jmp $1234		; set the ram driver's cycle counts
