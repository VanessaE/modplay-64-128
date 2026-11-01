; Loader image for reading a file through the KERNAL, with CHRIN.  This works with
; anything that the KERNAL can talk to, which makes it the image for every device
; that has no faster way in.
;
; This is assembled to run from the loader slot (see modplay.s), but it's stored
; in the PRG (and then in expansion memory) as plain data, like the audio driver
; images, and fetched into place when the load device needs it.  Its entry jumps
; are described in loader-select.s.

!zone loader_standard {

loader_standard_image = *

!pseudopc loader_slot {

	jmp open_file
	jmp close_file
	jmp close_file
	jmp CHRIN
	jmp loader_standard_get_block
	jmp loader_standard_get_1kb

loader_standard_get_block
	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

loader_standard_get_block_keep_ptr
	ldy #0

-	jsr CHRIN
	sta (load_pointer),y
	iny
	bne -

	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2
  +
rts

loader_standard_get_1kb
	jsr loader_standard_get_block
	inc load_pointer+1
	jsr loader_standard_get_block_keep_ptr
	inc load_pointer+1
	jsr loader_standard_get_block_keep_ptr
	inc load_pointer+1
jmp loader_standard_get_block_keep_ptr

loader_standard_end
}

}
