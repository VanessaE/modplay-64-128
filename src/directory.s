; show disk directory, C= hacking #6, greatly modified

show_directory
	!ifdef c128 {
		jsr draw_dir_window
		jsr set_dim_dir_win
		lda #HOME
		jsr CHROUT
	} else {
		lda #CLR
		jsr CHROUT
	}

	lda #YEL
	jsr CHROUT

	jsr dir_open
	jsr dir_err_check

	jsr CHRIN			; get/ignore the first four bytes
	jsr CHRIN
	jsr CHRIN
	jsr CHRIN

	jsr dir_read_entry_size
	ldx #<string_16_bit_trimmed
	ldy #>string_16_bit_trimmed
	jsr print_msg

	jsr dir_read_line		; first line is the dir/disk name

	lda #" "
	jsr CHROUT				; add a space

	ldx #<string_buffer
	ldy #>string_buffer
	jsr print_msg

	lda #$0d
	jsr CHROUT				; print return

-	jsr CHRIN				; skip first two bytes of each dir entry
	jsr CHRIN
	jsr dir_err_check		; check for EOF/err

	jsr dir_read_entry_size
	ldx #<string_16_bit_trimmed
	ldy #>string_16_bit_trimmed
	jsr print_msg

	lda #" "
	jsr CHROUT

	jsr dir_read_line

	ldx #<string_buffer
	ldy #>string_buffer
	jsr print_msg

	lda #$0d
	jsr CHROUT				; print return

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
	ldx #<errmsg
	ldy #>errmsg
	jsr print_msg
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
	ldx #<press_key_msg
	ldy #>press_key_msg
	jsr print_msg

-	jsr GETIN			; wait for keypress
	beq -

	!ifdef c128 {
		lda #0
		sta clear_menu_screen_flag
		jsr erase_dir_window
	}
rts

dir_open
	lda #0				; open_file will notice this and assume 1 byte len and SA=0
	ldx #<dirname
	ldy #>dirname
	jsr open_file
rts						; will exit with carry set if it can't open

dir_read_entry_size
	jsr CHRIN	; LSB
	pha
	jsr CHRIN	; MSB
	tay
	pla
	tax
	jsr int16_to_string
	jsr trim_num
rts

dir_read_line
	ldy #39
	lda #0
-	sta string_buffer,y
	dey
	bpl -
	ldy #0

-	jsr CHRIN
	sta string_buffer,y
	beq +					; continue until end of line
	iny
	cpy #40
	bne -					; ...or until string buf is full
+ rts

dirname
		!text "$"

errmsg
		!text 13,"Error #",0

!ifdef c128 {
	draw_dir_window
		jsr erase_dir_window

		ldx #<dir_popup_top
		ldy #>dir_popup_top
		jsr print_msg

		lda #17
		sta tempzp_d
	-	ldx #<dir_popup_mid
		ldy #>dir_popup_mid
		jsr print_msg
		dec tempzp_d
		bpl -

		ldx #<dir_popup_bot
		ldy #>dir_popup_bot
		jsr print_msg
	rts

	erase_dir_window
		jsr set_dim_full_screen
		lda #HOME
		jsr CHROUT
		jsr set_dim_dir_win_extra
		lda #CLR
		jsr CHROUT
		jsr set_dim_full_screen
		lda #HOME
		jsr CHROUT
	rts

	set_dim_dir_win
		lda #3
		sta SCTOP
		lda #20
		sta SCBOT
		lda #26
		sta SCLF
		lda #54
		sta SCRT
	rts

	set_dim_dir_win_extra
		lda #2
		sta SCTOP
		lda #21
		sta SCBOT
		lda #23
		sta SCLF
		lda #56
		sta SCRT
	rts
}
