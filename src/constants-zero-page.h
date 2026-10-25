; This file contains all of the declarations for Zero Page stuff.

!addr {

	; Various KERNAL-related variables/constants

	STATUS								= $90
	VERIFYFLAG							= $93
	MSGFLG								= $9d
	EAL									= $ae
	NAMELEN								= $b7
	SECADDR								= $b9
	FA									= $ba
	NAMEPTR								= $bb


; These Zero Page addrs can be the same on both C64 and C128
; and are for use when Zero Page is not backed-up.

	dividend							= $24 ; to $27
	quotient = dividend
	divisor								= $59 ; through $5b

	rle_mode_flag						= dividend ; safe to overwrite - math ops aren't used
	rle_byte_count						= rle_mode_flag + 1 ; at the same time as RLE printing

	load_pointer						= divisor ; 2 bytes
	filename_addr						= divisor ; 2 bytes

	expansion_memory_target_pointer		= $5c ; to $5e, expansion RAM stash target addr

	divide_tmp							= $5f ; and $60
	print_msg_addr						= divide_tmp
	save_addr							= divide_tmp

	binsearch_low						= dividend ; 2 bytes
	binsearch_mid						= binsearch_low + 2
	binsearch_high						= binsearch_mid + 2
	binsearch_value						= divisor ; 2 bytes

	utility_pointer_c					= $24 ; through $26

	; these Zero Page variables have the same addresses both inside of and
	; outside of the ZP-backup space, so they can be used in either mode, but
	; when used inside of the backup, thier values can't be carried back out.

	utility_pointer_b					= $50 ; through $52

	utility_pointer						= $f7 ; and $f8
	fill_copy_source					= utility_pointer + 2
	fill_copy_target					= fill_copy_source + 2

	; the third byte here will always be 0, but SCPU RAM driver
	; will need this later and it has to be in zero page
	expansion_transfer_local_addr		= $fd ; through $ff


; ZERO PAGE WHEN BACKED-UP
;
; From here on down are variables that can be freely placed and/or rearranged

; This area may only be used when player is running, or at least, when no
; KERNAL or BASIC calls are needed.  Must be restored after any such use.

	* = $02

	utility_zpbk_counter				!skip 3
	temp_zpbk_a							!skip 3
	temp_zpbk_b							!skip 1

	current_track_loop_flags			!skip 8
	current_track_gate_flags			!skip 8
	current_active_tracks_count			!skip 1

	arpeggio_counters					!skip 8 ; zero page is mandatory for this one (STX $ZP,Y)

	bzp_low_end = *

	; because they're needed both inside and outside of the player, multiply
	; divide, and binary search routines' zero page variables have to be in
	; the same places within the "backup-mode" as they are outside of it.

	; for 16/16 or 24/24 divide:
	; dividend/quotient uses $24 through $26
	; divisor uses $27 through $29

	; for 32/16 divide:
	; dividend/quotient uses $24 through $27
	; divisor uses $28/$29

	; for the binary search:
	; binsearch_low is at $24/$25
	; binsearch_mid is at $26/27
	; binsearch_high is at $28/$29

	; the various multiples of 8 bytes below are in order by track number

	; $2a is also available as an in/out-of-ZP-backup common addr

	* = $2a

	pattern_break_target_row			!skip 1
	pos_jump_target_pattern				!skip 1
	seq_current_pattern_number			!skip 1
	seq_current_row						!skip 1
	seq_current_track					!skip 1
	seq_cur_track_data_offset			!skip 1
	seq_ticks_counter					!skip 1
	current_song_pos					!skip 1
	glissando_flag						!skip 1
	vibrato_waveform					!skip 1
	tremolo_waveform					!skip 1
	delay_pattern_divisions				!skip 1
	audio_in_buf_index					!skip 1
	audio_out_buf_index					!skip 1

	song_speed							!skip 1
	seq_tempo_bpm						!skip 1
	seq_ticks_per_division				!skip 1

	mixer_loops_per_tick_fract			!skip 1
	mixer_loops_per_tick				!skip 1
	mixer_countdown_fract				!skip 1
	mixer_countdown						!skip 1

	current_sample_volume_levels		!skip 8

	bzp_lowmid_end = *

	; utility_pointer_b uses $50 through $52

	* = $53

	sequencer_temp_x					!skip 1
	sequencer_temp_y					!skip 1
	sequencer_temp_a					!skip 2 ; \__ these can also be used
	sequencer_temp_b					!skip 2 ; /   as one 4-byte temp

	bzp_upmid_end = *

	; remainder, load pointer and other random stuff uses $59-$5b
	; expansion_memory_target_pointer uses $5c-$5e
	; binary search binsearch_value is at $59/$5a
	; divide_tmp uses $5f and $60

	* = $61
	current_sample_pointers_fracts		!skip 8
	current_sample_pointers_lows		!skip 8
	current_sample_pointers_mids		!skip 8
	current_sample_pointers_highs		!skip 8

	current_steprates_fracts			!skip 8
	current_steprates_ints				!skip 8
	current_sample_end_addr_lows		!skip 8
	current_sample_end_addr_mids		!skip 8
	current_sample_end_addr_highs		!skip 8

	current_vibrato_fundamental_periods_lows	!skip 8
	current_vibrato_fundamental_periods_highs	!skip 8
	current_vibrato_top_periods_lows			!skip 8
	current_vibrato_top_periods_highs			!skip 8

	current_vibrato_step_sizes_fracts	!skip 8
	current_vibrato_step_sizes_ints		!skip 8

	current_pitch_slide_rates			!skip 8
	current_pitch_bend_dirs				!skip 8 ; 0=pitching down, $80=pitching up
												; ¯¯\__ vibrato uses this also

	nmi_temp_a							!skip 1 ; use these for saving and
	nmi_temp_x							!skip 1 ; restoring .AXY during IRQ's
	nmi_temp_y							!skip 1
	nmi_temp_b							!skip 1

	current_fetch_loop_ofl_amounts		!skip 8

	; should be a couple more bytes free here

	bzp_top_end = *

	; and there are in-/out-of-Zero-Page-backup multi-use
	; variables in $f7 through $ff, see above.
}
