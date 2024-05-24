; This loads a file into the expansion RAM
; enter with carry set to use the filename in the string buffer
; and if it's set, .Y must be the string length

header15_seek_to_pt				= 20+15*(22+2+1+1+2+2)+1+1 ; (472)
header31_seek_to_pt				= 20+31*(22+2+1+1+2+2)+1+1 ; (952)
header_first_inst_meta_offset	= 20
instrument_metadata_size		= 22+2+1+1+2+2 ; (30)

load_file_to_expansion
	lda #0
	sta header_loaded

	!ifndef c128 {
		size_text = 9
		progress_bar_row		= 13
		progress_bar_column		= 11
	} else {
		size_text = 12
		progress_bar_row		= 4
		progress_bar_column		= 5

		php
		jsr set_window_full_screen
		plp
		old_vec = $f66e				; original STOP vector

		progbar_pos      = VDC_SCREEN     + 14*80 + 32
		progbar_attr_pos = VDC_ATTRIBUTES + 14*80 + 32
	}

	bcc load_from_playlist

	sty file_to_load_name_len
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

	jsr populate_mini_popup_loader

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

; open the file so we can grab the first two bytes,
; because the KERNAL will discard them

	lda #0
	sta stash_pointer
	sta stash_pointer+1 ; start at $000000 in expansion RAM
	sta stash_pointer+2

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

	+
	!ifdef c128 {

		; On the C128, we can use the "STOP wedge" trick to cause the KERNAL
		; LOAD routine to do more of the work, enabling BURST mode on
		; on 1571, 1581, and newer devices.  A 1571 can do 3.6 kB/sec with a
		; disk sector interleave of 5.  We use a load buffer of exactly 5 disk
		; blocks (so 1270/$04f6 bytes) to ensure FAST and BURST load the same
		; amount and that the file header can be loaded all in one go.

		jsr CHRIN			; read the first two bytes from the open file
		sta load_buffer		; and close it
		jsr CHRIN
		sta load_buffer+1

		jsr close_file

		lda #<fill_load_buffer
		sta STOP_vec
		lda #>fill_load_buffer
		sta STOP_vec+1

		lda file_to_load_name_len
		ldx #<string_buffer
		ldy #>string_buffer+1
		jsr SETNAM

		lda #0
		ldx #0
		jsr SETBNK

		lda #0
		ldx load_device
		ldy #0
		jsr SETLFS

		lda #0
		ldx #2					; start loading at load_buffer + 2
		ldy #>load_buffer
		jsr LOAD

		jsr RESTOR

		+JSR_INDIRECT (stash_block_vec) ; don't forget to stash the last-loaded block

		lda file_size_in_kb
		sta current_file_size_in_kb
		lda file_size_in_kb+1
		sta current_file_size_in_kb+1

		ldy #0
	-	lda string_buffer,y
		sta current_file_name,y
		beq +
		iny
		cpy #16
		bne -
	rts

	fill_load_buffer				; STOP vector enters here after a byte is loaded

		lda EAL+1
		cmp #>load_buffer_end		; load buffer full?
		bne .not_full

; if the load comes from a BURST-capable drive, then it won't ever be exactly
; the size of the load buffer, but instead anything up to 6*254 bytes, so
; derive the actual byte count from EAL, and use THAT to push the expansion
; RAM pointer and stash size.

		sec
		lda EAL
		sbc #<load_buffer
		sta stash_size
		lda EAL+1 
		sbc #>load_buffer
		sta stash_size+1

		+JSR_INDIRECT (stash_block_vec)
		bit header_loaded
		bmi +
		lda #$80
		sta header_loaded
		jsr decode_header
		bcs abort_load

	+	clc
		lda stash_pointer
		adc stash_size
		sta stash_pointer
		lda stash_pointer+1
		adc stash_size+1
		sta stash_pointer+1
		bcc +
		inc stash_pointer+2

	+	lda #0
		sta EAL
		lda #>load_buffer
		sta EAL+1

		jsr update_progress
	.not_full
		jmp old_vec

	} else {

	; On C64, some fast loaders ignore the STOP vector, making the above "STOP
	; wedge" trick unusable, so we go with the regular method, using OPEN and
	; ACPTR and 1280-byte (5-page) buffer. A 1541 with JiffyDOS loads at
	; around 2kB/s this way.

	; the file is already open, so just use it.

		lda #0
		sta stash_size
		lda #5
		sta stash_size+1

	.next_block
		lda #0
		sta load_pointer
		lda #>load_buffer
		sta load_pointer+1
		ldy #0

	-	lda STATUS
		bne .done

		jsr ACPTR
		sta (load_pointer),y
		iny
		bne -
		inc load_pointer+1
		lda load_pointer+1
		cmp #>load_buffer_end		; load buffer full?
		bne -

		+JSR_INDIRECT (stash_block_vec)

		bit header_loaded
		bmi +
		lda #$80
		sta header_loaded
		jsr decode_header
		bcs abort_load

	+	clc
		lda stash_pointer+1
		adc stash_size+1
		sta stash_pointer+1
		bcc +
		inc stash_pointer+2

	+	jsr update_progress
		jmp .next_block

	.done
		jsr close_file
		+JSR_INDIRECT (stash_block_vec) ; last-loaded block

		lda file_size_in_kb
		sta current_file_size_in_kb
		lda file_size_in_kb+1
		sta current_file_size_in_kb+1

		ldy #0
	-	lda string_buffer,y
		sta current_file_name,y
		beq +
		iny
		cpy #16
		bne -
	rts
	}

