; The definitions for drive-install.s and drive-runtime.s (the drive code of the
; Covert Bitops Loadersystem, with files found by name), which are included after
; this, from drive.s or bitops-drive.s.  See drive.s for what these are.
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

        ; What can be set before this file is included.  These are the defaults.
        ;
        ;   PLAYER          the modplayer's version of InitLoader (it leaves the CIAs, the NMI,
        ;                   the memory configuration and the CPU speed alone, and returns .C = 0
        ;                   if the drive code is running in the drive), and the runtime without
        ;                   CLI, so interrupts stay as they are:  for loader-bitops.s
        ;   USETURBOMODE    1 = the runtime sets the SCPU and the C128 to 1 MHz when it opens a file
        ;   ATN_CHECK       0 = the drive code doesn't look at ATN when it has sent a sector
        ;   OPEN_DELAY      1 = a pause of 2.5 ms between sending the name and waiting for the sector
        ;   OPEN_CHECK      0 = the runtime doesn't look at DATA after the name has been sent
        ;   GETBYTE_IRQ     0 = the drive code doesn't allow interrupts while it waits for a byte
        ;
        ; The last four are for experiments (see cbbench-names.s, where they came from).

                ifnconst ATN_CHECK
ATN_CHECK       = 1
                endif
                ifnconst OPEN_DELAY
OPEN_DELAY      = 0
                endif
                ifnconst OPEN_CHECK
OPEN_CHECK      = 1
                endif
                ifnconst GETBYTE_IRQ
GETBYTE_IRQ     = 1
                endif
