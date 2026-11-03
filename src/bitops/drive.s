;-------------------------------------------------------------------------------
; The drive code of the Covert Bitops Loadersystem, for reading files from a 1541,
; 1571, 1581, or a CMD FD or HD, by their names
;
; Derived from loaderinit.s and loader.s of the Covert Bitops Loadersystem V3.06,
; which are
;
;       Copyright (c) 2002-2023 Lasse Oorni
;
; and are available under the MIT license (see README.md in this directory, which
; goes with the original files, and is not to be separated from them).
;
; What's here is the part of the loader that uploads code to the drive and starts it
; (InitLoader), the drive code itself, and the runtime that reads from it, with
; these changes:
;
;       - A file isn't named by a number that is two hexadecimal digits of a
;         name, but by its whole name, of 1 to 16 characters, which the host
;         sends to the drive first.  The drive looks the name up in the directory
;         every time a file is opened, and finds PRG and SEQ files (not REL, USR
;         and DEL).  The name has to be all of the name that the file has:  a
;         shorter one that is only the start of it isn't a match.  This is what
;         the 256-entry cache of tracks and sectors that the drive had is traded
;         for, so the drive's RAM at $0300 and $0700 isn't used by it anymore.
;       - OpenFile takes the length of the name in A, and its address in X (low)
;         and Y (high).
;       - Saving a file, the KERNAL fallback and ELoad (see eload.s) aren't
;         here, nor is the check that finds an SD2IEC.  InitLoader leaves
;         loaderMode 0 if the drive code didn't start.
;       - The drive code only differs from the original from DrvMain on, and in
;         DrvFindFile, which is new, so DrvMain is at $0500 and the code that
;         is timing-critical is where it was, or a few bytes later in the same page.
;
; The runtime is assembled where the program puts it, and InitLoader can be
; thrown away after it has been called.  config.s (or one like it) has to be
; included first, and defines the zero page, and loadBuffer, the 256 bytes that
; a sector is received into.
;-------------------------------------------------------------------------------

        ; Kernal zeropage variables

status          = $90
messages        = $9d
fa              = $ba

        ;Kernal routines

ScnKey          = $ff9f
CIOut           = $ffa8
Listen          = $ffb1
Second          = $ff93
UnLsn           = $ffae
Talk            = $ffb4
Tksa            = $ff96
UnTlk           = $ffab
ACPtr           = $ffa5
ChkIn           = $ffc6
ChkOut          = $ffc9
ChrIn           = $ffcf
ChrOut          = $ffd2
Close           = $ffc3
ClAll           = $ffe7
Open            = $ffc0
SetMsg          = $ff90
SetNam          = $ffbd
SetLFS          = $ffba
ClrChn          = $ffcc
GetIn           = $ffe4
Load            = $ffd5
Save            = $ffd8

        ; Drive defines

iddrv0          = $12           ;Disk drive ID (1541 only)
id              = $16           ;Disk ID (1541 only)

drvName         = $0300         ;The name that the drive was asked for
drvBuf          = $0400         ;Sector data buffer
drvStart        = $0404
InitializeDrive = $d005         ;1541 only

MW_LENGTH       = 32            ;Bytes in one M-W command
        ; Init loader
        ; Can be overwritten after calling
        ;
        ; Returns: loaderMode = $ff if the drive code is running in the drive,
        ;          or 0 if not.  ntscFlag set, timer IRQ disabled, Kernal off ($35)
        ; Modifies: A,X,Y

InitLoader:     php
                sei
                ldx #$00
                stx fileOpen
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
IL_FastLoadOK:  dec loaderMode                  ;Mark IRQ-loader mode in use
                bne IL_Done                     ;No loader runtime copy necessary
IL_NotFast:                                     ;Not a drive that the drive code can start in
IL_Done:        dec $01                         ;Loader init done, switch Kernal off
                rts

        ; NMI routine for init

NMI:            rti


        ; Runtime
        ;
        ; Open file
        ;
        ; Parameters: A length of the name (1-16), X/Y address of the name (low/high)
        ; Returns: fileOpen 0 if failed to open (or the file is empty), or the first
        ;          sector is in loadBuffer, as for FL_FillBuffer
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
                cli
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

drvPatchData:
drvJobTrkLo:    dc.b <$000d,<$000d,<$2802
drvJobTrkHi:    dc.b >$000d,>$000d,>$2802
drvJobSctLo:    dc.b <$000e,<$000e,<$2803
drvJobSctHi:    dc.b >$000e,>$000e,>$2803
drvExecLo:      dc.b <$ff54,<DrvFdExec,<$ff4e
drvExecHi:      dc.b >$ff54,>DrvFdExec,>$ff4e
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
                lda drvBuf+1                    ;Follow the T/S chain
                ldx drvBuf
                bne DrvSectorLoop
                tay                             ;If 2 first bytes are both 0,
                bne DrvEndMark                  ;endmark has been sent and can return to main loop
                jmp DrvMain

DrvGetByte:     cli                             ;Timing not critical; allow interrupts (motor will stop)
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

DrvFdExec:      jsr $ff54                       ;FD2000 fix By Ninja
                lda $03
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

                if (DrvMain != $0500)
                    err
                endif

                rend

ilDriveCodeEnd:

        ; Drive code upload and start commands

ilMWString:     dc.b MW_LENGTH,>drvStart, <drvStart,"W-M"
ilMEString:     dc.b >DrvDetect,<DrvDetect, "E-M"
ilNumPackets:   dc.b (ilDriveCodeEnd-ilDriveCode+MW_LENGTH-1)/MW_LENGTH

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
