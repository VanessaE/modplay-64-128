; The runtime of the Covert Bitops Loadersystem's drive code, which reads from the
; drive code once it is running, and quits it.  Derived from loader.s, see drive.s.
;-------------------------------------------------------------------------------


                ifconst PLAYER

        ; What loader-bitops.s calls, at the start of the runtime, as the install part
        ; is thrown away:
        ;
        ;       +0      jmp FastOpen        open the file:  .A = length of the name, .X/.Y = its
        ;                                   address.  Returns .C = 1 if the drive didn't have all
        ;                                   of the name, and otherwise fileOpen = 0 if the file
        ;                                   wasn't there (or is empty)
        ;       +3      jmp BitopsGetNext   the next byte of the file in .A.  .C = 1 if that was
        ;                                   the last (the file is over, then), or if it was over,
        ;                                   with 0 as the byte.  Doesn't change .X and .Y
        ;       +6      jmp FL_Quit         quit the drive code
        ;       +9      jmp FL_WaitDrive    wait for the drive to answer the KERNAL again.
        ;                                   Returns .C = 1 if it didn't
        ;       +12     jmp GetByte         the next byte of the file in .A, quicker than
        ;                                   +3.  fileOpen is 0 after the last one, and
        ;                                   nothing may be read after that

RuntimeStart:   jmp FastOpen
                jmp BitopsGetNext
                jmp FL_Quit
                jmp FL_WaitDrive
                jmp GetByte

BitopsGetNext:  lda fileOpen
                beq BG_Over
                jsr GetByte
                pha
                lda fileOpen                    ;It was the last one if the file is over now
                beq BG_Last
                pla
                clc
                rts
BG_Last:        pla
                sec
                rts
BG_Over:        lda #$00
                sec
                rts

                endif

        ; Runtime
        ;
        ; Open file
        ;
        ; Parameters: A length of the name (1-16), X/Y address of the name (low/high)
        ; Returns: fileOpen 0 if failed to open (or the file is empty), or the first
        ;          sector is in loadBuffer, as for FL_FillBuffer.  With OPEN_CHECK,
        ;          .C = 1 (and fileOpen 0) if the drive didn't have the whole of the
        ;          name, which is then not a file that wasn't there, and the drive
        ;          code is still in the drive, ready for a name:  FL_Quit it, start
        ;          it again with InitLoader, and ask again at once
        ; Modifies: A,X,Y

OpenFile:       jmp FastOpen

        ; Read a byte from an opened file. Do not call after fileOpen becomes 0
        ;
        ; Parameters: -
        ; Returns: byte in A, fileOpen set to 0 after EOF
        ; Modifies: A

GetByte:        lda loadBuffer
                inc GetByte+1
                dec loadBufferPos
                beq FL_FillBuffer               ;Get next sector when reach the sector buffer end
FO_Done:        rts

FastOpen:       inc fileOpen
                sta zpLenLo
                stx zpSrcLo
                sty zpSrcHi
                ldy #$00
                if USETURBOMODE > 0
                sty $d07a                       ;SCPU to slow mode
                sty $d030                       ;C128 back to 1MHz mode
                endif
                lda zpLenLo
                jsr FL_SendByte                 ;The length of the name
FL_SendName:    lda (zpSrcLo),y
                jsr FL_SendByte                 ;(this doesn't change Y)
                iny
                cpy zpLenLo
                bcc FL_SendName
                lda #$00                        ;Command 0 = load
                jsr FL_SendByte
                if OPEN_DELAY > 0
                ldy #$02                        ;(for the test:  about 2.5 ms)
FO_Settle:      ldx #$00
FO_Settle2:     dex
                bne FO_Settle2
                dey
                bne FO_Settle
                endif
                if OPEN_CHECK > 0
                ldy #$10                        ;(about 90 cycles.  A drive that has the whole
FO_Busy:        dey                             ;name is busy with it, and has DATA low.  One that is
                bne FO_Busy                     ;still waiting for more of a name has let go of it)
                bit $dd00
                bpl FO_BusyOk
                lda #$00
                sta fileOpen
                sec
                rts
FO_BusyOk:
                endif
                clc                             ;(.C = 0 means that the open worked)
FL_FillBuffer:  php
                pha                             ;Preserve A (the byte that was read if called from GetByte)
                stx loadTempReg
                ldx #$00
FL_FillBufferWait:
                bit $dd00                       ;Wait for 1541 to signal data ready by setting DATA high
                bpl FL_FillBufferWait
