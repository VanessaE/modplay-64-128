; This file handles most of the work to parse a MOD file's header, determine
; the file type, etc.

decode_mod_header
	ldx #19								; song title
-	lda load_buffer,x
	sta current_file_title,x
	dex
	bpl -

	lda #1								; check filetype
	sta temp_abs_a
	ldy #0

--	ldx #0
	stx match_header

-	lda mod_magic_numbers,y
	beq mod_filetype_unsure				; if none of the magic numbers match, try
	eor magic_number_location,x			; to identify the file another way
	ora match_header
	sta match_header

	iny
	inx
	cpx #4
	bne -

	inc temp_abs_a
	lda match_header
	bne --
	jmp set_num_tracks

; last ditch effort: see if there's something in the title, if the "restart"
; byte is between 1 and 128, if sample #1 has non-zero length and non-zero
; volume, if there's between 1 and 128 song positions, and if there's at
; least two patterns, with no pattern number being greater than 127.

; theoretically a mod could have only one pattern (#0), but then it would be
; so short that it would be basically empty.

; of course, a binary or just gibberish file could easily pass these checks,
; but what else can we do?  Blame M&K for not putting a proper magic number
; in the original 15-sample format. :-P

mod_filetype_unsure
	lda #0
	ldy #19										; check the whole title in
-	ora load_buffer,y							; case the author hid a msg
	dey
	bpl -
	and #$ff ; was .A was non-zero?
	beq +

	lda load_buffer + 20 + 22					;  \__ sample #1 length
	ora load_buffer + 20 + 22 + 1				;  /
	beq +

	lda load_buffer + 20 + 22 + 2 + 1			; sample #1 default volume
	beq +

	lda load_buffer + header15_seek_to_pat_tbl - 1	; "restart" byte
	beq +
	cmp #128
	bcs +

	ldy load_buffer + header15_seek_to_pat_tbl - 2	; number of song positions
	beq +
	cpy #129
	bcs +

	lda #0										; has pattern table  (duh :-P)
	ldy load_buffer + header15_seek_to_pat_tbl - 2
-	ora load_buffer + header15_seek_to_pat_tbl,y
	dey
	bpl -
	and #$ff ; was .A is non-zero?
	beq +
	cmp #$80					; were any pattern numbers greater than 127?
	bcs +
	lda #1						; if all of that is present, there is a
	sta current_file_type		; reasonable chance that it's a 15-sample mod
	lda #4
	sta current_file_tracks
	bne get_pattern_table

+	sec							; if any of that is wrong, consider the file
	rts							; as unknown and signal the loader to abort.

set_num_tracks
	lda temp_abs_a
	sta current_file_type
	cmp #5
	bcs +
-	lda #4						; filetypes 1-4 (no tag, "M.K.", "M!K!",
	sta current_file_tracks 	; and "FLT4") have 4 tracks
	bne get_pattern_table

+	cmp #6						; so does filetype 6 ("4CHN")
	beq -

	cmp #7						; filetype 7 ("6CHN") has 6 tracks (duh :-P )
	bne +
	lda #6
	sta current_file_tracks
	bne get_pattern_table

+	lda #8						; file types 5 and 8 ("FLT8" or "8CHN") are
	sta current_file_tracks		; all that's left, they have 8 tracks

get_pattern_table
	ldy #127
	lda current_file_type
	cmp #1
	bne +

	lda #<header15_seek_to_pat_data
	sta parse_header_sample_pointer
	lda #>header15_seek_to_pat_data
	sta parse_header_sample_pointer+1

	lda #<(load_buffer + header15_seek_to_pat_tbl - 2)
	sta fill_copy_source
	lda #>(load_buffer + header15_seek_to_pat_tbl - 2)
	sta fill_copy_source+1

-	lda load_buffer + header15_seek_to_pat_tbl,y
	sta pattern_table,y
	dey
	bpl -
	bmi count_patterns

+	lda #<header31_seek_to_pat_data
	sta parse_header_sample_pointer
	lda #>header31_seek_to_pat_data
	sta parse_header_sample_pointer+1

	lda #<(load_buffer + header31_seek_to_pat_tbl - 2)
	sta fill_copy_source
	lda #>(load_buffer + header31_seek_to_pat_tbl - 2)
	sta fill_copy_source+1

-	lda load_buffer + header31_seek_to_pat_tbl,y
	sta pattern_table,y
	dey
	bpl -

