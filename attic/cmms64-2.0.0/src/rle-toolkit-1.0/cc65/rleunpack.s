

	.export _rle_unpack, rle_unpack


	.import rle_store, rle_read
	.importzp src, dest
	.import lastbyte
	.import destlen

	.import popax


	.code


; cc65 interface to rle_unpack
; unsigned int __fastcall__ rle_unpack(unsigned char *dest, unsigned char *src);
_rle_unpack:
	sta src			; save src arg
	stx src + 1
	jsr popax		; get dest arg
	sta dest
	stx dest + 1
	jsr rle_unpack		; execute
	lda destlen		; return length
	ldx destlen + 1
	rts


; unpack a run length encoded stream
rle_unpack:
	ldy #0
	sty destlen		; reset byte counter
	sty destlen + 1
	jsr rle_read		; read the first byte
	sta lastbyte		; save as last byte
	jsr rle_store		; store
@unpack:
	jsr rle_read		; read next byte
	cmp lastbyte		; same as last one?
	beq @rle		; yes, unpack
	sta lastbyte		; save as last byte
	jsr rle_store		; store
	jmp @unpack		; next
@rle:
	jsr rle_read		; read byte count
	tax
	beq @end		; 0 = end of stream
	lda lastbyte
@read:
	jsr rle_store		; store X bytes
	dex
	bne @read
	beq @unpack		; next
@end:
	rts
