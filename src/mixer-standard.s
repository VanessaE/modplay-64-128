; This file contains the standard mixer/lookahead routines

; these counts are the average mixer run time, in cycles, per output sample
; pair.  See full details in doc/timing-info.txt.

mixer_standard_set_cycle_count
	!ifndef scpu {
		!ifndef c128 {
			lda #47
		} else {
			lda #48 / 2
		}
	} else {
		lda #3
	}
	sta mixer_cycle_count
rts

; Must enter with .X = the most recent 16-byte offset into the audio input
; buffer, which will be updated here

run_mixer_standard											; 6 to enter
	txa														; 2
	adc #16													; 2

	!ifndef use_profiler {
	-	ldy audio_out_buf_index									; 3
		cmp and_f0_table,y										; 4
		beq -													; 3/2
	}

	clc														; 2

	mixer_standard_loop_open
	  !for .idx2, 0, 15 {

		; the various `LDY $nnnn` below will have their addresses re-written
		; by the mixer_standard_do_selfmods_for_pitch_change routine below.
		; Similarly, each corresponding `LDA/ADC $nnnn,Y` will
		; have its high byte re-written by the set_volume routine.
		;
		; the addresses below are arbitrary, chosen only so that they're
		; definitely in absolute mode when assembled, and so that failure
		; to alter one of them is easy to spot in the ML monitor at runtime.

		!if .idx2 = 0 { mixer_std_rd_la_track_1 = * }
		ldy sample_data_buffer								; 4
		!if .idx2 = 0 { mixer_vol_std_addr_1 = * }
		lda $8100,y											; 4

		!if .idx2 = 0 { mixer_rd_la_track_4 = *}
		ldy sample_data_buffer+$0300						; 4
		!if .idx2 = 0 { mixer_vol_std_addr_4 = *}
		adc $8400,y											; 4

		sta audio_buffer_left,x								; 5

		!if .idx2 = 0 { mixer_rd_la_track_2 = * }
		ldy sample_data_buffer+$0100						; 4
		!if .idx2 = 0 { mixer_vol_std_addr_2 = * }
		lda $8200,y											; 4

		!if .idx2 = 0 { mixer_rd_la_track_3 = * }
		ldy sample_data_buffer+$0200						; 4
		!if .idx2 = 0 { mixer_vol_std_addr_3 = * }
		adc $8300,y											; 4

		sta audio_buffer_right,x							; 5

		inx													; 2
	  !if .idx2 = 0 { !set mixer_standard_loop_close = * }
	}
rts															; 6

; Mixer self-mod stuff

mixer_standard_loop_segment_length = mixer_standard_loop_close - mixer_standard_loop_open

mixer_standard_set_vol_addrs
	+MIXER_VOL_SELFMOD_LOOP mixer_vol_std_addr_1, mixer_standard_loop_segment_length, mixer_standard_vol_addr_idx
rts

mixer_standard_do_selfmods_for_pitch_change
	+MIXER_PITCH_SELFMOD_LOOP mixer_std_rd_la_track_1, mixer_standard_loop_segment_length, mixer_standard_read_addr_idx
rts

mixer_standard_read_addr_idx
	!byte 0
	!byte mixer_rd_la_track_2 - mixer_std_rd_la_track_1
	!byte mixer_rd_la_track_3 - mixer_std_rd_la_track_1
	!byte mixer_rd_la_track_4 - mixer_std_rd_la_track_1

mixer_standard_vol_addr_idx
	!byte 0
	!byte mixer_vol_std_addr_2 - mixer_vol_std_addr_1
	!byte mixer_vol_std_addr_3 - mixer_vol_std_addr_1
	!byte mixer_vol_std_addr_4 - mixer_vol_std_addr_1