count_patterns
	ldy #0
	sty number_of_patterns
	lda (fill_copy_source),y
	sta number_of_song_positions

-	lda pattern_table,y
	cmp number_of_patterns
	beq +
	bcc +
	sta number_of_patterns

+	iny
	cpy number_of_song_positions
	bne -
	inc number_of_patterns

parse_instruments
	ldx #31
	lda #0
-	sta sample_start_addresses_mids,x
	sta sample_start_addresses_highs,x
	sta sample_end_addresses_lows,x
	sta sample_end_addresses_mids,x
	sta sample_end_addresses_highs,x
	sta sample_loop_start_addresses_lows,x
	sta sample_loop_start_addresses_mids,x
	sta sample_loop_start_addresses_highs,x
	sta sample_loop_end_addresses_lows,x
	sta sample_loop_end_addresses_mids,x
	sta sample_loop_end_addresses_highs,x
	sta sample_default_loop_flags,x
	sta sample_default_fine_tunes,x
	sta sample_default_volume_levels,x
	dex
	bmi +
	jmp -

; the first pattern is at start + exp_file_data_start_page*256

+	lda #0
	sta parse_header_sample_pointer
	sta parse_header_sample_pointer+2

	lda exp_file_data_start_page
	sta parse_header_sample_pointer+1

	lda number_of_patterns
	asl
	asl
	clc
	adc parse_header_sample_pointer+1
	sta parse_header_sample_pointer+1
	lda parse_header_sample_pointer+2
	adc #0
	sta parse_header_sample_pointer+2

	lda #<(load_buffer + header_first_inst_meta_offset)
	sta fill_copy_source
	lda #>(load_buffer + header_first_inst_meta_offset)
	sta fill_copy_source+1

	ldx #1 ; the sample numbers in the pattern data start at 1, not 0.

.next_instr
	ldy #22

	lda parse_header_sample_pointer+1		; each sample starts at a 256 byte
	sta sample_start_addresses_mids,x		; boundary (so _lows is always 0)
	lda parse_header_sample_pointer+2
	sta sample_start_addresses_highs,x

	; .Y = 22 here.
	lda #0
	sta temp_counter+2
	lda (fill_copy_source),y				; read sample length, MSB first
	sta temp_counter+1
	iny ; 23
	lda (fill_copy_source),y

	asl
	sta temp_counter						; double it:  # words to # bytes
	sta sample_lengths_lows,x
	rol temp_counter+1
	rol temp_counter+2

	lda temp_counter+1
	sta sample_lengths_mids,x
	lda temp_counter+2
	sta sample_lengths_highs,x

	; check if that sample overlaps a 512k boundary

	clc
	lda sample_start_addresses_mids,x
	adc sample_lengths_mids,x
	lda sample_start_addresses_highs,x
	adc sample_lengths_highs,x

	and #$07
	bne .decode_no_512k_wrap
	lda sample_start_addresses_highs,x
	and #$07
	beq .decode_no_512k_wrap

	lda #0
	sta sample_start_addresses_mids,x
	sta parse_header_sample_pointer
	sta parse_header_sample_pointer+1
	inc sample_start_addresses_highs,x
	inc parse_header_sample_pointer+2

.decode_no_512k_wrap
	clc
	lda sample_lengths_lows,x
	adc parse_header_sample_pointer			; preset for next sample address
	sta sample_end_addresses_lows,x			; <--- this eliminates having to look
	lda sample_lengths_mids,x				;      "forward" in the header to find
	adc parse_header_sample_pointer+1		;      next sample start address to use
	sta parse_header_sample_pointer+1		;      as this sample's end.
	sta sample_end_addresses_mids,x
	lda sample_lengths_highs,x
	adc parse_header_sample_pointer+2
	sta parse_header_sample_pointer+2
	sta sample_end_addresses_highs,x

	clc										; the next sample will start at
	lda #0									; least 256 bytes past the end of
	sta parse_header_sample_pointer			; this sample
	lda parse_header_sample_pointer+1
	adc #2
	sta parse_header_sample_pointer+1
	bcc +
	inc parse_header_sample_pointer+2

