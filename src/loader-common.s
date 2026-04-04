; This loads a file into the expansion RAM
; enter with carry set to use the filename in the string buffer
; and if it's set, .Y must be the string length

load_file_to_expansion
	!ifndef c128 {
		size_text = 9
		progbar_row			= 13
		progbar_column		= 12
		progbar_len			= 16
		kbs_row				= 15
		kbs_column			= 15
	} else {
		size_text = 12
		progbar_row			= 13
		progbar_column		= 27
		progbar_len			= 26
		kbs_row				= 15
		kbs_column			= 35

		php
		jsr FULLW
		plp
	}

	lda #0
	sta loaded_bytes_count
	sta loaded_bytes_count+1
	sta loaded_bytes_count+2

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

	; the actual loading process starts here.

	jsr loader_paint_screen
	jsr can_load_dev_use_uci

	clc
	lda file_to_load_name_len
	ldx #<string_buffer
	ldy #>string_buffer+1

	bit load_device_can_use_uci
	bmi +
	jsr open_file
	jmp ++
+	jsr uci_open_file

++	bcc +
	jmp print_generic_load_error

+	lda #<load_buffer
	sta expansion_transfer_local_addr
	lda #>load_buffer
	sta expansion_transfer_local_addr+1

	lda #0
	sta expansion_transfer_local_addr+2
	sta expansion_memory_target_pointer
	sta expansion_memory_target_pointer+2

	jsr set_first_exp_pages_to_silence	; note: this trashes the target pointer and stash size.

	; actual file go to start + exp_file_data_start_page*256

	lda exp_file_data_start_page
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

; Header loader returns .N = 0 on error or if header is bad
; or returns .C = 0 for 15 samples, .C = 1 for 31

	jsr load_mod_header

	lda #4
	sta stash_size+1

	bit header_loaded
	bmi header_is_okay

	bit load_device_can_use_uci
	bmi +
	jsr close_file
	jmp ++
+	jsr uci_close_file

++	!ifndef c128 {
		ldy #mini_popup_left_column+4
	} else {
		ldy #mini_popup_left_column+31
	}

	ldx #mini_popup_top_row+4
	clc
	jsr PLOT

	lda #0
	ldx #<unknown_file_msg
	ldy #>unknown_file_msg
	sec
	jsr print_msg

	!ifndef c128 {
		ldy #mini_popup_left_column+3
	} else {
		ldy #mini_popup_left_column+33
	}

	ldx #mini_popup_top_row+6
	clc
	jsr PLOT

	jmp abort_load

header_is_okay
	lda highest_exp_addresss_used+2
	cmp reu_highest_bank
	bcc file_size_okay

	bit load_device_can_use_uci
	bmi +
	jsr close_file
	jmp ++
+	jsr uci_close_file

++	jsr draw_mini_popup

	lda #0
	ldx #<file_too_large_msg
	ldy #>file_too_large_msg
	sec
	jsr print_msg

	jmp abort_load

	; okay, at this point we can go ahead and load the rest of the file.

file_size_okay
	jsr loader_add_progress_bar
	jsr load_pattern_data
	jsr load_sample_data

	jsr unroll_mod_sample_loops
rts

abort_load
	lda #0
	sta current_file_type
	jsr press_any_key
rts

load_mod_header ; and also the first pattern if it's a 15-sample mod
	lda #0
	sta utility_counter
	sta utility_counter+1
	sta utility_counter+2

	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

	ldy #0
	sty header_loaded

-	jsr loader_get_one_byte
	sta (load_pointer),y
	inc load_pointer
	bne +
	inc load_pointer+1

+	inc utility_counter
	bne +
	inc utility_counter+1

+	lda utility_counter
	cmp #<header31_seek_to_pat_data
	lda utility_counter+1
	sbc #>header31_seek_to_pat_data
	bcc -

	lda #<header31_seek_to_pat_data
	sta loaded_bytes_count
	lda #>header31_seek_to_pat_data
	sta loaded_bytes_count+1
	lda #0
	sta loaded_bytes_count+2

	jsr decode_mod_header
	bcc +
	rts

+	lda #0
	sta pattern_conv_pat_counter
	lda current_file_type
	cmp #2
	sec
	beq .loaded_31			; if it's a 31-sample mod, then we're right at the
							; first byte of the first pattern.  otherwise, some
							; of the first pattern is loaded, so get the rest.
	lda #0
	sta utility_counter
	sta utility_counter+1

	ldy #0
