; This loads a file into the expansion RAM
; enter with carry set to use the filename in the string buffer
; and if it's set, .Y must be the string length

!text "loader-exp",0

load_file_to_expansion
	!ifndef c128 {
		size_text = 9
		progbar_row			= 14
		progbar_column		= 12
		progbar_len			= 16*8
	} else {
		size_text = 12
		progbar_row			= 14
		progbar_column		= 27
		progbar_len			= 26*8

		php
		jsr FULLW
		plp
	}

	sty file_to_load_name_len
	bcc load_from_playlist

-	lda string_buffer,y
	sta string_buffer+2,y
	dey
	bpl -
	lda #"$"
	sta string_buffer
	lda #":"
	sta string_buffer+1

	clc
	lda file_to_load_name_len
	adc #2
	sec
	ldx #<string_buffer
	ldy #>string_buffer
	jsr open_file

	jsr CHRIN				; get/ignore the first six bytes
	jsr CHRIN
	jsr CHRIN
	jsr CHRIN
	jsr CHRIN
	jsr CHRIN

	jsr dir_read_line		; we just throw the header away

	jsr CHRIN				; throw away two more bytes
	jsr CHRIN
	jsr CHRIN				; size LSB
	sta file_to_load_size
	sta file_size_in_kb
	jsr CHRIN				; size MSB
	sta file_to_load_size+1
	sta file_size_in_kb+1

	jsr dir_read_line
	jsr dir_file_unquote
	sty file_to_load_name_len

	jsr close_file

-	lda string_buffer+32,y  ; the "de-quoted" filename is at the end of the buf
	sta string_buffer,y
	dey
	bpl -

	jmp load_by_filename_entry

load_from_playlist
	ldy #0
	ldx playlist_scroll_pos
	jsr calc_filename_address
	stx filename_addr
	sty filename_addr+1

	ldx playlist_scroll_pos
	lda playlist_file_sizes_lows,x
	sta file_to_load_size
	sta current_file_size
	sta file_size_in_kb

	lda playlist_file_sizes_highs,x
	sta file_to_load_size+1
	sta current_file_size+1
	sta file_size_in_kb+1

	ldy #0
-	lda (filename_addr),y
	sta string_buffer,y
	beq +
	iny
	cpy #16
	bne -

+	sty file_to_load_name_len

load_by_filename_entry
	lsr file_size_in_kb+1		; divide by 4
	ror file_size_in_kb
	lsr file_size_in_kb+1
	ror file_size_in_kb

	jsr test_loader_compatibility

	jsr populate_loader_mini_popup

; preset the divisor to be proportional to max number of progress bar segments
; 16 char long bar * 4 segments per = 64 segments on C64, 16 * 8 = 128 on C128

	lda file_to_load_size		; turn blocks-to-load into bytes-to-load
	sta divisor+1
	lda file_to_load_size+1
	sta divisor+2
	lda #0
	sta divisor

	rol divisor+1	; multiply size by 2...
	rol divisor+2
	rol
	!ifndef c128 {	; and again on C64, so x4
		clc
		rol divisor+1
		rol divisor+2
		rol
	}
	tax

	lda divisor+1	; then displace by one byte, e.g. final is divide by 64
	sta divisor		; or divide by 128
	lda divisor+2
	sta divisor+1
	stx divisor+2	; divisor is now number of bytes per segment.

	lda #0
	sta expansion_memory_target_pointer
	sta expansion_memory_target_pointer+1 ; start at $000000 in expansion RAM
	sta expansion_memory_target_pointer+2

	lda #0
	sta EAL
	lda #>load_buffer
	sta EAL+1

	lda file_to_load_name_len
	ldx #<string_buffer
	ldy #>string_buffer+1
	jsr open_file

	bcc +
	jmp .load_err

; in case the loader method (below) is STOP wedge mode, we have to use ACPTR
; to read-in the file's header, because loading via the STOP wedge can't be
; canceled from the calling program (unless the drive errors-out).

