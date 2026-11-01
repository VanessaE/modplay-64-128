; The resident part of the loader:  picking the loader image that the load device
; needs, and swapping it into the loader slot.
;
; Every way of reading a file is a loader image:  a piece of code that is assembled
; to run from loader_slot (see modplay.s), and that starts with six entry jumps.
; Those are the only way in:
;
;	loader_open			open the file.  enter as for open_file, and .C = 1 on return
;						if it didn't work
;	loader_close		close it, when the load is given up halfway
;	loader_done			close it, when the load is finished
;	loader_get_one_byte	get one byte of the file, in .A
;	loader_get_block	read 256 bytes of the file to load_buffer
;	loader_get_1kb		read 1024 bytes of the file to load_buffer
;
; The images are in under-kernal.s, as plain data after the audio driver images.
; Init stashes them in expansion memory, in the pages that the booter sets aside
; for them (EXP_LOADER_PAGES, just in front of the audio driver images), and
; loader_select_image fetches the one it wants whenever that isn't already the
; one in the slot.  Nothing in an image may call the swap, or anything else that
; replaces the image.

!zone loader_select {

; picks the loader image for the load device and makes sure it's in the slot.
; trashes .A, .X and .Y.

loader_select_image
	!ifdef uci_loader_available {
		jsr can_load_dev_use_uci
		lda #LOADER_IMAGE_KERNAL
		bit load_device_can_use_uci
		bpl +
		lda #LOADER_IMAGE_UCI
	  +
	} else {
		lda #LOADER_IMAGE_KERNAL
	}

	cmp loader_active_image
	bne loader_swap_in_image
rts

; fetches loader image number .A (LOADER_IMAGE_*) into the slot.

loader_swap_in_image
	sta loader_active_image
	asl
	tax							; (the table has a dummy entry for image 0)

	lda #<loader_slot
	sta expansion_transfer_local_addr
	lda #>loader_slot
	sta expansion_transfer_local_addr+1

	lda #0
	sta expansion_transfer_local_addr+2
	sta expansion_memory_target_pointer+2
	sta stash_size
	lda #>LOADER_SLOT_SIZE
	sta stash_size+1

	lda loader_image_table,x
	sta expansion_memory_target_pointer

	sec
	lda exp_file_data_start_page
	sbc #EXP_AUDIO_DRIVER_PAGES + EXP_LOADER_PAGES
	clc
	adc loader_image_table+1,x
	sta expansion_memory_target_pointer+1
jmp fetch_block_vec

; the offsets of the images from loader_images_start, in the order of the
; LOADER_IMAGE_* numbers.

loader_image_table
	!word 0
	!word loader_standard_image - loader_images_start
	!ifdef uci_loader_available {
		!word loader_uci_image - loader_images_start
	}

!ifdef uci_loader_available {

UCI_IDENTIFIER			= $C9
CMD_PUSH_CMD			= $01
CMD_NEXT_DATA			= $02
CMD_ABORT				= $04
CMD_ERROR				= $08

CMD_STATE_BITS			= $30
CMD_STATE_BUSY			= $10
CMD_STATE_MORE_DATA		= $30

UCI_TARGET				= $05
UCI_CMD_OPEN			= $13
UCI_CMD_CLOSE			= $14
UCI_CMD_CHKIN			= $15

; sets load_device_can_use_uci to $80 if the load device is the Ultimate's, or to
; 0 if not.

can_load_dev_use_uci
	pha
	lda UCI_CMD_IF_COMMAND
	cmp #UCI_IDENTIFIER
	bne +

	lda load_device
	cmp UCI_OUR_DEVICE
	bne +

	lda #$80
	sta load_device_can_use_uci
	pla
	rts

+	lda #0
	sta load_device_can_use_uci
	pla
rts
}

}
