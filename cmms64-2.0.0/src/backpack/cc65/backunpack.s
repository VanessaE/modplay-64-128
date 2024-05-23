

	.export _back_unpack, back_unpack


	.importzp src, dest, backptr
	.import destlen
	.import bp_read

	.import popax


	.code


; cc65 interface to back_unpack
; unsigned int __fastcall__ back_unpack(unsigned char *dest, unsigned char *src);
_back_unpack:
	sta src			; save src arg
	stx src + 1
	jsr popax		; get dest arg
	sta dest
	stx dest + 1
	sta destlen		; save original dest
	stx destlen + 1
	jsr back_unpack		; execute
	lda dest
	sec
	sbc destlen
	sta destlen
	lda dest + 1
	sbc destlen + 1
	sta destlen + 1
	tax
	lda destlen		; return length
	rts


; unpack backpacked data
back_unpack:
	ldy #0
	jsr bp_read		; read command byte
	cmp #$00		; update flags
	bmi @literal		; msb means literal run
	beq @done		; 0 means eof

; back reference, length - 2 in A
	clc 			; put length + 2 in X
	adc #2
	tax

	jsr bp_read		; read offset byte

	; inc dest len

	clc 			; backptr = dest - 256 + offset
	adc dest
	sta backptr
	ldy dest + 1
	bcs :+
	dey
:	sty backptr + 1

	ldy #0			; copy forwards to handle overlaps
:	lda (backptr),y
	sta (dest),y
	iny
	dex
	bne :-

	dey			; put count - 1 in A
	tya
	pha
	bne @incdest		; jump to increment dest ptr

@done:
	rts

; literal run, length - 1 in A with msb set
@literal:
	and #$7f		; mask msb
	tay 			; use as counter

	pha			; save for later

@copy:
	lda (src),y
	sta (dest),y
	dey
	bpl @copy

	pla			; add length to src pointer
	pha
	sec
	adc src
	sta src
	bcc :+
	inc src + 1
:
@incdest:
	pla			; add length to dest pointer
	sec
	adc dest
	sta dest
	bcc :+
	inc dest + 1
:
	jmp back_unpack		; back to main loop