abort_load
	jsr close_file
	jsr draw_mini_popup
	lda #0
	ldx #<unknown_file_msg
	ldy #>unknown_file_msg
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
	lda #RIGHT
	jsr CHROUT
	jsr CHROUT
	jsr press_any_key
rts

populate_mini_popup_loader
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
	sty tempzp_c

	ldx file_size_in_kb
	ldy file_size_in_kb+1
	jsr get_num_length
	sty tempzp_e

	sec
	lda #mini_popup_width
	sbc tempzp_c			; length of the blocks figure
	sbc tempzp_e			; length of the kB figure
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
		lda #RETURN
		jsr CHROUT
	}

	lda #0
	ldx #<progress_bar_frame
	ldy #>progress_bar_frame
	jsr print_msg_rle

	lda #LGRN
	jsr CHROUT

	!ifdef c128 {
		+VDC_BLOCK_FILL progbar_attr_pos, 15, 5 ; (light green, ASCII charset)
	}
rts

update_progress
	clc
	ldx #progress_bar_row+1
	ldy #progress_bar_column+1
	jsr PLOT

	lda #0				; divided loaded bytes by bytes per segment
	sta dividend
	lda stash_pointer+1
	sta dividend+1
	lda stash_pointer+2
	sta dividend+2
	jsr divide_24by24	; now we have the number of segments to draw

	lda quotient		; to turn that into the character count, divide by 4
	lsr
	lsr
	!ifdef c128 {		; or divide by 8 on the C128
		lsr
	}
	tay
	iny				; bump up by 1 since it has to be decremented right away

	!ifndef c128 {	; on the C64,
		lda #RVSON	; we use the regular CHROUT routine to "print" the progbar
		jsr CHROUT
		lda #" "
	-	dey
		beq +
		jsr CHROUT
		jmp -

	+	lda quotient	; segment count

		and #$03	; we just need the two lowest bits: which segment to draw
		asl			; double it to get an index into the strings below
		tay
		lda progress_bar_segments,y
		jsr CHROUT
		iny
		lda progress_bar_segments,y
		jsr CHROUT
		lda #RVSOFF
		jsr CHROUT
	} else {			; on the C128, we directly write VDC RAM to draw it
		lda #18
		sta VDC
		lda #>progbar_pos
		sta VDC+1
		lda #19
		sta VDC
		lda #<progbar_pos
		sta VDC+1
		lda #31
		sta VDC

		dey
		beq +		; if that ends up 0, we don't want to draw even one rvs space

		lda #159 ; solid square
	-	bit VDC
		bpl -
		sta VDC+1
		dey
		bne -

	+	lda quotient
		and #$07		; we need 3 bits since there are 8 segs per char
		tay				; and we don't need to double it since it's a write, not print
		lda progress_bar_segments,y
	-	bit VDC
		bpl -
		sta VDC+1
	}
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