+	ldy #0
-	jsr ACPTR
	sta (EAL),y
	iny
	bne -
	inc EAL+1
	lda EAL+1
	cmp #>(load_buffer+5*256)
	bne -

	lda #>load_buffer
	sta EAL+1

	jsr decode_header

	bcs abort_load

	; ### Okay, at this point we can go ahead and load the file.

	; On some machines/drives, the STOP wedge won't work, so the loader calls
	; a test routine to see if it's safe to use.

	ldy load_device
	lda loader_compatibility_table-8,y

	bmi + 
	jsr load_via_acptr
	jmp ++

+	jsr load_via_stop_wedge

++	jsr zero_first_exp_pages

	jsr reformat_pattern_data
rts

abort_load
	jsr close_file
	jsr draw_mini_popup
	lda #0
	ldx #<unknown_file_msg
	ldy #>unknown_file_msg

	!ifndef c128 {
		jsr print_msg
		lda #0
		ldx #<mini_popup_next_line
		ldy #>mini_popup_next_line
		jsr print_msg_rle
		lda #RIGHT
	} else {
		jsr print_msg_rle
		lda #RIGHT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
		jsr CHROUT
	}
	jsr CHROUT
	jsr CHROUT
	jsr press_any_key
rts

populate_loader_mini_popup
	jsr gray_out
	clc
	jsr draw_mini_popup

	lda #mini_popup_width
	ldx #<string_buffer
	ldy #>string_buffer
	jsr center_string

+	lda #CYAN
	jsr CHROUT
	lda #$22 ; quote
	jsr CHROUT

	lda #16
	ldx #<string_buffer
	ldy #>string_buffer
	jsr print_msg

	lda #$22 ; quote
	jsr CHROUT

	!ifndef c128 {
		lda #0
		ldx #<mini_popup_next_line
		ldy #>mini_popup_next_line
		jsr print_msg_rle
	} else {
		lda #RETURN
		jsr CHROUT
	}

	lda #LBLU
	jsr CHROUT

	; determine lengths of filesize strings
	sec
	ldx file_to_load_size
	ldy file_to_load_size+1
	jsr get_num_length
	sty temp_abs_a

	ldx file_size_in_kb
	ldy file_size_in_kb+1
	jsr get_num_length
	sty temp_abs_c

	sec
	lda #mini_popup_width
	sbc temp_abs_a			; length of the blocks figure
	sbc temp_abs_c			; length of the kB figure
	sbc #size_text			; length of the "blocks" and "k" parts
	lsr
	tay
	dey
	beq +
	!ifdef c128 {
		dey
		beq +
	}

	lda #RIGHT
-	jsr CHROUT
	dey
	bne -

+	sec
	ldx file_to_load_size
	ldy file_to_load_size+1
	jsr print_uint16

	lda #0
	ldx #<blocks_msg
	ldy #>blocks_msg
	jsr print_msg

	sec
	ldx file_size_in_kb
	ldy file_size_in_kb+1
	jsr print_uint16

	lda #0
	ldx #<kb_msg
	ldy #>kb_msg
	jsr print_msg

	!ifndef c128 {
		lda #0
		ldx #<mini_popup_next_line
		ldy #>mini_popup_next_line
		jsr print_msg_rle
	} else {
		lda #RETURN
		jsr CHROUT
	}

	lda #0
	ldx #<loading_msg
	ldy #>loading_msg
	jsr print_msg

	!ifndef c128 {
		lda #0
		ldx #<mini_popup_next_line
		ldy #>mini_popup_next_line
		jsr print_msg_rle
	} else {
		jsr FULLW
	}

	lda #0					; file size in kB -> size in bytes
	sta dividend

	lda file_size_in_kb+1
	sta dividend+2

	lda file_size_in_kb
	asl
	rol dividend+2
	asl
	rol dividend+2
	sta dividend+1

	lda #progbar_len
	sta divisor
	lda #0
	sta divisor+1
	sta divisor+2
	jsr divide_24by24

	lda quotient
	sta progress_bar_bytes_per_segment
	lda quotient+1
	sta progress_bar_bytes_per_segment+1
	lda quotient+2
	sta progress_bar_bytes_per_segment+2
	lda #progbar_len
	ldx #progbar_column
	ldy #progbar_row
	jsr draw_empty_progress_bar
