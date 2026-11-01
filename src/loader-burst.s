; Loader image for reading a file with the C128's burst protocol, which the 1571,
; the 1581, and the devices that act like one of them have.
;
; The file is read with the drive's "Fastload" burst command.  Once that is given
; the drive reads the file sector by sector, on its own, and sends each sector with
; a status byte in front of it.  The bytes come in through the CIA1 shift register,
; and are acknowledged by toggling the clock line (CLK OUT) of the serial port.
; Nothing else can use the bus until the last sector has been sent, and interrupts
; have to stay off all that time (see burst_open).
;
; The sectors are received into the stage, one page that's shared with the audio
; buffers, and are handed out from there:  a sector has 254 bytes, so the blocks
; that the loader works in can't be received directly.  The copying out of the stage
; happens between the sectors, while the drive is reading the next one.
;
; If the device can't do any of this, burst_open fails and loader_open_file has the
; KERNAL image try again.  This is assembled to run from the loader slot (see
; modplay.s), but it's stored in the PRG (and then in expansion memory) as plain
; data, like the audio driver images.  Its entry jumps are described in
; loader-select.s.

!zone loader_burst {

burst_stage				= audio_buffer_right		; (the loader never needs this one)

loader_burst_image = *

!pseudopc loader_slot {

	jmp burst_open
	jmp burst_close
	jmp burst_close
	jmp burst_get_byte
	jmp burst_get_block
	jmp burst_get_1kb

burst_stage_pos		!byte 0		; the next byte to hand out from the stage
burst_stage_count	!byte 0		; how many bytes of the sector are in it
burst_status		!byte 0		; the status byte of the sector that was read last
burst_eof			!byte 0		; $80 when the last sector has been read or the drive gave up
burst_saved_i		!byte 0		; the interrupt flag, as it was at the open
burst_save_x		!byte 0
burst_save_y		!byte 0

; enter with .A = the length of the filename, .X/.Y = its address, and .C clear, as
; for open_file.  returns .C = 1 if the file couldn't be opened, with an error code
; in .A.  BURST_ERR_NOT_BURST means that the device can't do burst, and the rest of
; the codes are only there for the looks.  if it did work, the first sector is in
; the stage and interrupts are off, until the last sector has been received or
; burst_close is called.

burst_open
	jsr SETNAM

	php
	pla
	and #%00000100					; remember if interrupts were off already
	sta burst_saved_i

	lda #0
	sta burst_stage_pos
	sta burst_stage_count
	sta burst_eof
	sta STATUS

	lda FAST_SERIAL_FLAG			; the KERNAL sets bit 6 when a device answers
	and #%10111111					; in fast serial, so clear it first
	sta FAST_SERIAL_FLAG

	lda load_device
	jsr LISTN
	bit STATUS
	bmi .no_device

	lda #$6f						; the command channel
	jsr SECND

	lda #"u"						; the Fastload command is "U0", then $9f (the
	jsr CIOUT						; bit 7 of that lets it read SEQ files as well as
	bit STATUS						; PRG), then the filename.
	bmi .no_device

	lda #"0"
	jsr CIOUT
	lda #$9f
	jsr CIOUT

	ldy #0
-	lda (NAMEPTR),y
	jsr CIOUT
	iny
	cpy NAMELEN
	bcc -

	jsr UNLSN

	lda FAST_SERIAL_FLAG			; did the device take it in fast serial?
	and #%01000000
	bne +

	jsr burst_close					; if it did take the command after all, this
	lda #BURST_ERR_NOT_BURST		; makes it let go of the bus again
	sec
	rts

+	sei								; interrupts stay off until the file is over,
										; since the interrupt handler reads CIA1's ICR,
	clc								; and so clears the flag that we wait for.
	jsr SPIN						; set up fast serial input
	bit CIA1_ICR					; clear the flags, and then toggle CLK OUT
	lda CIA2_PORT_A					; to tell the drive that we're ready
	eor #$10
	sta CIA2_PORT_A

	jsr burst_read_sector
	bcc +
	rts								; (the drive refused it, so .C is set and .A has a code)

+	lda burst_status
	cmp #$1f
	bne .opened

	; the whole file is in the first sector.  nothing that small is a MOD, and the
	; drive reports the length of a short file wrong anyway, so don't use this one.

	lda #0
	sta burst_eof
	jsr burst_close
	lda #4
	sec
	rts

.opened
	clc
	rts

.no_device
	jsr UNLSN
	lda #5
	sec
	rts

; closes the file, both when it's been read to the end (and the drive is done
; already) and when the load is given up in the middle, in which case the drive is
; still waiting for the rest of it to be asked for, and has to be told to stop.
; that is what closing the command channel does.

