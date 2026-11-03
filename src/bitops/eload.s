;-------------------------------------------------------------------------------
; ELoad host code, for reading a file from an SD2IEC, for the modplayer's loader slot
;
; Derived from loaderinit.s of the Covert Bitops Loadersystem V3.06, which is
;
;       Copyright (c) 2002-2023 Lasse Oorni
;
; and is available under the MIT license (see README.md in this directory, which
; goes with the original files, and is not to be separated from them).  The ELoad
; protocol is by Thomas Giesel (skoe), and it was added to the loader by Lasse Oorni.
;
; What's here is the ELoad part of loaderinit.s, the runtime and the helper code
; with the IEC routines, with these changes:
;
;       - The file isn't named by a number, converted to two hexadecimal digits, but
;         with a name of any length, which the caller has put in NAMEPTR and NAMELEN
;         with the KERNAL's SETNAM.  The device number is in FA, as for the KERNAL.
;       - EL_Open does the whole opening, in one routine, and has a pause after the
;         M-E command.  Without that, the SD2IEC (version 1.0.0atentdead0-36 was the
;         one tried) never gets round to the fast protocol, and the machine hangs.
;       - The CPU speed isn't changed here (see loader-eload.s, which does that).
;       - The save routines, and the version of the open that is for turbo mode
;         being off, are left out.
;       - EL_GetNext and EL_Close are new, and the zero page bytes that the code uses
;         are put back as they were when the file is closed.
;
; This assembles to $200 bytes that run from ELOAD_BLOB, with the helper code at
; ELoadHelper, a page after it.  bitops-eload.s (which defines them) is what is
; assembled; this file is included by it.  The first three instructions of the
; blob are its entry points, for loader-eload.s:
;
;       ELOAD_BLOB      jmp EL_Open     open the file whose name is at NAMEPTR, of
;                                       length NAMELEN.  returns with Z = 1 if the
;                                       file couldn't be opened (or is empty)
;       ELOAD_BLOB+3    jmp EL_GetNext  get the next byte of the file, in A.  returns
;                                       with C = 1 if that was the last byte (in which
;                                       case the file is already closed), or if the
;                                       file was over already, with 0 as the byte.
;                                       X and Y aren't changed
;       ELOAD_BLOB+6    jmp EL_Close    close the file, even if it isn't over, and put
;                                       the zero page back.  the same, for after the
;                                       last byte
;-------------------------------------------------------------------------------

fileOpen        = ELOAD_ZP              ;3 bytes of zero page, which are put back
loadTempReg     = ELOAD_ZP+1            ;as they were when the file is closed
loadBufferPos   = ELOAD_ZP+2

NAMELEN         = $b7                   ;the KERNAL's filename length and address,
NAMEPTR         = $bb                   ;and device number
fa              = $ba

                org ELOAD_BLOB

                jmp EL_Open
                jmp EL_GetNext
                jmp EL_Close

        ; Open the file.  Returns with Z = 1 if it failed.

EL_Open:        ldx #$02                        ;save the zero page bytes
EO_Save:        lda fileOpen,x
                sta ELoadSavedZp,x
                dex
                bpl EO_Save
                lda #$01
                sta ELoadHaveSaved

                sta fileOpen                    ;(it's open until the drive says it's not)
                lda #$f0                        ;Open for read
                jsr EL_ListenAndSecond
                ldy #$00
EO_Name:        lda (NAMEPTR),y                 ;The name
                jsr EL_SendByte
                iny
                cpy NAMELEN
                bcc EO_Name
                jsr EL_Unlisten
                jsr EL_Init
                ldx #200                        ;The SD2IEC needs a moment, after the M-E,
EO_Wait:        dex                             ;to start the fast protocol.  This is
                bne EO_Wait                     ;200 * 5 cycles, about a millisecond
                jsr EL_SendLoadCmdFast
                stx loadBufferPos               ;Dummy value to prevent re-refill during initial refill
                jsr EL_Refill
                lda fileOpen                    ;The first refill closes the file if it's
                bne EO_Done                     ;empty, or not there
                jmp EL_RestoreZp                ;(this returns A = 0, Z = 1)