-	jsr loader_get_one_byte
	sta (load_pointer),y
	inc load_pointer
	bne +
	inc load_pointer+1

+	inc utility_counter
	bne +
	inc utility_counter+1

+	lda utility_counter		; we got all but 540 bytes initially.
	cmp #<540
	lda utility_counter+1
	sbc #>540
	bcc -

	clc
	lda loaded_bytes_count
	adc #<540
	sta loaded_bytes_count
	lda loaded_bytes_count+1
	adc #>540
	sta loaded_bytes_count+1
	bcc +
	inc loaded_bytes_count+2

	; now that the header is no longer needed and the first pattern has been
	; loaded, move it down to the bottom of the load buffer

+	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

	lda #<(load_buffer+header15_seek_to_pat_data)
	sta utility_pointer_b
	lda #>(load_buffer+header15_seek_to_pat_data)
	sta utility_pointer_b+1

	ldy #0
-	lda (utility_pointer_b),y
	sta (load_pointer),y
	iny
	bne -
	inc utility_pointer_b+1
	inc load_pointer+1
	lda load_pointer+1
	cmp #>(load_buffer+$0400)
	bne -
	clc
.loaded_31
	lda #$80
	sta header_loaded
rts


load_pattern_data
	lda num_samples_to_load ; if the file has 15 samples, the header loader
	cmp #15					; will have fetched the first pattern already.
	beq .is_15

.load_next_patt

	bit load_device_can_use_uci
	bmi +
	jsr loader_standard_get_1kb
	jmp ++
+	jsr loader_uci_get_1kb

++	jsr loader_update_progress

.is_15
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
	bcc .load_next_patt
rts


load_sample_data
	lda #1
	sta stash_size+1

	lda #0
	sta sample_number_count

.load_next_sample
	inc sample_number_count
	ldy sample_number_count

	lda sample_lengths_lows,y			; if the length is 0, it's an empty
	ora sample_lengths_mids,y			; sample slot (duh 🙂)
	ora sample_lengths_highs,y
	bne ++
	jsr loader_get_one_byte				; skip two bytes of the file if the
	jsr loader_get_one_byte				; sample is empty (mods always have this)

	clc
	lda loaded_bytes_count
	adc #2
	sta loaded_bytes_count
	bcc +
	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2

+	jmp .load_next_sample

++	lda sample_start_addresses_mids,y
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
	beq .load_rest_of_sample			; the sample is less than one page, so
										; just use the load-remainder routine

.load_next_sample_block
	bit load_device_can_use_uci
	bmi +
	jsr loader_standard_get_block
	jmp ++
+	jsr loader_uci_get_block

++	ldy #0
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
	beq +
	jmp .ldr_done

+	sec
	lda utility_counter+1
	sbc #1
	sta utility_counter+1
	bcs +
	dec utility_counter+2

+	ora utility_counter+2				; are there less than 256 bytes left?
	bne .load_next_sample_block			; if not, keep loading...

	lda utility_counter					; is the remainder just 0?  (e.g. sample
	beq .chk_more_samples				; is a multiple of 256 bytes)

.load_rest_of_sample					; if neither, load the exact number of remaining bytes
	ldy #0
-	jsr loader_get_one_byte
	clc
	adc #$80							; translate signed -> unsigned
	sta load_buffer,y
	iny
	cpy utility_counter
	bne -

	clc
	tya
	adc loaded_bytes_count
	sta loaded_bytes_count
	bcc +
	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2

+	lda #$80							; clear rest of load buf page
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
	bne .ldr_done

.chk_more_samples
	ldy num_samples_to_load
	dey
	cpy sample_number_count
	bcc .ldr_done
	jmp .load_next_sample

.ldr_done
	jsr close_file
	lda file_size_in_kb
	sta current_file_size_in_kb
	lda file_size_in_kb+1
	sta current_file_size_in_kb+1

	ldy #0
-	lda string_buffer,y
	sta current_file_name,y
	beq .ldr_exit
	iny
	cpy #16
	bne -
  .ldr_exit
rts

