; Load a file using the KERNAL's LOAD call, exploiting the "STOP wedge" trick

; this causes the KERNAL to do most of the hard work, resulting in faster data
; transfer.  Of particular importance is that on the C128, it uses BURST mode
; on 1571, 1581, and later devices.  A 1571 can do 3.6 kB/sec with a disk
; sector interleave of 5.  A CMD HD can do about 9 kB/sec.  We use a load
; buffer of exactly 5 disk blocks (so 1270/$04f6 bytes) as BURST mode loads
; whole blocks at a time and we need to make sure the whole file header is
; loaded in one go.

load_via_stop_wedge
	jsr close_file ; loader_common leaves the file open but we don't need that.

	lda STOP_vec
	sta old_STOP_vec
	lda STOP_vec+1
	sta old_STOP_vec+1

	lda #<fill_load_buffer
	sta STOP_vec
	lda #>fill_load_buffer
	sta STOP_vec+1

	lda file_to_load_name_len
	ldx #<string_buffer
	ldy #>string_buffer+1
	jsr SETNAM

	!ifdef c128 {
		lda #0
		ldx #0
		jsr SETBNK
	}

	lda #0
	ldx load_device
	ldy #0
	jsr SETLFS

	lda #0
	ldx #2					; start loading at load_buffer + 2, so that we don't
	ldy #>load_buffer		; lose the first two bytes (KERNAL LOAD will discard
	jsr LOAD				; them)

	jsr RESTOR

	+JSR_INDIRECT (stash_block_vec) ; don't forget to stash the last-loaded block

	lda file_size_in_kb
	sta current_file_size_in_kb
	lda file_size_in_kb+1
	sta current_file_size_in_kb+1

	ldy #0
-	lda string_buffer,y
	sta current_file_name,y
	beq stop_wedge_exit
	iny
	cpy #16
	bne -

stop_wedge_exit
rts

fill_load_buffer				; STOP vector enters here after a byte is loaded
	lda EAL+1
	cmp #>load_buffer_end		; load buffer full?
	bne .not_full

; if the load comes from a BURST-capable drive, then it won't ever be exactly
; the size of the load buffer, but instead anything up to 6*254 bytes, so
; derive the actual byte count from EAL, and use THAT to push the expansion
; RAM pointer and stash size.

	sec
	lda EAL
	sbc #<load_buffer
	sta stash_size
	lda EAL+1 
	sbc #>load_buffer
	sta stash_size+1

	+JSR_INDIRECT (stash_block_vec)

	clc
	lda stash_pointer
	adc stash_size
	sta stash_pointer
	lda stash_pointer+1
	adc stash_size+1
	sta stash_pointer+1
	bcc +
	inc stash_pointer+2

+	lda #0
	sta EAL
	lda #>load_buffer
	sta EAL+1

	jsr update_progress
.not_full
	jmp (old_STOP_vec)
