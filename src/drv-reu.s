; RAM driver for standard REU

reu_fetch_byte
	; code here
	rts

reu_stash_byte
	; code here
	rts

reu_fetch_row
	; code here
	rts

reu_stash_block

	!ifdef c128 {
		jsr c128_set_1mhz_mode
	}

	lda #<load_buffer
	sta DMA_ADL
	lda #>load_buffer
	sta DMA_ADH

	lda stash_pointer
	sta DMA_LO
	lda stash_pointer+1
	sta DMA_HI
	lda stash_pointer+2
	sta DMA_BANK

	lda #0
	sta DMA_DAL
	lda #4
	sta DMA_DAH

	lda #$90
	sta DMA_CMD

	!ifdef c128 {
		jsr c128_set_2mhz_mode
	}

rts


; This came from Codebase, author unknown
; https://codebase64.org/doku.php?id=base:reu_detect

	REUCOMMAND_STASH    = $90   ; immediately, no reload
	REUCOMMAND_FETCH    = $91   ; immediately, no reload

reu_get_size
		ldx #0  ; pre-init
		; first write signatures to banks in *descending* order (banks 255..0):
.wrlp	dex
		stx reu_banknum
		lda #<reu_signature_start
		ldx #>reu_signature_start
		ldy #REUCOMMAND_STASH
		jsr set_registers_AXY
		ldx reu_banknum
		bne .wrlp	; all banks written?

	; now check signatures in *ascending* order:
	; banknum just became zero so no need to init it
.rdlp	lda #<reu_sig_candidate_start
		ldx #>reu_sig_candidate_start
		ldy #REUCOMMAND_FETCH
		jsr set_registers_AXY
		; compare data
		ldx #8 ; signature length, minus 1
-			lda reu_sig_candidate_start, x
			cmp reu_signature_start, x
			bne failed
			dex
			bpl -
			; bank has correct signature
		inc reu_banknum ; next bank (== number of banks already found)
		bne .rdlp

	; there are actually 256 banks!
	sec
	lda reu_banknum
	jmp +
 
	failed
		clc
		lda reu_banknum

	+	sta reu_num_banks		; if 0, REU not detected at all.
		lda #0
		rol
		sta reu_num_banks+1
	rts

set_registers_AXY ; setup REU registers (used for both reading and writing)
	; A/X: c64 address
	; Y: REU command
	sta DMA_ADL
	stx DMA_ADH
	ldx #0
	stx DMA_LO
	stx DMA_HI
	lda reu_banknum
	sta DMA_BANK
	lda #9 ; signature length
	sta DMA_DAL
	stx DMA_DAH
	sty DMA_CMD
rts

	!align 255,0,$ff

	; signature we write to REU banks, first byte is bank number
	reu_signature_start
	reu_banknum
		!text 0,"reutest!"
 
	; target buffer when reading signatures back from REU
	reu_sig_candidate_start
		!text $ff,"icanhaz?"; same length as above