loader_paint_screen
	lda #CLR
	jsr CHROUT

	!ifdef c128 {
		bit c128_vdc_has_64k
		bmi +
		jsr vdc_retrieve_loader_bg_from_reu
		jmp ++

	+	jsr vdc_copy_loader_bg_from_cache

		++
	} else {
		jsr vic_retrieve_loader_bg_from_reu
	}

	!ifndef c128 {
		lda #0
		ldx #<mini_popup_top_line
		ldy #>mini_popup_top_line
		sec
		jsr print_msg_rle

		lda #0
		ldx #<mini_popup_next_line
		ldy #>mini_popup_next_line
		jsr print_msg_rle
	} else {
		jsr set_window_mini_popup
		clc
		ldx #0
		ldy #0
		jsr PLOT
	}

	lda #0
	sta string_buffer+16

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
	sec
	jsr print_msg

	lda #$22 ; quote
	jsr CHROUT

	!ifndef c128 {
		lda #0
		ldx #<mini_popup_next_line
		ldy #>mini_popup_next_line
		sec
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
	sec
	jsr print_msg

	sec
	ldx file_size_in_kb
	ldy file_size_in_kb+1
	jsr print_uint16

	lda #0
	ldx #<kb_msg
	ldy #>kb_msg
	sec
	jsr print_msg

	!ifndef c128 {
		lda #0
		ldx #<mini_popup_next_line
		ldy #>mini_popup_next_line
		sec
		jsr print_msg_rle
	} else {
		lda #RETURN
		jsr CHROUT
	}

	lda #0
	ldx #<loading_msg
	ldy #>loading_msg
	sec
	jsr print_msg

	!ifndef c128 {
		lda #0
		ldx #<mini_popup_next_line
		ldy #>mini_popup_next_line
		sec
		jsr print_msg_rle
	} else {
		jsr FULLW
	}
rts

loader_add_progress_bar

	; file size is in blocks, so displace by 1 byte in dividend to get bytes-to-load

	lda #0
	sta dividend
	lda file_to_load_size
	sta dividend+1
	lda file_to_load_size+1
	sta dividend+2

	; divide the size by the number of progress bar segments

	lda #(progbar_len * 8)
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

	lda #(progbar_len * 8)
	ldx #progbar_column
	ldy #progbar_row
	jsr draw_empty_progress_bar
rts

loader_update_progress
	jsr loader_print_loading_speed

	lda loaded_bytes_count
	sta dividend
	lda loaded_bytes_count+1
	sta dividend+1
	lda loaded_bytes_count+2
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
	; (every second if it's the UCI loader just cuz it's so fast)

	lda divisor
	bne +
	rts
+	cmp last_seconds_lsb
	bne +
	rts

+	bit load_device_can_use_uci
	bmi +
	and #$01
	bne +
	rts

+	lda divisor
	sta last_seconds_lsb

	lda loaded_bytes_count
	sta dividend
	lda loaded_bytes_count+1
	sta dividend+1
	lda loaded_bytes_count+2
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
	sec
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
	sec
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

	; the silence zone is always at the start of the exp RAM
	lda expansion_memory_start_page
	sta expansion_memory_target_pointer+1
	lda #0
	sta expansion_memory_target_pointer+2

	+JSR_INDIRECT (stash_block_vec)
rts

unroll_mod_sample_loops
	ldy #15

	lda current_file_type
	cmp #1
	beq unroll_one_loop
	ldy #31

unroll_one_loop
	; is there a loop at all?
	lda sample_default_loop_flags,y
	bmi +
	jmp unroll_next

	; is its len > 2kB?

+	sec
	lda sample_loop_end_addresses_lows,y
	sbc sample_loop_start_addresses_lows,y
	sta utility_pointer_b
	sta stash_size
	lda sample_loop_end_addresses_mids,y
	sbc sample_loop_start_addresses_mids,y
	sta utility_pointer_b+1
	sta stash_size+1
	lda sample_loop_end_addresses_highs,y
	sbc sample_loop_start_addresses_highs,y
	sta utility_pointer_b+2

	lda utility_pointer_b
	cmp #0
	lda utility_pointer_b+1
	sbc #8
	lda utility_pointer_b+2
	sbc #0
	bcc +

	; if so, just copy its end addr to the sample end addr and bail out

	lda sample_loop_end_addresses_lows,y
	sta sample_end_addresses_lows,y
	lda sample_loop_end_addresses_mids,y
	sta sample_end_addresses_mids,y
	lda sample_loop_end_addresses_highs,y
	sta sample_end_addresses_highs,y
	jmp unroll_next

	; otherwise, fetch the loop data into the load buf
	; the loop length becomes the stash/fetch size

+	lda #<load_buffer
	sta expansion_transfer_local_addr
	lda #>load_buffer
	sta expansion_transfer_local_addr+1

	lda sample_loop_start_addresses_lows,y
	sta expansion_memory_target_pointer
	lda sample_loop_start_addresses_mids,y
	sta expansion_memory_target_pointer+1
	lda sample_loop_start_addresses_highs,y
	sta expansion_memory_target_pointer+2

	+JSR_INDIRECT (fetch_block_vec)

	; calculate the endpoint of the unroll reserve area,
	; same as in decode-mod.s -- first add the loop length

	clc
	lda sample_loop_end_addresses_lows,y
	adc stash_size
	sta utility_pointer_b
	lda sample_loop_end_addresses_mids,y
	adc stash_size+1
	sta utility_pointer_b+1
	lda sample_loop_end_addresses_highs,y
	adc #0
	sta utility_pointer_b+2

	; ..then add 2kB

	; clc implied
	lda utility_pointer_b+1
	adc #8
	sta utility_pointer_b+1
	bcc store_first_copy
	inc utility_pointer_b+2

	; store the first new copy of the loop data right at the end of the
	; existing data, overwriting any trailing sample data (since it'll be
	; ignored anyway)

store_first_copy
	lda sample_loop_end_addresses_lows,y
	sta expansion_memory_target_pointer
	lda sample_loop_end_addresses_mids,y
	sta expansion_memory_target_pointer+1
	lda sample_loop_end_addresses_highs,y
	sta expansion_memory_target_pointer+2

unroll_more
	+JSR_INDIRECT (stash_block_vec)

	clc
	lda expansion_memory_target_pointer
	adc stash_size
	sta expansion_memory_target_pointer
	sta sample_loop_end_addresses_lows,y
	sta sample_end_addresses_lows,y
	lda expansion_memory_target_pointer+1
	adc stash_size+1
	sta expansion_memory_target_pointer+1
	sta sample_loop_end_addresses_mids,y
	sta sample_end_addresses_mids,y
	lda expansion_memory_target_pointer+2
	adc #0
	sta expansion_memory_target_pointer+2
	sta sample_loop_end_addresses_highs,y
	sta sample_end_addresses_highs,y

	; is there more room in the reserved space for this loop?

	; clc implied
	lda expansion_memory_target_pointer
	adc stash_size
	sta utility_pointer_c
	lda expansion_memory_target_pointer+1
	adc stash_size+1
	sta utility_pointer_c+1
	lda expansion_memory_target_pointer+2
	adc #0
	sta utility_pointer_c+2

	lda utility_pointer_c
	cmp utility_pointer_b
	lda utility_pointer_c+1
	sbc utility_pointer_b+1
	lda utility_pointer_c+2
	sbc utility_pointer_b+2
	bcc unroll_more

	; Fill the load buffer with silence

	ldx #0
	lda #$80
-	sta load_buffer,x
	sta load_buffer+$0100,x
	sta load_buffer+$0200,x
	sta load_buffer+$0300,x
	sta load_buffer+$0400,x
	sta load_buffer+$0500,x
	sta load_buffer+$0600,x
	sta load_buffer+$0700,x
	dex
	bne -

	; use that to fill the remaining space

	; expansion_memory_target_pointer already points to the target addr

	sec
	lda #0
	sbc expansion_memory_target_pointer
	sta stash_size
	lda sample_start_addresses_mids+1,y
	sbc expansion_memory_target_pointer+1
	cmp #9
	bcc +
	lda #0						; cap the size at 2kB just in case a start
	sta stash_size				; address somehow wanders off into neverland
	lda #8
+	sta stash_size+1

	lda #<load_buffer
	sta expansion_transfer_local_addr
	lda #>load_buffer
	sta expansion_transfer_local_addr+1

	+JSR_INDIRECT (stash_block_vec)

unroll_next
	dey
	beq +
	jmp unroll_one_loop
  +
rts

loader_get_one_byte
	bit load_device_can_use_uci
	bmi +
	jsr CHRIN
	rts
+	jsr uci_get_byte
rts

print_generic_load_error
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

kbs_fract_approx
	!byte 0,0,1,1,2,3,3,4,5,5,6,6,7,8,8,9

last_seconds_lsb
	!byte 0

sample_number_count
	!byte 0