rts

update_progress
	sec
	lda expansion_memory_target_pointer
	sbc expansion_memory_start_address
	sta dividend
	lda expansion_memory_target_pointer+1
	sbc expansion_memory_start_address+1
	sta dividend+1
	lda expansion_memory_target_pointer+2
	sbc expansion_memory_start_address+2
	sta dividend+2

	lda progress_bar_bytes_per_segment
	sta divisor
	lda progress_bar_bytes_per_segment+1
	sta divisor+1
	lda progress_bar_bytes_per_segment+2
	sta divisor+2
	jsr divide_24by24

	lda quotient
	jsr update_progress_bar
rts

.load_err
	lda #"E"
	jsr CHROUT
	lda #"r"
	jsr CHROUT
	lda #"r"
	jsr CHROUT
	lda #"o"
	jsr CHROUT
	lda #"r"
	jsr CHROUT
	lda #" "
	jsr CHROUT

	sec
	ldx STATUS
	ldy #0
	jsr print_uint16

-	jsr GETIN
	beq -
rts

decode_header
	lda expansion_memory_start_address
	sta parse_header_sample_pointer
	lda expansion_memory_start_address+1
	sta parse_header_sample_pointer+1
	lda expansion_memory_start_address+2
	sta parse_header_sample_pointer+2

	ldx #19							; song title
-	lda load_buffer,x
	sta current_file_title,x
	dex
	bpl -

	lda #1							; check filetype
	sta temp_abs_a
	ldy #0

--	ldx #0
	stx match_header

-	lda mod_magic_numbers,y
	beq filetype_unsure				; if none of the magic numbers match, try
	eor magic_number_location,x		; to identify the file another way
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
; least two patterns.

