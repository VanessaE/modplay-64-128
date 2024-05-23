1 REM This is a simple program to RLE compress a file, written for Blassic
2 REM by Vanessa Ezekowitz, based on the "Traditional" RLE method described at
4 REM   http://michael.dipperstein.com/rle/index.html
5 REM
6 REM Usage:  blassic compress.bas <infile> <outfile>

10 OPEN "I",#1,PROGRAMARG$(1)
20 OPEN "O",#2,PROGRAMARG$(2)

100 gosub 1000
110 ob=by: gosub 1000: if EOF (1) then 400
120 nb=ob: gosub 2000
130 if ob<>by then 110
140 rl=1
150 nb=by: gosub 2000
160 ob=by: gosub 1000: if EOF (1) then 500
170 if by=ob and rl < 255 then rl=rl+1: goto 160
180 if rl=255 then nb=rl: gosub 2000: goto 140
190 nb=rl: gosub 2000: goto 110

400 REM End of file outside a run
410 nb=ob: gosub 2000
420 if ob=by then gosub 2000: nb=1: gosub 2000: nb=by: gosub 2000: nb=0: gosub 2000: goto 10000
430 nb=by: gosub 2000: gosub 2000: nb=0: gosub 2000
440 goto 10000

500 REM End of file within a run
510 if ob<>by then nb=rl: gosub 2000: nb=by: gosub 2000: gosub 2000: nb=0: gosub 2000: goto 10000
520 nb=rl+1: gosub 2000: nb=by: gosub 2000: nb=0: gosub 2000
530 goto 10000

1000 REM read one byte from input stream
1010 a$=INPUT$(1,#1)
1020 by=ASC(a$)
1030 RETURN

2000 REM write a byte to the output stream
2010 print #2, chr$(nb);
2020 return

10000 CLOSE #1: close #2
10010 end
