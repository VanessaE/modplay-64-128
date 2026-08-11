; show disk directory, C= hacking #6, greatly modified

c64_dir_popup_base_addr		= VIC_SCREEN + 2*40 + 5
c64_dir_popup_colors_addr	= VIC_COLOR_RAM + 2*40 + 5
c64_dir_height				= 21
c64_dir_width				= 30

show_directory
	jsr dir_open
	jsr dir_err_check

show_directory_cmd_prompt_entry
	jsr gray_out
	clc
	jsr draw_tall_popup

	lda #$80
	sta scroll_area_blank_last_line_flag

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
	sec
	jsr print_msg

	jsr dir_read_line		; first line is the dir/disk name

	lda #" "
	jsr CHROUT				; add a space

	lda #RIGHT
	jsr CHROUT

	lda #0
	ldx #<string_buffer
	ldy #>string_buffer
	sec
	jsr print_msg

	lda #RETURN
	jsr CHROUT

-	jsr CHRIN				; skip first two bytes of each dir entry
	jsr CHRIN
	jsr dir_err_check		; check for EOF/err

	jsr dir_read_entry_size

	lda #RIGHT
	jsr CHROUT

	!ifndef c128 {
		lda #0
		ldx #<dir_window_left_margin
		ldy #>dir_window_left_margin
		sec
	jsr print_msg
	}

	lda #0
	ldx #<uint16_string_buf_trim
	ldy #>uint16_string_buf_trim
	sec
	jsr print_msg

	lda #" "
	jsr CHROUT

	jsr dir_read_line

	jsr strip_trailing_spaces

	lda #0
	ldx #<string_buffer
	ldy #>string_buffer
	sec
	jsr print_msg

	lda #RETURN
	jsr CHROUT

	!ifndef c128 {
		jsr check_if_need_to_scroll
	}

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

	lda #RETURN
	jsr CHROUT
	jsr CHROUT

	!ifndef c128 {
		lda #0
		ldx #<dir_window_left_margin
		ldy #>dir_window_left_margin
		sec
		jsr print_msg

		jsr check_if_need_to_scroll
	}

	lda #0
	ldx #<default_error_message
	ldy #>default_error_message
	sec
	jsr print_msg

	sec
	pla
	tax
	ldy #0
	jsr print_uint16

	lda #RETURN
	jsr CHROUT

+	pla						; pull the last return address off the stack
	pla						; so that we can exit directly from here.

dir_finish
	jsr close_file

	lda #RETURN
	jsr CHROUT

	!ifndef c128 {
		jsr check_if_need_to_scroll
	}

	lda #RIGHT
	jsr CHROUT

	!ifndef c128 {
		lda #0
		ldx #<dir_window_left_margin
		ldy #>dir_window_left_margin
		sec
		jsr print_msg
	}

jmp press_any_key


dir_open
	lda #1
	ldx #<dirname
	ldy #>dirname
	sec
jmp open_file		; will exit with carry set if it can't open

dir_open_for_cmd_prompt
	ldx #<string_buffer
	ldy #>string_buffer
	sec
jmp open_file		; will exit with carry set if it can't open

dir_read_entry_size
	jsr CHRIN	; LSB
	pha
	jsr CHRIN	; MSB

	sec
	tay
	pla
	tax
	jsr uint16_to_string
jmp trim_num

dir_read_line
	jsr clear_string_buffer
	lda #$20
	sta string_buffer		; just to ensure there's *something* to print
							; in case nothing could be read.

	ldy #0
-	jsr CHRIN
	bcs +					; proceed as long as status doesn't indicate end/error

	sta string_buffer,y
	beq +					; continue until end of line
	iny
	cpy #48
	bne -					; ...or until string buf is full
  +
rts

dir_file_unquote	; routine returns clear carry and a quote-less string at
					; string buffer + 32, .X = length, else it exits with set carry
					; if valid, then .A contains first char of file type
	ldx #0
-	lda string_buffer,x
	cmp #$22				; look for the first quote mark
	beq +
	inx
	cpx #16
	bne -					; keep looking for up to 16 chars (max filename length)

.duq_no_file
	sec						; if we got that far, there's no filename,
	ldy #0
	tya
	rts						; so tell caller to discard the string buffer.

+	inx
	ldy #0

-	lda string_buffer,x
	cmp #$22				; look for the next quote mark.  Note: the file
	beq +					; type comes 2 bytes after the closing quote
	sta string_buffer+32,y
	inx
	iny
	cpy #16					; give up if we hit the max filename length
	bne -
+	txa
	tay						; we want to preserve .X now, but we can clobber .Y

-	iny						; search forward from the second quote for a non-
	cpy #32					; space char.  Give up if >32 bytes (end of file
	beq .duq_no_file		; name area), declare it as no file.

	lda string_buffer,y
	cmp #$20
	beq -

	; we nowe have the first char of file type

	cmp #"d"				; if it isn't a "D", it can't be "DEL" or "DIR" 😛
	beq +
	lda string_buffer+1,y	; second char
	cmp #"e"				; if it's an "E" then this is a "DEL" i.e.
	beq .duq_no_file		; deleted file, so ignore it.
	lda string_buffer,y

+	clc
rts

!ifndef c128 {
	check_if_need_to_scroll
		lda cursor_current_line
		cmp #23
		bne +

		lda #<c64_dir_popup_base_addr
		sta scroll_area_target_addr
		lda #>c64_dir_popup_base_addr
		sta scroll_area_target_addr+1

		lda #c64_dir_width
		sta scroll_area_width
		lda #c64_dir_height
		sta scroll_area_height

		jsr scroll_area_up

		lda #<c64_dir_popup_colors_addr
		sta scroll_area_target_addr
		lda #>c64_dir_popup_colors_addr
		sta scroll_area_target_addr+1

		lda #c64_dir_width
		sta scroll_area_width
		lda #c64_dir_height
		sta scroll_area_height

		jsr scroll_area_up

		lda #UP
		jsr CHROUT
		lda #0
	  +
	rts
}

; For this check, the program simply attempts to send `cd:blahdeblah`, which
; is basically guaranteed to fail. 🙂  Then it checks the error channel to
; see if the drive actually understood the command.  These are the returned
; strings when the command is either invalid or the dir doesn't exist:
;
; 1541: 30, syntax error
; 1571: 30, syntax error
; 1581: 30, syntax error
;
; SD2IEC: 62, file not found
; C64U SoftIEC: 71, directory error
; VICE virtual fs: 62, file not found
;
; CMD FD w/1581 disk or HD disk with 15xx subpartition:  30, syntax error
; CMD FD w/HD disk and native partition:  39, file not found
; CMD HD:  39, file not found
;
; So anything that doesn't return "syntax error" should accept `cd` commands.
; (the error code number and "track"/"sector" fields are ignored).

check_for_dir_support
	lda #0
	sta load_device_supports_dirs

	ldx #<dir_check_string
	ldy #>dir_check_string
	jsr send_dos_command

	ldy #$ff
-	iny
	lda syntax_err_string,y
	beq +
	cmp string_buffer+3,y
	beq -

	lda #$80
	sta load_device_supports_dirs
  +
rts
