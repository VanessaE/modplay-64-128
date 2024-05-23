  	.exportzp src, dest, backptr
	.export destlen
	.export bp_read


	.importzp ptr1, ptr2, tmp1


	.zeropage

src		= ptr1		; borrow cc65's temp pointers
dest		= ptr2
backptr		= tmp1		; oof...


	.bss

destlen:	.res 2		; number of bytes written


	.code

; read a byte and increment source pointer
bp_read:
	lda (src),y
	inc src
	bne :+
	inc src + 1
:	rts