+	lda temp_counter+1						; if this sample's len < 2 words,
	bne +									; zero-out its start addrs and
	lda temp_counter						; skip setting any attributes, now
	cmp #2									; that there's a valid addr to use
	bcs +									; for the next sample's start addr

	lda #0
	sta sample_start_addresses_mids,x
	sta sample_start_addresses_highs,x

	sec										; if a sample is to be skipped, don't
	lda parse_header_sample_pointer+1		; waste RAM on useless padding :)
	sbc #2
	sta parse_header_sample_pointer+1
	lda parse_header_sample_pointer+2
	sbc #0
	sta parse_header_sample_pointer+2

	jmp skip_sample

+	iny ; 24
	lda (fill_copy_source),y
	and #$0f
	clc
	adc #8
	and #$0f
	sta sample_default_fine_tunes,x

	iny ; 25
	lda (fill_copy_source),y
	sta sample_default_volume_levels,x

	ldy #28
	lda #0
	sta temp_counter+2
	lda (fill_copy_source),y				; read loop length, MSB first
	sta temp_counter+1
	iny ; 29
	lda (fill_copy_source),y
	sta temp_counter

	lda #0
	sta sample_default_loop_flags,x

	lda temp_counter+1						; if loop len > 1 word, flag this
	bne +									; sample as loopable
	lda temp_counter
	cmp #2
	bcc skip_sample

+	lda #$80
	sta sample_default_loop_flags,x

	ldy #26
	lda #0
	sta temp_counter+2
	lda (fill_copy_source),y				; read loop start offset, MSB first
	sta temp_counter+1
	iny ; 27
	lda (fill_copy_source),y

	asl
	sta temp_counter						; double it:  # words to # bytes
	rol temp_counter+1
	rol temp_counter+2

	clc										; convert to address
	lda temp_counter
	sta sample_loop_start_addresses_lows,x
	lda sample_start_addresses_mids,x
	adc temp_counter+1
	sta sample_loop_start_addresses_mids,x
	lda sample_start_addresses_highs,x
	adc temp_counter+2
	sta sample_loop_start_addresses_highs,x

	ldy #28									; read loop length again
	lda #0
	sta temp_counter+2
	lda (fill_copy_source),y
	sta temp_counter+1
	iny ; 29
	lda (fill_copy_source),y
	sta temp_counter

	asl temp_counter						; double it:  # words to # bytes
	rol temp_counter+1
	rol temp_counter+2

	clc										; convert to address
	lda sample_loop_start_addresses_lows,x
	adc temp_counter
	sta sample_loop_end_addresses_lows,x
	lda sample_loop_start_addresses_mids,x
	adc temp_counter+1
	sta sample_loop_end_addresses_mids,x
	lda sample_loop_start_addresses_highs,x
	adc temp_counter+2
	sta sample_loop_end_addresses_highs,x

skip_sample
	clc
	lda fill_copy_source
	adc #instrument_metadata_size
	sta fill_copy_source
	bcc +
	inc fill_copy_source+1

+	inx

	lda current_file_type
	cmp #1
	bne +

	cpx #16
	beq ++
	jmp .next_instr

+	cpx #32
	beq ++
	jmp .next_instr

++	dex
	stx num_samples_to_load
	ldx #31

	; if a sample had a start addr of $0, then it's been declared as "empty",
	; so reset its end to $000100, the middle of the silence block.

-	lda sample_start_addresses_mids,x
	ora sample_start_addresses_highs,x
	bne +

	lda #0
	sta sample_end_addresses_lows,x
	sta sample_end_addresses_highs,x
	lda #1
	sta sample_end_addresses_mids,x

+	dex
	bpl -

	lda parse_header_sample_pointer			; the progress bar code needs to
	sta highest_exp_addresss_used			; know where the sample data ends
	lda parse_header_sample_pointer+1
	sta highest_exp_addresss_used+1
	lda parse_header_sample_pointer+2
	sta highest_exp_addresss_used+2

; Transfer the instrument names to expansion RAM

	; back-up the expansion pointers since we'll need to overwrite them

	lda expansion_transfer_local_addr
	sta utility_pointer
	lda expansion_transfer_local_addr+1
	sta utility_pointer+1

	lda expansion_memory_target_pointer
	sta utility_pointer_b
	lda expansion_memory_target_pointer+1
	sta utility_pointer_b+1
	lda expansion_memory_target_pointer+2
	sta utility_pointer_b+2

	; use the two audio bufs for scratch space
	; to erase the instrument names area

	lda #0
	ldy #0
