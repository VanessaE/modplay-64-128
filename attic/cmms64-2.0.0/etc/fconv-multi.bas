      1 REM This program is written for blassic, not the C64, and converts a Sun
      2 REM file to a C64 multicolor font.  The original file must be flattened,
      3 REM black, and dark grey pixels on a white background, indexed mode 
      4 REM using the full Commodore 64 palette (that is, don't exclude unused
      5 REM colors), 4 pixels wide, and saved in "Standard" Sun .IM8 format.
      6 REM
      7 REM Call as:  blassic fconv-multi.bas infile.im1 outfile.fn
      8 REM
     10 OPEN "I",#1,PROGRAMARG$(1)
     20 OPEN "O",#2,PROGRAMARG$(2)
     30 z$=INPUT$(80,#1)	: REM ignore Sun header
     40 print #2,chr$(0)chr$(32); : REM new load address is $2000.
     50 c=0
     60 for x=0 to 3		: REM read four pixels at a time
     70 a$=INPUT$(1,#1)
     80 a=asc(a$)
     90 if a=1 then b=3	: REM original white background (now Color RAM)
    100 if a=0 then b=1	: REM original black text (now Video Matrix MSB)
    110 if a=12 then b=2 : REM original grey AA (now Video matrix LSB)
    120 c=c+(b*(4^(3-x))) : REM 4^x gives us every other bit value
    130 next
    140 PRINT #2,chr$(c);
    150 GOTO 50		: REM we just let the program error out.
