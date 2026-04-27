; RAM driver for standard REU, block operations

; the sequencer will look here (via a vector) to find the address and offsets
; into the fetch routine that it must use to do the self-mod stuff.

!zone reu_driver_block_ops {

reu_fetch_block
	lda expansion_transfer_local_addr
	sta DMA_LOCAL_LO
	lda expansion_transfer_local_addr+1
	sta DMA_LOCAL_HI

	lda expansion_memory_target_pointer
	sta DMA_EXTERNAL_LO
	lda expansion_memory_target_pointer+1
	sta DMA_EXTERNAL_HI
	lda expansion_memory_target_pointer+2
	sta DMA_EXTERNAL_BANK

	lda stash_size
	sta DMA_LENGTH_LO
	lda stash_size+1
	sta DMA_LENGTH_HI

	lda #$91

	+C128_2MHZ_OFF_FOR_REU
	sta DMA_CMD
	+C128_2MHZ_ON_FOR_REU
rts

reu_stash_block
	lda expansion_transfer_local_addr
	sta DMA_LOCAL_LO
	lda expansion_transfer_local_addr+1
	sta DMA_LOCAL_HI

	lda expansion_memory_target_pointer
	sta DMA_EXTERNAL_LO
	lda expansion_memory_target_pointer+1
	sta DMA_EXTERNAL_HI
	lda expansion_memory_target_pointer+2
	sta DMA_EXTERNAL_BANK

	lda stash_size
	sta DMA_LENGTH_LO
	lda stash_size+1
	sta DMA_LENGTH_HI

	lda #$90

	+C128_2MHZ_OFF_FOR_REU
	sta DMA_CMD
	+C128_2MHZ_ON_FOR_REU
rts

; This came from Codebase, author unknown
; https://codebase64.org/doku.php?id=base:reu_detect

REUCOMMAND_STASH    = $90   ; immediately, no reload
REUCOMMAND_FETCH    = $91   ; immediately, no reload

reu_get_size
	+C128_2MHZ_OFF_FOR_REU

	ldx #0  ; pre-init
	; first write signatures to banks in *descending* order (banks 255..0):
.wrlp
	dex
	stx reu_banknum
	lda #<reu_signature_start
	ldx #>reu_signature_start
	ldy #REUCOMMAND_STASH
	jsr set_registers_AXY
	ldx reu_banknum
	bne .wrlp	; all banks written?

; now check signatures in *ascending* order:
; banknum just became zero so no need to init it
.rdlp
	lda #<reu_sig_candidate_start
	ldx #>reu_sig_candidate_start
	ldy #REUCOMMAND_FETCH
	jsr set_registers_AXY
	; compare data
	ldx #8 ; signature length, minus 1
	-	lda reu_sig_candidate_start, x
		cmp reu_signature_start, x
		bne .failed
		dex
		bpl -
		; bank has correct signature
	inc reu_banknum ; next bank (== number of banks already found)
	bne .rdlp

	ldx reu_banknum
	dex
	jmp +

.failed
	clc
	ldx reu_banknum
	beq +
	dex

+	stx reu_highest_bank		; if 0, REU not detected at all.

	+C128_2MHZ_ON_FOR_REU
rts

set_registers_AXY ; setup REU registers (used for both reading and writing in size test only)
	; A/X: c64 address
	; Y: REU command
	sta DMA_LOCAL_LO
	stx DMA_LOCAL_HI
	ldx #0
	stx DMA_EXTERNAL_LO
	stx DMA_EXTERNAL_HI
	lda reu_banknum
	sta DMA_EXTERNAL_BANK
	lda #9 ; signature length
	sta DMA_LENGTH_LO
	stx DMA_LENGTH_HI
	sty DMA_CMD
rts
}

; signature we write to REU banks, first byte is bank number
reu_signature_start
reu_banknum
	!text 0,"reutest!"

; target buffer when reading signatures back from REU
reu_sig_candidate_start
	!text $ff,"icanhaz?"; same length as above

reu_not_found_msg
	!text LOWER,CLR,"No REU found!",RETURN,RETURN,0

!align 255,0,0
