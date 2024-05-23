      1 REM This program is written for blassic, not the C64, and converts a Sun
      2 REM file to a C64 hires font.  The original file must be flattened,
      3 REM black pixels on a white background, indexed mode using the "black
      4 REM and white" palette, 8 pixels wide, and saved in "Standard" Sun .IM1
      5 REM format.
      6 REM
      7 REM Call as:  blassic fconv-hires.bas infile.im1 outfile.fn
      8 REM
     10 OPEN "I",#1,PROGRAMARG$(1)
     20 OPEN "O",#2,PROGRAMARG$(2)
     30 z$=INPUT$(48,#1)	 : REM ignore Sun header
     35 print #2,chr$(0)chr$(64);: REM new load address is $4000.
     40 a$=INPUT$(1,#1)
     50 PRINT BIN$(ASC(A$),8)	 : REM the ",8" pads to 8 digits.
     60 PRINT #2,a$;
     70 a$=INPUT$(1,#1)		 : REM every other byte is bogus.
     80 GOTO 40			 : REM we just let the program error out.
