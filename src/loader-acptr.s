; load a file using the regular ACPTR call

; Basically, the old method of loading files, via sequential access.  This
; uses a 1280-byte (5-page) buffer. A 1541 with JiffyDOS loads at around 2kB/s
; this way.

; loader_common leaves the file open after the header has been loaded, so
; just use it directly.

load_via_acptr
	lda #0
	sta stash_size
	lda #5
	sta stash_size+1

	+JSR_INDIRECT (stash_block_vec) ; stash the header that loader_common grabbed

	lda stash_size+1
	sta stash_pointer+1

.next_block
	lda #0
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1
	ldy #0

-	lda STATUS
	bne .done

	jsr ACPTR
	sta (load_pointer),y
	iny
	bne -
	inc load_pointer+1
	lda load_pointer+1
	cmp #>load_buffer_end		; load buffer full?
	bne -

	+JSR_INDIRECT (stash_block_vec)

	clc
	lda stash_pointer+1
	adc stash_size+1
	sta stash_pointer+1
	bcc +
	inc stash_pointer+2

+	jsr update_progress
	jmp .next_block

.done
	jsr close_file
	+JSR_INDIRECT (stash_block_vec) ; last-loaded block

	lda file_size_in_kb
	sta current_file_size_in_kb
	lda file_size_in_kb+1
	sta current_file_size_in_kb+1

	ldy #0
-	lda string_buffer,y
	sta current_file_name,y
	beq acptr_exit
	iny
	cpy #16
	bne -

acptr_exit
rts

