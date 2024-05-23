; Routines for packing and unpacking run length encoded byte streams
;
; When two or more consecutive bytes are identical, they are replaced by
; <BYTE> <BYTE> <COUNT>. A COUNT of 0 indicates End Of Stream. A COUNT
; of 1 indicates that two bytes should be written, a COUNT of 2 indicates
; three bytes, and so on.


  	.export rle_read, rle_store
  	.exportzp src, dest
	.export lastbyte
	.export destlen


	.importzp ptr1, ptr2


	.zeropage

src		= ptr1		; borrow cc65's temp pointers
dest		= ptr2


	.bss

lastbyte:	.res 1		; last byte read
destlen:	.res 2		; number of bytes written


	.code


; read a byte and increment source pointer
rle_read:
	lda (src),y
	inc src
	bne :+
	inc src + 1
:	rts


; write a byte and increment destination pointer
rle_store:
	sta (dest),y
	inc dest
	bne :+
	inc dest + 1
:	inc destlen
	bne :+
	inc destlen + 1
:	rts
