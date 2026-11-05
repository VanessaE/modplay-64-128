; The part of the Covert Bitops Loadersystem's drive code that is thrown away after
; it has been called (InitLoader), and the drive code itself, which InitLoader
; uploads and starts.  Derived from loaderinit.s, see drive.s.
;-------------------------------------------------------------------------------

        ; Init loader
        ; Can be overwritten after calling
        ;
        ; Returns: loaderMode = $ff if the drive code is running in the drive,
        ;          or 0 if not.  ntscFlag set, timer IRQ disabled, Kernal off ($35)
        ;
        ; With PLAYER:  nothing but ntscFlag (and the delay of the runtime, which
        ; is changed for NTSC) is changed, the KERNAL has to be on, and what is
        ; returned is .C = 0 if the drive code is running in the drive, or 1 if not.
        ; Modifies: A,X,Y

InitLoader:     php
                sei
                ldx #$00
                stx fileOpen
                ifnconst PLAYER
                stx $d07a                       ;SCPU to slow mode
                lda #$7f
                sta $dc0d
                lda $dc0d                       ;Disable & acknowledge IRQ sources
                lda #<NMI
                sta $0318
                lda #>NMI
                sta $0319
                lda #$81                        ;Run CIA2 Timer A once to disable NMI from Restore keypress
                sta $dd0d                       ;Timer A interrupt source
                lda #$01                        ;Timer A count ($0001)
                sta $dd04
                stx $dd05
                lda #%00011001                  ;Run Timer A in one-shot mode
                sta $dd0e
                lda #$36                        ;Kernal on, Basic off
                sta $01
                endif
IL_DetectNtsc1: lda $d012                       ;Detect PAL/NTSC/Drean
IL_DetectNtsc2: cmp $d012
                beq IL_DetectNtsc2
                bmi IL_DetectNtsc1
                cmp #$20
                bcc IL_IsNtsc
IL_CountCycles: inx
                lda $d012
                bpl IL_CountCycles
                cpx #$8d
                bcc IL_IsPal
IL_IsDrean:     txa
IL_IsNtsc:      sta ntscFlag
                lda #$25                        ;Adjust 2-bit fastload transfer delay for NTSC / Drean
                sta FL_Delay
                lda #fastLoadEor
                sta FL_Delay+1
                lda #$03
                sta fastLoadEor
IL_IsPal:       plp

        ; Drive detection stage 1: try to start the drivecode

IL_TryUploadDriveCode:
                lda #$00                        ;Everything that the upload changes in the code and
                sta loaderMode                  ;its data is set as it was, so that this can be called
                lda #>ilDriveCode               ;again, from the same copy
                sta UDC_SendData+2              ;this can be called again, from the same copy
                lda #>drvStart
                sta ilMWString+1
                lda #<drvStart
                sta ilMWString+2
                lda ilNumPacketsInit
                sta ilNumPackets
                lda #$aa
                sta $a5
                ldy #$00
                beq UDC_NextPacket
UDC_SendMW:     lda ilMWString,x                ;Send M-W command (backwards)
                jsr CIOut
                dex
                bpl UDC_SendMW
                ldx #MW_LENGTH
UDC_SendData:   lda ilDriveCode,y               ;Send one byte of drive code
                jsr CIOut
                iny
                bne UDC_NotOver
                inc UDC_SendData+2
UDC_NotOver:    inc ilMWString+2                ;Also, move the M-W pointer forward
                bne UDC_NotOver2
                inc ilMWString+1
UDC_NotOver2:   dex
                bne UDC_SendData
                jsr UnLsn                       ;Unlisten to perform the command
UDC_NextPacket: lda fa                          ;Set drive to listen
                jsr Listen
                lda status                      ;Quit to Kernal mode if error
                bmi IL_NotFast
                lda #$6f
                jsr Second
                ldx #$05
                dec ilNumPackets                ;All "packets" sent?
                bpl UDC_SendMW
UDC_SendME:     lda ilMEString-1,x              ;Send M-E command (backwards)
                jsr CIOut
                dex
                bne UDC_SendME
                jsr UnLsn
