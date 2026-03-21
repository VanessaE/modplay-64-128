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

	bit load_device_can_use_uci
	bmi +
	jsr loader_standard_get_mod_header
	jmp ++
+	jsr loader_uci_get_mod_header

++	lda #4
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

	bit load_device_can_use_uci
	bmi +

	jsr loader_standard_load_pattern_data
	jsr loader_standard_load_sample_data
	rts

+	jsr loader_uci_load_pattern_data
	jsr loader_uci_load_sample_data
rts

abort_load
	lda #0
	sta current_file_type
	jsr press_any_key
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

; enter with .Y = sample number

mod_unroll_loop
	; is there a loop at all?
	lda sample_default_loop_flags,y
	bmi +
	rts

	; is its len > 2kB?

+	sec
	lda sample_loop_end_addresses_lows,y
	sbc sample_loop_start_addresses_lows,y
	sta temp_counter
	lda sample_loop_end_addresses_mids,y
	sbc sample_loop_start_addresses_mids,y
	sta temp_counter+1
	lda sample_loop_end_addresses_highs,y
	sbc sample_loop_start_addresses_highs,y
	sta temp_counter+2

	lda temp_counter
	cmp #0
	lda temp_counter+1
	sbc #8
	lda temp_counter+2
	sbc #0
	bcc +
	rts ; if not, just bail out

	; otherwise, fetch the loop data into the load buf
	; but first, back-up the expansion RAM pointers

+	lda expansion_memory_target_pointer
	sta exp_target_ptr_temp
	lda expansion_memory_target_pointer+1
	sta exp_target_ptr_temp+1
	lda expansion_memory_target_pointer+2
	sta exp_target_ptr_temp+2

	lda expansion_transfer_local_addr
	sta exp_local_ptr_temp
	lda expansion_transfer_local_addr+1
	sta exp_local_ptr_temp+1

	lda stash_size
	sta exp_stash_size_temp
	lda stash_size+1
	sta exp_stash_size_temp+1

	; the loop length becomes the stash/fetch size

	lda temp_counter
	sta stash_size
	lda temp_counter+1
	sta stash_size+1

	lda #<load_buffer
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

	; store a new copy of the loop data at the end of the existing data

unroll_more
	clc
	lda expansion_memory_target_pointer
	adc temp_counter
	sta expansion_memory_target_pointer
	sta sample_loop_end_addresses_lows,y
	lda expansion_memory_target_pointer+1
	adc temp_counter+1
	sta expansion_memory_target_pointer+1
	sta sample_loop_end_addresses_mids,y
	lda expansion_memory_target_pointer+2
	adc #0
	sta expansion_memory_target_pointer+2
	sta sample_loop_end_addresses_highs,y

+	+JSR_INDIRECT (stash_block_vec)

	; was that the last cycle that needed to be copied?

	sec
	lda expansion_memory_target_pointer+1
	sbc sample_loop_start_addresses_mids,y
	cmp #9
	bcc unroll_more

	; and restore the exp variables

	lda exp_target_ptr_temp
	sta expansion_memory_target_pointer
	lda exp_target_ptr_temp+1
	sta expansion_memory_target_pointer+1
	lda exp_target_ptr_temp+2
	sta expansion_memory_target_pointer+2

	lda exp_local_ptr_temp
	sta expansion_transfer_local_addr
	lda exp_local_ptr_temp+1
	sta expansion_transfer_local_addr+1

	lda exp_stash_size_temp
	sta stash_size
	lda exp_stash_size_temp+1
	sta stash_size+1
rts

;----------------------------------
; reserve extra mem for unrolling loops
;
; temp_counter still holds the loop len...
;
	; is that loop more than 2kB in size?
;	lda temp_counter
;	cmp #0
;	lda temp_counter+1
;	sbc #8
;	lda temp_counter+2
;	sbc #0
;	bcs skip_sample ; loop is > 2kB, no need to unroll it
;
; reserve original loop length....
;	clc
;	lda sample_loop_end_addresses_lows,x
;	adc temp_counter
;	sta utility_pointer_b
;	lda sample_loop_end_addresses_mids,x
;	adc temp_counter+1
;	sta utility_pointer_b+1
;	lda sample_loop_end_addresses_highs,x
;	adc temp_counter+2
;	sta utility_pointer_b+2
;
; ..plus 2kb
;	clc
;	lda utility_pointer_b+1
;	adc #8
;	sta utility_pointer_b+1
;	bcc +
;	inc utility_pointer_b+2
;
; +	sta parse_header_sample_pointer+1
;	sta sample_loop_end_addresses_mids,x
;	sta sample_end_addresses_mids,x
;	lda utility_pointer_b
;	sta parse_header_sample_pointer
;	sta sample_loop_end_addresses_lows,x
;	sta sample_end_addresses_lows,x
;	lda utility_pointer_b+2
;	sta parse_header_sample_pointer+2
;	sta sample_loop_end_addresses_highs,x
;	sta sample_end_addresses_highs,x
;
; and add 256 bytes to pad to the next sample
;
;	inc parse_header_sample_pointer+1
;	bne +
;	inc parse_header_sample_pointer+2
;
;  +





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
