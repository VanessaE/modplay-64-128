; The program that runs inside the CMD HD while a file is streamed to the C64 over
; the parallel bus.  The C64 uploads it to $0400 of the HD's memory (M-W), and
; starts it there (M-E).  See hd-host.s for the C64's half.
;
; This is $0400-based, and not a PRG:  the bytes are what is uploaded.

!zone hd_drive {

; the HD's DOS, as of ROM v1.92 of the HD's DOS:  these are its addresses

hdd_JOB_NUM		= 0
hdd_READ_JOB	= $80
hdd_job0Queue	= $0020
hdd_d1		= $fe				; two bytes of zero page
hdd_jobBuffer	= $0300
hdd_job0Track	= $2800
hdd_job0Sector	= $2801
hdd_curOpenPartition = $2bd6
hdd_headerTrack	= $9100
hdd_headerSector	= $9200
hdd_Exec_Job	= $ff4e

; the HD's hardware.  hdd_busIOChip is its serial bus, with the lines for the clock and
; data going in and out, and the 8255 is the parallel port that goes to the RamLink.

hdd_busIOChip	= $8000
hdd_paHD8255	= $8800
hdd_pbHD8255	= $8801
hdd_pcHD8255	= $8802
hdd_crHD8255	= $8803
hdd_ledChip		= $8f00

hdd_CLOCKBIT	= %00000100
hdd_DATABIT		= %00000001
hdd_DATA_LO		= %00010010
hdd_DATA_HI		= %00010000
hdd_CLOCK_LO	= %00011000
hdd_CLOCK_HI	= %00010000

!pseudopc $0400 {

hd_drive_start
	jmp hdd_CTakeControl

; the file's name (padded with zeros), and whether it is to be repeated

hdd_dFileTable
hdd_fName		!fill 17, 0
hdd_repeatFlag	!byte 0				; bit 7 set:  start over when it ends
hdd_dataMode	!byte 0				; (the C64's, and not used here)
hdd_packetSize	!word 0				; (the same)
hdd_bufZ		!byte 0				; (the same)

hdd_startTrack	!byte 0
hdd_startSector	!byte 0

hdd_Send1Block
	jsr hdd_LEDS_On
	jsr hdd_ParHDOut
	ldy #0
	lda #hdd_CLOCKBIT			; wait for the C64 to release the clock line
-	bit hdd_busIOChip
	bne -
	lda #hdd_DATABIT
	ldx #hdd_DATA_HI
	stx hdd_busIOChip			; let go of anything that is held
	bit hdd_busIOChip			; is the C64 holding the data line?
	beq .send			; not if StopTurbo hasn't been called
	ldx #hdd_CLOCK_LO
	stx hdd_busIOChip			; grab the clock line
-	bit hdd_busIOChip
	bne -				; until the C64 lets go of the data line
	ldx #hdd_DATA_HI
	stx hdd_busIOChip			; let go of everything
	jsr hdd_ParHDIn
	jmp hdd_Return2DOS			; and end this

.send
	ldx #hdd_DATA_LO
	lda #hdd_CLOCKBIT			; wait for the C64 to grab the clock line
-	bit hdd_busIOChip
	beq -
	lda hdd_jobBuffer,y			; a byte, to the parallel port
	sta hdd_paHD8255
	stx hdd_busIOChip			; and tell the C64 that it is there
	ldx #hdd_DATA_HI
	iny
	cpy hdd_bytesToSend
	beq .last
	lda #hdd_CLOCKBIT			; wait for the C64 to say that it has the byte
-	bit hdd_busIOChip
	bne -
	lda hdd_jobBuffer,y
	sta hdd_paHD8255
	stx hdd_busIOChip
	iny
	cpy hdd_bytesToSend
	bne .send
.last
	lda #hdd_CLOCKBIT
-	bit hdd_busIOChip
	beq -
	ldx #hdd_DATA_LO
	stx hdd_busIOChip
	jsr hdd_LEDS_Off

; the HD's parallel port, as input, and as output

hdd_ParHDIn
	ldx #%10010010
	!byte $2c
hdd_ParHDOut
	ldx #%10000010
	lda hdd_pcHD8255			; (keep port C)
	stx hdd_crHD8255
	sta hdd_pcHD8255
	rts

hdd_LEDS_Off
	lda hdd_ledChip
	ora #%01000001			; the upper activity light off
	bne hdd_LED2			; (always)
hdd_LEDS_On
	lda #%10111110			; and on
	and hdd_ledChip
hdd_LED2
	sta hdd_ledChip
	rts

; takes over the HD, and does its thing

hdd_CTakeControl
	sei
	lda hdd_d1+1			; (the zero page that it uses is put back)
	pha
	lda hdd_d1
	pha
	tsx
	stx hdd_stackSave
	ldx #2
	ldy #0
-	dey
	bne -
	dex
	bne -
	lda #hdd_CLOCKBIT			; wait for the C64 to grab the clock line
-	bit hdd_busIOChip
	beq -
	lda #hdd_DATA_LO
	sta hdd_busIOChip			; and now the data line is the HD's
	lda #hdd_CLOCKBIT
-	bit hdd_busIOChip
	bne -
	jsr hdd_ParHDOut
	lda #$aa
	sta hdd_paHD8255			; the first byte of the test of the parallel port
	lda #hdd_DATA_HI
	sta hdd_busIOChip
	lda #hdd_CLOCKBIT
-	bit hdd_busIOChip
	beq -
	lda #$55
	sta hdd_paHD8255
	lda #hdd_DATA_LO
	sta hdd_busIOChip
	lda #hdd_CLOCKBIT
-	bit hdd_busIOChip
	bne -
	lda #hdd_DATA_HI
	sta hdd_busIOChip
	jsr hdd_ParHDIn
	lda #hdd_DATABIT
	bit hdd_busIOChip			; is the C64 holding the data line?
	bne hdd_Return2DOS
	lda #hdd_CLOCKBIT
-	bit hdd_busIOChip
	beq -
	lda #hdd_DATA_LO
	sta hdd_busIOChip
	jsr hdd_StartSend			; find the file, and ship it
hdd_Return2DOS
	jsr hdd_LEDS_Off
	ldx #hdd_DATA_HI
	stx hdd_busIOChip			; the serial lines are let go of
	ldx hdd_stackSave
	txs
	pla
	sta hdd_d1
	pla
	sta hdd_d1+1
	cli
	rts

hdd_stackSave	!byte 0
hdd_bytesToSend	!byte 0

hdd_ReadToBuffer
	lda #hdd_READ_JOB
	ldx #hdd_JOB_NUM
	sta hdd_job0Queue
	jsr hdd_Exec_Job
	cmp #2
	rts

hdd_StartSend
	jsr hdd_LookForFile
	beq .found
.notfound
	lda #0				; no such file:  a block with nothing in it
	sta hdd_jobBuffer+0
	sta hdd_jobBuffer+1
	lda #2
	sta hdd_bytesToSend
	jmp hdd_Send1Block
.found
	ldy #1
	lda (hdd_d1),y
	sta hdd_startTrack
	iny
	lda (hdd_d1),y
	sta hdd_startSector
.again
	lda hdd_startTrack
	sta hdd_job0Track
	lda hdd_startSector
	sta hdd_job0Sector
.read
	jsr hdd_ReadToBuffer
	bcs .notfound
	ldy #255
	lda hdd_jobBuffer+0
	bne .count
	ldy hdd_jobBuffer+1
.count
	iny
	sty hdd_bytesToSend
	jsr hdd_Send1Block
	lda hdd_jobBuffer+1
	sta hdd_job0Sector			; the next block
	lda hdd_jobBuffer+0
	sta hdd_job0Track			; (and was that the last?)
	bne .read
	bit hdd_repeatFlag
	bmi .again
	rts

; looks for the name in hdd_fName in the directory, and returns with hdd_d1 pointing to the
; entry if it is there.  X = 0 if it was found

hdd_LookForFile
	ldx hdd_curOpenPartition
	lda hdd_headerTrack,x
	sta hdd_job0Track
	lda hdd_headerSector,x
	sta hdd_job0Sector
	jsr hdd_ReadToBuffer		; the header of the directory
	bcs .missing
	lda hdd_jobBuffer+1
	sta hdd_job0Sector			; and the first block of entries
	lda hdd_jobBuffer+0
	sta hdd_job0Track
.block
	jsr hdd_ReadToBuffer
	bcs .missing
	lda #>(hdd_jobBuffer+2)		; (the high byte first, as the original has it)
	sta hdd_d1+1
	lda #<(hdd_jobBuffer+2)
	sta hdd_d1
.entry
	ldx #0
	ldy #0
	lda (hdd_d1),y			; PRG or SEQ files only (closed, and locked or not)
	and #%10111111
	cmp #$82
	beq .name
	cmp #$81
	bne .next
.name
	ldy #3
-	lda hdd_fName,x			; at the end of the name?
	bne .char
	lda (hdd_d1),y			; then it has to be a shifted space
	cmp #$a0
	beq .match
	bne .next
.char
	cmp (hdd_d1),y
	bne .next
	iny
	inx
	cpx #16
	bcc -
.match
	ldx #0
	rts
.next
	clc
	lda hdd_d1
	adc #32
	sta hdd_d1
	bcc .entry
	lda hdd_jobBuffer+1
	sta hdd_job0Sector
	lda hdd_jobBuffer+0
	sta hdd_job0Track
	bne .block
.missing
	ldx #5				; FILE_NOT_FOUND
	rts

hd_drive_end

}

hd_drive_size = hd_drive_end - hd_drive_start

}
