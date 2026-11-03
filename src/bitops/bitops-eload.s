;-------------------------------------------------------------------------------
; Assembles the ELoad host code (eload.s) into the $200 bytes that
; loader-eload.s includes in the loader image for the SD2IEC.  The Makefiles run
;
;       dasm src/bitops/bitops-eload.s -f3 -osrc/bitops/bitops-eload.o \
;               -Isrc/bitops -v3 -p3
;
; The output is plain bytes, with no load address.  The blob runs from
; the loader slot (see modplay.s), $100 bytes into it, with its helper code a page
; after that.  The slot is at the start of the program, after the load buffer, so
; its address is fixed, and loader-eload.s checks that it's where this expects it.
;-------------------------------------------------------------------------------

        processor 6502

ELOAD_SLOT      = $1d00                 ;where the program has the loader slot
ELOAD_BLOB      = ELOAD_SLOT + $100
ELoadHelper     = ELOAD_SLOT + $200

ELOAD_ZP        = $02                   ;3 bytes of zero page for ELoad's variables

        include "eload.s"
