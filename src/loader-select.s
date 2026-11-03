; The resident part of the loader:  picking the loader image that the load device
; needs, and swapping it into the loader slot.
;
; Every way of reading a file is a loader image (the KERNAL's CHRIN, the UCI, the
; C128's burst protocol, and ELoad for the SD2IEC):  a piece of code that is assembled
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

; how wide the screen is, for centering the note about the loader, and its color

!ifndef c128 {
	LOADER_NOTE_WIDTH = 40
	LOADER_NOTE_COLOR = DGRY
} else {
	LOADER_NOTE_WIDTH = 80
	LOADER_NOTE_COLOR = DCYN
}

!zone loader_select {

; picks the loader image for the load device and makes sure it's in the slot.
; trashes .A, .X and .Y.

loader_select_image
	!ifdef uci_loader_available {
		jsr can_load_dev_use_uci
	}

	bit loader_auto_enable
	bmi .auto

	lda #0							; the user wants CHRIN and nothing else
	sta load_device_can_use_uci
	beq .kernal						; (always)

.auto
	!ifdef uci_loader_available {
		lda #LOADER_IMAGE_UCI
		bit load_device_can_use_uci
		bmi .select
	}

	ldx load_device						; an SD2IEC is read with ELoad.  (what the device is
	lda loader_eload_state-8,x			; only has to be looked into once.)
	bne +
	jsr loader_detect_eload
	ldx load_device
	lda loader_eload_state-8,x
+	bmi .not_eload
	lda #LOADER_IMAGE_ELOAD
	bne .select							; (always)

.not_eload
	!ifdef c128 {
		ldx load_device					; (the burst loader is tried for every device,
		ldy loader_burst_state-8,x		; until one fails because it can't do burst)
		bmi .kernal
		lda #LOADER_IMAGE_BURST
		bne .select						; (always)
	}

.kernal
	lda #LOADER_IMAGE_KERNAL

.select
	cmp loader_active_image
	bne loader_swap_in_image
rts

; opens the file that's about to be loaded, whose name is in string_buffer, with the
; loader image that loader_select_image picked.  returns .C = 1 if it didn't work.
; if the burst loader or ELoad can't open it, whether the device doesn't do burst or
; for some other reason (the drive only does burst on PRG and SEQ files, for one), then
; this tries again with the KERNAL image, so that it's the KERNAL that has the say
; about whether there's a file.  a device that can't do burst at all is marked, so
; that the burst loader won't be tried for it again.

loader_open_file
	jsr .try
	bcc .opened

	ldx loader_active_image
	cpx #LOADER_IMAGE_ELOAD
	beq .retry

	!ifndef c128 {
		bne .failed						; (always:  nothing else has a fallback)
	} else {
		cpx #LOADER_IMAGE_BURST
		bne .failed

		cmp #BURST_ERR_NOT_BURST
		bne .retry
		ldx load_device
		lda #$80
		sta loader_burst_state-8,x
	}

.retry
	lda #LOADER_IMAGE_KERNAL
	jsr loader_swap_in_image
	jsr .try
	bcc .opened

.failed
	sec
.opened
	rts

.try
	clc
	lda file_to_load_name_len
	ldx #<string_buffer
	ldy #>string_buffer+1
jmp loader_open

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

; says on the bottom line of the loader screen, in the middle, which loader image is
; reading the file.  the UCI loader reads a small file so quickly that nobody could
; read the line, so it's left out for that, unless the file is at least 1024 blocks.
; trashes .A, .X and .Y.

loader_show_backend
	ldx loader_active_image
	!ifdef uci_loader_available {
		cpx #LOADER_IMAGE_UCI
		bne +
		lda file_to_load_size+1
		cmp #4
		bcs +
		rts
	+
	}

	lda #<loader_msg_kernal
	sta temp_abs_x
	lda #>loader_msg_kernal
	sta temp_abs_y
	!ifdef uci_loader_available {
		cpx #LOADER_IMAGE_UCI
		bne +
		lda #<loader_msg_uci
		sta temp_abs_x
		lda #>loader_msg_uci
		sta temp_abs_y
	+
	}
	!ifdef c128 {
		cpx #LOADER_IMAGE_BURST
		bne +
		lda #<loader_msg_burst
		sta temp_abs_x
		lda #>loader_msg_burst
		sta temp_abs_y
	+
	}
	cpx #LOADER_IMAGE_ELOAD
	bne +
	lda #<loader_msg_eload
	sta temp_abs_x
	lda #>loader_msg_eload
	sta temp_abs_y
	+

	ldx #24
	ldy #0
	clc
	jsr PLOT

	lda #LOADER_NOTE_COLOR
	jsr CHROUT

	lda #LOADER_NOTE_WIDTH
	ldx temp_abs_x
	ldy temp_abs_y
	jsr center_string				; (that prints as many cursor-RIGHTs as it takes)

	lda #0
	ldx temp_abs_x
	ldy temp_abs_y
	sec
jmp print_msg

; finds out whether the load device is an SD2IEC (or a uIEC, which has the same
; firmware), and puts 1 or $80 in its place in loader_eload_state.  that's the only
; kind of device that ELoad can read from, and any other kind would leave the machine
; waiting forever for an answer, so this has to be sure, and has to do no harm to a
; device that it's wrong about.
;
; a plain "X" is sent first.  on an SD2IEC that's the command that reports the extended
; settings, and the reply starts with 03.  a Commodore drive, or a CMD one, doesn't
; know it and says "31,SYNTAX ERROR", which is all that happens to it.  only if the
; reply is 03 is "UI" sent, which is what the SD2IEC's documentation says to use to
; recognize it:  the reply has "IEC" in it (SD2IEC, uIEC).  on an SD2IEC, UI only sets
; that message and changes nothing else, the current directory included.  on any other
; device it's a reset, which is why it's only sent to one that has answered with 03.
; trashes .A, .X and .Y, and the load buffer, which isn't in use yet.

loader_detect_eload
	ldx load_device
	lda #$80
	sta loader_eload_state-8,x			; (until it's seen to be one)

	lda #1
	ldx #<.cmd_x
	ldy #>.cmd_x
	jsr .dos_query
	bcs .detect_done

	lda load_buffer						; the reply starts with "03"
	cmp #"0"
	bne .detect_done
	lda load_buffer+1
	cmp #"3"
	bne .detect_done

	lda #2
	ldx #<.cmd_ui
	ldy #>.cmd_ui
	jsr .dos_query
	bcs .detect_done

	ldy #0								; and this one has "IEC" in it somewhere
-	lda load_buffer,y
	cmp #"i"
	bne +
	lda load_buffer+1,y
	cmp #"e"
	bne +
	lda load_buffer+2,y
	cmp #"c"
	beq .is_sd2iec
+	iny
	cpy #30
	bcc -

.detect_done
	rts

.is_sd2iec
	ldx load_device
	lda #1
	sta loader_eload_state-8,x
	rts

.cmd_x	!text "x"
.cmd_ui	!text "ui"

; sends a command over the command channel of the load device, and reads the reply
; into load_buffer, through the carriage return, or 32 bytes.  enter with .A = the
; length of the command and .X/.Y = its address.  returns .C = 1 if that didn't work.

.dos_query
	jsr SETNAM
	lda #15
	ldx load_device
	tay									; (secondary address 15, as well)
	jsr SETLFS
	jsr OPEN
	bcs .query_failed
	lda STATUS
	bne .query_failed

	ldx #15
	jsr CHKIN
	bcs .query_failed

	ldy #0
-	jsr CHRIN
	sta load_buffer,y
	iny
	cmp #13
	beq .query_done
	lda STATUS							; (stop at no device, or a time-out)
	and #%10000011
	bne .query_done
	cpy #32
	bcc -

.query_done
	lda #15
	jsr CLOSE
	jsr CLRCH
	clc
	rts

.query_failed
	lda #15
	jsr CLOSE
	jsr CLRCH
	sec
	rts

; the offsets of the images from loader_images_start, in the order of the
; LOADER_IMAGE_* numbers.

loader_image_table
	!word 0
	!word loader_standard_image - loader_images_start
	!ifdef uci_loader_available {
		!word loader_uci_image - loader_images_start
	} else {
		!word 0
	}
	!ifdef c128 {
		!word loader_burst_image - loader_images_start
	} else {
		!word 0
	}
	!word loader_eload_image - loader_images_start

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
