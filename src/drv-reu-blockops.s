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

	+C128_DEC_CLOCK_FOR_REU
	sta DMA_CMD
	+C128_STA_CLOCK_FOR_REU
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

	+C128_STA_CLOCK_FOR_REU
	sta DMA_CMD
	+C128_INC_CLOCK_FOR_REU
rts

}
