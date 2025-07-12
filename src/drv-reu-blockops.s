; RAM driver for standard REU, block operations

!text "reu driver, block ops",0,0,0

; the sequencer will look here (via a vector) to find the address and offsets
; into the fetch routine that it must use to do the self-mod stuff.

!zone reu_driver_block_ops {

reu_fetch_block
	lda expansion_transfer_local_addr
	sta DMA_ADL
	lda expansion_transfer_local_addr+1
	sta DMA_ADH

	lda expansion_memory_target_pointer
	sta DMA_LO
	lda expansion_memory_target_pointer+1
	sta DMA_HI
	lda expansion_memory_target_pointer+2
	sta DMA_BANK

	lda stash_size
	sta DMA_DAL
	lda stash_size+1
	sta DMA_DAH
	lda #$91

	!ifdef c128 {
		!ifndef scpu {
			dec VIC_2_MHZ
		}
	}

	sta DMA_CMD

	!ifdef c128 {
		!ifndef scpu {
			sta VIC_2_MHZ
		}
	}
rts

reu_stash_block
	lda expansion_transfer_local_addr
	sta DMA_ADL
	lda expansion_transfer_local_addr+1
	sta DMA_ADH

	lda expansion_memory_target_pointer
	sta DMA_LO
	lda expansion_memory_target_pointer+1
	sta DMA_HI
	lda expansion_memory_target_pointer+2
	sta DMA_BANK

	lda stash_size
	sta DMA_DAL
	lda stash_size+1
	sta DMA_DAH

	lda #$90

	!ifdef c128 {
		!ifndef scpu {
			sta VIC_2_MHZ
		}
	}

	sta DMA_CMD

	!ifdef c128 {
		!ifndef scpu {
			inc VIC_2_MHZ
		}
	}
rts

; This came from Codebase, author unknown
; https://codebase64.org/doku.php?id=base:reu_detect

REUCOMMAND_STASH    = $90   ; immediately, no reload
REUCOMMAND_FETCH    = $91   ; immediately, no reload

reu_get_size
	!ifdef c128 {
		!ifndef scpu {
			dec VIC_2_MHZ
		}
	}

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
-			lda reu_sig_candidate_start, x
		cmp reu_signature_start, x
		bne .failed
		dex
		bpl -
		; bank has correct signature
	inc reu_banknum ; next bank (== number of banks already found)
	bne .rdlp

	ldx reu_banknum
	jmp +

.failed
	clc
	ldx reu_banknum

+	dex
	stx reu_highest_bank		; if 0, REU not detected at all.

	!ifdef c128 {
		!ifndef scpu {
			inc VIC_2_MHZ
		}
	}
rts

set_registers_AXY ; setup REU registers (used for both reading and writing in size test only)
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
}

; signature we write to REU banks, first byte is bank number
reu_signature_start
reu_banknum
	!text 0,"reutest!"

; target buffer when reading signatures back from REU
reu_sig_candidate_start
	!text $ff,"icanhaz?"; same length as above
