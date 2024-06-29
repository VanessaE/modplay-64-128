; show disk directory, C= hacking #6, greatly modified

!text "directory",0

show_directory
	jsr dir_open
	jsr dir_err_check

show_directory_cmd_prompt_entry
	!ifdef c128 {
		jsr gray_out
		clc
		jsr draw_tall_popup
	} else {
		lda #CLR
		jsr CHROUT
	}

	lda #YEL
	jsr CHROUT

	jsr CHRIN			; get/ignore the first four bytes
	jsr CHRIN
	jsr CHRIN
	jsr CHRIN

	jsr dir_read_entry_size

	lda #RIGHT
	jsr CHROUT

	lda #0
	ldx #<uint16_string_buf_trim
	ldy #>uint16_string_buf_trim
	jsr print_msg

	jsr dir_read_line		; first line is the dir/disk name

	lda #" "
	jsr CHROUT				; add a space

	lda #RIGHT
	jsr CHROUT

	lda #0
	ldx #<string_buffer
	ldy #>string_buffer
	jsr print_msg

	lda #$0d
	jsr CHROUT				; print return

-	jsr CHRIN				; skip first two bytes of each dir entry
	jsr CHRIN
	jsr dir_err_check		; check for EOF/err

	jsr dir_read_entry_size

	lda #RIGHT
	jsr CHROUT

	lda #0
	ldx #<uint16_string_buf_trim
	ldy #>uint16_string_buf_trim
	jsr print_msg

	lda #" "
	jsr CHROUT

	jsr dir_read_line

	lda #0
	ldx #<string_buffer
	ldy #>string_buffer
	jsr print_msg

	lda #$0d
	jsr CHROUT				; print return

	jsr check_com_key		; we just care that if pressed, it'll hold there.

	jsr STOP				; run/stop pressed?
	bne -					; no run/stop -> continue
	beq dir_finish

dir_err_check
	lda STATUS
	bne +					; if status is non-0, something important happened
	rts

+	cmp #$40				; status/.A will be $40 for EOF
	beq +					; in which case we just exit normally.

	pha						; any other value is an error code
	lda #0
	ldx #<default_error_message
	ldy #>default_error_message
	jsr print_msg

	sec
	pla
	tax
	ldy #0
	jsr print_uint16

	lda #$0d ; Return
	jsr CHROUT

+	pla						; pull the last return address off the stack
	pla						; so that we can exit directly from here.

dir_finish
	jsr close_file

	lda #$0d
	jsr CHROUT

	lda #RIGHT
	jsr CHROUT

	jsr press_any_key

	!ifdef c128 {
		lda #0
		sta clear_menu_screen_flag
		ldx #tall_popup_height
		ldy #medium_popup_width
		jsr erase_popup
	}
rts

dir_open
	lda #1
	ldx #<dirname
	ldy #>dirname
	sec
	jsr open_file
rts						; will exit with carry set if it can't open

dir_open_for_cmd_prompt
	ldx #<string_buffer
	ldy #>string_buffer
	sec
	jsr open_file
rts						; will exit with carry set if it can't open

dir_read_entry_size
	jsr CHRIN	; LSB
	pha
	jsr CHRIN	; MSB

	sec
	tay
	pla
	tax
	jsr uint16_to_string
	jsr trim_num
rts

dir_read_line
	jsr clear_string_buffer

	ldy #0
-	jsr CHRIN
	sta string_buffer,y
	beq +					; continue until end of line
	iny
	cpy #48
	bne -					; ...or until string buf is full
+ rts

dir_file_unquote	; routine returns clear carry and a quote-less string at
					; string buffer + 32, .X = length, else it exits with set carry

	ldx #0
-	lda string_buffer,x
	cmp #$22				; look for the first quote mark
	beq +
	inx
	cpx #16
	bne -					; keep looking for up to 16 chars (max filename length)

	sec						; if we got that far, there's no filename,
	ldy #0
	rts						; so tell caller to discard the string buffer.

+	inx
	ldy #0

-	lda string_buffer,x
	cmp #$22				; look for the next quote mark
	beq +
	sta string_buffer+32,y
	inx
	iny
	cpy #16					; give up if we hit the max
	bne -
+	clc
rts