-	sta audio_buffer_left,y
	sta audio_buffer_right,y
	iny
	bne -

	lda #0
	sta expansion_memory_target_pointer
	sta expansion_memory_target_pointer+2

	lda exp_instr_names_start_page
	sta expansion_memory_target_pointer+1

	lda #<audio_buffer_left
	sta expansion_transfer_local_addr
	lda #>audio_buffer_left
	sta expansion_transfer_local_addr+1

	lda #0
	sta stash_size
	lda #2
	sta stash_size+1

	+JSR_INDIRECT (stash_block_vec)

	clc
	lda exp_instr_names_start_page
	sta expansion_memory_target_pointer+1

	+JSR_INDIRECT (stash_block_vec)

	lda #0
	sta expansion_memory_target_pointer
	sta expansion_memory_target_pointer+2

	lda exp_instr_names_start_page
	sta expansion_memory_target_pointer+1

	lda #<(load_buffer + header_first_inst_meta_offset)
	sta expansion_transfer_local_addr
	lda #>(load_buffer + header_first_inst_meta_offset)
	sta expansion_transfer_local_addr+1

	lda #22
	sta stash_size
	lda #0
	sta stash_size+1

	ldy num_samples_to_load

.decode_mod_next_instr_name

	+JSR_INDIRECT (stash_block_vec)

	clc
	lda expansion_memory_target_pointer
	adc #32
	sta expansion_memory_target_pointer
	lda expansion_memory_target_pointer+1
	adc #0
	sta expansion_memory_target_pointer+1
	lda expansion_memory_target_pointer+2
	adc #0
	sta expansion_memory_target_pointer+2

	lda expansion_transfer_local_addr
	adc #30
	sta expansion_transfer_local_addr
	lda expansion_transfer_local_addr+1
	adc #0
	sta expansion_transfer_local_addr+1

	dey
	bne .decode_mod_next_instr_name

	; restore the original exp pointers

	lda utility_pointer
	sta expansion_transfer_local_addr
	lda utility_pointer+1
	sta expansion_transfer_local_addr+1

	lda utility_pointer_b
	sta expansion_memory_target_pointer
	lda utility_pointer_b+1
	sta expansion_memory_target_pointer+1
	lda utility_pointer_b+2
	sta expansion_memory_target_pointer+2

	clc ; and exit with carry clear to indicate successful parse, okay to load
rts

; this routine rearranges the MOD's pattern data slightly, to reduce the
; sequencer's and visualizer's realtime workload.
;
; old format:
; 7654-3210 76543210 7654-3210 76543210
; wwww-xxxx xxxxxxxx yyyy-cccc zzzzzzzz
;
; new format:
;
; 76543210 7654-3210 76543210 76543210
; wwwwyyyy cccc xxxx-xxxxxxxx zzzzzzzz
;
; where:
;       wwwwyyyy (8 bits) is the sample number
;  xxxx-xxxxxxxx (12 bits) is the note period
;           cccc (4 bits) is the effect number
;       zzzzzzzz (8 bits) is the effect parameter(s)

reformat_pattern_data
	php
	sei
	jsr disable_roms ; the note period table is buried under the KERNAL

	lda #<load_buffer
	sta utility_pointer
	lda #>load_buffer
	sta utility_pointer+1

	lda #0
	sta pattern_conv_row_counter

	conv_row_loop
		lda #0
		sta pattern_conv_trk_counter
		conv_trk_loop
 
			ldy #0
			lda (utility_pointer),y
			and #$f0
			sta temp_abs_a
			ldy #2
			lda (utility_pointer),y
			lsr
			lsr
			lsr
			lsr
			ora temp_abs_a
			sta temp_abs_a

			ldy #2
			lda (utility_pointer),y
			asl
			asl
			asl
			asl
			sta temp_abs_b

			ldy #1
			lda (utility_pointer),y
			iny
			sta (utility_pointer),y

			ldy #0
			lda (utility_pointer),y
			and #$0f
			ora temp_abs_b
			iny
			sta (utility_pointer),y

			ldy #0
			lda temp_abs_a
			sta (utility_pointer),y

			clc
			lda utility_pointer
			adc #4
			sta utility_pointer
			bcc +
			inc utility_pointer+1

		+	inc pattern_conv_trk_counter
			lda pattern_conv_trk_counter
			cmp #4
		bne conv_trk_loop

		inc pattern_conv_row_counter
		lda pattern_conv_row_counter
		cmp #64
	beq +
	jmp conv_row_loop

+	jsr enable_kernal_only
	plp
rts