FL_FillBufferLoop:
FL_SpriteWait:  lda $d012                       ;Check for sprite Y-coordinate range
FL_MaxSprY:     cmp #$00                        ;(max & min values are filled in the
                bcs FL_NoSprites                ;raster interrupt)
FL_MinSprY:     cmp #$00
                bcs FL_SpriteWait
FL_NoSprites:   sei
FL_WaitBadLine: lda $d011
                clc
                sbc $d012
                and #$07
                beq FL_WaitBadLine
                lda #$10
                ora $dd00
                sta $dd00                       ;CLK=low to begin transfer
FL_Delay:       and #$03
                sta FL_Eor+1
                sta $dd00
FL_ReceiveByte: lda $dd00
                lsr
                lsr
                eor $dd00
                lsr
                lsr
                eor $dd00
                lsr
                lsr
                eor $dd00
                ifconst PLAYER
                nop                             ;(interrupts stay off, for the whole file)
                else
                cli
                endif
FL_Eor:         eor #$00
                sta loadBuffer,x
                inx
                bne FL_FillBufferLoop
                ldx #$fe                        ;Assume full buffer
                lda loadBuffer
                bne FL_FullBuffer
                ldx loadBuffer+1
                bne FL_NoEOF
                stx fileOpen                    ;Endmark received, close file
FL_NoEOF:       dex
FL_FullBuffer:  stx loadBufferPos               ;Bytes left to read
                lda #$02
                sta GetByte+1                   ;Reset read position
                ldx loadTempReg
                pla
                plp
                rts

FL_SendByte:    sta loadTempReg
                ldx #$08                        ;Bit counter
FL_SendLoop:    bit $dd00                       ;Wait for both DATA & CLK to go high
                bpl FL_SendLoop
                bvc FL_SendLoop
                lsr loadTempReg                 ;Send one bit
                lda #$10
                ora $dd00
                bcc FL_ZeroBit
                eor #$30
FL_ZeroBit:     sta $dd00
                lda #$c0                        ;Wait for CLK & DATA low (diskdrive answers)
FL_SendAck:     and $dd00
                bne FL_SendAck
                lda #$ff-$30                    ;Set DATA and CLK high
                and $dd00
                sta $dd00
                dex
                bne FL_SendLoop
                rts

        ; Quit the drive code, with ATN
        ;
        ; Puts ATN and CLK low.  The drive code quits when it sees ATN, which is when it
        ; is waiting for the host to send it a name (as after the last sector of a file),
        ; and when it has sent a sector.  If a file isn't all read, the drive is
        ; waiting for the host to clock the next byte out, so CLK is kept low, which
        ; lets it finish the sector at once.  Then this waits, a short time if the
        ; file was all read, and about 650 ms if not (it may have to wait for a sector to come round first),
        ; and lets go of the lines.  A 1541 initializes itself after that, which takes
        ; a while:  FL_WaitDrive, below, waits for it.
        ; Needs I/O visible.  Modifies: A,X,Y

FL_Quit:        php
                sei
                lda $dd00
                ora #$18                        ;ATN low, CLK low
                sta $dd00
                ldy #$10                        ;20 ms if the file was all read
                lda fileOpen
                beq FQ_Short
                ldy #$fa                        ;or 2 * 320 ms
                jsr FQ_Delay
                ldy #$fa
FQ_Short:       jsr FQ_Delay
                lda $dd00
                and #$e7                        ;Let go of ATN and CLK
                sta $dd00
                lda #$00
                sta fileOpen
                plp
                rts

FQ_Delay:       ldx #$00                        ;Y * 1280 cycles, which is 1.3 ms each
FQ_Delay2:      dex
                bne FQ_Delay2
                dey
                bne FQ_Delay
                rts

        ; Wait for the drive to answer the KERNAL, after FL_Quit, for several
        ; seconds at the most.  Needs the KERNAL on, and the device in fa.
        ; Returns C = 1 if there was no answer.  Modifies: A,X,Y

FL_WaitDrive:   ldy #$60                        ;Number of tries
FW_Try:         lda #$00
                sta status
                lda fa
                jsr Listen
                lda #$6f                        ;Command channel
                jsr Second
                lda status
                bmi FW_Fail                     ;Device not present
                jsr UnLsn
                clc
                rts
FW_Fail:        jsr UnLsn
                ldx #$00                        ;Some time between tries
FW_Delay:       lda #$0d                        ;(about 25 ms between the tries)
FW_Delay2:      sec
                sbc #$01
                bne FW_Delay2
                dex
                bne FW_Delay
                dey
                bne FW_Try
                sec
                rts


