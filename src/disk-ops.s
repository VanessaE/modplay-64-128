; this file contains all the usual DOS operations

!text "file ops",0

check_drive_presence			; enter with .A = device to check
	ldx #0
	stx $90
	jsr LISTN
	lda #$6f					; secondary address 15 (command channel)
	jsr SECND
	jsr UNLSN
	lda $90						; get status flags
	pha
	jsr UNTLK
	pla							; a non-zero return = device not present
rts

read_err_channel
	jsr clear_string_buffer

	lda #0
	ldx #0
	ldy #0
	jsr SETNAM

	lda #2
	ldx load_device
	ldy #15
	jsr SETLFS

	jsr OPEN

	ldx #2
	jsr CHKIN

	ldy #0
-	lda $90			; (read status byte)
	bne .close		; either EOF or read error
	jsr CHRIN
	sta string_buffer,y
	iny
	cpy #39
	bne -

.close
	jsr close_file
rts


!ifndef c128 {
	input_limit = 28
} else {
	input_limit = 38
}

request_dos_command
	jsr gray_out
	clc
	jsr draw_text_input_popup

	lda #0
	ldx #<dos_command_msg
	ldy #>dos_command_msg
	jsr print_msg

	!ifndef c128 {
		clc
		ldx #(24 - text_input_popup_height) / 2 + 2
		ldy #text_input_popup_left_column + 1
		jsr PLOT
	} else {
		lda #RETURN
		jsr CHROUT
		jsr CHROUT
	}

	lda #LGRN
	jsr CHROUT
	lda #"@"
	jsr CHROUT
	lda #">"
	jsr CHROUT
	ldy #input_limit
	jsr get_text_input
	beq no_cmd

	tya
	ldy string_buffer ; is the first byte of input a "$"?
	cpy #"$"
	bne +

	jsr dir_open_for_cmd_prompt
	jsr dir_err_check
	jmp show_directory_cmd_prompt_entry

+	clc
	ora #$80
	ldx #<string_buffer
	ldy #>string_buffer

	jsr open_file

no_cmd
	jsr read_err_channel

	!ifndef c128 {
		clc
		jsr draw_text_input_popup
	} else {
		lda #CLR
		jsr CHROUT
	}

	lda #CYAN
	jsr CHROUT

	lda #30
	ldx #<string_buffer
	ldy #>string_buffer
	jsr print_msg

+	lda #YEL
	jsr CHROUT

	!ifndef c128 {
		clc
		ldx #(24 - text_input_popup_height) / 2 + 2
		ldy #text_input_popup_left_column + 1
		jsr PLOT
	} else {
		lda #RETURN
		jsr CHROUT
	}

	jsr press_any_key
rts

request_filename
	jsr gray_out
	clc
	jsr draw_text_input_popup

	lda #0
	ldx #<filename_req_msg
	ldy #>filename_req_msg
	jsr print_msg

	!ifndef c128 {
		clc
		ldx #(24 - text_input_popup_height) / 2 + 2
		ldy #text_input_popup_left_column + 1
		jsr PLOT
	} else {
		lda #RETURN
		jsr CHROUT
		jsr CHROUT
	}

	lda #LGRN
	jsr CHROUT
	lda #"="
	jsr CHROUT
	lda #">"
	jsr CHROUT
	ldy #input_limit
	jsr get_text_input
rts

get_free_disk_space
	lda #"$"
	sta string_buffer
	lda #":"
	sta string_buffer+1
	lda #1
	sta string_buffer+2
	lda #"*"
	sta string_buffer+3
	lda #0
	sta string_buffer+4

	sec
	lda #4
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
	jsr CHRIN				; blocks free LSB
	sta tempzp_d
	jsr CHRIN				; blocks free MSB
	sta tempzp_d+1

	jsr close_file
rts

open_file			; enter with .A = filename len, .X/.Y = filename addr
	php
	sta tempzp_c
	and #$7f		; in case the len indicates need for DOS command channel
	jsr SETNAM

	!ifdef c128 {
		lda #0
		ldx #0
		jsr SETBNK
	}

	ldy #2			; default SA=2
	ldx load_device

	plp
	bcc +			; if we called this with the carry set,
	ldy #0			; it means we need the directory, so SA=0
	beq .setlfs

+	lda tempzp_c	; retrieve filename length
	and #$80		; if the high bit of the length was set
	beq +
	ldy #15			; then it's for the DOS command channel, so SA=15

.setlfs
+	lda #2			; always using file number 2

	jsr SETLFS

	jsr OPEN
	bcc +
	jmp close_file

+	ldx #2
	jsr CHKIN
rts

close_file
	lda #2			; filenumber 2
	jsr CLOSE
	jsr CLRCH
rts

default_error_message
	!text "Error #",0
