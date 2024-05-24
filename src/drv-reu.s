; RAM driver for standard REU

reu_fetch_byte
	; code here
	rts

reu_stash_byte
	; code here
	rts

reu_stash_block
	; code here
	rts

reu_fetch_row
	; code here
	rts

; This came from Codebase, author unknown
; https://codebase64.org/doku.php?id=base:reu_detect

reu_get_size
	REUCOMMAND_STASH    = $90   ; immediately, no reload
	REUCOMMAND_FETCH    = $91   ; immediately, no reload

		; returns:
		;   Carry = 0, A = 0    NO REU detected
		;   Carry = 1, A = 0    256 Banks (16MB)
		;   else Carry = 0, A = number of RAM banks found in REU

	detect_capacity
		ldx #0  ; pre-init
		; first write signatures to banks in *descending* order (banks 255..0):
----		dex
			stx reu_banknum
			lda #<reu_signature_start
			ldx #>reu_signature_start
			ldy #REUCOMMAND_STASH
			jsr set_registers_AXY
			; all banks written?
			ldx reu_banknum
			bne ----
		; now check signatures in *ascending* order:
		; banknum just became zero so no need to init it
----		lda #<reu_sig_candidate_start
			ldx #>reu_sig_candidate_start
			ldy #REUCOMMAND_FETCH
			jsr set_registers_AXY
			; compare data
			ldx #REU_SIGNATURE_LENGTH_LOW - 1
--				lda reu_sig_candidate_start, x
				cmp reu_signature_start, x
				bne failed
				dex
				bpl --
			; bank has correct signature
			inc reu_banknum ; next bank (== number of banks already found)
			bne ----
		; there are actually 256 banks!
		sec
		lda reu_banknum
		rts
 
	failed
		clc
		lda reu_banknum
		rts

set_registers_AXY ; setup REU registers (used for both reading and writing)
	; A/X: c64 address
	; Y: REU command
	sta DMA_ADL
	stx DMA_ADHhi
	ldx #0
	stx DMA_LO
	stx DMA_HI
	lda reu_banknum
	sta DMA_BANK
	lda #REU_SIGNATURE_LENGTH_LOW
	sta DMA_DAL
	stx DMA_DAH
	sty DMA_CMD
	rts


	!align 256,0,0

	; signature we write to REU banks, first byte is bank number
	reu_signature_start
	reu_banknum		!byte 0,$10,$20,$30,$40,$50,$60,$70,$7f
	REU_SIGNATURE_LENGTH_LOW = * - reu_signature_start
 
	; target buffer when reading signatures back from REU
	reu_sig_candidate_start
		!byte $ff,$f0,$e0,$d0,$c0,$b0,$a0,$90,$80   ; must be same length as signature above, obviously
	reu_sig_candidate_end
	REU_SIGNATURE_LENGTH_LOW = * - reu_sig_candidate_start
