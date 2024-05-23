
start tok64 mp64.main.fix
0 goto 1
1sys36240
50 POKE53280,.:POKE53281,.:dv=PEEK(186):IFdv<8ORdv>30THENdv=8
60 mh=PEEK(2024):IFmh=20THENPOKE53374,.:POKE53366,.:POKE53375,.:POKE53371,.
70 PRINT"{clear}{ct n}{light gray}{down*3}Reading Data{.*3}"
80 DIM lt(1023),aj(17),sl(31),in$(31),c$(1),pm$(4,4),fr$(7),oo$(1)
90 GOSUB5000:GOSUB5050
100 PRINT"{down}Generating LOG(x) Table{.*3}":FORx=0TO31:lt(x)=.:NEXT
110 lg=LOG(2):FORx=32TO1023:lt(x)=LOG(x)/lg:NEXT:l1=58880:l2=l1+1024
120 FORx=0TO31:POKEl1+x,.:POKEl2+x,.:NEXT
130 PRINT"{down}Generating Pitch Table{.*3}":GOSUB2500
200 OPEN1,dv,15:INPUT#1,z$,z$,z$,z$:CLOSE1
210 PRINT"{clear}{light gray}{ct n} Welcome to {red}Mod{orange}pl{yellow}ay {green}64 {light blue}v1{purple}.2b  {yellow}8/19/2{0*3}"
220 PRINT"{down}{gray}{reverse on} L {reverse off} {light gray}Load Module{space*7}{gray}{reverse on} # {reverse off} {light gray}Change Device"
230 PRINT"{gray}{reverse on} P {reverse off} {light gray}Play Module{space*7}{gray}{reverse on} $ {reverse off} {light gray}Directory"
240 PRINT"{gray}{reverse on} M {reverse off} {light gray}Change Play Mode{space*2}{gray}{reverse on} @ {reverse off} {light gray}DOS Command"
250 IFfi>0THENPRINT"{gray}{reverse on} I {reverse off} {light gray}Show Module Info{space*2}";:GOTO270
260 PRINT"{gray}{reverse on} I {reverse off} {dark gray}Show Module Info{space*2}";
270 IFpm=3ORpm=4ORsp=0THENPRINT"{gray}{reverse on} A {reverse off} {dark gray}SID #2 {light gray}[{blue}N/A{light gray} ]":GOTO290
280 PRINT"{gray}{reverse on} A {reverse off} {light gray}SID #2 {white}[{space*4}]"
290 IFpm=4THENPRINT"{gray}{reverse on} S {reverse off} {dark gray}Stereo {light gray}[{green}ON {light gray}]{space*6}";:GOTO300
291 PRINT"{gray}{reverse on} S {reverse off} {light gray}Stereo {white}[{space*3}]{space*6}";
300 IFpm=1THENa$="{reverse on}{gray} D {reverse off} {light gray}Dither {white}[{space*3}]":b$="{reverse on}{gray} V {reverse off} {light gray}Vol Fix {white}[{space*3}]":GOTO320
310 a$="{reverse on}{gray} D {reverse off} {dark gray}Dither {light gray}[{blue}N/A{light gray}]":b$="{reverse on}{gray} V {reverse off} {dark gray}Vol Fix {light gray}[{blue}N/A{light gray}]"
320 PRINTa$:PRINTb$"{space*5}{reverse on}{gray} X {reverse off} {light gray}Exit Modplay"
330 IFpm=2ANDsp=1THENa$="{gray}{reverse on} B {reverse off} {light gray}Balance Adjust":GOTO350
340 a$="{gray}{reverse on} B {reverse off} {dark gray}Balance Adjust"
350 PRINTa$
360 IFpm=1THENPRINT"{home}{down*7}"TAB(13)oo$(vo)
370 IFpm=1THENPRINT"{home}{down*6}"TAB(34)oo$(di)
380 PRINT"{home}{down*6}"TAB(12)oo$(sp):IFpm<3ANDsp=1THENGOSUB17020
390 PRINT"{home}{down*9}"
400 PRINT"{light gray}Computer speed is{yellow}"mh"MHz{down}"
410 IFfi=0THENPRINT"{light gray}No Song Loaded (Device{yellow}"dv"{left}{light gray})":GOTO440
420 PRINT"{light gray} File{white}:{yellow} "fi$" {light gray}on Device{yellow}"dv:PRINT"{light gray}Title{white}: {yellow}"tl$
430 PRINT"{light gray} Size{white}:{yellow}"sz-1500"{light gray}Bytes"
440 PRINT"{home}{down*16}{light gray}Playback Dev{white}:{light green} "pm$(pm-1,0)" "pm$(pm-1,1);
450 PRINT" in "pm$(pm-1,2)" Bits"
460 IFpm=4THENsp=1:PRINT"{home}{down*6}"TAB(12)"{green}ON "
461 PRINT"{home}{down*16}":WAIT203,64:GETk$
470 IFk$="x"THENPOKE53280,14:POKE53281,6:PRINT"{142}{light blue}{clear}";:END
480 IFk$="#"THENGOSUB10000:GOTO210
490 IFk$="@"THENGOSUB11000:GOTO210
500 IFk$="l"THENGOSUB12000:GOTO210
510 IFk$="$"THENGOSUB8000:GOTO210
520 IFk$="p"ANDfi>0THENGOSUB1000:GOTO210
530 IFk$="m"THENGOSUB2000:GOTO210
540 IFk$="i"ANDfi>0THENpg=0:GOSUB13000:GOTO210
550 IFk$="v"ANDpm=1THENvo=1-vo:PRINT"{home}{down*7}"TAB(13)oo$(vo):GOTO460
560 IFk$="d"ANDpm=1THENdi=1-di:PRINT"{home}{down*6}"TAB(34)oo$(di):GOTO460
570 IFk$="s"THENsp=1-sp:PRINT"{home}{down*6}"TAB(12)oo$(sp):GOTO460
580 IFk$="a"ANDpm<3ANDsp=1THENGOSUB17000:GOTO460
590 IFk$="b"ANDpm=2ANDsp=1THENGOSUB18000:GOTO210
600 GOTO460
1000 WAIT203,41,41
1010 IF(p0=pm)AND(s0=sp)AND(d0=di)THEN1050
1020 s0=sp:d0=di:p0=pm
1030 PRINT"{down}{light gray}One or more Play Settings were changed"
1040 PRINT"A new Pitch Table is being generated{.*3}":GOSUB2500
1050 v=11:IFpm=2ANDsp=1THENv=13
1060 POKE994,pm:POKE995,v
1070 REM: 996-1000 are reserved.
1080 POKE1001,di:POKE1002,vo:POKE1003,sp:POKE1004,s2
1090 POKE1005,lv:POKE1006,rv
1100 SYS25091:SYS25088:SYS25097:RETURN
2000 PRINT"{up}Select Playback Device:{space*16}"
2010 PRINT"{space*37}"
2020 PRINT"{yellow}1{light green}) {light gray}SID Chip in 4 bits":IFmh=20THEN2040
2030 PRINT"{gray}2{green}) {dark gray}SID Chip in 8 bit PWM":GOTO2050
2040 PRINT"{yellow}2{light green}) {light gray}SID Chip in 8 bit PWM"
2050 PRINT"{yellow}3{light green}) {light gray}User Port DAC in 8 bits"
2055 IFmh=20THEN2057
2056 PRINT"{gray}4{green}) {dark gray}DigiMax Interpolated 8 bits":GOTO2060
2057 PRINT"{yellow}4{light green}) {light gray}DigiMax Interpolated 8 bits"
2060 WAIT203,36,36
2070 WAIT203,64,64:GETk$:IFk$>"0"ANDk$<"5"THEN2090
2080 GOTO2070
2090 IFmh=20THENpm=VAL(k$):RETURN
2100 IFk$="2"ORk$="4"THEN2060
2110 pm=VAL(k$):RETURN
2500 IFmh=20THEN2550
2510 IFpm=1THENaj=aj(sp+di*2):GOTO2580
2520 IFpm=2THENPRINT"PWM Mode not available on 1MHz systems":END
2530 IFpm=3THENaj=aj(4+sp)
2535 IFpm=4THENPRINT"Interpolating not available on 1 MHz":PRINT"systems":END
2540 GOTO2580
2550 IFpm=1THENaj=aj(8+sp+di*2):GOTO2580
2560 IFpm=2THENaj=aj(12+sp):GOTO2580
2570 IFpm=3THENaj=aj(14+sp):GOTO2580
2575 IFpm=4THENaj=aj(16+sp)
2580 FORx=32TO1023:z=2^(aj-lt(x)):POKEl1+x,z-INT(z/bg)*bg:POKEl2+x,INT(z/bg)
2590 NEXT:RETURN
3000 is=ib+952:FORx=isTOis+127:a=PEEK(x):IFa>hpTHENhp=a
3010 NEXT:hp=hp-1:ns=31:np=PEEK(ib+950)-1:RETURN
3020 is=ib+472:FORx=isTOis+127:a=PEEK(x):IFa>hpTHENhp=a
3030 NEXT:hp=hp-1:ns=15:np=PEEK(ib+470)-1:POKEib+950,PEEK(ib+470)
3040 FORx=0TO127:POKEib+952+x,PEEK(ib+472+x):NEXT:RETURN
4000 GOSUB6000:IFeTHENPRINT"Error - "rs$;:RETURN
4010 OPEN1,dv,2,"0:"+fi$:z8=.:z9=sz*k1+k1
4020 GOSUB5000
4030 PRINT"{up*3}{space*39}"
4040 PRINT"{space*39}"
4050 PRINT"{up*2}{light gray} Loading File{white}:{light green} "fi$:PRINT"{light gray}{right*4}File Size{white}:{yellow}"sz-1500"{light gray}Bytes."
4060 PRINT"{white}{right*5}{cm @*20}"
4070 PRINT"{right*4}{cm m}{space*20}{cm g}"
4080 PRINT"{right*5}{cm t*20}{up}":ml=0
4090 FORz=0TO31:in$(z)="":sl(z)=.:NEXT
4100 SYS24576:b$="":FORx=1TO4:GET#1,a$:b$=b$+a$:NEXT:x=0:tl$=""
4110 a=PEEK(at+PEEK(ib+x)):IFa=0THEN4130
4120 tl$=tl$+CHR$(a):x=x+1:IFx<20THEN4110
4130 ml=ml+1000:GOSUB16000:mt$="SoundTracker: 15 Smp/4 Trk":z1=600
4140 IFb$="m.k."THENGOSUB3000:mt$="ProTracker: 31 Smp/4 Trk":z1=1080:GOTO4210
4150 IFb$="flt4"THENGOSUB3000:mt$="StarTrekker: 31 Smp/4 Trk":z1=1080:GOTO4210
4160 IFb$="m!k!"THENGOSUB7000:RETURN
4170 IFb$="6chn"THENGOSUB7020:RETURN
4180 IFb$="8chn"THENGOSUB7040:RETURN
4190 IFb$="flt8"THENGOSUB7060:RETURN
4200 CLOSE1:OPEN1,dv,2,"0:"+fi$:SYS24579:GOSUB3020
4210 ml=ml+z1:GOSUB16000:z8=z8+z1:FORx=0TO415:POKEdb+x,.:NEXT
4220 FORx=0TO31:POKEdb+64+x,1:POKEdb+128+x,2:POKEdb+160+x,1:NEXT
4230 FORz=0TO31:in$(z)="{space*15}":NEXT
4240 l$="{blue}":FORx=0TOns-1:zz$="":ad=x*30+ib+20:a=.
4250 FORc=0TO21:z=PEEK(at+PEEK(ad+c)):IF(z>31)THENa=aORz:zz$=zz$+CHR$(z)
4260 NEXT
4270 sl=(PEEK(ib+x*im+42)*bg+PEEK(ib+x*im+43))*2-1:IFsl<3AND(a=.ORa=32ORa=160)THEN4300
4280 IF(a=.)OR(a=32)OR(a=160)THEN4300
4290 in$(x+1)=LEFT$(zz$+"{space*23}",22)
4300 NEXT:ml=ml+500:GOSUB16000
4310 POKE57098,.:FORx=0TOhp+1:SYS24582:ml=ml+k1:GOSUB16000
4320 tl=k1:ca=tb:ra=(xAND63)*k1:rb=0:GOSUB14000
4330 z8=z8+k1:NEXT:ss=(hp+2)*k1
4340 FORx=0TO1023:POKEtb+x,.:NEXT
4350 tl=512:ca=tb:ra=ss-INT(ss/hh)*hh:rb=ss/hh:GOSUB14000:se=ss+512
4360 FORx=0TO31:POKEdb+x,ss-INT(ss/bg)*bg:POKEdb+32+x,INT(ss/bg)ANDff
4370 POKEdb+64+x,ss/hh:POKEdb+96+x,se-INT(se/bg)*bg:POKEdb+128+x,INT(se/bg)ANDff
4380 POKEdb+160+x,se/hh:NEXT
4390 z=0:FORx=0TOns-1:z=z+(PEEK(ib+x*im+42)*bg+PEEK(ib+x*im+43))*2-1:NEXT
4400 i2=32:ss=ss+512:FORx=0TOns-1:sl=(PEEK(ib+x*im+42)*bg+PEEK(ib+x*im+43))*2-1
4410 z8=z8+sl
4420 IFsl>2THENin=x+1
4430 sl(x+1)=0:IFsl<2THEN4690
4440 sl(x+1)=sl
4450 v=PEEK(ib+x*im+45):rs=(PEEK(ib+x*im+46)*bg+PEEK(ib+x*im+47))*2-1
4460 rl=(PEEK(ib+x*im+48)*bg+PEEK(ib+x*im+49))*2-1:IF(rs+rl)>slTHENrl=sl-rs
4470 IFrs<2THENrs=0
4480 IFrl<=2THENrl=0:rs=0
4490 POKEdb+1+x,ss-INT(ss/bg)*bg:POKEdb+33+x,(ss/bg)ANDff:POKEdb+65+x,ss/hh
4500 se=ss+sl:POKEdb+97+x,se-INT(se/bg)*bg:POKEdb+129+x,(se/bg)ANDff
4510 POKEdb+161+x,se/hh
4520 POKEdb+193+x,rs-INT(rs/bg)*bg:POKEdb+225+x,(rs/bg)ANDff:POKEdb+257+x,rs/hh
4530 POKEdb+289+x,rl-INT(rl/bg)*bg:POKEdb+321+x,(rl/bg)ANDff:POKEdb+353+x,rl/hh
4540 POKEdb+385+x,v
4550 z1=INT(ss/hh)AND7:z2=INT((ss+sl)/hh)AND7
4560 IF(z1=7)AND(z2=0)THENGOSUB4750:GOTO4590
4570 POKE57092,ss-INT(ss/bg)*bg:POKE57093,(ss/bg)ANDff:POKE57094,INT(ss/hh)
4580 POKE252,sl-INT(sl/bg)*bg:POKE253,(sl/bg)ANDff:POKE254,sl/hh:SYS24585
4590 ss=ss+sl:IFrl=0ORrl>k1THEN4690
4600 POKE57098,.:ss=ss-sl
4610 rl=rl+1:r1=ss+rs:tl=rl:ca=tb:ra=r1-INT(r1/hh)*hh:rb=r1/hh:GOSUB14010
4620 na=INT(k1/rl)+1:ss=r1+rl
4630 FORad=1TOna:tl=rl:ca=tb:ra=ss-INT(ss/hh)*hh:rb=ss/hh:GOSUB14000:ss=ss+rl
4640 NEXT
4650 rz=rl*na:POKEdb+289+x,rz-INT(rz/bg)*bg:POKEdb+321+x,(rz/bg)ANDff
4660 POKEdb+353+x,rz/hh:se=ss-1
4670 POKEdb+97+x,se-INT(se/bg)*bg:POKEdb+129+x,(se/bg)ANDff:POKEdb+161+x,se/hh
4680 POKEdb+193+x,rs-INT(rs/bg)*bg:POKEdb+225+x,(rs/bg)ANDff:POKEdb+257+x,rs/hh
4690 IFsl<=2THEN4730
4700 tl=o:ca=tb:z=ss-2:ra=z-INT(z/hh)*hh-1:rb=z/hh:GOSUB14010:FORi=0TO8
4710 POKEtb+i,PEEK(tb):NEXT:tl=8:ca=tb:ra=z-INT(z/hh)*hh-1:rb=z/hh
4720 GOSUB14000:ss=ss+8
4730 ml=ml+sl:GOSUB16000:NEXT:CLOSE1:in=1:mu=1
4740 RETURN
4750 df=(INT(ss/hh)*hh+hh)-ss-1:rm=sl-df
4760 POKE57092,ss-INT(ss/bg)*bg:POKE57093,(ss/bg)ANDff:POKE57094,ss/hh
4770 POKE252,df-INT(df/bg)*bg:POKE253,(df/bg)ANDff:POKE254,df/hh:SYS24585
4780 ss=ss+df+1:POKE57092,ss-INT(ss/bg)*bg:POKE57093,(ss/bg)ANDff
4790 POKE57094,ss/hh:POKE252,rm-INT(rm/bg)*bg:POKE253,(rm/bg)ANDff
4800 POKE254,rm/hh:SYS24585:ss=ss+rm:RETURN
4810 END
5000 qt=34:gt=65445:im=30:ff=255:mn=.
5010 hn=240:hd=16:o=1:t=2:th=3:f=4:k8=8192:hh=65536:ck=53296
5020 ve=57098:k1=1024:s1=54272:hp=.:z1=.:z2=.:i2=.:ns=.:bg=256:hm=.
5030 c$(0)=" {left}":c$(1)="{reverse on} {reverse off}{left}":ib=23040:tb=22016:db=58112:at=24320
5040 sp$="{space*20}":oo$(0)="{red}Off":oo$(1)="{light green}On ":RETURN
5050 FORx=0TO3:FORy=0TO2:READpm$(x,y):NEXT:NEXT
5060 FORx=0TO7:READfr$(x):NEXT
5070 FORx=0TO17:READaj(x):NEXT
5080 di=0:vo=1:lf=140:rf=40:lr=.:rr=.
5090 sp=0:s2=215:pm=1:si$="{cyan}D700"
5100 lv=7:rv=15
5110 p0=pm:d0=di:s0=sp:RETURN
6000 OPEN15,dv,15:INPUT#15,a$,b$,c$,d$:CLOSE15:rs$=a$+","+b$+","+c$+","+d$
6010 e=VAL(a$):RETURN
7000 PRINT"{clear}Can't play ProTracker 128-Pattern Mod:":PRINTfi$:CLOSE1:GOSUB5000
7010 ns=0:mt$="":e=1:RETURN
7020 PRINT"{clear}Can't play ProTracker 6 track Module: ":PRINTfi$:CLOSE1:GOSUB5000
7030 ns=0:mt$="":e=1:RETURN
7040 PRINT"{clear}Can't play ProTracker 8 track Module: ":PRINTfi$:CLOSE1:GOSUB5000
7050 ns=0:mt$="":e=1:RETURN
7060 PRINT"{clear}Can't play StarTrekker 8 track Module: ":PRINTfi$:CLOSE1:GOSUB5000
7070 ns=0:mt$="":e=1:RETURN
8000 PRINT"{clear}{yellow}":sys24896:PRINT
9000 PRINT:PRINT"{yellow}* {white}Press Any Key {yellow}*"
9010 WAIT 203,64:WAIT203,64,64:GETzz$:RETURN
10000 PRINT:PRINT"{white}New Device Number? {light green}";:in$="":c=0:mc=2:GOSUB15000
10010 IFin$=""THENRETURN
10020 a=VAL(in$):IFa>7ANDa<31THENdv=a:poke186,a:RETURN
10030 PRINT:PRINT"{red}{down}Illegal Device Number":GOTO9000
11000 in$="":PRINT:PRINT"{light gray}Disk Command":PRINT"{white}@{light green}";:mc=38:c=0:GOSUB15000
11010 IFin$=""THENe=0:RETURN
11020 OPEN1,dv,15,in$:CLOSE1:GOSUB6000:in$="":IFe=0THENRETURN
11030 PRINT:PRINT"{down}{yellow}"rs$:GOTO9000
12000 PRINT:PRINT"{white}Please Enter a Filename or Pattern"
12010 PRINT"{white}On Device{yellow}"dv"{white}-> {light green}";:in$="":mc=16:c=0:GOSUB15000
12020 IFin$=""THENe=0:RETURN
12030 f$=in$:GOSUB12070:IFe=0THEN12050
12040 RETURN
12050 fi=0:PRINT"{down}":GOSUB4000:CLOSE1:IFe=0THENfi=1:RETURN
12060 GOTO9000
12070 OPEN1,dv,0,"$":CLOSE1:GOSUB6000:IFe>0THENPRINT:PRINT"{down}{orange}"rs$:GOTO9000
12080 OPEN1,dv,2,"0:"+f$:CLOSE1:GOSUB6000:IFe>0THENPRINT:PRINT"{down}{orange}"rs$:GOTO9000
12090 b$="":z=.:e=.:OPEN1,dv,0,"$0:"+f$:FORx=1TO34:GET#1,z$:NEXT
12100 GET#1,l$,h$:sz=(ASC(l$+CHR$(0))+ASC(h$+CHR$(0))*256)*254+1500
12110 GET#1,a$:IFa$<>CHR$(34)THEN12110
12120 GET#1,a$:IFa$=CHR$(34)THENfi$=b$:CLOSE1:RETURN
12130 b$=b$+a$:z=z+1:IFz<16THEN12120
12140 fi$=b$:CLOSE1:RETURN
13000 PRINT"{white}{clear}Sample/Info Screen";:IFns=31THENPRINT" - Page{yellow}"pg+1;
13010 PRINT:IFns=31THENPRINT"{down}{gray}{reverse on} Spc {reverse off} {light gray}Switch Pages{space*4}{gray}{reverse on} X {reverse off} {light gray}Exit to Main"
13020 IFns<>31THENPRINT"{down}{gray}{reverse on} Spc {reverse off} {dark gray}Switch Pages{space*4}{gray}{reverse on} X {reverse off} {light gray}Exit to Main"
13030 PRINT"{down}{light gray} File Name{white}: {yellow}"fi$:PRINT"{light gray}Song Title{white}: {yellow}"tl$
13040 PRINT"{white}":sx=pg*15+1:ex=sx+14:IFex=30THENex=31
13050 FORx=sxTOex:IFx<10THENPRINT"{right}";
13060 PRINT"{yellow}"x"{light green}{left}) "in$(x):NEXT:WAIT203,64:WAIT203,64
13070 GETz$:POKE208,0:IFz$=" "ANDns=31THENpg=1-pg:GOTO13000
13080 IFz$="x"THENRETURN
13090 GOTO13070
14000 GOSUB14020:POKE57089,148:RETURN
14010 GOSUB14020:POKE57089,149:RETURN
14020 h=INT(ca/bg):l=ca-h*256
14030 POKE57090,l:POKE57091,h
14040 h=INT(ra/bg):l=ra-h*256
14050 POKE57092,l:POKE57093,h:POKE57094,rb
14060 h=INT(tl/bg):l=tl-h*256
14070 POKE57095,l:POKE57096,h:POKE57098,0:RETURN
15000 GETa$:IFa$<>""THEN15030
15010 IFti>(t2+30)THENt2=ti:c=NOTc:PRINTc$(ABS(c));
15020 GOTO15000
15030 IFa$=CHR$(13)THENPRINT" ";:RETURN
15040 IFa$<>CHR$(20)THEN15070
15050 IF(LEN(in$)>0)THENPRINTa$;:in$=LEFT$(in$,LEN(in$)-1)
15060 GOTO15000
15070 IFLEN(in$)=mcTHEN15000
15080 IFa$=CHR$(34)THENPRINTa$CHR$(20);:GOTO15120
15090 IF(a$>CHR$(31)ANDa$<CHR$(128))ORa$>CHR$(159)THENPRINTa$;:GOTO15120
15100 IFa$<" "THENPRINT"{reverse on}"CHR$(ASC(a$)+64)"{reverse off}";:GOTO15120
15110 IFa$>CHR$(127)ANDa$<CHR$(160)THENPRINT"{reverse on}"CHR$(ASC(a$)-32)"{reverse off}";
15120 in$=in$+a$:GOTO15000
16000 l=INT(ml/sz*160)/8
16010 fr=(l-INT(l))*8:IFl<1THENa$=fr$(fr)+"{reverse off}"+LEFT$(sp$,20-INT(l)):GOTO16030
16020 IFl<20THENa$="{reverse on}"+LEFT$(sp$,INT(l))+"{reverse off}"+fr$(fr)+"{reverse off}"+LEFT$(sp$,20-INT(l))
16030 PRINT"{up}{right*5}{green}"a$"{left}{white}{cm g}":RETURN
17000 IFs2=215THENs2=222:si$="{light blue}DE00":GOTO17020
17010 IFs2=222THENs2=215:si$="{cyan}D700"
17020 PRINT"{home}{down*5}"TAB(34)si$:RETURN
18000 c=.:PRINT"{down*2}{light gray}Please Enter Balance Setting";:IFspTHENPRINT"s";
18010 PRINT:PRINT"{light gray}({green}Range{light green}: {yellow}0{light gray}..{yellow}15{light gray}){down}":in$=MID$(STR$(lv),2)
18020 IFsp=.THENPRINT"{white}--> {light green}"in$;:mc=3:GOSUB15000:a=VAL(in$):GOTO18040
18030 in$=MID$(STR$(lv),2):PRINT"{yellow} Left {white}--> {light green}"in$;:mc=3:GOSUB15000:a=VAL(in$)
18040 IFa<0ORa>15THEN18080
18050 lv=a:IFsp=.THENRETURN
18060 in$=MID$(STR$(rv),2):PRINT:PRINT"{yellow}Right {white}--> {light green}"in$;
18070 mc=3:GOSUB15000:a=VAL(in$):IF(a>-1)AND(a<16)THENrv=a:RETURN
18080 PRINT:PRINT"{down}{red}Invalid Setting":GOTO9000
20000 POKE994,4:aj=16.12:GOSUB2580
20010 SYS25091:SYS25088:SYS25097:RETURN
63000 DATA"Standard","SID","4"
63010 DATA"PWM Mode","SID","8"
63020 DATA"User Port","DAC","8"
63025 DATA"Interp.","DigiMAX","8"
63030 DATA" ","{cm g}","{cm h}","{cm j}","{cm k}","{reverse on}{cm l}","{reverse on}{cm n}","{reverse on}{cm m}"
63040 DATA 19.9,20.05,20.05,20.25,19.75,19.82,20,20
63050 DATA 16.61,16.74,16.82,17.05,17.32,17.73,16.72,17.39,17,16.12
stop tok64
(bastext 1.04)
