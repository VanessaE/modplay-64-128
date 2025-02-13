; This file contains the standard mixer/lookahead routines

!text "mixer-std",0

; these counts are the average mixer run time, in cycles, per output sample
; pair.  See full details in doc/timing-info.txt.

!ifndef scpu {
	!ifndef c128 {
		mixer_cycle_count = 47
	} else {
		mixer_cycle_count = 48 / 2
	}
} else {
	mixer_cycle_count = 3
}

; Must enter with .X = the most recent 16-byte offset into the audio input
; buffer, which will be updated here

run_mixer_lookahead											; 6 to enter
	txa														; 2
	adc #16													; 2

-	ldy audio_out_buf_index									; 3
	cmp and_f0_table,y										; 4
	beq -													; 3/2

	clc														; 2

	mixer_loop_open
	  !for .idx2, 0, 15 {

		; the various `LDY $nnnn` below will have their addresses re-written
		; by the mixer_do_selfmods_for_pitch_change routine below.
		; Similarly, each corresponding `LDA/ADC $nnnn,Y` will
		; have its high byte re-written by the set_volume routine.
		;
		; the addresses below are arbitrary, chosen only so that they're
		; definitely in absolute mode when assembled, and so that failure
		; to alter one of them is easy to spot in the ML monitor at runtime.

		!if .idx2 = 0 { mixer_rd_la_track_1 = * }
		ldy $6100											; 4
		!if .idx2 = 0 { mixer_vol_addr_1 = * }
		lda $8100,y											; 4

		!if .idx2 = 0 { mixer_rd_la_track_4 = *}
		ldy $6400											; 4
		!if .idx2 = 0 { mixer_vol_addr_4 = *}
		adc $8400,y											; 4

		sta audio_buffer_left,x								; 5

		!if .idx2 = 0 { mixer_rd_la_track_2 = * }
		ldy $6200											; 4
		!if .idx2 = 0 { mixer_vol_addr_2 = * }
		lda $8200,y											; 4

		!if .idx2 = 0 { mixer_rd_la_track_3 = * }
		ldy $6300											; 4
		!if .idx2 = 0 { mixer_vol_addr_3 = * }
		adc $8300,y											; 4

		sta audio_buffer_right,x							; 5

		inx													; 2
	  !if .idx2 = 0 { !set mixer_loop_close = * }
	}
rts															; 6

; Mixer self-mod stuff

mixer_loop_segment_length = mixer_loop_close - mixer_loop_open

mixer_set_lookahead_vol_addrs
	ldx mixer_lookahead_code_volume_addr_idx,y

	!zone lookahead_idx_set {
		!for .idx6, 0, 15 {
			sta mixer_vol_addr_1 + mixer_loop_segment_length * .idx6 + 2,x
		}
	}
rts

mixer_do_selfmods_for_pitch_change
  !zone lookahead_idx_set {
	ldy seq_current_track

	lda #0
	sta utility_zpbk_counter
	sta utility_zpbk_counter+1
	sta utility_zpbk_counter+2

	sta temp_zpbk_a
	lda current_steprates_fracts,y
	sta temp_zpbk_a+1

	lda current_steprates_ints,y
	lsr
	ror temp_zpbk_a+1
	ror temp_zpbk_a
	lsr
	ror temp_zpbk_a+1
	ror temp_zpbk_a
	lsr
	ror temp_zpbk_a+1
	ror temp_zpbk_a
	lsr
	ror temp_zpbk_a+1
	ror temp_zpbk_a
	sta temp_zpbk_a+2

	ldx mixer_lookahead_code_read_byte_addr_idx,y

	clc
	lda seq_current_track
	adc #>sample_data_buffer

	!for .idx4, 0, 15 {
		!set .mixer_la_rd_addr_st = mixer_rd_la_track_1 + mixer_loop_segment_length * .idx4
		sta .mixer_la_rd_addr_st + 2,x
	}

	!for .idx5, 0, 15 {

		!set .mixer_la_rd_addr_st = mixer_rd_la_track_1 + mixer_loop_segment_length * .idx5

		lda utility_zpbk_counter+2
		sta .mixer_la_rd_addr_st + 1,x

		lda utility_zpbk_counter
		adc temp_zpbk_a
		sta utility_zpbk_counter

		lda utility_zpbk_counter+1
		adc temp_zpbk_a+1
		sta utility_zpbk_counter+1

		lda utility_zpbk_counter+2
		adc temp_zpbk_a+2
		sta utility_zpbk_counter+2
	  }
	}

	adc #1
rts

mixer_lookahead_code_read_byte_addr_idx
	!byte 0
	!byte mixer_rd_la_track_2 - mixer_rd_la_track_1
	!byte mixer_rd_la_track_3 - mixer_rd_la_track_1
	!byte mixer_rd_la_track_4 - mixer_rd_la_track_1

mixer_lookahead_code_volume_addr_idx
	!byte 0
	!byte mixer_vol_addr_2 - mixer_vol_addr_1
	!byte mixer_vol_addr_3 - mixer_vol_addr_1
	!byte mixer_vol_addr_4 - mixer_vol_addr_1
