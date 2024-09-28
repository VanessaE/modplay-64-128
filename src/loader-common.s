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

	lda #<load_buffer
	sta expansion_transfer_local_addr
	lda #>load_buffer
	sta expansion_transfer_local_addr+1
	lda #0
	sta expansion_transfer_local_addr+2

	lda expansion_memory_start_address
	sta expansion_memory_target_pointer
	lda expansion_memory_start_address+1
	sta expansion_memory_target_pointer+1
	lda expansion_memory_start_address+2
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
	jmp load_err

; read-in the file's header

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

	jsr decode_mod_header

	bcc +
	jmp abort_load

	; ### Okay, at this point we can go ahead and load the file.

+	lda CIA1+$0f	; ensure that the next few STA's reset the TOD clock
	and #$7f
	sta CIA1+$0f

	lda #0
	sta CIA1+$0b
	sta CIA1+$0a
	sta CIA1+$09
	sta CIA1+$08

	jsr load_via_acptr

	jsr reformat_pattern_data

	jsr zero_first_exp_pages
rts

load_via_acptr
	lda #0
	sta stash_size
	lda #5
	sta stash_size+1

	+JSR_INDIRECT (stash_block_vec) ; stash the header

	lda #5
	sta expansion_memory_target_pointer+1

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
	cmp #>(load_buffer+$0500)		; load buffer full?
	bne -

	+JSR_INDIRECT (stash_block_vec)

	clc
	lda expansion_memory_target_pointer+1
	adc #5
	sta expansion_memory_target_pointer+1
	bcc +
	inc expansion_memory_target_pointer+2

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
	beq acptr_exit
	iny
	cpy #16
	bne -

acptr_exit
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
	jsr print_loading_speed

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

print_loading_speed
	bit CIA1+$0b; read hours to latch the time

	lda CIA1+$0a ; minutes
	lsr
	lsr
	lsr
	lsr
	tax
	lda nybble_x10,x ; CIA's TOD clock is expressed in BCD.
	sta temp_abs_a
	lda CIA1+$0a
	and #$0f
	clc
	adc temp_abs_a
	ldx #60
	jsr multiply_8x8

	lda CIA1+$09 ; seconds
	lsr
	lsr
	lsr
	lsr
	tax
	lda nybble_x10,x
	sta temp_abs_a
	lda CIA1+$09
	and #$0f
	clc
	adc temp_abs_a

	ldx CIA1+$08; read tenths to un-latch the time

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
	lda expansion_memory_target_pointer
	sbc expansion_memory_start_address
	sta dividend
	lda expansion_memory_target_pointer+1
	sbc expansion_memory_start_address+1
	sta dividend+1
	lda expansion_memory_target_pointer+2
	sbc expansion_memory_start_address+2
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

zero_first_exp_pages
	lda #0
	ldx #0

-	sta expansion_transfer_buffer,x
	sta expansion_transfer_buffer+256,x
	dex
	bne -

	lda #<expansion_transfer_buffer
	sta expansion_transfer_local_addr
	lda #>expansion_transfer_buffer
	sta expansion_transfer_local_addr+1
	lda #0
	sta expansion_transfer_local_addr+2

	lda expansion_memory_start_address
	sta expansion_memory_target_pointer
	lda expansion_memory_start_address+1
	sta expansion_memory_target_pointer+1
	lda expansion_memory_start_address+2
	sta expansion_memory_target_pointer+2

	sta stash_size
	lda #2
	sta stash_size+1

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

kbs_fract_approx
	!byte 0,0,1,1,2,3,3,4,5,5,6,6,7,8,8,9

last_seconds_lsb
	!byte 0