IL_WaitDataLow: lda status
                bmi IL_NotFast
                bit $dd00                       ;Wait for drivecode to signal activation with DATA=low
                bpl IL_FastLoadOK               ;If not detected within time window, use slow loading
                dex
                bne IL_WaitDataLow
                beq IL_NotFast                  ;Fastload start failed
                ifconst PLAYER
IL_FastLoadOK:  clc                             ;The drive code is running
                rts
IL_NotFast:     sec                             ;Not a drive that the drive code can start in
                rts
                else
IL_FastLoadOK:  dec loaderMode                  ;Mark IRQ-loader mode in use
                bne IL_Done                     ;No loader runtime copy necessary
IL_NotFast:                                     ;Not a drive that the drive code can start in
IL_Done:        dec $01                         ;Loader init done, switch Kernal off
                rts

        ; NMI routine for init

NMI:            rti
                endif


        ; Non-zeropage variables

loaderMode:     dc.b 0
ntscFlag:       dc.b 0


ilDriveCode:
                rorg drvStart

        ; Drive patch data

        ; 1MHz transfer routine

Drv1MHzSend:    lda drvSendTbl,x
Drv1MHzWait:    ldx $1800                       ;Wait for CLK=low
                beq Drv1MHzWait
                sta $1800
                asl
                and #$0f
                sta $1800
                lda drvSendTbl,y
                sta $1800
                asl
                and #$0f
                sta $1800
                inc Drv2MHzSend+1
                bne *-48
                beq *+13
Drv1MHzSendEnd:

drvFamily:      dc.b $43,$0d,$ff
drvIdByte:      dc.b "8","F","H"
drvIdLocLo:     dc.b $a4,$c6,$e9
drvIdLocHi:     dc.b $fe,$e5,$a6

        ; What differs between the drives, a byte for each of the three:  1581,
        ; CMD FD and CMD HD.  The FD is read as the HD is, through $ff4e, with
        ; the job's track and sector in the native queue ($2802 and $2803 for
        ; job 1), and not as a 1581 is, through $ff54, which on an FD did not
        ; come back from some reads, after a long run of sequential ones (and
        ; which had to have its result read from $03).

drvPatchData:
drvJobTrkLo:    dc.b <$000d,<$2802,<$2802
drvJobTrkHi:    dc.b >$000d,>$2802,>$2802
drvJobSctLo:    dc.b <$000e,<$2803,<$2803
drvJobSctHi:    dc.b >$000e,>$2803,>$2803
drvExecLo:      dc.b <$ff54,<$ff4e,<$ff4e
drvExecHi:      dc.b >$ff54,>$ff4e,>$ff4e
drvLedBit:      dc.b $40,$40,$00
drvLedAdrHi:    dc.b $40,$40,$05
drvLedAdrHi2:   dc.b $40,$40,$05
drvDirTrkLo:    dc.b <$022b,<$54,<$2ba7
drvDirTrkHi:    dc.b >$022b,>$54,>$2ba7
drvDirSctLo:    dc.b <drv1581DirSct,<$56,<$2ba9
drvDirSctHi:    dc.b >drv1581DirSct,>$56,>$2ba9

drvPatchOfs:    dc.b DrvReadTrk+1-DrvReadTrk
                dc.b DrvReadTrk+2-DrvReadTrk
                dc.b DrvReadSct+1-DrvReadTrk
                dc.b DrvReadSct+2-DrvReadTrk
                dc.b DrvExecJsr+1-DrvReadTrk
                dc.b DrvExecJsr+2-DrvReadTrk
                dc.b DrvLed+1-DrvReadTrk
                dc.b DrvLedAcc0+2-DrvReadTrk
                dc.b DrvLedAcc1+2-DrvReadTrk
                dc.b DrvDirTrk+1-DrvReadTrk
                dc.b DrvDirTrk+2-DrvReadTrk
                dc.b DrvDirSct+1-DrvReadTrk
                dc.b DrvDirSct+2-DrvReadTrk
                dc.b 0
                
drv1800Lo:      dc.b <$4001,<$4001,<$8000
drv1800Hi:      dc.b >$4001,>$4001,>$8000

