; subroutine: audio buffer in-feed from player

; sum two tracks' samples

!macro BUF_INSERT .channel {
		!if .channel == "L" {
			.track_data = track_1_data
			.vt_vec = track_1_vol_tab_vec
		} else {
			.track_data = track_2_data
			.vt_vec = track_2_vol_tab_vec
		}

		ldy .track_data				; track sample byte -> index into vol tab
		lda (.vt_vec),y				; the vol table vectors will be set by
		sta .tmp+1					; player/sequencer when vol is changed
		ldy .track_data+1
		lda (.vt_vec+2),y
		clc
	.tmp
		adc #0 ; overwritten just above
		ror

		!if .channel == "L" {
			sta audio_buffer_left,y
		} else {
			sta audio_buffer_right,y

			ldy audio_in_buf_index ; wait for an empty slot for the samples
			iny
		-	cpy audio_out_buf_index
			beq -
			sty audio_in_buf_index
		}
}

add_to_audio_buffers
	+BUF_INSERT "L"
	+BUF_INSERT "R"
	rts
