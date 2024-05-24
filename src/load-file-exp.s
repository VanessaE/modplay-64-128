; this loads a file into the expansion RAM

load_file_to_expansion
	!ifdef c128 {
		jsr set_dim_full_screen
		loader_window_width = 24
		size_text = 12
	} else {
		loader_window_width = 18
		size_text = 8
	}

; first we open the file so we can grab the first two bytes
; because the KERNAL will discard them

	lda file_to_load_name_len
	ldx #<file_to_load_name
	ldy #>file_to_load_name
	jsr open_file

	bcc +
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
	ldx STATUS
	ldy #0
	jsr print_uint16

-	jsr GETIN
	beq -
	rts

+	lda file_to_load_size
	sta file_size_in_kb
	lda file_to_load_size+1
	sta file_size_in_kb+1

	lsr file_size_in_kb+1		; divide by 4
	ror file_size_in_kb
	lsr file_size_in_kb+1
	ror file_size_in_kb

	jsr draw_loading_popup

; preset the divisor to be proportional to max number of progress bar segments
; 16 char long bar * 4 segments per = 64 segments on C64, 32 * 4 = 128 on C128

	lda file_to_load_size		; turn blocks-to-load into bytes-to-load
	sta divisor+1
	lda file_to_load_size+1
	sta divisor+2
	lda #0
	sta divisor

	rol divisor+1	; multiply size by 4...
	rol divisor+2
	rol
	clc
	rol divisor+1
	rol divisor+2
	rol
	tax

	lda divisor+1	; then displace by one byte, e.g. final is divide by 64
	sta divisor
	lda divisor+2
	sta divisor+1
	stx divisor+2	; divisor is now number of bytes per segment.

	lda #0
	sta stash_pointer
	sta stash_pointer+1 ; start at $000000 in expansion RAM
	sta stash_pointer+2
	
	!ifdef c128 {

		; If C128, we can load the file 50% faster via the KERNAL LOAD routine
		; using the "STOP wedge" trick that popped-up the mid-load splash.

		old_stop_vec = $f66e
		load_pointer_alias = EAL

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
		ldx #<file_to_load_name
		ldy #>file_to_load_name
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

		lda #<old_stop_vec
		sta STOP_vec
		lda #>old_stop_vec
		sta STOP_vec+1
	} else {

	; on the C64, we have to use the regular CHRIN method because the "STOP
	; wedge" method breaks on JiffyDOS and probably other fast loaders.

	; the file is still open from above, so just continue using it.

		old_stop_vec = $f6ed
		load_pointer_alias = load_pointer

		lda #<load_buffer
		sta load_pointer_alias
		lda #>load_buffer
		sta load_pointer_alias+1
		ldy #0

	-	lda STATUS
		bne .done

		tya
		pha
		jsr fill_load_buffer
		pla
		tay
		jsr CHRIN

		sta (load_pointer_alias),y
		iny
		bne -
		inc load_pointer_alias+1
		bne -

	.done
		jsr close_file
	}

	jsr stash_block		; don't forget to stash the last block that was loaded

	!ifdef c128 {
		lda #0
		sta clear_menu_screen_flag
		jsr erase_loading_popup
	}

rts

fill_load_buffer				; STOP vector enters here after a byte is loaded
	lda load_pointer_alias+1
	cmp #>load_buffer_end		; load buffer full?
	bne .not_full

	jsr stash_block

	clc
	lda stash_pointer+1
	adc #4
	sta stash_pointer+1
	bcc +
	inc stash_pointer+2

+	lda #0
	sta load_pointer_alias
	lda #>load_buffer
	sta load_pointer_alias+1

	jsr update_progress

.not_full

!ifdef c128 {
	jmp old_stop_vec
} else {
	rts
}

stash_block					; the load buffer is under the KERNAL, so we'll
	!ifndef c128 {
		php
		sei
	}
	jsr disable_roms		; need to switch it in/out.
	jsr reu_stash_block
	jsr enable_kernal
	!ifndef c128 {
		plp
	}
rts

