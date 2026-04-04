; Mod file loader using standard CHRIN calls

!zone loader_standard {

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
	jsr loader_standard_get_block_keep_ptr
rts

}
