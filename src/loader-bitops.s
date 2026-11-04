; Loader image for reading a file with the Bitops drive code.
;
; This is for the 1541, 1571, 1581 and the CMD FD and HD (see src/bitops).  Opening
; the file starts a small program in the drive, which reads the file by its name, and
; sends it a sector at a time with a protocol that the machine clocks.  The drive can't
; be used for anything else while that is running, so the program is started for every
; file, and quit when the file is closed or has been read.  (The drive then restarts
; itself, which takes a few seconds on a 1541, and the close waits for it.)
;
; All of the protocol, and the code that goes with it, is the Covert Bitops
; Loadersystem's.  It's assembled separately with DASM into src/bitops/bitops-drive.o
; (see bitops-drive.s there), which has two parts that go into this image:
;
;   the runtime, which reads from the drive code, and is in the slot with the entry
;   points that are here, $100 bytes into it.
;
;   the install part, which uploads the drive code and starts it, and is $380 bytes.
;   It doesn't fit in the slot, and is only used for the open, so it's stored after
;   the image, and loader_fetch_bitops_install (in loader-select.s) fetches it to
;   the load buffer, where it runs from, every time a file is opened.
;
; A sector is received in the page of the right audio buffer, because the load buffer
; is where the bytes of the file go.
;
; Nothing but a drive that the drive code has an entry for can be read with this, and
; the install part finds out whether it is one of those:  if it isn't, the open fails
; with BITOPS_ERR_NOT_FAST, which loader_open_file takes as the cue to use the KERNAL
; image, and not to try this one on the device again.
;
; This is assembled to run from the loader slot (see modplay.s), but it's stored in
; the PRG (and then in expansion memory) as plain data, like the audio driver images.

