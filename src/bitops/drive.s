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
;       - A CMD FD is read as a CMD HD is:  through the ROM's $ff4e, with the
;         job's track and sector in the native queue, at $2802 and $2803 for
;         job 1, and not through $ff54, as a 1581 is, which on an FD did not
;         come back from some reads, after a long run of sequential ones.  It
;         gives its result in .A, so DrvFdExec, which read it from $03, is
;         gone.  (The CMD FD's entries in the tables at drvPatchData are what
;         is different.)
;       - The drive code only differs from the original from DrvMain on, in
;         DrvFindFile, which is new, and in those tables, so DrvMain is at
;         $0500 and the code that is timing-critical is where it was, or a few
;         bytes later in the same page.
;
; The runtime is assembled where the program puts it, and InitLoader can be
; thrown away after it has been called.  config.s (or one like it) has to be
; included first, and defines the zero page, and loadBuffer, the 256 bytes that
; a sector is received into.
;-------------------------------------------------------------------------------

        ; The three parts that this is made of.  (The modplayer uses the install part
        ; and the runtime separately:  see bitops-drive.s.)

                include "drive-defs.s"
                include "drive-install.s"
                include "drive-runtime.s"
