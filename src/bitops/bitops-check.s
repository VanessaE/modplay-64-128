;-------------------------------------------------------------------------------
; Checks that the loader's sources assemble, the same way as the loader's own
; examples do it.  The Makefiles run this every time.  The output isn't used.
;-------------------------------------------------------------------------------

        processor 6502
        org $0801

        include "config.s"

Start:          rts

        include "loader.s"
        include "loadunpacked.s"
        include "loaderinit.s"
