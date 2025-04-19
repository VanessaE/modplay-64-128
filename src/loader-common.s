; This loads a file into the expansion RAM
; enter with carry set to use the filename in the string buffer
; and if it's set, .Y must be the string length

!text "loader-exp",0

load_file_to_expansion
	!ifndef c128 {
		size_text = 9
		progbar_row			= 13
		progbar_column		= 12
		progbar_len			= 16*8
		kbs_row				= 15
		kbs_column			= 15
	} else {
		size_text = 12
		progbar_row			= 13
		progbar_column		= 27
		progbar_len			= 26*8
		kbs_row				= 15
		kbs_column			= 35

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
	sec
	jsr calc_filename_address
	stx expansion_memory_target_pointer
	sty expansion_memory_target_pointer+1
	lda #0
	sta expansion_memory_target_pointer+2

	sta stash_size+1
	lda #16
	sta stash_size

	lda #<string_buffer
	sta expansion_transfer_local_addr
	lda #>string_buffer
	sta expansion_transfer_local_addr+1


	+JSR_INDIRECT (fetch_block_vec)

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
-	lda string_buffer,y
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

	jsr loader_populate_mini_popup

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

	lda file_to_load_name_len
	ldx #<string_buffer
	ldy #>string_buffer+1
	jsr open_file

	bcc +
	jmp load_err

+	lda #<load_buffer
	sta expansion_transfer_local_addr
	lda #>load_buffer
	sta expansion_transfer_local_addr+1

	lda #0
	sta expansion_transfer_local_addr+2
	sta expansion_memory_target_pointer
	sta expansion_memory_target_pointer+2

	jsr set_first_exp_pages_to_silence	; note: this trashes the target pointer and stash size.

	; actual file go to start + exp_load_offset_pages*256

	clc
	lda expansion_memory_start_page
	adc exp_load_offset_pages
	sta expansion_memory_target_pointer+1

	lda #0
	sta stash_size
	lda #4
	sta stash_size+1

	lda CIA1_CRB	; ensure that the next few STA's reset the TOD clock
	and #$7f
	sta CIA1_CRB

	lda #0
	sta CIA1_TOD_HOURS
	sta CIA1_TOD_MINUTES
	sta CIA1_TOD_SECONDS
	sta CIA1_TOD_TENTHS

; read-in the header

	jsr load_mod_header		; returns .N = 0 on error or if header is bad
							; or .C = 0 for 15 samples, .C = 1 for 31
	lda #0
	ror
	sta temp_carry

	lda #4
	sta stash_size+1

	bit header_loaded
	bmi +

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

	jmp abort_load

+	lda highest_exp_addresss_used+2
	cmp reu_highest_bank
	bcc +

	jsr close_file

	jsr draw_mini_popup

	lda #0
	ldx #<file_too_large_msg
	ldy #>file_too_large_msg
	jsr print_msg

	jmp abort_load

+	jsr loader_add_progress_bar

	bit temp_carry
	bpl loaded_15

; okay, at this point we can go ahead and load the rest of the file.

load_next_pattern
	jsr loader_get_1kb
	jsr loader_update_progress

loaded_15
	jsr reformat_pattern_data

	+JSR_INDIRECT (stash_block_vec)

	clc
	lda expansion_memory_target_pointer+1
	adc #4
	sta expansion_memory_target_pointer+1
	bcc +
	inc expansion_memory_target_pointer+2

+	inc pattern_conv_pat_counter
	lda pattern_conv_pat_counter
	cmp number_of_patterns
	bcc load_next_pattern

	lda #1
	sta stash_size+1

	lda #0
	sta sample_number_count

load_next_sample
	inc sample_number_count
	ldy sample_number_count

	lda sample_lengths_lows,y			; if the length is 0, it's an empty
	ora sample_lengths_mids,y			; sample slot (duh 🙂)
	ora sample_lengths_highs,y
	bne +
	jsr loader_get_1_byte				; skip two bytes of the file if the
	jsr loader_get_1_byte				; sample is empty (mods always have this) 
	jmp load_next_sample

+	lda sample_start_addresses_mids,y
	sta expansion_memory_target_pointer+1
	lda sample_start_addresses_highs,y
	sta expansion_memory_target_pointer+2

	lda sample_lengths_lows,y			; okay, so it isn't empty 🙂
	sta utility_counter					; use the specified length
	lda sample_lengths_mids,y
	sta utility_counter+1
	lda sample_lengths_highs,y
	sta utility_counter+2

	ora sample_lengths_mids,y			; if the top two bytes of len are 0,
	beq load_rest_of_sample				; the sample is less than one page, so
										; just use the load-remainder routine

load_next_sample_block
	jsr loader_get_1_block

	ldy #0
-	lda load_buffer,y
	clc
	adc #$80							; translate signed -> unsigned
	sta load_buffer,y
	iny
	bne -

	+JSR_INDIRECT (stash_block_vec)

	inc expansion_memory_target_pointer+1
	bne +
	inc expansion_memory_target_pointer+2

+	lda expansion_memory_target_pointer+1
	and #$03
	bne +
	jsr loader_update_progress

+	lda STATUS
	bne .done

	sec
	lda utility_counter+1
	sbc #1
	sta utility_counter+1
	bcs +
	dec utility_counter+2

+	ora utility_counter+2				; are there less than 256 bytes left?
	bne load_next_sample_block			; if not, keep loading...

	lda utility_counter					; is the remainder just 0?  (e.g. sample
	beq loader_check_for_more_samples	; is a multiple of 256 bytes)

load_rest_of_sample						; if neither, load the exact number of remaining bytes
	ldy #0
-	jsr loader_get_1_byte
	clc
	adc #$80							; translate signed -> unsigned
	sta load_buffer,y
	iny
	cpy utility_counter
	bne -

	lda #$80							; clear rest of load buf page
-	sta load_buffer,y
	iny
	bne -

	+JSR_INDIRECT (stash_block_vec)		; store the result

	inc expansion_memory_target_pointer+1
	bne +
	inc expansion_memory_target_pointer+2

+	lda #$80							; create an entirely blank page
	ldy #0
-	sta load_buffer,y
	iny
	bne -

	+JSR_INDIRECT (stash_block_vec)		; and tack it onto the end of the sample

	lda STATUS
	bne .done

loader_check_for_more_samples
	ldy num_samples_to_load
	dey
	cpy sample_number_count
	bcc .done
	jmp load_next_sample

.done
	jsr close_file
	lda file_size_in_kb
	sta current_file_size_in_kb
	lda file_size_in_kb+1
	sta current_file_size_in_kb+1

	ldy #0
-	lda string_buffer,y
	sta current_file_name,y
	beq acptr_exit
	iny
	cpy #16
	bne -

acptr_exit
rts

abort_load
	lda #0
	sta current_file_type
	jsr press_any_key
rts

loader_populate_mini_popup
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
rts

loader_add_progress_bar

; rather than use the file size, we use the end addr of the last sample, as
; we're using the exp load pointer as the progress reference, and that address
; will more or less represent the actual RAM usage anyway (since the start of
; exp RAM won't be very large anyway)

	lda highest_exp_addresss_used
	sta dividend
	lda highest_exp_addresss_used+1
	sta dividend+1
	lda highest_exp_addresss_used+2
	sta dividend+2

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

loader_update_progress
	jsr loader_print_loading_speed

	sec
	lda #0
	sta dividend
	lda expansion_memory_target_pointer+1
	sbc expansion_memory_start_page
	sta dividend+1
	lda expansion_memory_target_pointer+2
	sbc expansion_memory_start_bank
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

loader_print_loading_speed
	bit CIA1_TOD_HOURS; read hours to latch the time

	lda CIA1_TOD_MINUTES ; minutes
	lsr
	lsr
	lsr
	lsr
	tax
	lda nybble_x10,x ; CIA's TOD clock is expressed in BCD.
	sta temp_abs_a
	lda CIA1_TOD_MINUTES
	and #$0f
	clc
	adc temp_abs_a
	ldx #60
	jsr multiply_8x8

	lda CIA1_TOD_SECONDS ; seconds
	lsr
	lsr
	lsr
	lsr
	tax
	lda nybble_x10,x
	sta temp_abs_a
	lda CIA1_TOD_SECONDS
	and #$0f
	clc
	adc temp_abs_a

	ldx CIA1_TOD_TENTHS; read tenths to un-latch the time

	adc product
	sta divisor
	lda #0
	sta divisor+2
	adc product+1
	sta divisor+1

	; only print the loading speed every couple of seconds

	lda divisor
	cmp last_seconds_lsb
	bne +
	rts

+	and #$01
	bne +
	rts

+	lda divisor
	sta last_seconds_lsb
	sec
	lda #0
	sta dividend
	lda expansion_memory_target_pointer+1
	sbc expansion_memory_start_page
	sta dividend+1
	lda expansion_memory_target_pointer+2
	sbc expansion_memory_start_bank
	sta dividend+2

	jsr divide_24by24

	lsr quotient+2
	ror quotient+1
	ror quotient
	lsr quotient+2
	ror quotient+1
	ror quotient

	clc
	ldx #kbs_row
	ldy #kbs_column
	jsr PLOT

	lda #0
	ldx #<loader_erase_kbs_msg
	ldy #>loader_erase_kbs_msg
	jsr print_msg

	ldx quotient+1
	ldy quotient+2
	sec
	jsr print_uint16

	lda #"."
	jsr CHROUT

	sec
	lda quotient
	lsr
	lsr
	lsr
	lsr
	tay
	ldx kbs_fract_approx,y
	ldy #0
	sec
	jsr print_uint16

	lda #0
	ldx #<loader_kbs_msg
	ldy #>loader_kbs_msg
	jsr print_msg
rts

set_first_exp_pages_to_silence
	lda #2
	sta stash_size+1
	lda #0
	sta stash_size

	lda #$80
	ldx #0
-	sta load_buffer,x
	sta load_buffer+256,x
	dex
	bne -

	lda expansion_memory_start_page
	sta expansion_memory_target_pointer+1
	lda expansion_memory_start_bank
	sta expansion_memory_target_pointer+2

	+JSR_INDIRECT (stash_block_vec)
rts

load_err
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

; obviously this bit of indirection costs a few cycles but it'll be needed
; later when multiple loaders are available.

loader_get_1_byte
	jsr ACPTR
rts

loader_get_1_block
	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

loader_get_1_block_no_reset_ptr
	ldy #0

-	jsr loader_get_1_byte
	sta (load_pointer),y
	iny
	bne -
rts

loader_get_1kb
	jsr loader_get_1_block
	inc load_pointer+1
	jsr loader_get_1_block_no_reset_ptr
	inc load_pointer+1
	jsr loader_get_1_block_no_reset_ptr
	inc load_pointer+1
	jsr loader_get_1_block_no_reset_ptr
rts

kbs_fract_approx
	!byte 0,0,1,1,2,3,3,4,5,5,6,6,7,8,8,9

last_seconds_lsb
	!byte 0

sample_number_count
	!byte 0