EO_Done:        rts

        ; Get a byte.

EL_GetNext:     lda fileOpen
                beq EG_Over
                jsr EL_GetByteFast
                pha
                lda fileOpen                    ;It was the last one if it's closed now
                beq EG_Last
                pla
                clc
                rts
EG_Last:        pla
                sec
                rts
EG_Over:        lda #$00
                sec
                rts

        ; Close the file.

EL_Close:       lda ELoadHaveSaved              ;Nothing to do if no file was opened
                beq ERZ_Done
                lda fileOpen
                beq EL_RestoreZp
                jsr EL_CloseReadFile            ;(and on to put the zero page back)

        ; Put the zero page bytes back, if they were saved.  Returns A = 0, Z = 1

EL_RestoreZp:   lda ELoadHaveSaved
                beq ERZ_Done
                ldx #$02
ERZ_Loop:       lda ELoadSavedZp,x
                sta fileOpen,x
                dex
                bpl ERZ_Loop
                lda #$00
                sta ELoadHaveSaved
ERZ_Done:       rts

ELoadSavedZp:   dc.b 0,0,0
ELoadHaveSaved: dc.b 0

        ; Read a byte from an opened file.  Do not call after fileOpen becomes 0.
        ;
        ; Returns: byte in A, fileOpen set to 0 after EOF
        ; Modifies: A


EL_GetByteFast: php
EL_GetByteWait: bit $dd00                       ;Wait for drive to signal data ready with
                bmi EL_GetByteWait              ;DATA low
EL_SpriteWait:  lda $d012                       ;Check for sprite Y-coordinate range
EL_MaxSprY:     cmp #$00                        ;(max & min values are filled in the
                bcs EL_NoSprites                ;raster interrupt)
EL_MinSprY:     cmp #$00
                bcs EL_SpriteWait
EL_NoSprites:   sei
EL_BadLineWait: lda $d011
                clc
                sbc $d012
                and #7
                beq EL_BadLineWait
                lda $dd00
                ora #$10
                sta $dd00
                bit loadTempReg
                and #$03
                sta $dd00
                sta EL_Eor+1
                nop
                nop
                nop
                nop
                nop
                lda $dd00
                lsr
                lsr
                eor $dd00
                lsr
                lsr
                eor $dd00
                lsr
                lsr
EL_Eor:         eor #$00
                eor $dd00
                cli
                plp
                dec loadBufferPos
                beq EL_Refill
EL_NoRefill:    rts

        ; The first byte of a block of the file is its length, and an
        ; empty block or $ff is the end.  A is kept, for the byte before.

EL_Refill:      pha
                php
EL_FinishRefill:jsr EL_GetByteFast              ; This will decrement loadBufferPos for the second time, but does not matter
                cmp #$00
                beq EL_EOF
                cmp #$ff
                beq EL_EOF
EL_NoEOF:       sta loadBufferPos               ; Bytes to read in the next "buffer"
                plp
                pla
                rts
EL_EOF:         jsr EL_CloseReadFile
                beq EL_NoEOF

EL_RuntimeEnd:
                if EL_RuntimeEnd > ELoadHelper
                err                             ;the runtime must end before the helper
                endif
                ds.b ELoadHelper - *,0

        ; ELoad helper code / IEC protocol implementation


EL_ListenAndSecond:
                pha
                lda fa
                ora #$20
                jsr EL_SendByteATN
                pla
                jsr EL_SendByteATN
                lda $dd00
                and #$03
                ora #$10                        ;After the secondary address, just CLK low for further non-atn bytes
                sta $dd00
                rts

EL_SendBytePrepare:
                sta loadTempReg
                lda $dd00
                and #$03
                sta EL_SetLinesIdle+1
                rts

EL_SendByteATN: jsr EL_SendBytePrepare
                ora #$08
                bne EL_SendByteCommon

EL_SendByte:
EL_WaitDataLow: bit $dd00                       ;for non-ATN bytes, wait for DATA low before we continue
                bmi EL_WaitDataLow
                jsr EL_SendBytePrepare
