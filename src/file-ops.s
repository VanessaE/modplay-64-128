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
	sta tempzp_c
	and #$7f		; in case the len indicates need for DOS command channel
	bne +
	lda #1			; if the length was 0, asssume we want the directory, len=1

+	jsr SETNAM

	!ifdef c128 {
		lda #0
		ldx #0
		jsr SETBNK
	}

	ldy #2			; default SA=2
	ldx load_device
	lda tempzp_c	; retrieve filename length


	bne +			; if we called this with filename length = 0,
	ldy #0			; it means we need the directory, so SA=0
	beq .setlfs

+	and #$80		; if on the other hand, the high bit of the length was set
	beq +
	ldy #15			; then it's for the DOS command channel,so SA=15

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
	lda #$00		; no filename, also pre-fill
	ldy #40
-	dey
	sta error_message_text,y
	bne -

	lda #$80		; open_file will notice this and assume len=0, SA=15
	ldx #0
	ldy #0
	jsr open_file
	bcs .close

	ldy #0
-	lda $90			; (read status byte)
	bne .close		; either EOF or read error
	jsr CHRIN
	sta error_message_text,y
	iny
	cpy #39
	bne -

.close
	jmp close_file

error_message_text !fill 40,0