draw_loading_popup
	!ifdef c128 {
		jsr erase_loading_popup
	}
	ldx #<loading_popup_top
	ldy #>loading_popup_top
	jsr print_msg

	lda #6
	sta tempzp_d
-	ldx #<loading_popup_mid
	ldy #>loading_popup_mid
	jsr print_msg
	dec tempzp_d
	bpl -

	ldx #<loading_popup_bot
	ldy #>loading_popup_bot
	jsr print_msg

	ldx #<progress_bar_frame
	ldy #>progress_bar_frame
	jsr print_msg

	ldx #<loading_popup_top_left_inside
	ldy #>loading_popup_top_left_inside
	jsr print_msg

	lda #loader_window_width
	ldx #<file_to_load_name
	ldy #>file_to_load_name
	jsr center_string

+	lda #CYAN
	jsr CHROUT
	lda #$22 ; quote
	jsr CHROUT

	ldx #<file_to_load_name
	ldy #>file_to_load_name
	jsr print_msg

	lda #$22 ; quote
	jsr CHROUT

	ldx #<loading_popup_next_line
	ldy #>loading_popup_next_line
	jsr print_msg

	lda #LBLU
	jsr CHROUT

	; determine lenghts of filesize strings
	ldx file_to_load_size
	ldy file_to_load_size+1
	jsr get_num_length
	sty tempzp_c

	ldx file_size_in_kb
	ldy file_size_in_kb+1
	jsr get_num_length
	sty tempzp_e

	sec
	lda #loader_window_width
	sbc tempzp_c			; length of the blocks figure
	sbc tempzp_e			; length of the kB figure
	sbc #size_text			; length of the "blocks" and "k" parts
	lsr
	tay
	dey
	beq +

	lda #RIGHT
-	jsr CHROUT
	dey
	bne -

+	ldx file_to_load_size
	ldy file_to_load_size+1
	jsr print_uint16

	ldx #<blocks_msg
	ldy #>blocks_msg
	jsr print_msg

	ldx file_size_in_kb
	ldy file_size_in_kb+1
	jsr print_uint16

	!ifndef c128 {
		lda #"k"
		jsr CHROUT
	} else {
		lda #" "
		jsr CHROUT
		lda #"k"
		jsr CHROUT
		lda #"B"
		jsr CHROUT
	}
	ldx #<loading_popup_next_line
	ldy #>loading_popup_next_line
	jsr print_msg

	ldx #<loading_msg
	ldy #>loading_msg
	jsr print_msg
rts

!ifdef c128 {
	erase_loading_popup
		jsr set_dim_full_screen
		lda #HOME
		jsr CHROUT
		jsr set_dim_loading_popup_extra
		lda #CLR
		jsr CHROUT
		jsr set_dim_full_screen
		lda #HOME
		jsr CHROUT
	rts

	set_dim_loading_popup_extra
		lda #7
		sta SCTOP
		lda #15
		sta SCBOT
		lda #23
		sta SCLF
		lda #56
		sta SCRT
	rts
}

update_progress
	ldx #<progress_bar_pos
	ldy #>progress_bar_pos
	jsr print_msg

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

	clc					; bump up by 1 since it has to be decremented right away
	adc #1
	tay

	lda #RVSON
	jsr CHROUT
	lda #" "
-	dey
	beq +
	jsr CHROUT
	jmp -

+	lda quotient	; get segment count again
	and #$03		; we just need the two lowest bits: which segment to draw
	asl				; double it to get an index into the strings below
	tay
	lda progress_bar_segments,y
	jsr CHROUT
	iny
	lda progress_bar_segments,y
	jsr CHROUT
	lda #RVSOFF
	jsr CHROUT
rts

progress_bar_segments
	!byte RVSOFF," "
	!byte RVSOFF,$a5
	!byte RVSOFF,$a1
	!byte $a7,0

file_to_load_name_len		!byte 13
file_to_load_name			!text "cutie pie.mod",0,0,0,0
file_to_load_size			!byte 190,0				 ; 190 blocks, about 47 kB