burst_close
	bit burst_eof
	bmi .closed

	lda #$80
	sta burst_eof

	lda load_device
	jsr LISTN
	lda #$ef						; close channel 15
	jsr SECND
	jsr UNLSN

.closed
	jsr burst_restore_i
	clc
	rts

; interrupts back on, if they were on at the open.

burst_restore_i
	lda burst_saved_i
	bne +
	cli
+	rts

; receives the next sector of the file into the stage.  on return, burst_stage_pos
; is 0 and burst_stage_count is the number of bytes in it.  .C = 1 if the drive
; reported an error, with a code in .A and the stage empty.  trashes .A, .X and .Y.
; when it receives the last sector (or gets an error), the drive's end of the
; session is over, so it turns interrupts back on.

burst_read_sector
	lda #0
	sta burst_stage_pos

	lda #$08						; wait for the status byte
-	bit CIA1_ICR
	beq -

	lda CIA2_PORT_A					; acknowledge it
	eor #$10
	sta CIA2_PORT_A

	lda CIA1_SDR
	sta burst_status
	ldx #254
	cmp #2
	bcc .sector_data				; 0 is a regular sector, with 254 bytes

	cmp #$1f						; $1f is the last one, which starts with its
	bne .sector_error				; byte count.  everything else is an error

	lda #$08
-	bit CIA1_ICR
	beq -

	ldx CIA1_SDR
	lda CIA2_PORT_A
	eor #$10
	sta CIA2_PORT_A

	lda #$80						; the drive is finished with the file now
	sta burst_eof

.sector_data
	stx burst_stage_count
	cpx #0
	beq .sector_done

	ldy #0
.sector_byte
	lda CIA2_PORT_A					; work out the toggled clock first, to
	eor #$10						; have it ready as soon as the byte is
	tax

	lda #$08
-	bit CIA1_ICR
	beq -

	stx CIA2_PORT_A
	lda CIA1_SDR
	sta burst_stage,y
	iny
	cpy burst_stage_count
	bne .sector_byte

.sector_done
	bit burst_eof
	bpl +
	jsr burst_restore_i
+	clc
	rts

.sector_error
	lda #0
	sta burst_stage_count
	lda #$80
	sta burst_eof
	jsr burst_restore_i
	lda burst_status
	ora #$10
	sec
	rts

; gets the next sector into the stage if there is one.  returns .X = 0, and .C = 1
; if the file is over.  preserves .Y.

burst_refill
	bit burst_eof
	bmi .refill_end

	tya
	pha
	jsr burst_read_sector
	pla
	tay

	ldx #0
	cpx burst_stage_count			; (an empty sector means the end, too)
	rts

.refill_end
	ldx #0
	sec
	rts

; gets the next byte of the file, in .A, and sets STATUS to $40 when it's the last.
; past the end of the file it returns zeros, and the same STATUS.  preserves .X
; and .Y.

burst_get_byte
	stx burst_save_x
	sty burst_save_y

	ldx burst_stage_pos
	cpx burst_stage_count
	bcc .byte_have

	jsr burst_refill
	bcc .byte_have

	lda #$40
	sta STATUS
	lda #0
	beq .byte_exit

.byte_have
	lda burst_stage,x
	inx
	stx burst_stage_pos
	cpx burst_stage_count
	bne .byte_exit

	bit burst_eof
	bpl .byte_exit

	pha
	lda #$40
	sta STATUS
	pla

.byte_exit
	ldx burst_save_x
	ldy burst_save_y
	rts

; reads 256 bytes of the file to load_buffer, or from where load_pointer is, for
; the one that's called for the later pages of a bigger read.  the end of the
; file is handled as for burst_get_byte.

burst_get_block
	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

burst_get_block_keep_ptr
	ldy #0
	ldx burst_stage_pos

.block_next
	cpx burst_stage_count
	bcs .block_refill

.block_copy
	lda burst_stage,x
	inx
	sta (load_pointer),y
	iny
	bne .block_next
	beq .block_done

.block_refill
	jsr burst_refill
	bcc .block_copy

	lda #0							; the file is over, so fill with zeros
	sta (load_pointer),y
	iny
	bne .block_refill

.block_done
	stx burst_stage_pos
	cpx burst_stage_count
	bne +

	bit burst_eof
	bpl +

	lda #$40
	sta STATUS

+	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2
  +
rts

burst_get_1kb
	jsr burst_get_block
	inc load_pointer+1
	jsr burst_get_block_keep_ptr
	inc load_pointer+1
	jsr burst_get_block_keep_ptr
	inc load_pointer+1
jmp burst_get_block_keep_ptr

loader_burst_end
}

}
