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


; Test the user's KERNAL/drive combo, see if we can use the STOP wedge loader

test_loader_compatibility
	ldx load_device
	lda loader_compatibility_table-8,x	; if the device's record is non-zero,
	beq +								; then we already tested it.
	rts

+	clc
	jsr draw_mini_popup

	lda #0
	ldx #<drive_loader_check_msg
	ldy #>drive_loader_check_msg
	jsr print_msg_rle

test_file_start_addr = load_buffer + $0400

test_loader_compatibility_no_popup
	ldx load_device
	lda #$60							; assume we can't use the STOP wedge
	sta loader_compatibility_table-8,x	; until proven otherwise.

	ldx #0								; back-up the string buf, as it holds
-	lda string_buffer,x					; the to-be-loaded MOD filename.
	sta string_buffer_backup,x
	beq +
	inx
	cpx #48
	bne -

	jsr get_free_disk_space

	lda tempzp_d						; Is there at least one block free?
	ora tempzp_d+1						; If not, assume the drive is not
	bne +								; compatible, since we can't test it.
	rts

+	lda #$64							; use the load buffer as scratch
	ldx #0								; space to generate the test file
-	sta test_file_start_addr,x
	dex
	bne -

	jsr scratch_test_file				; save it, overwrite if needed
	jsr save_test_file
	bcc +								; error? assume drive is incompatible
	rts									; since it means the test is invalid

+	lda #0								; zero-out the area
	ldx #0
-	sta test_file_start_addr,x
	dex
	bne -

	lda STOP_vec						; now try to use STOP wedge to load
	sta old_STOP_vec					; the test file
	lda STOP_vec+1
	sta old_STOP_vec+1

	lda #<mark_test_load
	sta STOP_vec
	lda #>mark_test_load
	sta STOP_vec+1

	lda #11
	ldx #<test_filename
	ldy #>test_filename
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
	ldx #<test_file_start_addr
	ldy #>test_file_start_addr

	jsr LOAD
	bcc +

	ldx load_device						; load error? mark the drive as
	lda #$60							; incompatible since we can't trust
	sta loader_compatibility_table-8,x	; the result of the load.

+	jsr RESTOR
	jsr scratch_test_file

	ldx #0								; restore the string buffer from its
-	lda string_buffer_backup,x			; backup.
	sta string_buffer,x
	beq +
	inx
	cpx #48
	bne -

+	!ifdef c128 {
		jsr set_window_full_screen
	}
rts

; If this wedge triggers, we can mark the drive as compatible.  Yeah, it'll
; keep overwriting that entry, but big deal, it's only a one-block file. 😛

mark_test_load
	ldx load_device
	lda #$80
	sta loader_compatibility_table-8,x
jmp (old_STOP_vec)
 

save_test_file
	lda #11
	ldx #<test_filename
	ldy #>test_filename
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

	lda #<test_file_start_addr
	sta save_addr
	lda #>test_file_start_addr
	sta save_addr+1

	lda #save_addr
	ldx #<(test_file_start_addr+253)	; exactly one disk block (has to be
	ldy #>(test_file_start_addr+253)	; at least that big or BURST protocol
	jsr SAVE							; won't allow STOP wedge to run).
rts

scratch_test_file
	ldx #0
-	lda test_filename,x
	sta string_buffer+3,x
	beq +
	inx
	bne -
+	lda #"s"
	sta string_buffer
	lda #"0"
	sta string_buffer+1
	lda #":"
	sta string_buffer+2

	clc
	lda #14
	ora #$80 ; tell the open function this needs to go to the command channel
	ldx #<string_buffer
	ldy #>string_buffer
	jsr open_file
	jsr close_file
rts

test_filename
	!text "mp-test.bin",0
