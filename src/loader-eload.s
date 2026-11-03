; Loader image for reading a file from an SD2IEC, with ELoad.
;
; ELoad is a fast protocol for reading a file, which the SD2IEC (and the uIEC, which
; has the same firmware) does by itself:  the machine opens the file with an ordinary
; command, then "uploads" a short tag with M-W and M-E, that the firmware recognizes
; as ELoad's, and from then on the device sends the file's bytes with a two-bit
; protocol that the machine clocks.  There's no sector buffer:  each byte is read as
; it's wanted, but the blocks that the player works in are read from it in a loop.
;
; All of the protocol, and the code that goes with it, is the Covert Bitops
; Loadersystem's (see src/bitops).  It's assembled separately with DASM into
; src/bitops/bitops-eload.o, which is $200 bytes that go on the end of this image,
; $100 bytes into the slot.  What's here is only the entry points, which have the
; jobs that the loader slot gives them (see loader-select.s), and the CPU speed,
; which ELoad needs to be 1 MHz, as it counts cycles.
;
; Nothing but the SD2IEC family can be read with this, and a machine that's reading
; from anything else would hang waiting for it.  loader_select_image makes sure of
; what the device is before it picks this image.
;
; This is assembled to run from the loader slot (see modplay.s), but it's stored in
; the PRG (and then in expansion memory) as plain data, like the audio driver images.

!zone loader_eload {

; where the entry points of the DASM-built part are

eload_blob_open		= loader_slot + $100
eload_blob_get		= loader_slot + $103
eload_blob_close	= loader_slot + $106

; what the open returns for a file that couldn't be opened, or is empty.  nothing looks
; at it but the person reading the code.

ELOAD_ERR_OPEN = 4

loader_eload_image = *

!pseudopc loader_slot {

	jmp eload_open
	jmp eload_close
	jmp eload_close
	jmp eload_get_byte
	jmp eload_get_block
	jmp eload_get_1kb

eload_saved_i		!byte 0		; the interrupt flag, as it was at the open

!ifdef c128 {
eload_saved_clock	!byte 0		; the C128's CPU clock setting, as it was at the open
}

; enter with .A = the length of the filename, .X/.Y = its address, and .C clear, as
; for open_file.  returns .C = 1 if the file couldn't be opened, with an error code
; in .A.  if it did work, interrupts are off until eload_close puts them back.  (the
; fast protocol has places where an interrupt would break it, and the C128's has a
; raster interrupt right where one of them is.)  the CPU is only at 1 MHz inside each
; of the entry points, and is put back as it was when they return, because the code
; that runs in between does DMA with the REU, which expects the clock as it found it.

eload_open
	jsr SETNAM						; the blob reads the name and the device from the
	lda load_device					; KERNAL's places for them
	sta FA
	lda #0
	sta STATUS

	php									; remember if interrupts were off already
	pla
	and #%00000100
	sta eload_saved_i
	sei

	jsr eload_speed_down
	jsr eload_blob_open
	php
	jsr eload_speed_up
	plp
	beq .failed

	clc
	rts

.failed
	jsr eload_restore_i				; (the blob has done the rest of the cleaning up)
	lda #ELOAD_ERR_OPEN
	sec
	rts

; closes the file, both when it's been read to the end (and the drive is done
; already) and when the load is given up in the middle.

eload_close
	jsr eload_speed_down
	jsr eload_blob_close
	jsr eload_speed_up
	jsr eload_restore_i
	clc
	rts

; interrupts back on, if they were on at the open.

eload_restore_i
	lda eload_saved_i
	bne +
	cli
+	rts

; ELoad counts cycles, so the CPU has to be at 1 MHz.  that isn't a problem on a
; stock machine, and the SuperCPU and the C128 get slowed down for it, for as long
; as one of the entry points is running.  (an Ultimate's speed is left as it is,
; because it's only changed for playing.)  these trash .A, and not .X or .Y, and each
; speed_down has to be followed by its speed_up.

eload_speed_down
	!ifdef scpu {
		bit SCPU_PRESENT
		bmi +
		sta SCPU_TURBO_OFF
	  +
	}
	!ifdef c128 {
		lda C128_VIC_CLOCK_SPEED
		sta eload_saved_clock
		lda #0
		sta C128_VIC_CLOCK_SPEED
	}
rts

eload_speed_up
	!ifdef c128 {
		lda eload_saved_clock
		sta C128_VIC_CLOCK_SPEED
	}
	!ifdef scpu {
		bit SCPU_PRESENT
		bmi +
		sta SCPU_TURBO_ON
	  +
	}
rts

; gets the next byte of the file, in .A, and sets STATUS to $40 when it's the last.
; past the end of the file it returns zeros, and the same STATUS.  preserves .X and
; .Y.

eload_get_byte
	jsr eload_speed_down
	jsr eload_blob_get
	php									; (.C says whether it was the last)
	pha
	jsr eload_speed_up
	pla
	plp
	bcc +
	pha
	lda #$40
	sta STATUS
	pla
+
rts

; reads 256 bytes of the file to load_buffer, or from where load_pointer is, for the
; one that's called for the later pages of a bigger read.  if the file ends in the
; middle of it, the rest is zeros, and STATUS is set as for eload_get_byte.

eload_get_block
	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

eload_get_block_keep_ptr
	jsr eload_speed_down
	ldy #0

.block_byte
	jsr eload_blob_get
	sta (load_pointer),y
	bcs .block_over					; (that was the last byte, or the file was over)
	iny
	bne .block_byte
	beq .block_done					; (always)

.block_over
	lda #$40
	sta STATUS
	iny
	beq .block_done
	lda #0
-	sta (load_pointer),y
	iny
	bne -

.block_done
	jsr eload_speed_up
	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2
  +
rts

eload_get_1kb
	jsr eload_get_block
	inc load_pointer+1
	jsr eload_get_block_keep_ptr
	inc load_pointer+1
	jsr eload_get_block_keep_ptr
	inc load_pointer+1
jmp eload_get_block_keep_ptr

; (the code above has to end before the DASM-built part)

	!if * - loader_slot > $100 {
		!error "The ELoad entry points are too big for their page by ", * - loader_slot - $100, " bytes!"
	}
	!fill loader_slot + $100 - *, 0

	!binary "src/bitops/bitops-eload.o", $200

loader_eload_end

}

}
