; Loader image for reading a file with the UCI subsystem featured in the
; 1541-Ultimate, Ultimate64, and Commodore 64 Ultimate
;
; This is assembled to run from the loader slot (see modplay.s), but it's stored
; in the PRG (and then in expansion memory) as plain data, like the audio driver
; images, and fetched into place when the load device needs it.  Its entry jumps
; are described in loader-select.s.

!zone loader_uci {

loader_uci_image = *

!pseudopc loader_slot {

	jmp uci_open_file
	jmp uci_close_file
	jmp close_file				; (a finished load has always closed the KERNAL's file)
	jmp uci_get_byte
	jmp loader_uci_get_block
	jmp loader_uci_get_1kb

loader_uci_get_block
	lda #<load_buffer
	sta load_pointer
	lda #>load_buffer
	sta load_pointer+1

loader_uci_get_block_keep_ptr
	ldy #0

-	jsr uci_get_byte
	sta (load_pointer),y
	iny
	bne -

	inc loaded_bytes_count+1
	bne +
	inc loaded_bytes_count+2
  +
rts

loader_uci_get_1kb
	jsr loader_uci_get_block
	inc load_pointer+1
	jsr loader_uci_get_block_keep_ptr
	inc load_pointer+1
	jsr loader_uci_get_block_keep_ptr
	inc load_pointer+1
jmp loader_uci_get_block_keep_ptr

; From here on down are all the "helper" and "low-level" routines
; needed by the above calls

; enter with .A = filename len, .X/.Y = filename addr

uci_open_file
	php
	sta temp_abs_a
	and #$7f		; in case the len indicates need for DOS command channel
	jsr SETNAM

	!ifdef c128 {
		lda #KERNAL_FILE_BANK
		ldx #KERNAL_FILE_BANK
		jsr SETBNK
	}

	ldy #2			; default SA=2
	ldx load_device

	plp
	bcc +			; if we called this with the carry set,
	ldy #0			; it means we need the directory, so SA=0
	beq .usetlfs

+	lda temp_abs_a	; retrieve filename length
	and #$80		; if the high bit of the length was set
	beq .usetlfs
	ldy #15			; then it's for the DOS command channel, so SA=15

.usetlfs
	lda #2			; always using file number 2

	jsr SETLFS

	ldx #UCI_CMD_OPEN
	jsr uci_setup_cmd
	jsr uci_filename ; also executes
	jsr uci_ack

	ldx #UCI_CMD_CHKIN
	jsr uci_setup_cmd
	jsr uci_execute
	clc
rts

; These routines were partially derived from the 1541-Ultimate
; "Hyperspeed" KERNAL, originally (C) 2020 Gideon Zweijtzer

uci_close_file
	lda #2			; filenumber 2

	ldx #UCI_CMD_CLOSE
	jsr uci_setup_cmd
	jsr uci_execute
	jsr uci_ack

	jsr uci_abort	; same as CLRCH, for UCI
	clc
rts

uci_get_byte
	lda #0
	sta STATUS
	bit UCI_CMD_IF_CONTROL	; if there's data available, read it.
	bpl refill_buffer		; else go look for more
	lda UCI_CMD_IF_RESULT
	rts

refill_buffer
	jsr uci_ack				; wait for UCI to signal ready
	jsr uci_wait_busy
	lda UCI_CMD_IF_CONTROL	; is there more data to load into the buffer?
	and #CMD_STATE_BITS
	cmp #CMD_STATE_MORE_DATA
	beq uci_get_byte		; if so, grab it and return the next byte
	lda #$40				; else this must be EOF.
	sta STATUS
	bit UCI_CMD_IF_CONTROL
	rts


; #######################################################
; Original UCI helper routines from the Hyperspeed KERNAL

uci_setup_cmd
	jsr uci_abort ; will abort any pending command first

	; clean slate
	lda #$80
	sta UCI_PENDING_CMD ; Bit 7 is now set

	lda #UCI_TARGET
	sta UCI_CMD_IF_COMMAND
	stx UCI_CMD_IF_COMMAND
	stx UCI_LAST_CMD
	lda SECADDR
	sta UCI_CMD_IF_COMMAND
	sta UCI_LAST_SA
	lda VERIFYFLAG
	sta UCI_CMD_IF_COMMAND
	rts

uci_filename
	lda NAMELEN
	beq uci_execute
	ldy #$00
_fn1
	lda (NAMEPTR),y
	sta UCI_CMD_IF_COMMAND
	iny
	cpy NAMELEN
	bne _fn1
	; intentional fall through

uci_execute
	lda #CMD_PUSH_CMD
	sta UCI_CMD_IF_CONTROL
	lda #0
	sta UCI_PENDING_CMD ; bit 7 is now cleared
	; intentional fall through

uci_wait_busy
	lda UCI_CMD_IF_CONTROL
	and #CMD_STATE_BITS
	cmp #CMD_STATE_BUSY
	beq uci_wait_busy
	; we should now be in the data state, where we can also read the status
	rts

uci_ack
	pha
	lda #CMD_NEXT_DATA
	sta UCI_CMD_IF_CONTROL
_ack1
	lda UCI_CMD_IF_CONTROL
	and #CMD_NEXT_DATA
	bne _ack1
	pla
	rts

uci_abort   ; may be in command state
	bit UCI_PENDING_CMD
	bpl _abrt1 ; Bit 7 is not set, so there is no pending command
	jsr uci_execute

_abrt1
	lda #$00
	sta UCI_LAST_CMD
	lda UCI_CMD_IF_CONTROL
	and #CMD_STATE_BITS
	beq _abrt2 ; UCI is already in idle state; we're done

;	cmp #CMD_STATE_MORE_DATA  ; only if it is 'more data', we use abort, otherwise data is just acked.
;	bne uci_ack ; NOT in More Data state, just ack

	; Perform Abort of current command
	lda #CMD_ABORT
	sta UCI_CMD_IF_CONTROL
_wa1
	lda UCI_CMD_IF_CONTROL
	and #CMD_ABORT
	bne _wa1
_abrt2
	rts

uci_clear_error
	lda #CMD_ERROR
	sta UCI_CMD_IF_CONTROL
	rts


loader_uci_end
}

}