EL_SendByteCommon:
                sta $dd00                       ;CLK high -> ready to send; wait for DATA high response
                jsr EL_WaitDataHigh
                pha
                lda #$60
                sec
EL_WaitEOI:     sbc #$01                        ;Wait until we are sure to have generated an EOI response
                cmp #$09                        ;It doesn't matter that every byte we send is with EOI
                bcs EL_WaitEOI
                jsr EL_WaitDataHigh             ;Wait until EOI response over
                sta loadBufferPos               ;Bit counter
                pla
EL_SendByteLoop:and #$08+$03                    ;CLK low
                ora #$10
                sei                             ;Timing of last CLK high (last bit) in ATN bytes is critical for SD2IEC,
                sta $dd00                       ;as delay means enabling JiffyDOS, which we don't want. For simplicity,
                dec loadBufferPos               ;disable IRQs for each bit sent, causing IRQ delay similar to the 2-bit transfer
                bmi EL_SendByteDone
                jsr EL_Delay27
                and #$08+$03
                lsr loadTempReg
                bcs EL_SendBitOne
                ora #$20                        ;CLK high + data bit
EL_SendBitOne:  sta $dd00
                cli
                jsr EL_Delay27
                jmp EL_SendByteLoop
EL_SendByteDone:cli
                rts

EL_Delay27:     jsr EL_Delay18
                jmp EL_Delay12
        ; Close file

EL_CloseReadFile:
                lda #$e0
EL_CloseFile:   jsr EL_ListenAndSecond
                jsr EL_Unlisten                 ;Returns with A=0
EL_CloseFileDelay:
                adc #$01
                bne EL_CloseFileDelay           ;Delay for load - save - load -sequence with NTSC machine, which could hang up without
                sta fileOpen
                rts

        ; Init the eload1 drivecode

EL_Init:        lda #"W"
                ldx #<eloadMWStringEnd
                jsr EL_SendCommand
                lda #"E"
                ldx #<eloadMEStringEnd
EL_SendCommand: sta eloadMWString+2
                ldy #<eloadMWString
                lda #$6f
                jsr EL_ListenAndSecond
EL_SendBlock:   stx EL_SendEndCmp+1
EL_SendBlockLoop:
                lda ELoadHelper,y
                jsr EL_SendByte
                iny
EL_SendEndCmp:  cpy #$00
                bcc EL_SendBlockLoop
EL_Unlisten:    lda #$3f                        ;Unlisten command always after a block
                jsr EL_SendByteATN
                jsr EL_SetLinesIdle             ;Let go of DATA+CLK+ATN
EL_WaitDataHigh:bit $dd00                       ;Wait until device lets go of the DATA line
                bpl EL_WaitDataHigh
                rts

        ; Send load command by fast protocol

EL_SendLoadCmdFast:
                bit $dd00                       ;Wait for drive to signal ready to receive
                bvs EL_SendLoadCmdFast          ;with CLK low
                lda EL_SetLinesIdle+1
                ora #$20
                tax                             ;pull data low to acknowledge
                stx $dd00
EL_SendFastWait:bit $dd00                       ;Wait for drive to release CLK
                bvc EL_SendFastWait
EL_SendFastWaitBorder:
                bit $d011                       ;Wait to be in border for no badlines
                bpl EL_SendFastWaitBorder
                jsr EL_SetLinesIdle             ;Waste cycles / send 0 bits
                jsr EL_SetLinesIdle
                jsr EL_Delay12                  ;Send the lower nybble (always 1)
                stx $dd00
                nop
                nop
EL_SetLinesIdle:lda #$00                        ;Rest of bits / idle value
EL_Delay18:     sta $dd00
                nop
EL_Delay12:     rts

        ; Strings

eloadMWString:  dc.b "M-W"
                dc.w $0300
eloadMEStringEnd:
                dc.b 6
                dc.b "eload1"
eloadMWStringEnd:

ELoadHelperEnd:
                if ELoadHelperEnd > ELoadHelper + $100
                err                             ;the helper must fit in its page
                endif
                ds.b ELoadHelper + $100 - *,0