; theoretically a mod could have only one pattern (#0), but then it would be
; so short that it would be basically empty.

; of course, a binary or just gibberish file could easily pass these checks,
; but what else can we do?  Blame M&K for not putting a proper magic number
; in the original 15-sample format. :-P

filetype_unsure
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
	lda #1						; if all of that is present, there is a
	sta current_file_type		; reasonable chance that it's a 15-sample mod
	lda #4
	sta current_file_tracks
	bne get_pattern_table

+	sec							; if any of that is missing, consider the file
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

; get pattern table

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

	clc
	lda expansion_memory_start_address
	adc parse_header_sample_pointer
	sta parse_header_sample_pointer
	lda expansion_memory_start_address+1
	adc parse_header_sample_pointer+1
	sta parse_header_sample_pointer+1
	lda expansion_memory_start_address+2
	adc #0
	sta parse_header_sample_pointer+2

	lda number_of_patterns
	asl
	asl
	clc
	adc parse_header_sample_pointer+1
	sta parse_header_sample_pointer+1
	lda parse_header_sample_pointer+2
	adc #0
	sta parse_header_sample_pointer+2

	lda #<mod_instrument_names
	sta fill_copy_target
	lda #>mod_instrument_names
	sta fill_copy_target+1

	lda #<(load_buffer + header_first_inst_meta_offset)
	sta fill_copy_source
	lda #>(load_buffer + header_first_inst_meta_offset)
	sta fill_copy_source+1

	ldx #1 ; the sample numbers in the pattern data start at 1, not 0.

.next_instr
	ldy #0								; copy instrument name
-	lda (fill_copy_source),y
	sta (fill_copy_target),y
	iny
	cpy #22
	bne -

	lda parse_header_sample_pointer
	sta sample_start_addresses_lows,x
	lda parse_header_sample_pointer+1
	sta sample_start_addresses_mids,x
	lda parse_header_sample_pointer+2
	sta sample_start_addresses_highs,x

	; .Y = 22 here.
	lda #0
	sta temp_counter+2
	lda (fill_copy_source),y					; read sample length, MSB first
	sta temp_counter+1
	iny ; 23
	lda (fill_copy_source),y

	asl
	sta temp_counter						; double it:  # words to # bytes
	rol temp_counter+1
	rol temp_counter+2

	clc
	lda temp_counter
	adc parse_header_sample_pointer		; preset for next sample address
	sta parse_header_sample_pointer
	sta sample_end_addresses_lows,x		; <--- this eliminates having to look
	lda temp_counter+1						;      "forward" in the header to find
	adc parse_header_sample_pointer+1	;      next sample start address to use
	sta parse_header_sample_pointer+1	;      as this sample's end.
	sta sample_end_addresses_mids,x
	lda temp_counter+2
	adc parse_header_sample_pointer+2
	sta parse_header_sample_pointer+2
	sta sample_end_addresses_highs,x

	iny ; 24
	lda (fill_copy_source),y
	sta sample_default_fine_tunes,x

	iny ; 25
	lda (fill_copy_source),y
	sta sample_default_volume_levels,x

	iny ; 26
	lda #0
	sta temp_counter+2
	lda (fill_copy_source),y					; read loop start offset, MSB first
	sta temp_counter+1
	iny ; 27
	lda (fill_copy_source),y

	asl
	sta temp_counter						; double it:  # words to # bytes
	rol temp_counter+1
	rol temp_counter+2

	clc									; convert to address
	lda temp_counter
	adc sample_start_addresses_lows,x
	sta sample_loop_start_addresses_lows,x
	lda temp_counter+1
	adc sample_start_addresses_mids,x
	sta sample_loop_start_addresses_mids,x
	lda temp_counter+2
	adc sample_start_addresses_highs,x
	sta sample_loop_start_addresses_highs,x

	iny ; 28
	lda #0
	sta temp_counter+2
	lda (fill_copy_source),y					; read loop length, MSB first
	sta temp_counter+1
	iny ; 29
	lda (fill_copy_source),y
	sta temp_counter

	lda temp_counter+1						; if loop len > 1, flag this sample as loopable
	bne +
	lda temp_counter
	cmp #2
	bcs +

	lda sample_end_addresses_lows,x			; otherwise, we just set the "loop
	sta sample_loop_end_addresses_lows,x	; end" equal to the sample end to
	lda sample_end_addresses_mids,x			; reduce the mixer's workload.
	sta sample_loop_end_addresses_mids,x
	lda sample_end_addresses_highs,x
	sta sample_loop_end_addresses_highs,x

	lda #0
	sta sample_default_loop_flags,x
	beq ++

+	lda #$80
	sta sample_default_loop_flags,x
	asl temp_counter						; double the len:  # words to # bytes
	rol temp_counter+1
	rol temp_counter+2

	clc									; convert to address
	lda temp_counter
	adc sample_loop_start_addresses_lows,x
	sta sample_loop_end_addresses_lows,x
	lda temp_counter+1
	adc sample_loop_start_addresses_mids,x
	sta sample_loop_end_addresses_mids,x
	lda temp_counter+2
	adc sample_loop_start_addresses_highs,x
	sta sample_loop_end_addresses_highs,x

++	clc
	lda fill_copy_source
	adc #instrument_metadata_size
	sta fill_copy_source
	bcc +
	inc fill_copy_source+1

	clc
+	lda fill_copy_target
	adc #22
	sta fill_copy_target
	bcc +
	inc fill_copy_target+1

+	inx

	lda current_file_type
	cmp #1
	bne +

	cpx #16
	beq .ldex
	jmp .next_instr

+	cpx #32
	beq .ldex
	jmp .next_instr

.ldex
	clc ; exit with carry clear to indicate successful parse, okay to load
rts

zero_first_exp_pages
	lda #0
	ldx #0

-	sta load_buffer,x
	sta load_buffer+256,x
	dex
	bne -

	sta expansion_memory_target_pointer
	sta expansion_memory_target_pointer+1
	sta expansion_memory_target_pointer+2

	sta stash_size
	lda #2
	sta stash_size+1

	+JSR_INDIRECT (stash_block_vec)
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
; 76543210 76543210 7654-3210 76543210
; xxxxxxxx wwwwyyyy 0000-cccc zzzzzzzz
;
; where:
;      wwwwyyyy (8 bits) is the sample number
;      xxxxxxxx (now 8 bits) is the note number, 0 - 60 (see init.s)
; cccc-zzzzzzzz (4+8 bits) is the effect and its parameters

reformat_pattern_data
	sei
	jsr disable_roms ; the note period table is buried under the KERNAL

	lda #4			; fetch/stash size is 1 kB
	sta stash_size+1
	lda #0
	sta stash_size

	lda current_file_type
	cmp #1
	bne +

	lda #<header15_seek_to_pat_data
	sta expansion_memory_target_pointer
	lda #>header15_seek_to_pat_data
	sta expansion_memory_target_pointer+1
	bne ++

+	lda #<header31_seek_to_pat_data
	sta expansion_memory_target_pointer
	lda #>header31_seek_to_pat_data
	sta expansion_memory_target_pointer+1

++	clc
	lda expansion_memory_start_address
	adc expansion_memory_target_pointer
	sta expansion_memory_target_pointer

	lda expansion_memory_start_address+1
	adc expansion_memory_target_pointer+1
	sta expansion_memory_target_pointer+1

	lda expansion_memory_start_address+2
	adc #0
	sta expansion_memory_target_pointer+2

	lda #0
	sta pattern_conv_pat_counter
	conv_pat_loop
		+JSR_INDIRECT (fetch_block_vec)

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

				lda #<note_period_table
				sta binsearch_low
				lda #>note_period_table
				sta binsearch_low+1

				lda #<(note_period_table+118)
				sta binsearch_high
				lda #>(note_period_table+118)
				sta binsearch_high+1

				ldy #1
				lda (utility_pointer),y
				sta binsearch_value

				ldy #0
				lda (utility_pointer),y
				and #$0f
				sta binsearch_value+1
				ora binsearch_value
				beq no_bin_search

				jsr binary_search
				bcc +

				lda binsearch_mid
				bcs ++

			+	lda binsearch_low

			++	sec							; it starts out as the address of the period word
				sbc #<note_period_table		; make it into a byte offset
				lsr
				clc							; divide by 2 and add 1 and now it's
				adc #1						; a note number 1-60.

			no_bin_search
				sta temp_abs_a

				ldy #0
				lda (utility_pointer),y
				and #$f0
				sta temp_abs_b

				ldy #2
				lda (utility_pointer),y
				lsr
				lsr
				lsr
				lsr
				ora temp_abs_b
				ldy #1
				sta (utility_pointer),y

				ldy #2
				lda (utility_pointer),y
				and #$0f
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

	+	+JSR_INDIRECT (stash_block_vec)

		clc
		lda expansion_memory_target_pointer+1
		adc #4
		sta expansion_memory_target_pointer+1
		bcc +
		inc expansion_memory_target_pointer+2

	+	inc pattern_conv_pat_counter
		lda pattern_conv_pat_counter
		cmp number_of_patterns
	beq +
	jmp conv_pat_loop
  +

	jsr enable_kernal_only
	cli
rts


!ct raw {
	mod_magic_numbers ; type 1 is Soundtracker
		!text "M.K." ; file type 2 \___ Protracker
		!text "M!K!" ;             /
		!text "FLT4" ; file type 4 \___ StarTrekker
		!text "FLT8" ;             /
		!text "4CHN" ; file type 6 ¯|
		!text "6CHN" ;              |-- FastTracker
		!text "8CHN" ; file type 8 _|
		!byte 0
}