drv1800Ofs:     dc.b Drv2MHzSerialAcc1-Drv2MHzSerialAcc1+1
                dc.b Drv2MHzSerialAcc2-Drv2MHzSerialAcc1+1
                dc.b Drv2MHzSerialAcc3-Drv2MHzSerialAcc1+1
                dc.b Drv2MHzSerialAcc4-Drv2MHzSerialAcc1+1
                dc.b Drv2MHzSerialAcc5-Drv2MHzSerialAcc1+1
                dc.b Drv2MHzSerialAcc6-Drv2MHzSerialAcc1+1
                dc.b DrvSerialAcc7-Drv2MHzSerialAcc1+1
                dc.b DrvSerialAcc8-Drv2MHzSerialAcc1+1
                dc.b DrvSerialAcc9-Drv2MHzSerialAcc1+1
                dc.b DrvSerialAcc10-Drv2MHzSerialAcc1+1
                dc.b DrvSerialAcc11-Drv2MHzSerialAcc1+1
                dc.b DrvSerialAcc12-Drv2MHzSerialAcc1+1
                dc.b 0

DrvDetect:      sei
                ldy #$01
DrvIdLda:       lda $fea0                       ;Recognize drive family
                ldx #$03                        ;(from Dreamload)
DrvIdLoop:      cmp drvFamily-1,x
                beq DrvFFound
                dex                             ;If unrecognized, assume 1541
                bne DrvIdLoop
                beq DrvIdFound
DrvFFound:      lda #<(drvIdByte-1)
                sta DrvIdLoop+1
                lda drvIdLocLo-1,x
                sta DrvIdLda+1
                lda drvIdLocHi-1,x
                sta DrvIdLda+2
                dey
                bpl DrvIdLda
DrvIdFound:     txa
                bne DrvNot1541
                lda #$2c
                nop                             ;(there was a patch of the flush job here, for saving)
                nop
                nop
                lda #$7a                        ;Set data direction so that can compare against $1800 being zero
                sta $1802
                lda $e5c6
                cmp #$37
                bne DrvNot1571                  ;Recognize 1571 as a subtype
                jsr DrvNoData                   ;Set DATA=low to signal C64 we're here, before the slow 2MHz enable
                jsr $904e                       ;Enable 2Mhz mode, overwrites buffer at $700
                jmp DrvPatchDone
DrvNot1571:     ldy #Drv1MHzSendEnd-Drv1MHzSend-1 ;For non-1571, copy 1MHz transfer code
Drv1MHzCopy:    lda Drv1MHzSend,y
                sta DrvSendPatchStart,y
                dey
                bpl Drv1MHzCopy
                bmi DrvPatchDone
DrvNot1541:
DrvPatch1800Loop:
                ldy drv1800Ofs                  ;Patch $1800 accesses
                beq DrvPatch1800Done            ;Offset 0 = endmark
                lda drv1800Lo-1,x
                sta Drv2MHzSerialAcc1,y
                lda drv1800Hi-1,x
                sta Drv2MHzSerialAcc1+1,y
                inc DrvPatch1800Loop+1
                bne DrvPatch1800Loop
DrvPatch1800Done:
DrvPatchGeneralLoop:
                ldy drvPatchOfs
                beq DrvPatchGeneralDone         ;Offset 0 = endmark
                lda drvPatchData-1,x
                sta DrvReadTrk,y
                inx
                inx
                inx
                inc DrvPatchGeneralLoop+1
                bne DrvPatchGeneralLoop
DrvPatchGeneralDone:
                lda #$60                        ;Patch exit jump as RTS
                sta DrvExitJump
DrvPatchDone:   jsr DrvNoData                   ;Set DATA=low to signal C64 we're here
                tax
DrvBeginDelay:  inx                             ;Delay to make sure C64 catches the signal
                bne DrvBeginDelay

        ; Drive main loop

DrvMain:        jsr DrvGetByte                  ;Get the length of the filename (1-16)
                sta DrvNameLen+1
                ldy #$00