; if there's a tag at all, it'll always be here (because otherwise, it's a
; 15 sample mod and has no tag at all)

magic_number_location = load_buffer + header31_seek_to_pt + 128

decode_header
	lda free_memory_start
	sta parse_header_sample_pointer
	lda free_memory_start+1
	sta parse_header_sample_pointer+1
	lda free_memory_start+2
	sta parse_header_sample_pointer+2

	ldx #19							; song title
-	lda load_buffer,x
	sta current_file_title,x
	dex
	bpl -

	lda #1							; check filetype
	sta tempzp_c
	ldy #0

--	ldx #0
	stx match_hdr

-	lda mod_magic_numbers,y
	beq filetype_unsure				; if none of the magic numbers match, try
	eor magic_number_location,x		; to identify the file another way
	ora match_hdr
	sta match_hdr

	iny
	inx
	cpx #4
	bne -

	inc tempzp_c
	lda match_hdr
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

	lda load_buffer + header15_seek_to_pt - 1	; "restart" byte
	beq +
	sec
	cmp #128
	bcs +

	ldy load_buffer + header15_seek_to_pt - 2	; number of song positions
	beq +
	cpy #129
	bcs +

	lda #0										; has pattern table  (duh :-P)
	ldy load_buffer + header15_seek_to_pt - 2
-	ora load_buffer + header15_seek_to_pt,y
	dey
	bpl -
	and #$ff ; was .A is non-zero?
	beq +

	lda #1						; if all of that is present, there is a
	sta current_file_type		; reasonable chance that it's a 15-sample mod
	lda #4
	sta current_file_tracks
	bne parse_instruments

+	sec							; if any of that is missing, consider the file
	rts							; as unknown and signal the loader to abort.

set_num_tracks
	lda tempzp_c
	sta current_file_type
	sec
	lda current_file_type
	cmp #5
	bcs +
-	lda #4						; filetypes 1-4 (no tag, "M.K.", "M!K!",
	sta current_file_tracks 	; and "FLT4") have 4 tracks
	bne parse_instruments

+	cmp #6						; so does filetype 6 ("4CHN")
	beq -

	cmp #7						; filetype 7 ("6CHN") has 6 tracks (duh :-P )
	bne +
	lda #6
	sta current_file_tracks
	bne parse_instruments

+	lda #8						; file types 5 and 8 ("FLT8" or "8CHN") are
	sta current_file_tracks		; all that's left, they have 8 tracks

parse_instruments
	lda #<(load_buffer + header_first_inst_meta_offset)
	sta tempzp_d
	lda #>(load_buffer + header_first_inst_meta_offset)
	sta tempzp_d+1

	lda #<mod_instrument_names
	sta tempzp_e
	lda #>mod_instrument_names
	sta tempzp_e+1

	ldx #0

.next_instr
	ldy #0								; copy instrument name