!zone loader_bitops {

; where the entry points of the DASM-built runtime are, and what its zero page is

bitops_rt_open		= loader_slot + $100
bitops_rt_get		= loader_slot + $103
bitops_rt_quit		= loader_slot + $106
bitops_rt_wait		= loader_slot + $109
bitops_rt_byte		= loader_slot + $10c

BITOPS_ZP			= $02			; (see src/bitops/bitops-drive.s)
BITOPS_ZP_SIZE		= 7
bitops_file_open	= BITOPS_ZP	; the first of them:  0 once the file is over

; the install part is in the load buffer, and its first byte is InitLoader.  its size
; and the offset of the runtime in the file are the same as in bitops-drive.s.

BITOPS_INSTALL_SIZE	= $380
BITOPS_RUNTIME_OFFSET	= $600

; what the open returns for a file that couldn't be opened, or is empty.  (the one for
; a device that can't be started is in constants-com.h.)

BITOPS_ERR_OPEN = 4

loader_bitops_image = *

!pseudopc loader_slot {

	jmp bitops_open
	jmp bitops_close
	jmp bitops_close
	jmp bitops_get_byte
	jmp bitops_get_block
	jmp bitops_get_1kb

bitops_saved_i		!byte 0				; the interrupt flag, as it was at the open
bitops_name_len		!byte 0				; the name of the file, until the open is done
bitops_name_ptr		!word 0
bitops_tries		!byte 0				; how many times the drive code has been asked for the file
bitops_saved_zp		!fill BITOPS_ZP_SIZE, 0	; the zero page that the runtime uses

; enter with .A = the length of the filename, .X/.Y = its address, and .C clear, as
; for open_file.  returns .C = 1 if the file couldn't be opened, with an error code
; in .A.  if it did work, interrupts are off until bitops_close puts them back (the
; protocol has places where an interrupt would break it).  the CPU is only at 1 MHz
; inside each of the entry points, and is put back as it was when they return, as for
; ELoad.
;
; the drive code is started, and asked for the file.  now and then (after it has sat
; and waited for a name for a long time, which is why this doesn't happen when the
; name is sent straight away, but it is the drive code's to say) the drive doesn't
; get all of the name, and the runtime says so, with .C = 1.  then the drive code is
; quit, and started again, and asked again, twice at the most.

bitops_open
	sta bitops_name_len
	stx bitops_name_ptr
	sty bitops_name_ptr+1

	php									; remember if interrupts were off already
	pla
	and #%00000100
	sta bitops_saved_i
	sei

	jsr loader_fetch_bitops_install	; (at the speed that the machine is at)
	jsr bitops_speed_down

	ldx #BITOPS_ZP_SIZE-1				; the runtime's zero page, put back at the close
-	lda BITOPS_ZP,x
	sta bitops_saved_zp,x
	dex
	bpl -

	lda #0
	sta bitops_tries

.start
	lda load_device						; (the drive code reads the device from where the
	sta FA								; KERNAL has it)
	lda #0
	sta STATUS
	jsr load_buffer						; InitLoader.  .C = 1 if it can't be started
	bcc .started
	lda #BITOPS_ERR_NOT_FAST
	bne .fail							; (always)

.started
	lda bitops_name_len
	ldx bitops_name_ptr
	ldy bitops_name_ptr+1
	jsr bitops_rt_open
	bcs .again							; the drive didn't get all of the name

	lda bitops_file_open				; 0 if the file isn't there, or is empty.  then the
	bne .opened							; drive code is waiting for another name, and it's
	jsr bitops_rt_quit					; quit (which is quick, with no file open)
	jsr bitops_rt_wait
	jmp .failed_open

.again
	lda #1								; the drive code may be waiting in the middle of a
	sta bitops_file_open				; name, which takes a while to quit
	jsr bitops_rt_quit
	jsr bitops_rt_wait
	bcs .failed_open					; (the drive didn't answer)
	inc bitops_tries
	lda bitops_tries
	cmp #3
	bcc .start

.failed_open
	lda #BITOPS_ERR_OPEN

.fail
	pha
	jsr bitops_restore_zp
	jsr bitops_speed_up
	jsr bitops_restore_i
	pla
	sec
	rts

.opened
	jsr bitops_speed_up
	clc
	rts

; closes the file, both when it's been read to the end (and the drive code is waiting
; for another name) and when the load is given up in the middle.  quits the drive
; code, and waits until the drive is back, because what comes next is the KERNAL's.

bitops_close
	lda load_device						; (the KERNAL's place for it may have changed)
	sta FA
	jsr bitops_speed_down
	jsr bitops_rt_quit
	jsr bitops_rt_wait
	jsr bitops_restore_zp
	jsr bitops_speed_up
	jsr bitops_restore_i
	clc
	rts

bitops_restore_zp
	ldx #BITOPS_ZP_SIZE-1
-	lda bitops_saved_zp,x
	sta BITOPS_ZP,x
	dex
	bpl -
	rts

; interrupts back on, if they were on at the open.

bitops_restore_i
	lda bitops_saved_i
	bne +
	cli
+	rts

; the protocol counts cycles, so the CPU has to be at 1 MHz.  that isn't a problem on
; a stock machine, and the SuperCPU gets slowed down for it, for as long as one of the
; entry points is running.  (an Ultimate's speed is left as it is, because it's only
; changed for playing.)  these trash .A, and not .X or .Y, and each speed_down has to
; be followed by its speed_up.

bitops_speed_down
	!ifdef scpu {
		bit SCPU_PRESENT
		bmi +
		sta SCPU_TURBO_OFF
	  +
	}
	rts

bitops_speed_up
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

bitops_get_byte
	jsr bitops_speed_down
	jsr bitops_rt_get
	php									; (.C says whether it was the last)
	pha
	jsr bitops_speed_up
	pla
	plp
	bcc +
	pha
	lda #$40
	sta STATUS
	pla
+	rts

; (the code above has to end before the DASM-built part, which has to be where the
; entry points expect it)

	!if * - loader_slot > $100 {
		!error "The Bitops entry points are too big for their page by ", * - loader_slot - $100, " bytes!"
	}
	!fill loader_slot + $100 - *, 0

	!binary "src/bitops/bitops-drive.o", , BITOPS_RUNTIME_OFFSET

; and what's left of the slot after the runtime has the rest.

; reads 256 bytes of the file to load_buffer, or from where load_pointer is, for the
; one that's called for the later pages of a bigger read.  if the file ends in the
; middle of it, the rest is zeros, and STATUS is set as for bitops_get_byte.

bitops_get_block
	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

bitops_get_block_keep_ptr
	jsr bitops_speed_down
	ldy #0
	lda bitops_file_open
	beq .past_end						; (it was over already)

.block_byte
	jsr bitops_rt_byte
	sta (load_pointer),y
	lda bitops_file_open				; the runtime clears this when it has given the
	beq .block_last						; last byte
	iny
	bne .block_byte
	beq .block_done						; (always)

.block_last
	lda #$40
	sta STATUS
	iny
	beq .block_done						; (that was the last of the 256, too)
	bne .fill							; (always)

.past_end
	lda #$40
	sta STATUS

.fill
	lda #0
-	sta (load_pointer),y
	iny
	bne -

.block_done
	jsr bitops_speed_up
	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2
  +
rts

bitops_get_1kb
	jsr bitops_get_block
	inc load_pointer+1
	jsr bitops_get_block_keep_ptr
	inc load_pointer+1
	jsr bitops_get_block_keep_ptr
	inc load_pointer+1
jmp bitops_get_block_keep_ptr

loader_bitops_end

}

; the install part, which isn't in the slot, but is in the stash, right after the
; image.  see loader_fetch_bitops_install.

loader_bitops_install = *

	!binary "src/bitops/bitops-drive.o", BITOPS_INSTALL_SIZE, 0

loader_bitops_install_end

}
