; this file contains all the usual DOS operations

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

read_err_channel
	jsr clear_string_buffer ; this also leaves .A=0, which signals "no filename"

	lda #$80		; open_file will notice this and assume len=0, SA=15
	ldx #0
	ldy #0
	jsr open_file
	bcs .close

	ldy #0
-	lda $90			; (read status byte)
	bne .close		; either EOF or read error
	jsr CHRIN
	sta string_buffer,y
	iny
	cpy #39
	bne -

.close
	jmp close_file

!ifndef c128 {
	input_limit = 28
} else {
	input_limit = 38
}

request_dos_command
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
rts

request_filename
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

default_error_message
		!text 13,"Error #",0
