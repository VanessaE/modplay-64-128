;-------------------------------------------------------------------------------
; Assembles the drive code (drive-install.s and drive-runtime.s) for the modplayer's
; loader image for drives (src/loader-bitops.s), into one file, that has the install
; part where it runs from, and the runtime where it runs from, with nothing in
; between.  The Makefiles run
;
;       dasm src/bitops/bitops-drive.s -f3 -osrc/bitops/bitops-drive.o \
;               -Isrc/bitops -v3 -p10
;
; The output is plain bytes, with no load address, and starts at INSTALL_ADDR:
;
;   INSTALL_ADDR        the install part, INSTALL_SIZE bytes of it, which is copied to
;                       the load buffer, and called there (InitLoader).  It has the
;                       drive code that it uploads in it, and is thrown away after
;                       (as long as the drive code is started again for every file,
;                       it is fetched again every time)
;   RUNTIME_ADDR        the runtime, which goes in the loader slot (see the
;                       jump table at the start of it, in drive-runtime.s)
;
; Both addresses are fixed because the program has the load buffer, and the loader
; slot after it, at the start of the program (see modplay.s), and loader-bitops.s
; checks that they are where this expects them.
;-------------------------------------------------------------------------------

        processor 6502

PLAYER          = 1             ;(see drive-defs.s)
USETURBOMODE    = 0             ;the speed of the CPU is not for this to change

BITOPS_ZP       = $02           ;7 bytes of zero page, which are put back as they were when
fileOpen        = BITOPS_ZP     ;the file is closed
loadTempReg     = BITOPS_ZP+1
loadBufferPos   = BITOPS_ZP+2
fastLoadEor     = BITOPS_ZP+3
zpLenLo         = BITOPS_ZP+4
zpSrcLo         = BITOPS_ZP+5
zpSrcHi         = BITOPS_ZP+6
BITOPS_ZP_SIZE  = 7

loadBuffer      = $1200         ;where a sector is received:  the page of the right audio buffer, which the
                                ;loader has to itself while a file is read (the install part is in the load
                                ;buffer, and the file is read into that, so it can't be received there)

INSTALL_ADDR    = $1800
INSTALL_SIZE    = $0380
RUNTIME_ADDR    = $1e00
RUNTIME_LIMIT   = $2000         ;(the end of the loader slot)

        include "drive-defs.s"

        org INSTALL_ADDR
        include "drive-install.s"

        if * > INSTALL_ADDR + INSTALL_SIZE
        err                             ;The install part is bigger than INSTALL_SIZE
        endif
        ds.b INSTALL_ADDR + INSTALL_SIZE - *,0
        ds.b RUNTIME_ADDR - *,0

        include "drive-runtime.s"

        if * > RUNTIME_LIMIT
        err                             ;The runtime doesn't fit in the loader slot
        endif