DrvNameRecv:    jsr DrvGetByte                  ;(this doesn't change Y)
                sta drvName,y
                iny
DrvNameLen:     cpy #$00
                bcc DrvNameRecv
                jsr DrvGetByte                  ;Get command (it's always 0 = load)

DrvLoad:        jsr DrvFindFile
                bne DrvSendBlk
DrvFileNotFound:
DrvEndMark:     stx drvBuf
                stx drvBuf+1
                jmp DrvSendBlk

DrvSectorLoop:  jsr DrvReadSector               ;Read the data sector
DrvSendBlk:     ldx #$00
Drv2MHzSend:    lda drvBuf
                tay
                and #$0f
Drv2MHzSerialAcc1:
                stx $1800                       ;Set DATA=high to mark data available
                tax
                tya
                lsr
                lsr
                lsr
                lsr
                tay
DrvSendPatchStart:
                lda #$04                        ;Wait for CLK=low
Drv2MHzSerialAcc2:
                bit $1800
                beq Drv2MHzSerialAcc2
                lda drvSendTbl,x
                nop
                nop
Drv2MHzSerialAcc3:
                sta $1800
                asl
                and #$0f
                cmp ($00,x)
                nop
Drv2MHzSerialAcc4:
                sta $1800
                lda drvSendTbl,y
                cmp ($00,x)
                nop
Drv2MHzSerialAcc5:
                sta $1800
                asl
                and #$0f
                cmp ($00,x)
                nop
Drv2MHzSerialAcc6:
                sta $1800
                inc Drv2MHzSend+1
                bne DrvSendBlk
DrvSendDone:    jsr DrvNoData
DrvSerialAcc12: lda $1800                       ;Quit if ATN is low:  the host has stopped
                if ATN_CHECK > 0
                bmi DrvQuitSend                 ;reading (and is clocking out what's left)
                else
                nop                             ;(not looked at, for the test)
                nop
                endif
                lda drvBuf+1                    ;Follow the T/S chain
                ldx drvBuf
                bne DrvSectorLoop
                tay                             ;If 2 first bytes are both 0,
                bne DrvEndMark                  ;endmark has been sent and can return to main loop
                jmp DrvMain
DrvQuitSend:    jmp DrvExitJump                 ;(not through DrvQuit, as there's no JSR to undo here)

DrvGetByte:
                if GETBYTE_IRQ > 0
                cli                             ;Timing not critical; allow interrupts (motor will stop)
                else
                sei                             ;(not allowed, for the test)
                endif
                ldx #$08                        ;Bit counter
DrvGetBitLoop:  lda #$00
DrvSerialAcc7:  sta $1800                       ;Set CLK & DATA high for next bit
DrvSerialAcc8:  lda $1800
                bmi DrvQuit                     ;Quit if ATN is low
                and #$05                        ;Wait for CLK or DATA going low
                beq DrvSerialAcc8
                sei                             ;Disable interrupts after 1st bit to make sure "no data" signal will be on time
                lsr                             ;Read the data bit
                lda #$02
                bcc DrvGetZero
                lda #$08
DrvGetZero:     ror drvReceiveBuf               ;Store the data bit
DrvSerialAcc9:  sta $1800                       ;And acknowledge by pulling the other line low
DrvSerialAcc10: lda $1800                       ;Wait for either line going high
                and #$05
                cmp #$05
                beq DrvSerialAcc10              ;C=0 after exiting this loop
                dex
                bne DrvGetBitLoop
DrvNoData:      lda #$02                        ;DATA low - no sector data to be transmitted yet
DrvSerialAcc11: sta $1800                       ;or C64 cannot yet transmit next byte
                lda drvReceiveBuf
                rts

DrvQuit:        pla
                pla
DrvExitJump:    lda #$1a                        ;Restore data direction when exiting
                sta $1802
                jmp InitializeDrive             ;1541 = exit through Initialize, others = exit through RTS

DrvReadSector:
DrvReadTrk:     stx.w $0008
DrvReadSct:     sta.w $0009
                lda #$80
DrvDoJob:       sta DrvRetry+1
                jsr DrvLed
DrvRetry:       lda #$80
                ldx #$01
DrvExecJsr:     jsr Drv1541Exec                 ;Exec buffer 1 job
                cmp #$02                        ;Error?
                bcs DrvRetry                    ;Retry infinitely until success
DrvSuccess:     sei                             ;Make sure interrupts now disabled
DrvLed:         lda #$08
DrvLedAcc0:     eor $1c00
DrvLedAcc1:     sta $1c00
                rts

Drv1541Exec:    sta $01                         ;Set command for execution
                cli                             ;Allow interrupts to execute command
Drv1541ExecWait:
                lda $01                         ;Wait until command finishes
                bmi Drv1541ExecWait
                pha
                ldx #$01
DrvCheckID:     lda id,x                        ;Check for disk ID change
                cmp iddrv0,x                    ;(1541 only)
                beq DrvIDOK
                sta iddrv0,x
DrvIDOK:        dex
                bpl DrvCheckID
                pla
                rts

        ; Find a file by its name, which is in drvName, drvNameLen+1 bytes long, and
        ; read its first sector.  The name has to be all of the name of the file in
        ; the directory, with that ending where the padding ($a0) starts, or after
        ; 16 characters.  The file can be PRG or SEQ.  Returns Z = 0 if found, or
        ; X = 0 and Z = 1 if not.  The directory is looked through every time.

DrvFindFile:
DrvDirTrk:      ldx drv1541DirTrk               ;Start from the first directory block
DrvDirSct:      lda drv1541DirSct
DrvDirLoop:     jsr DrvReadSector               ;Read a directory block
                ldy #$02
DrvFileLoop:    lda drvBuf,y
                and #$87
                cmp #$81                        ;Closed SEQ file
                beq DrvCheckName
                cmp #$82                        ;Closed PRG file
                bne DrvSkipFile
DrvCheckName:   sty DrvEntry+1                  ;Keep where the entry is
                tya
                clc
                adc #$03
                tay                             ;Y = where the name is
                ldx #$00
DrvNameLoop:    lda drvBuf,y
                cmp drvName,x
                bne DrvNoMatch
                iny
                inx
                cpx DrvNameLen+1                ;(that is the length)
                bne DrvNameLoop
                cpx #$10
                beq DrvMatch                    ;A name of 16 characters ends by itself
                lda drvBuf,y
                cmp #$a0
                beq DrvMatch
DrvNoMatch:
DrvEntry:       ldy #$00
DrvSkipFile:    tya
                clc
                adc #$20
                tay
                bcc DrvFileLoop
                lda drvBuf+1                    ;Go to next directory block, until no
                ldx drvBuf                      ;more directory blocks
                bne DrvDirLoop
                rts                             ;(X = 0, Z = 1)

DrvMatch:       ldy DrvEntry+1
                lda drvBuf+2,y                  ;The first sector of the file
                ldx drvBuf+1,y
                jsr DrvReadSector
                lda #$01
                rts

drvSendTbl:     dc.b $0f,$07,$0d,$05
                dc.b $0b,$03,$09,$01
                dc.b $0e,$06,$0c,$04
                dc.b $0a,$02,$08,$00

drv1541DirSct  = drvSendTbl+7                   ;Byte $01
drv1581DirSct  = drvSendTbl+5                   ;Byte $03

drv1541DirTrk:  dc.b 18
drvReceiveBuf:  dc.b 0

                if drvReceiveBuf >= $0700
                    err
                endif

                if DrvMain < $0500                  ;The sector buffer ($0400-$04ff) isn't to be used by code
                    err
                endif

                rend

ilDriveCodeEnd:

        ; Drive code upload and start commands

ilMWString:     dc.b MW_LENGTH,>drvStart, <drvStart,"W-M"
ilMEString:     dc.b >DrvDetect,<DrvDetect, "E-M"
ilNumPackets:   dc.b (ilDriveCodeEnd-ilDriveCode+MW_LENGTH-1)/MW_LENGTH
ilNumPacketsInit:
                dc.b (ilDriveCodeEnd-ilDriveCode+MW_LENGTH-1)/MW_LENGTH

        ; The drive code must not change the order of its timing-critical parts
        ; relative to the pages that they were in

                if (drvSendTbl & $ff00) != ((drvSendTbl + $0f) & $ff00)
                err                             ;The table can't cross a page
                endif

                if (DrvSendBlk & $ff00) != (DrvSendDone & $ff00)
                err                             ;The send loop can't cross a page
                endif

                if (DrvGetBitLoop & $ff00) != (DrvNoData & $ff00)
                err                             ;The receive loop can't cross a page
                endif