-	lda (tempzp_d),y
	sta (tempzp_e),y
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
	sta tempzp_f+2
	lda (tempzp_d),y					; read sample length, MSB first
	sta tempzp_f+1
	iny ; 23
	lda (tempzp_d),y

	asl
	sta tempzp_f						; double it:  # words to # bytes
	rol tempzp_f+1
	rol tempzp_f+2

	clc
	lda tempzp_f
	adc parse_header_sample_pointer		; preset for next sample address
	sta parse_header_sample_pointer
	sta sample_end_addresses_lows,x		; <--- this eliminates having to look
	lda tempzp_f+1						;      "forward" in the header to find
	adc parse_header_sample_pointer+1	;      next sample start address to use
	sta parse_header_sample_pointer+1	;      as this sample's end.
	sta sample_end_addresses_mids,x
	lda tempzp_f+2
	adc parse_header_sample_pointer+2
	sta parse_header_sample_pointer+2
	sta sample_end_addresses_highs,x

	iny ; 24
	lda (tempzp_d),y
	sta sample_default_fine_tunes,x

	iny ; 25
	lda (tempzp_d),y
	sta sample_default_volume_levels,x

	iny ; 26
	lda #0
	sta tempzp_f+2
	lda (tempzp_d),y					; read loop start offset, MSB first
	sta tempzp_f+1
	iny ; 27
	lda (tempzp_d),y

	asl
	sta tempzp_f						; double it:  # words to # bytes
	rol tempzp_f+1
	rol tempzp_f+2

	clc									; convert to address
	lda tempzp_f
	adc sample_start_addresses_lows,x
	sta sample_loop_start_addresses_lows,x
	lda tempzp_f+1
	adc sample_start_addresses_mids,x
	sta sample_loop_start_addresses_mids,x
	lda tempzp_f+2
	adc sample_start_addresses_highs,x
	sta sample_loop_start_addresses_highs,x

	iny ; 28
	lda #0
	sta tempzp_f+2
	lda (tempzp_d),y					; read loop length, MSB first
	sta tempzp_f+1
	iny ; 29
	lda (tempzp_d),y
	sta tempzp_f

	lda tempzp_f+1						; if loop len > 1, flag this sample as loopable
	bne +
	sec
	lda tempzp_f
	cmp #2
	bcs +

	lda #0
	beq ++

+	lda #$80
++	sta track_loop_flags,x
	asl tempzp_f						; double it:  # words to # bytes
	sta tempzp_f
	rol tempzp_f+1
	rol tempzp_f+2

	clc									; convert to address
	lda tempzp_f
	adc sample_loop_start_addresses_lows,x
	sta sample_loop_end_addresses_lows,x
	lda tempzp_f+1
	adc sample_loop_start_addresses_mids,x
	sta sample_loop_end_addresses_mids,x
	lda tempzp_f+2
	adc sample_loop_start_addresses_highs,x
	sta sample_loop_end_addresses_highs,x

	clc
	lda tempzp_d
	adc #instrument_metadata_size
	sta tempzp_d
	bcc +
	inc tempzp_d+1

	clc
+	lda tempzp_e
	adc #22
	sta tempzp_e
	bcc +
	inc tempzp_e+1

+	inx

	lda current_file_type
	cmp #1
	bne +

	cpx #15
	beq .phd
	jmp .next_instr

+	cpx #31
	beq .phd
	jmp .next_instr

.phd		; tempzp_d is now pointing at the # of song positions byte
	ldy #0
	lda (tempzp_d),y
	sta number_of_song_positions

; get pattern table
	ldy #127
	lda current_file_type
	cmp #1
	bne +

-	lda load_buffer + header15_seek_to_pt,y
	sta pattern_table,y
	dey
	bpl -
	bmi count_patterns

+
-	lda load_buffer + header31_seek_to_pt,y
	sta pattern_table,y
	dey
	bpl -

count_patterns
	ldy #0
	sty number_of_patterns

-	sec
	lda pattern_table,y
	cmp number_of_patterns
	beq +
	bcc +
	sta number_of_patterns

+	iny
	cpy number_of_song_positions
	bne -
	inc number_of_patterns

	clc ; exit with carry clear to indicate successful parse, okay to load
rts

progress_bar_segments
!ifndef c128 {
	!byte RVSOFF," "
	!byte RVSOFF,$b4
	!byte RVSOFF,$a1
	!byte $aa,0
} else {
	!byte 32, 152,153,154,155,156,157,158
}

stash_size		!byte 0,0

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

match_hdr		!byte 0
