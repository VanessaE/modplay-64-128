; Loader image for reading a file from a CMD HD that is on a RamLink, with the HD
; streamer.
;
; Opening the file uploads a small program to the HD and starts it.  From then on the
; HD reads the file by its name, a sector at a time, and sends each sector to the C64
; over the RamLink's parallel bus, with the clock and data lines of the serial bus to
; say when a byte is there.  The HD can't be used for anything else while it does
; that, so the program is started for every file, and quit when the file is closed or
; has been read, and the close waits for the HD to answer the KERNAL again.
;
; The protocol is in src/hdstream (see its notes).  This has what the loader slot
; needs:  the entry points (see loader-select.s) on top of the routines that read a
; sector, which are the runtime, and live in the slot with them.  The part that finds
; the HD and starts its program is too big for the slot, and it is only used for the
; open, so it is stored after the image, and loader_fetch_hd_install fetches it to
; the load buffer, where it runs from, every time a file is opened.
;
; A sector is received in the page of the right audio buffer, because the load buffer
; is where the file goes.  The RamLink's hardware is only switched in for as long as a
; sector takes (the KERNAL's ROM is the RamLink's for that time, and the REU and the
; screen can't be used), and the HD waits between the sectors.
;
; The only check of the HD is that the two bytes at $FEA4 of its ROM say that it is one,
; as the program for the HD has addresses of the HD's DOS in it (those of V1.92, the
; last version), which are not checked.  Anything that isn't right for this (no
; RamLink, not an HD, no parallel bus) makes the open fail with HDSTREAM_ERR_UNUSABLE,
; which loader_open_file takes as the cue to mark the device in loader_hd_state, and to
; use the Bitops loader (or the KERNAL's) for it.
;
; In the C128 builds it is the same, but for the way that the RamLink's hardware is
; switched in and out, which is with a write to $DF7E and $DF7F, and for the CPU clock,
; which is put to 1 MHz for as long as an entry point runs (see src/hdstream/NOTES).
;
; The speed of a SuperCPU doesn't matter to the protocol, which waits for the HD for
; each byte.  The "Auto" loader setting leaves it as it is, and "Auto/1MHz" makes it
; 1 MHz inside each entry point (the same as for the other loaders that count cycles).
;
; This is assembled to run from the loader slot (see modplay.s), but it's stored in
; the PRG (and then in expansion memory) as plain data, like the audio driver images.

!zone loader_hdstream {

; what the streamer's two halves are given (see src/hdstream/hd-defs.s)

hd_cmd_ptr		= load_pointer		; two bytes that the open uses.  (the player sets load_pointer
						; itself before it needs it, which is after the open)
hd_blk_buffer		= audio_buffer_right	; the sector buffer, which the loader has to itself

; what the open returns for a file that couldn't be opened, or is empty.  (the one for
; a device that the streamer can't be used with is in constants-com.h.)

HDSTREAM_ERR_OPEN = 4

	!source "src/hdstream/hd-defs.s"

loader_hdstream_image = *

!pseudopc loader_slot {

	jmp hds_open
	jmp hds_close
	jmp hds_close
	jmp hds_get_byte
	jmp hds_get_block
	jmp hds_get_1kb

hds_saved_i		!byte 0			; the interrupt flag, as it was at the open
hds_len			!byte 0			; the name of the file, until the open is done
hds_ptr			!word 0
hds_pos			!byte 0			; the next byte of the sector, as an index
hds_left		!byte 0			; how many bytes of it there are left
hds_last		!byte 0			; bit 7:  the sector is the last, and the HD has ended
hds_y			!byte 0
hds_x			!byte 0
	!ifdef c128 {
hds_saved_clock		!byte 0			; the C128's CPU clock setting, as it was
	}

; enter with .A = the length of the filename, .X/.Y = its address, and .C clear, as
; for open_file.  returns .C = 1 if the file couldn't be opened, with an error code in
; .A.  if it did work, interrupts are off until hds_close puts them back (nothing but
; the RamLink's hardware may be disturbed in between), and the first sector is in the
; buffer, so there is a file.

hds_open
	sta hds_len
	stx hds_ptr
	sty hds_ptr+1

	php							; remember if interrupts were off already
	pla
	and #%00000100
	sta hds_saved_i
	sei

	jsr loader_fetch_hd_install			; (at the speed that the machine is at)
	jsr hds_speed_down

	lda load_device						; (the streamer reads the device from where the
	sta FA								; KERNAL has it)
	lda hds_len
	ldx hds_ptr
	ldy hds_ptr+1
	jsr load_buffer						; hd_start, at the start of the install part
	cpx #0
	bne .unusable

	lda #0								; the first sector.  none of the file in it means that
	sta hds_left						; the file isn't there, or is empty
	sta hds_pos
	sta hds_last
	jsr hds_fill
	lda hds_left
	bne .opened

	jsr hd_release						; (the HD has gone back to its DOS by itself)
	jsr hd_wait_dos
	lda #HDSTREAM_ERR_OPEN
	bne .fail							; (always)

.unusable
	cpx #HD_ERR_NO_PARALLEL				; (the HD has been told to quit, which it does at its
	bne +								; own pace, and the next loader needs it)
	jsr hd_wait_dos
+	lda #HDSTREAM_ERR_UNUSABLE

.fail
	pha
	jsr hds_speed_up
	jsr hds_restore_i
	pla
	sec
	rts

.opened
	jsr hds_speed_up
	clc
	rts

; interrupts back on, if they were on at the open.

hds_restore_i
	lda hds_saved_i
	bne +
	cli
+	rts

; reads the next sector to the buffer, with the RamLink's hardware in for as long as
; it takes.  hds_left = the bytes of the file that are in it, and hds_last gets bit 7
; if it is the last sector (there is a link of 0, or less than a whole sector of the
; file, or none:  the HD ends by itself then).  trashes .A, .X and .Y.

hds_fill
	jsr hd_open_port
	jsr hd_read_block
	sty hds_left
	lda #0
	sta hds_pos
	sta hds_last
	cpy #254							; (a sector with fewer than 254 bytes in it, or with
	bne .last							; none, is the last)
	lda hd_blk_buffer					; and so is one that has no next sector
	bne +
.last
	lda #$80
	sta hds_last
+	jmp hd_close_port

; closes the file, both when it's been read to the end (and the HD has ended by
; itself, and only has to be let go of) and when the load is given up in the middle
; (and it has to be told to quit).  then it waits until the HD is back, because what
; comes next is the KERNAL's.

hds_close
	jsr hds_speed_down
	lda load_device						; (the KERNAL's place for it may have changed)
	sta FA
	bit hds_last
	bmi .ended
	jsr hd_stop
	jmp .wait
.ended
	jsr hd_release
.wait
	jsr hd_wait_dos
	jsr hds_speed_up
	jsr hds_restore_i
	clc
	rts

; the speed of the CPU.  the C128 is at 1 MHz for as long as an entry point runs, and put
; back as it was (the REU's transfers expect it as it was), like the other loaders do.  a
; SuperCPU is left as it is by "Auto" (bit 7 of the setting), and made 1 MHz by
; "Auto/1MHz", for as long as an entry point runs.  (the protocol waits for the HD for
; every byte, so it doesn't need either, but the RamLink's parallel port is read.)  these
; trash .A, and not .X or .Y, and each speed_down has to be followed by its speed_up, and
; they are not nested.

hds_speed_down
	!ifdef scpu {
		bit loader_auto_enable
		bmi +
		bit SCPU_PRESENT
		bmi +
		sta SCPU_TURBO_OFF
	  +
	}
	!ifdef c128 {
		lda C128_VIC_CLOCK_SPEED
		sta hds_saved_clock
		lda #0
		sta C128_VIC_CLOCK_SPEED
	}
	rts

hds_speed_up
	!ifdef c128 {
		lda hds_saved_clock
		sta C128_VIC_CLOCK_SPEED
	}
	!ifdef scpu {
		bit loader_auto_enable
		bmi +
		bit SCPU_PRESENT
		bmi +
		sta SCPU_TURBO_ON
	  +
	}
	rts

; gets the next byte of the file, in .A, and sets STATUS to $40 when it's the last.
; past the end of the file it returns zeros, and the same STATUS.  preserves .X and
; .Y.

hds_get_byte
	stx hds_x
	sty hds_y
	jsr hds_speed_down
	lda hds_left
	bne .have
	bit hds_last						; (a sector after the last:  the file is over)
	bmi .over
	jsr hds_fill
	lda hds_left
	beq .over

.have
	ldx hds_pos
	lda hd_blk_buffer+2,x
	inc hds_pos
	dec hds_left
	bne .got
	bit hds_last						; (this doesn't change .A)
	bpl .got
	ldx #$40							; that was the last of the file
	stx STATUS
.got
	pha
	jsr hds_speed_up
	pla
	ldx hds_x
	ldy hds_y
	rts

.over
	lda #$40
	sta STATUS
	jsr hds_speed_up
	ldx hds_x
	ldy hds_y
	lda #0
	rts

; reads 256 bytes of the file to load_buffer, or from where load_pointer is, for the
; one that's called for the later pages of a bigger read.  if the file ends in the
; middle of it, the rest is zeros, and STATUS is set as for hds_get_byte.

hds_get_block
	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

hds_get_block_keep_ptr
	jsr hds_speed_down
	ldy #0

.next
	lda hds_left
	bne .copy
	bit hds_last
	bmi .eof
	sty hds_y
	jsr hds_fill
	ldy hds_y
	lda hds_left
	beq .eof

.copy
	ldx hds_pos
	lda hd_blk_buffer+2,x
	sta (load_pointer),y
	inc hds_pos
	dec hds_left
	bne +
	bit hds_last
	bpl +
	lda #$40							; (that was the last of the file)
	sta STATUS
+	iny
	bne .next
	beq .done							; (always)

.eof
	lda #$40
	sta STATUS
	lda #0
-	sta (load_pointer),y
	iny
	bne -

.done
	jsr hds_speed_up
	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2
  +
	rts

hds_get_1kb
	jsr hds_get_block
	inc load_pointer+1
	jsr hds_get_block_keep_ptr
	inc load_pointer+1
	jsr hds_get_block_keep_ptr
	inc load_pointer+1
	jmp hds_get_block_keep_ptr

; the routines that read a sector:  hd_open_port, hd_close_port, hd_read_block, hd_stop,
; hd_release and hd_wait_dos

	!source "src/hdstream/hd-host-runtime.s"

loader_hdstream_end

}

; the install part, which isn't in the slot, but is in the stash, right after the
; image.  it runs from the load buffer, with the program for the HD at its end.  see
; loader_fetch_hd_install.

loader_hd_install = *

!pseudopc load_buffer {

	!source "src/hdstream/hd-host-install.s"

hd_image
	!source "src/hdstream/hd-drive.s"

}

loader_hd_install_end

}
