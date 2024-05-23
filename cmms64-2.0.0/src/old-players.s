; Modplay Super-64 CPU v1.5 Source Code
; Currently handles the following:

; Most modes use a 'delay' timer controlled by BASIC that adjusts the speed
; of all routines to match about 42 KHz, the speed of the Digimax driver.

; Mode  Description
;   1   SID chip(s) in 4 bits (Dithering available)
;   2   SID chip(s) in 8 bit PWM mode
;   3   User Port DAC circuit(s)

; Stereo is available in all modes.  Digimax used in stereo User Port mode.

.org $6200

rombank = $01
lonote = 1023
hinote = 16
noteperl = $02
noteperh = noteperl+4
oldperiodl = noteperh+4
oldperiodh = oldperiodl+4
notestopl = oldperiodh+4
notestoph = notestopl+4
arpnote1l = notestoph+4
arpnote1h = arpnote1l+4
arpnote2l = arpnote1h+4
arpnote2h = arpnote2l+4
arpcounter = arpnote2h+4
arpflag = arpcounter+4
setvolflag = arpflag+4
portaflag = setvolflag+4
vslidedir = portaflag+4
pslide = vslidedir+4
vslide = pslide+4
porta = vslide+4
trackvol = porta+4
vol1 = trackvol+4
vol2 = vol1+2
vol3 = vol2+2
vol4 = vol3+2
samplenum = vol4+2
enableflgs = samplenum+4
ticks = enableflgs+1
tempobpm = ticks+1
tempotpd = tempobpm+1
command = tempotpd+1
cmdarg = command+4
oldcommand = cmdarg+4
oldcmdarg = oldcommand+4
lastkey = oldcmdarg+4
tempa = lastkey+1
tempb = tempa+5
tempc = tempb+5
tempd = tempc+5
tempx = tempd+5
tempy = tempx+1
temppnt1 = tempy+1
second = temppnt1+2
third = second+4
fourth = third+4
fifth = fourth+4
sixth = fifth+4
seventh = sixth+4
eighth = seventh+4
patindex = eighth+4
breakaddr = patindex+2
patnumber = breakaddr+2
rownumber = patnumber+1
fraction = rownumber+1
stepl = fraction+4
steph = stepl+4
trkpntl = steph+4
trkpnth = trkpntl+4
trkpntb = trkpnth+4
startl = trkpntb+4
starth = startl+4
startb = starth+4
endl = startb+4
endh = endl+4
endb = endh+4
offset = endb+4
tempper = offset+4
sampnum = tempper+4
sid4outright = sampnum+4
sid8outloright = sid4outright+2
sid8outhiright = sid8outloright+2
sid8clkloright = sid8outhiright+2
sid8clkhiright = sid8clkloright+2
ntperoff = sid8clkhiright+2

temppnt3 = $fa
temppnt4 = $fc
rightsid = $fe
abortflag = $03e1
playmode = $03e2
delay = $03e3
delay2 = $03e4          ; $03e5-$03e8 are reserved for future use.
dither = $03e9          ; 0=Normal 4 bit, 1=enable dithering
volfix = $03ea          ; 0=normal 6581 SID, 1=fix volume for 8580
stereo = $03eb          ; 0=mono, 1=stereo
rsidcopy = $03ec        ; Base address page of stereo SID (n. $D7)
balleft = $03ed         ; Global Volume Left Side (PWM STEREO ONLY)
balright = $03ee        ; Global Volume Right Side (PWM STEREO ONLY)
left = %11001011
right = %11001111
trk1data = $0340
trk2data = $0348
trk3data = $0350
trk4data = $0358
arptablel = $0360
arptableh = $0370
vibtablel = $0380
vibtableh = $0390
patternbuf = $5600
patterntop = $5a00      ; Raw Header Data is $5A00 to $5EFF.
songlength = $5db6
patterntbl = $5db8      ; ASCII Conv. Table is $5F00 to $5FFF.
voltable = $9000
tempotbl = $e000
tempotbh = $e100
page0temp = $e200
lsbsaddr = $e300
msbsaddr = $e320
bnksaddr = $e340
lsbsend = $e360
msbsend = $e380
bnksend = $e3a0
lsblppnt = $e3c0
msblppnt = $e3e0
bnklppnt = $e400
lsblplen = $e420
msblplen = $e440
bnklplen = $e460
volumes = $e480         ; Signed-to-Unsigned table is $E500 to $E5FF.
divide16 = $e500
ntperiod = $e600        ; Unused Ram is $EF00 to $FFEF

; I/O Registers

sid = $d400
sid8outlo = sid+2
sid8clklo = sid+4
sid8outhi = sid+9
sid8clkhi = sid+11
sid4out = sid+24
sidnoise = sid+27
keycols = $dc00
keyrows = $dc01
digitrack = $dd00
userout = $dd01
tempo = $dd04
dmacmd = $df01
dmaadl = $df02
dmaadh = $df03
dmalo = $df04
dmahi = $df05
dmabnk = $df06
dmadal = $df07
dmadah = $df08
dmaver = $df0a

jmp playsong
jmp initsound
jmp playsamp
jmp silence

reudata
 .byte 0
bittable
 .byte 1,2,4,8,16,32,64,128

 .byte 0,0,0,"vibrato vars"

vibflag
 .byte 0,0,0,0
vibrate
 .byte 0,0,0,0
vibdepth
 .byte 0,0,0,0
vibtopl
 .byte 0,0,0,0
vibtoph
 .byte 0,0,0,0
vibbotl
 .byte 0,0,0,0
vibboth
 .byte 0,0,0,0
vibstepf
 .byte 0,0,0,0
vibstepl
 .byte 0,0,0,0
vibsteph
 .byte 0,0,0,0
stepfract
 .byte 0,0,0,0
vibcounter
 .byte 0,0,0,0
vibhalfc
 .byte 0,0,0,0
upflag
 .byte 0,0,0,0
vibwave
 .byte 0,0,0,0

 .byte 0,0,0,"Jump tables",0,0,0

jumptab1l
 .byte <arpeggio
 .byte <slideup
 .byte <slidedn
 .byte <slide2nt
 .byte <vibrato
 .byte <slidevs
 .byte <vibratovs
 .byte <unused
 .byte <unused
 .byte <soffset
 .byte <volslide
 .byte <posjump
 .byte <setvol
 .byte <patbrk
 .byte <unused
 .byte <setspeed

jumptab1h
 .byte >arpeggio
 .byte >slideup
 .byte >slidedn
 .byte >slide2nt
 .byte >vibrato
 .byte >slidevs
 .byte >vibratovs
 .byte >unused
 .byte >unused
 .byte >soffset
 .byte >volslide
 .byte >posjump
 .byte >setvol
 .byte >patbrk
 .byte >unused
 .byte >setspeed

jumptab2l
 .byte <darpeggio
 .byte <dslideup
 .byte <dslidedn
 .byte <dslide2nt
 .byte <dvibrato
 .byte <dslidevs
 .byte <dvibratovs
 .byte <unused
 .byte <unused
 .byte <unused
 .byte <dvolslide
 .byte <unused
 .byte <unused
 .byte <unused
 .byte <unused
 .byte <unused

jumptab2h
 .byte >darpeggio
 .byte >dslideup
 .byte >dslidedn
 .byte >dslide2nt
 .byte >dvibrato
 .byte >dslidevs
 .byte >dvibratovs
 .byte >unused
 .byte >unused
 .byte >unused
 .byte >dvolslide
 .byte >unused
 .byte >unused
 .byte >unused
 .byte >unused
 .byte >unused

playsong
 sei
 lda #0
 sta 53280
 lda #32
 sta 53265
 lda #53
 sta rombank
 ldx #2
 
copylp1
 lda $00,x
 sta page0temp,x
 inx
 bne copylp1

 lda #$7f
 sta $dd0d
 lda #$00
 sta $dd0e
 lda #23
 sta $dd00
 lda #255
 sta $dd01
 sta $dd03
 lda #63
 sta $dd02
 lda #0
 ldx #2

clrloop
 sta $00,x
 inx
 bne clrloop
 ldx #61

clrloop2
 dex
 sta vibflag,x
 bne clrloop2
 sta abortflag
 sta dmacmd
 lda rsidcopy
 sta rightsid+1
 sta sid4outright+1
 sta sid8outloright+1
 sta sid8outhiright+1
 sta sid8clkloright+1
 sta sid8clkhiright+1
 lda #$18
 sta sid4outright
 lda #2
 sta sid8outloright
 lda #9
 sta sid8outhiright
 lda #4
 sta sid8clkloright
 lda #$0b
 sta sid8clkhiright
 lda playmode
 cmp #2
 bne notpwmstr
 lda stereo
 beq notpwmstr
 lda #8
 sta ntperoff

notpwmstr
 lda #1
 sta dmadal
 lda #0
 sta dmadah
 lda #0
 sta dmaver
 lda #$0f
 sta enableflgs
 lda #125
 sta tempobpm
 lda #6
 sta tempotpd
 jsr calctempo
 lda #<lonote
 sta noteperl
 sta noteperl+1
 sta noteperl+2
 sta noteperl+3
 lda #>lonote
 sta noteperh
 sta noteperh+1
 sta noteperh+2
 sta noteperh+3
 lda #>voltable
 sta vol1+1
 sta vol2+1
 sta vol3+1
 sta vol4+1
 lda #1
 sta startb
 sta startb+1
 sta startb+2
 sta startb+3
 sta endb
 sta endb+1
 sta endb+2
 sta endb+3
 sta trkpntb
 sta trkpntb+1
 sta trkpntb+2
 sta trkpntb+3
 lda #3
 sta endh
 sta endh+1
 sta endh+2
 sta endh+3

newpatn
 lda #0
 sta rownumber
 sta dmalo
 ldx patnumber
 lda patterntbl,x
 asl
 asl
 sta dmahi
 lda #0
 adc #0
 sta dmabnk
 lda #<patternbuf
 sta dmaadl
 lda #>patternbuf
 sta dmaadh
 lda #0
 sta dmaver
 sta dmadal
 lda #4
 sta dmadah
 lda #$95
 sta dmacmd
 lda #8
 sta dmadal
 lda #0
 sta dmadah
 sta dmaver
 sta dmaadh
 lda #$09
 sta $dd0e
 lda breakaddr+1
 bne setbreak
 lda #<patternbuf
 sta patindex
 lda #>patternbuf
 sta patindex+1
 jmp startnote

setbreak
 lda breakaddr
 sta patindex
 lda breakaddr
 sta patindex+1

startnote
 lda #$fe
 sta keycols
 lda keyrows
 cmp #$bf
 bne chkspc
 lda #2 
 sta abortflag
 jmp stopsong

chkspc
 lda #$7f
 sta keycols
 lda keyrows
 cmp #$ef
 bne nostop
 lda #1
 sta abortflag
 jmp stopsong

nostop
 cmp #$fe
 bne notog1
 jmp toggle1

notog1
 cmp #$f7
 bne notog2
 jmp toggle2

notog2
 lda #$fd
 sta keycols
 lda keyrows
 cmp #$fe
 bne notog3
 jmp toggle3

notog3
 cmp #$f7
 bne notog4
 jmp toggle4

notog4
 lda #$df
 sta keycols
 lda keyrows
 cmp #$fd
 bne nokeys
 jmp pause

nokeys
 lda #0
 sta lastkey
 jmp rowcmds

toggle1
 lda #1
 cmp lastkey
 bne tgl1
 jmp rowcmds

tgl1
 sta lastkey
 lda enableflgs
 eor #$01
 sta enableflgs
 and #$01
 bne tgon1
 lda #0
 ldx #0
 jsr sv2
 jmp tg11

tgon1
 lda trackvol
 ldx #0
 jsr sv2

tg11
 ldx #0
 jmp rowcmds

toggle2
 lda #2
 cmp lastkey
 bne tgl2
 jmp rowcmds

tgl2
 sta lastkey
 lda enableflgs
 eor #$02
 sta enableflgs
 and #$02
 bne tgon2
 lda #0
 ldx #1
 jsr sv2
 jmp tg21

tgon2
 lda trackvol+1
 ldx #1
 jsr sv2

tg21
 ldx #1
 jmp rowcmds

toggle3
 lda #3
 cmp lastkey
 bne tgl3
 jmp rowcmds

tgl3
 sta lastkey
 lda enableflgs
 eor #$04
 sta enableflgs
 and #$04
 bne tgon3
 lda #0
 ldx #2
 jsr sv2
 jmp tg31

tgon3
 lda trackvol+2
 ldx #2
 jsr sv2

tg31
 ldx #2
 jmp rowcmds

toggle4
 lda #4
 cmp lastkey
 bne tgl4
 jmp rowcmds

tgl4
 sta lastkey
 lda enableflgs
 eor #$08
 sta enableflgs
 and #$08
 bne tgon4
 lda #0
 ldx #3
 jsr sv2
 jmp tg41

tgon4
 lda trackvol+3
 ldx #3
 jsr sv2

tg41
 ldx #3
 jmp rowcmds

pause
 lda #5
 cmp lastkey
 beq rowcmds
 sta lastkey
 lda #$df
 sta keycols
 lda #$49
 sta sid+4
 sta sid+11
 sta sid+18
 ldy #4
 sta (rightsid),y
 ldy #11
 sta (rightsid),y
 ldy #18
 sta (rightsid),y
 lda #$fd

pausedb
 cmp keyrows
 beq pausedb
 lda #$fd

pausewt
 cmp keyrows
 bne pausewt
 lda #$41
 sta sid+18
 ldy #18
 sta (rightsid),y

rowcmds
 ldx #4
 lda #0

clrrowloop
 dex
 sta setvolflag,x
 sta portaflag,x
 sta vslide,x
 sta pslide,x
 sta offset,x
 sta vslidedir,x
 sta arpflag,x
 sta vibflag,x
 bne clrrowloop
 ldy #2
 lda (patindex),y
 tay
 ldx divide16,y
 lda jumptab1l,x
 sta jsrcmd1+1
 lda jumptab1h,x
 sta jsrcmd1+2
 lda command
 sta oldcommand
 stx command
 ldy #3
 ldx #0
 lda cmdarg
 sta oldcmdarg
 lda (patindex),y
 sta cmdarg

jsrcmd1
 jsr $0000
 ldy #6
 lda (patindex),y
 tay
 ldx divide16,y
 lda jumptab1l,x
 sta jsrcmd2+1
 lda jumptab1h,x
 sta jsrcmd2+2
 lda command+1
 sta oldcommand+1
 stx command+1
 ldy #7
 ldx #1
 lda cmdarg+1
 sta oldcmdarg+1
 lda (patindex),y
 sta cmdarg+1

jsrcmd2
 jsr $0000
 ldy #10
 lda (patindex),y
 tay
 ldx divide16,y
 lda jumptab1l,x
 sta jsrcmd3+1
 lda jumptab1h,x
 sta jsrcmd3+2
 lda command+2
 sta oldcommand+2
 stx command+2
 ldy #11
 ldx #2
 lda cmdarg+2
 sta oldcmdarg+2
 lda (patindex),y
 sta cmdarg+2

jsrcmd3
 jsr $0000
 ldy #14
 lda (patindex),y
 tay
 ldx divide16,y
 lda jumptab1l,x
 sta jsrcmd4+1
 lda jumptab1h,x
 sta jsrcmd4+2
 lda command+3
 sta oldcommand+3
 stx command+3
 ldy #15
 ldx #3
 lda cmdarg+3
 sta oldcmdarg+3
 lda (patindex),y
 sta cmdarg+3

jsrcmd4
 jsr $0000

 ldy #0
 lda (patindex),y
 beq freqchk1
 ldy portaflag
 bne freqchk1
 cmp samplenum
 sta samplenum
 bne ns1
 ldy vslide
 beq ns1
 ldx samplenum
 lda volumes,x
 ldx #0
 jsr setvol
 jmp freqchk1

ns1
 jsr setsamp1

freqchk1
 ldy #2
 lda (patindex),y
 and #$0f
 sta tempa
 dey
 ldx #0
 ora (patindex),y
 beq sampchk2
 lda portaflag
 bne sampchk2
 lda tempa
 sta noteperh
 lda (patindex),y
 sta noteperl
 jsr stepcalc
 lda offset
 ora vibflag
 bne no1
 jsr start1
 lda setvolflag
 bne sampchk2

no1
 ldx samplenum
 lda volumes,x
 ldx #0
 jsr setvol

sampchk2
 ldy #4
 lda (patindex),y
 beq freqchk2
 ldy portaflag+1
 bne freqchk2
 cmp samplenum+1
 sta samplenum+1
 bne ns2
 ldy vslide+1
 beq ns2
 ldx samplenum+1
 lda volumes,x
 ldx #1
 jsr setvol
 jmp freqchk2

ns2
 jsr setsamp2

freqchk2
 ldy #6
 lda (patindex),y
 and #$0f
 sta tempa
 dey
 ldx #1
 ora (patindex),y
 beq sampchk3
 lda portaflag+1
 bne sampchk3
 lda tempa
 sta noteperh+1
 lda (patindex),y
 sta noteperl+1
 jsr stepcalc
 lda offset+1
 ora vibflag+1
 bne no2
 jsr start2
 lda setvolflag+1
 bne sampchk3

no2
 ldx samplenum+1
 lda volumes,x
 ldx #1
 jsr setvol

sampchk3
 ldy #8
 lda (patindex),y
 beq freqchk3
 ldy portaflag+2
 bne freqchk3
 cmp samplenum+2
 sta samplenum+2
 bne ns3
 ldy vslide+2
 beq ns3
 ldx samplenum+2
 lda volumes,x
 ldx #2
 jsr setvol
 jmp freqchk3

ns3
 jsr setsamp3

freqchk3
 ldy #10
 lda (patindex),y
 and #$0f
 sta tempa
 dey
 ldx #2
 ora (patindex),y
 beq sampchk4
 lda portaflag+2
 bne sampchk4
 lda tempa
 sta noteperh+2
 lda (patindex),y
 sta noteperl+2
 jsr stepcalc
 lda offset+2
 ora vibflag+2
 bne no3
 jsr start3
 lda setvolflag+2
 bne sampchk4

no3
 ldx samplenum+2
 lda volumes,x
 ldx #2
 jsr setvol

sampchk4
 ldy #12
 lda (patindex),y
 beq freqchk4
 ldy portaflag+3
 bne freqchk4
 cmp samplenum+3
 sta samplenum+3
 bne ns4
 ldy vslide+3
 beq ns4
 ldx samplenum+3
 lda volumes,x
 ldx #3
 jsr setvol
 jmp freqchk4

ns4
 jsr setsamp4

freqchk4
 ldy #14
 lda (patindex),y
 and #$0f
 sta tempa
 dey
 ldx #3
 ora (patindex),y
 beq startmixer
 lda portaflag+3
 bne startmixer
 lda tempa
 sta noteperh+3
 lda (patindex),y
 sta noteperl+3
 jsr stepcalc
 lda offset+3
 ora vibflag+3
 bne no4
 jsr start4
 lda setvolflag+3
 bne startmixer

no4
 ldx samplenum+3
 lda volumes,x
 ldx #3
 jsr setvol

startmixer
 lda tempotpd
 sec
 sbc #1
 sta ticks
 lda #>trk1data
 sta dmaadh

 lda #<trk1data
 sta dmaadl
 lda arpflag
 beq noarp1
 ldx #0
 jsr calcarp

noarp1
 lda arpflag+1
 beq noarp2
 ldx #1
 jsr calcarp

noarp2
 lda arpflag+2
 beq noarp3
 ldx #2
 jsr calcarp

noarp3
 lda arpflag+3
 beq vibchk1
 ldx #3
 jsr calcarp

vibchk1
 ldx #0
 lda vibflag
 bne vib1
 sta vibstepf
 sta vibstepl
 sta vibsteph
 jsr stepcalc
 jmp vibchk2

vib1
 jsr vibcalc

vibchk2
 ldx #1
 lda vibflag+1
 bne vib2
 sta vibstepf+1
 sta vibstepl+1
 sta vibsteph+1
 jsr stepcalc
 jmp vibchk3

vib2
 jsr vibcalc

vibchk3
 ldx #2
 lda vibflag+2
 bne vib3
 sta vibstepf+2
 sta vibstepl+2
 sta vibsteph+2
 jsr stepcalc
 jmp vibchk4

vib3
 jsr vibcalc

vibchk4
 ldx #3
 lda vibflag+3
 bne vib4
 sta vibstepf+3
 sta vibstepl+3
 sta vibsteph+3
 jsr stepcalc
 jmp timetick

vib4
 jsr vibcalc

timetick
 jsr mixer

tickcmds
 ldx command
 lda jumptab2l,x
 sta jsrticks1+1
 lda jumptab2h,x
 sta jsrticks1+2
 txa
 ldx #0

jsrticks1
 jsr $0000

js2
 ldx command+1
 lda jumptab2l,x
 sta jsrticks2+1
 lda jumptab2h,x
 sta jsrticks2+2
 txa
 ldx #1

jsrticks2
 jsr $0000

js3
 ldx command+2
 lda jumptab2l,x
 sta jsrticks3+1
 lda jumptab2h,x
 sta jsrticks3+2
 txa
 ldx #2

jsrticks3
 jsr $0000

js4
 ldx command+3
 lda jumptab2l,x
 sta jsrticks4+1
 lda jumptab2h,x
 sta jsrticks4+2
 txa
 ldx #3

jsrticks4
 jsr $0000

nt
 lda ticks
 beq checkbreak
 dec ticks
 beq checkbreak
 jmp timetick

checkbreak
 jsr mixer
 lda breakaddr+1
 beq checkpatn
 lda #0
 sta breakaddr
 sta breakaddr+1
 jmp nextpatn

checkpatn
 inc rownumber
 lda breakaddr+1
 bne nextpatn
 clc
 lda patindex
 adc #16
 sta patindex
 bne patnotdone
 inc patindex+1
 lda patindex+1
 cmp #>patterntop
 beq nextpatn

patnotdone
 jmp startnote

nextpatn
 inc patnumber
 lda patnumber
 cmp songlength
 beq stopsong
 jmp newpatn

stopsong
 ldx #2

copylp2
 ldy $0000,x
 lda page0temp,x
 sta $00,x
 tya
 sta page0temp,x
 inx
 bne copylp2

 lda #55
 sta rombank
 lda #0
 jsr 65412
 jsr 65511
 jsr 65451
 jsr 65454
 lda #27
 sta 53265
 lda #0
 sta 53280
 lda #23
 sta $dd00
 lda #255
 sta $dd01
 lda #63
 sta $dd02
 lda #0
 sta $dd03
 lda #$00
 sta $dd0e
 lda #$7f
 sta $dd0d
 cli
 lda abortflag

unused
 rts

; Row command interpreters

arpeggio
 beq stoparp
 lda #1
 sta arpflag,x
 lda cmdarg,x
 cmp oldcmdarg,x
 bne samearp
 lda #1
 sta arpcounter,x

samearp
 rts

stoparp
 lda #0
 sta arpflag,x
 sta arpnote1l,x
 sta arpnote1h,x
 sta arpnote2l,x
 sta arpnote2h,x
 lda #1
 sta arpcounter,x
 rts

calcarp
 lda noteperl,x
 clc
 adc #<ntperiod
 sta temppnt1
 lda noteperh,x
 adc #>ntperiod
 adc ntperoff
 sta temppnt1+1
 ldy #0
 lda (temppnt1),y
 sta stepl,x
 sta tempa
 lda temppnt1+1
 clc
 adc #4
 sta temppnt1+1
 lda (temppnt1),y
 sta steph,x
 sta tempa+1

; first new note

firstnote
 lda cmdarg,x
 lsr
 lsr
 lsr
 lsr
 tay
 lda arptablel,y
 sta tempa
 lda arptableh,y
 sta tempa+1
 lda stepl,x
 sta tempb
 sta tempd
 lda steph,x
 sta tempb+1
 lda #0
 sta tempc
 sta tempc+1
 sta tempc+2
 sta tempa+2
 sta tempa+3
 clc
 stx tempx
 jsr multbyte
 lda tempb+1
 sta tempd
 jsr multbyte
 ldx tempx
 lda tempc+1
 sta tempc
 lda tempc+2
 sta tempc+1
 lda tempc+3
 sta tempc+2
 lda #0
 sta tempc+3
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lda tempc
 sta arpnote1l,x
 lda tempc+1
 sta arpnote1h,x

; second new note

 lda cmdarg,x
 and #$0f
 tay
 lda arptablel,y
 sta tempa
 lda arptableh,y
 sta tempa+1
 lda stepl,x
 sta tempb
 sta tempd
 lda steph,x
 sta tempb+1
 lda #0
 sta tempc
 sta tempc+1
 sta tempc+2
 sta tempa+2
 sta tempa+3
 clc
 stx tempx
 jsr multbyte
 lda tempb+1
 sta tempd
 jsr multbyte
 ldx tempx
 lda tempc+1
 sta tempc
 lda tempc+2
 sta tempc+1
 lda tempc+3
 sta tempc+2
 lda #0
 sta tempc+3
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lda tempc
 sta arpnote2l,x
 lda tempc+1
 sta arpnote2h,x
 rts

multbyte
 ldx #0
 ldy #8

mloop1
 lda tempd
 and bittable,x
 beq dontadd
 lda tempc
 adc tempa
 sta tempc
 lda tempc+1
 adc tempa+1
 sta tempc+1
 lda tempc+2
 adc tempa+2
 sta tempc+2
 lda tempc+3
 adc tempa+3
 sta tempc+3 
 php
 asl tempa
 rol tempa+1
 rol tempa+2
 rol tempa+3
 plp
 inx
 dey
 bne mloop1
 rts

dontadd
 asl tempa
 rol tempa+1
 rol tempa+2
 rol tempa+3
 inx
 dey
 bne mloop1
 rts

slideup
 sta pslide,x
 lda #<hinote
 sta notestopl,x
 lda #>hinote
 sta notestoph,x
 rts

slidedn
 sta pslide,x
 lda #<lonote
 sta notestopl,x
 lda #>lonote
 sta notestoph,x
 rts

slide2nt
 bne cksl2nt

snt
 lda porta,x

cksl2nt
 sta pslide,x
 sta porta,x
 dey
 dey
 lda (patindex),y
 sta tempper
 iny
 lda (patindex),y
 and #$0f
 sta tempper+1
 ora tempper
 beq contslide
 lda tempper
 sta notestopl,x
 lda tempper+1
 sta notestoph,x

contslide
 sec
 lda noteperl,x
 sbc notestopl,x
 lda noteperh,x
 sbc notestoph,x
 lda #2
 bcc pordown
 lda #1

pordown
 sta portaflag,x
 lda #3
 sta command,x
 lda oldcommand,x
 beq holdporta
 cmp #1
 beq holdporta
 cmp #2
 beq holdporta
 cmp #3
 beq holdporta
 cmp #5
 beq holdporta
 jsr retrig
 ldy samplenum,x
 lda volumes,y
 jmp setvol

holdporta
 rts

vibrato
 lda #1
 sta vibflag,x
 rts

vibcalc
 lda command,x
 cmp #5
 bne startvibc
 rts

startvibc
 sta tempa
 stx tempx
 lda oldcommand,x
 cmp #4
 beq samevib1
 cmp #5
 beq samevib1
 jmp newvibrato

samevib1
 lda tempa 
 bne nvib
 rts

newvibrato
 lda #0
 sta upflag,x
 sta stepfract,x

nvib
 stx tempx
 clc
 lda noteperl,x
 adc #<ntperiod
 sta temppnt1
 lda noteperh,x
 adc #>ntperiod
 adc ntperoff
 sta temppnt1+1
 ldy #0
 lda (temppnt1),y
 sta vibbotl,x
 clc
 lda temppnt1+1
 adc #4
 sta temppnt1+1
 lda (temppnt1),y
 sta vibboth,x
 lda tempa
 lsr
 lsr
 lsr
 lsr
 and #$0f
 bne newrate
 lda vibrate,x
 
newrate
 sta vibrate,x
 lda tempa
 and #$0f
 bne newdepth
 lda vibdepth,x

newdepth
 sta vibdepth,x
 tay
 lda vibtablel,y
 sta tempb
 lda vibtableh,y
 sta tempb+1
 lda #0
 sta tempa+2
 sta tempa+3
 sta tempb+2
 sta tempc
 sta tempc+1
 sta tempc+2
 sta tempc+3
 sta tempc+4
 lda vibbotl,x
 sta tempa
 lda vibboth,x
 sta tempa+1
 clc
 lda tempb
 sta tempd
 jsr multbyte
 lda tempb+1
 sta tempd
 jsr multbyte

 ldx tempx
 lda tempc+1
 sta tempc
 lda tempc+2
 sta tempc+1
 lda tempc+3
 sta tempc+2
 lda #0
 sta tempc+3
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc
 lsr tempc+2
 ror tempc+1
 ror tempc

 lda tempc
 sta vibtopl,x
 lda tempc+1
 sta vibtoph,x
 lda #0
 sta tempc
 sta tempc+1
 sta tempc+2
 sta tempc+3
 sta tempc+4
 sta tempa+2
 sta tempa+3
 sta tempa+4

 sec
 lda vibtopl,x
 sbc vibbotl,x
 sta tempa
 lda vibtoph,x
 sbc vibboth,x
 sta tempa+1
 lda vibrate,x 
 sta tempd
 clc
 ldy #4
 ldx #0
 jsr mbyte2
 ldx tempx
 lda #0
 lsr tempc+1
 ror tempc
 ror
 lsr tempc+1
 ror tempc
 ror
 lsr tempc+1
 ror tempc
 ror
 lsr tempc+1
 ror tempc
 ror
 lsr tempc+1
 ror tempc
 ror
 lsr tempc+1
 ror tempc
 ror

triwave1
 sta vibstepf,x
 lda tempc
 sta vibstepl,x
 lda tempc+1
 sta vibsteph,x
 lda vibwave,x
 cmp #2
 bne newvib2

 lda oldcommand,x
 cmp #4
 beq samevib

newvib2
 lda tempotpd
 sta vibcounter,x
 lsr
 sta vibhalfc,x
 lda vibbotl,x
 sta stepl,x
 sta tempa
 lda vibboth,x
 sta steph,x
 sta tempa+1
 jmp stepcalc2

samevib
 rts

mbyte2
 lda tempd
 and bittable,x
 beq noadd2
 lda tempc
 adc tempa
 sta tempc
 lda tempc+1 
 adc tempa+1
 sta tempc+1
 lda tempc+2
 adc tempa+2
 sta tempc+2
 php
 asl tempa
 rol tempa+1
 rol tempa+2
 plp
 inx
 dey 
 bne mbyte2
 rts

noadd2
 php
 asl tempa
 rol tempa+1
 rol tempa+2
 plp
 inx
 dey
 bne mbyte2
 rts

slidevs
 stx tempx
 sty tempy
 jsr volslide
 ldy tempy
 jsr snt
 ldx tempx
 lda #5
 sta command,x
 lda #1
 sta setvolflag,x
 rts

vibratovs
 stx tempx
 jsr volslide
 ldx tempx
 lda #6
 sta command,x
 lda #1
 sta setvolflag,x
 sta vibflag,x
 rts

soffset
 sta offset,x
 rts

volslide
 sta tempa
 tay
 lda divide16,y
 beq chky
 sta vslide,x
 lda #1
 sta vslidedir,x
 sta setvolflag,x
 lda tempa
 rts

chky
 lda tempa
 and #$0f
 beq novls
 sta vslide,x
 lda #0
 sta vslidedir,x
 lda #1
 sta setvolflag,x

novls
 lda tempa
 rts

posjump
 sta tempa
 sec
 cmp songlength
 beq setpos
 bcc setpos
 lda #0
 sta breakaddr
 sta breakaddr+1
 rts

setpos
 lda tempa
 sec
 sbc #1
 sta patnumber
 lda #<patternbuf
 sta breakaddr
 lda #>patternbuf
 sta breakaddr+1
 rts

setvol
 sec
 cmp #64
 bcc sv
 lda #63

sv
 sta trackvol,x
 lda enableflgs
 and bittable,x
 beq novol
 lda trackvol,x
 ldy #1
 sty setvolflag,x

sv2
 tay
 txa
 asl
 tax
 tya
 clc
 adc #>voltable
 sta vol1+1,x

novol
 rts

patbrk
 sta tempa
 and #$0f
 sta tempb
 lda tempa
 and #$f0
 lsr
 lsr
 sta tempa
 lsr
 lsr
 clc
 adc tempa
 asl
 adc tempb
 ldx #0
 stx tempb
 asl
 rol tempb
 asl
 rol tempb
 asl
 rol tempb
 asl
 rol tempb
 clc
 adc #<patternbuf
 sta breakaddr
 lda tempb
 adc #>patternbuf
 sta breakaddr+1
 rts

setspeed
 lda cmdarg,x
 bne dospd
 rts

dospd
 sec
 cmp #$20
 bcc setticks
 sta tempobpm
 jmp calctempo

setticks
 sta tempotpd

calctempo
 ldx tempobpm
 lda tempotbh,x
 sta tempo+1
 lda tempotbl,x
 sta tempo
 lda #$49
 sta $dd0e
 rts

; 'Tick' command interpreters

darpeggio
 lda cmdarg,x
 bne arp1
 rts

arp1
 lda arpcounter,x
 bne newnote1
 jsr stepcalc
 jmp incarpcnt

newnote1
 and #$01
 beq newnote2
 clc
 lda arpnote1l,x
 sta stepl,x
 sta tempa
 lda arpnote1h,x
 sta steph,x
 sta tempa+1
 jsr stepcalc2
 jmp incarpcnt

newnote2
 clc
 lda arpnote2l,x
 sta stepl,x
 sta tempa
 lda arpnote2h,x
 sta steph,x
 sta tempa+1
 jsr stepcalc2

incarpcnt
 inc arpcounter,x
 lda arpcounter,x
 cmp #3
 bne counterok
 lda #0
 sta arpcounter,x

counterok
 rts

dslideup
 lda noteperl,x
 sec
 sbc pslide,x
 sta noteperl,x
 lda noteperh,x
 sbc #0
 sta noteperh,x
 bcc endofsup
 lda noteperl,x
 sec
 sbc notestopl,x
 lda noteperh,x
 sbc notestoph,x
 bcc endofsup
 jsr stepcalc
 rts

endofsup
 lda notestopl,x
 sta noteperl,x
 lda notestoph,x
 sta noteperh,x
 jsr stepcalc
 lda #0
 sta pslide,x
 sta portaflag,x
 rts

dslidedn
 lda noteperl,x
 clc
 adc pslide,x
 sta noteperl,x
 lda noteperh,x
 adc #0
 sta noteperh,x
 lda noteperl,x
 sec
 sbc notestopl,x
 lda noteperh,x
 sbc notestoph,x
 bcs endofsdn
 jsr stepcalc
 rts

endofsdn
 lda notestopl,x
 sta noteperl,x
 lda notestoph,x
 sta noteperh,x
 jsr stepcalc
 lda #0
 sta pslide,x
 sta portaflag,x
 rts

dslide2nt
 lda portaflag,x
 bne s2nt
 sta pslide,x
 rts

s2nt
 cmp #1
 beq dslideup
 cmp #2
 beq dslidedn
 lda #0
 sta pslide,x
 sta portaflag,x
 rts

novib
 rts

dvibrato
 stx tempx
 lda vibflag,x
 beq novib
 lda vibwave,x
 beq tri
 jmp nottri

tri
 lda upflag,x
 bne goup

godown
 sec
 lda stepfract,x
 sbc vibstepf,x
 sta stepfract,x
 lda stepl,x
 sbc vibstepl,x
 sta stepl,x
 sta tempa
 lda steph,x
 sbc vibsteph,x
 sta steph,x
 sta tempa+1
 sec
 lda vibbotl,x
 cmp tempa
 lda vibboth,x
 cmp tempa+1
 bcs toolow
 lda tempa+1
 jmp stepcalc2

toolow
 lda #1
 sta upflag,x
 lda #0
 sta stepfract,x
 lda vibbotl,x
 sta stepl,x
 sta tempa
 lda vibboth,x
 sta steph,x
 sta tempa+1
 jmp stepcalc2

goup
 clc
 lda stepfract,x
 adc vibstepf,x
 sta stepfract,x
 lda stepl,x
 adc vibstepl,x
 sta stepl,x
 sta tempa
 lda steph,x
 adc vibsteph,x
 sta steph,x
 sta tempa+1
 sec
 lda tempa
 cmp vibtopl,x
 lda tempa+1
 cmp vibtoph,x
 bcs toohigh
 lda tempa+1
 jmp stepcalc2

toohigh
 lda #0
 sta upflag,x
 sta stepfract,x
 lda vibtopl,x
 sta stepl,x
 sta tempa
 lda vibtoph,x
 sta steph,x
 sta tempa+1
 jmp stepcalc2

nottri
 cmp #2
 beq square

ramp
 lda #0
 sta upflag,x
 sec
 lda stepfract,x
 sbc vibstepf,x
 sta stepfract,x
 lda stepl,x
 sbc vibstepl,x
 sta stepl,x
 sta tempa
 lda steph,x
 sbc vibsteph,x
 sta steph,x
 sta tempa+1
 sec
 lda vibbotl,x
 cmp tempa
 lda vibboth,x
 cmp tempa+1
 bcs toolow2
 lda tempa+1
 jmp stepcalc2

toolow2
 lda #0
 sta upflag,x
 sta stepfract,x
 lda vibtopl,x
 sta stepl,x
 sta tempa
 lda vibtoph,x
 sta steph,x
 sta tempa+1
 jmp stepcalc2 

square
 sec
 lda vibcounter,x
 cmp vibhalfc,x
 bcs high

low
 lda vibbotl,x
 sta stepl,x
 sta tempa
 lda vibboth,x
 sta steph,x
 sta tempa+1
 jmp stepcalc2
 
high
 lda vibtopl,x
 sta stepl,x
 sta tempa
 lda vibtoph,x
 sta steph,x
 sta tempa+1
 jmp stepcalc2

dvibratovs
 stx tempx
 jsr dvolslide
 ldx tempx
 jmp dvibrato

dslidevs
 stx tempx
 jsr dvolslide
 ldx tempx
 jmp dslide2nt

dvolslide
 lda vslidedir,x
 beq voldown
 clc
 lda trackvol,x
 adc vslide,x
 jmp setvol

voldown
 sec
 lda trackvol,x
 sbc vslide,x
 bcs dovol
 lda #0

dovol
 jmp sv

; Misc. Routines..

retrig
 lda startl,x
 sta trkpntl,x
 lda starth,x
 sta trkpnth,x
 lda startb,x
 sta trkpntb,x
 lda #0
 sta arpcounter,x
 rts

setsamp1
 ldy #0
 lda (patindex),y
 tax
 lda lsbsaddr,x
 sta startl
 sta trkpntl
 lda msbsaddr,x
 sta starth
 clc
 adc offset
 sta trkpnth
 lda bnksaddr,x
 sta startb
 adc #0
 sta trkpntb
 lda lsbsend,x
 sta endl
 lda msbsend,x
 sta endh
 lda bnksend,x
 sta endb
 lda #0
 sta fraction
 lda setvolflag
 bne es1
 ldx samplenum
 lda volumes,x
 ldx #0
 jsr setvol

es1
 rts

setsamp2
 ldy #4
 lda (patindex),y
 tax
 lda lsbsaddr,x
 sta startl+1
 sta trkpntl+1
 lda msbsaddr,x
 sta starth+1
 clc
 adc offset+1
 sta trkpnth+1
 lda bnksaddr,x
 sta startb+1
 adc #0
 sta trkpntb+1
 lda lsbsend,x
 sta endl+1
 lda msbsend,x
 sta endh+1
 lda bnksend,x
 sta endb+1
 lda #0
 sta fraction+1
 lda setvolflag+1
 bne es2
 ldx samplenum+1
 lda volumes,x
 ldx #1
 jsr setvol

es2
 rts

setsamp3
 ldy #8
 lda (patindex),y
 tax
 lda lsbsaddr,x
 sta startl+2
 sta trkpntl+2
 lda msbsaddr,x
 sta starth+2
 clc
 adc offset+2
 sta trkpnth+2
 lda bnksaddr,x
 sta startb+2
 adc #0
 sta trkpntb+2
 lda lsbsend,x
 sta endl+2
 lda msbsend,x
 sta endh+2
 lda bnksend,x
 sta endb+2
 lda #0
 sta fraction+2
 lda setvolflag+2
 bne es3
 ldx samplenum+2
 lda volumes,x
 ldx #2
 jsr setvol

es3
 rts

setsamp4
 ldy #12
 lda (patindex),y
 tax
 lda lsbsaddr,x
 sta startl+3
 sta trkpntl+3
 lda msbsaddr,x
 sta starth+3
 clc
 adc offset+3
 sta trkpnth+3
 lda bnksaddr,x
 sta startb+3
 adc #0
 sta trkpntb+3
 lda lsbsend,x
 sta endl+3
 lda msbsend,x
 sta endh+3
 lda bnksend,x
 sta endb+3
 lda #0
 sta fraction+3
 lda setvolflag+3
 bne es4
 ldx samplenum+3
 lda volumes,x
 ldx #3
 jsr setvol

es4
 rts

stepcalc
 lda noteperl,x
 clc
 adc #<ntperiod
 sta temppnt1
 lda noteperh,x
 adc #>ntperiod
 adc ntperoff
 sta temppnt1+1
 ldy #0
 lda (temppnt1),y
 sta stepl,x
 sta tempa
 lda temppnt1+1
 clc
 adc #4
 sta temppnt1+1
 lda (temppnt1),y
 sta steph,x
 sta tempa+1

stepcalc2
 lsr
 sta fifth,x        ; 4/8
 ror tempa
 lsr
 sta third,x        ; 2/8
 sta tempb+1
 ror tempa
 lsr
 sta second,x       ; 1/8
 sta tempa+1
 ror tempa
 lda tempa
 asl 
 sta tempb
 clc
 lda tempa
 adc tempb
 sta tempc
 lda tempa+1
 adc tempb+1
 sta tempc+1
 sta fourth,x       ; 3/8
 lda tempb
 adc tempc
 sta tempd
 lda tempb+1
 adc tempc+1
 sta tempd+1
 sta sixth,x        ; 5/8
 lda tempd
 adc tempa
 sta tempd
 lda tempd+1
 adc tempa+1
 sta tempd+1
 sta seventh,x      ; 6/8
 lda tempd
 adc tempa
 lda tempd+1
 adc tempa+1
 sta eighth,x       ; 7/8
 rts
 
start1
 lda startl
 sta trkpntl
 lda starth
 sta trkpnth
 lda startb
 sta trkpntb
 lda #0
 sta arpcounter
 rts

start2
 lda startl+1
 sta trkpntl+1
 lda starth+1
 sta trkpnth+1
 lda startb+1
 sta trkpntb+1
 lda #0
 sta arpcounter+1
 rts

start3
 lda startl+2
 sta trkpntl+2
 lda starth+2
 sta trkpnth+2
 lda startb+2
 sta trkpntb+2
 lda #0
 sta arpcounter+2
 rts

start4
 lda startl+3
 sta trkpntl+3
 lda starth+3
 sta trkpnth+3
 lda startb+3
 sta trkpntb+3
 lda #0
 sta arpcounter+3
 rts

; Sample Player Routines

playsamp
 sei
 lda $fd
 sta stepsa+1
 lda $fe
 sta stepsb+1
 ldx #54
 stx rombank
 ldx $fc
 lda lsbsaddr,x
 sta startsa+1
 lda msbsaddr,x
 sta startsb+1
 lda bnksaddr,x
 sta startsc+1
 clc
 lda lsbsend,x
 sta endsmpa+1
 lda msbsend,x
 sta endsmpb+1
 lda bnksend,x
 sta endsmpc+1
 jsr startsa
 lda #<reudata
 sta dmaadl
 lda #>reudata
 sta dmaadh
 lda #$c0
 sta dmaver
 ldy #0

updates
 clc
fracts lda #0
stepsa adc #0
 sta fracts+1
samppnta lda #0
stepsb adc #0
 sta samppnta+1
 sta dmalo
samppntb lda #0
 adc #0
 sta samppntb+1
 sta dmahi
samppntc lda #0
 adc #0
 sta samppntc+1
 sta dmabnk
 lda #1
 sta dmadal
 lda #$95
 sta dmacmd
 sec
 lda samppnta+1
endsmpa sbc #0
 lda samppntb+1
endsmpb sbc #0
 lda samppntc+1
endsmpc sbc #0
 bcc cyclesmp
 lda lsblppnt,x
 ora msblppnt,x
 ora bnklppnt,x
 ora lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 beq stopsamp
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta samppnta+1
 lda msbsaddr,x
 adc msblppnt,x
 sta samppntb+1
 lda bnksaddr,x
 adc bnklppnt,x
 sta samppntc+1
 clc
 lda samppnta+1
 adc lsblplen,x
 sta endsmpa+1
 lda samppntb+1
 adc msblplen,x
 sta endsmpb+1
 lda samppntc+1
 adc bnklplen,x
 sta endsmpc+1
 jmp updates

cyclesmp
 lda reudata
 sta userout
 lda #$7f
 sta keycols
 lda keyrows
 cmp #$ef
 beq stopsamp
 jmp updates

stopsamp
 lda #0
 sta dmaver
 lda #55
 sta rombank
 cli
 rts

startsa lda #0
 sta samppnta+1
startsb lda #0
 sta samppntb+1
startsc lda #0
 sta samppntc+1
 rts

initsound
 lda playmode
 cmp #1
 beq sid4init
 cmp #2
 beq sid8init
 cmp #3
 bne exitinit
 jmp digiinit
exitinit
 rts

sid4init
 jsr silencesid
 lda dither
 beq nodither  
 lda #$ff
 sta sid+14
 ldy #14
 sta (rightsid),y
 sta sid+15
 ldy #15
 sta (rightsid),y
 lda #$81
 sta sid+18
 ldy #18
 sta (rightsid),y
nodither
 lda volfix
 beq novolfix
 lda #$f0
 sta sid+6
 ldy #6
 sta (rightsid),y
 lda #$41
 sta sid+4
 ldy #4
 sta (rightsid),y
novolfix
 rts

sid8init
 jsr silencesid
 lda #120
 sta sid+1
 ldy #1
 sta (rightsid),y
 sta sid+8
 ldy #8
 sta (rightsid),y
 lda #$10
 sta sid+6
 ldy #6
 sta (rightsid),y
 lda #$c0
 sta sid+13
 ldy #13
 sta (rightsid),y
 lda #$70
 sta sid+20
 ldy #20
 sta (rightsid),y 
 lda #$ff
 sta sid+16
 sta sid+17
 ldy #16
 sta (rightsid),y
 iny
 sta (rightsid),y
 ldx stereo
 bne dostereo
 lda #$0f
 sta sid+24
 rts

dostereo
 lda balleft
 sta sid+24
 lda balright
 ldy #24
 sta (rightsid),y
 rts

digiinit
 jsr silence
 lda #$ff
 sta $dd03 
 rts

silence
 lda #55
 sta rombank
 lda #$00
 sta $dd01

silencesid
 lda rsidcopy
 sta rightsid+1
 lda #0
 sta rightsid
 ldy #$1f
silencelp1
 sta sid,y
 sta (rightsid),y
 dey
 bpl silencelp1
 rts

; This part decides which mixer to use

mixer
 lda stereo
 bne playstereo

playmono
 lda playmode
 cmp #1
 bne nm1
 jmp sid4ud1
nm1
 cmp #2
 bne nm2
 jmp mixer8mono
nm2
 cmp #3
 bne nm3
 jmp userud1
nm3
 pla
 pla
 jmp stopsong   ; Forces the song to stop playing if
                ; Mixer # get's corrupted.

playstereo
 lda playmode
 cmp #1
 bne nstr1
 jmp sid4sud1
nstr1
 cmp #2
 bne nstr2
 jmp mixer8stereo
nstr2
 cmp #3
 bne nm3
 jmp digiud1

; Mixer for 4 bit Mono SID (Dithering Available)

sid4ud1
 lda #<trk1data
 sta dmaadl
 clc
 lda fraction
 adc stepl
 sta fraction
 lda trkpntl
 adc steph
 sta trkpntl
 sta dmalo
 lda trkpnth
 adc #0
 sta trkpnth
 sta dmahi
 lda trkpntb
 adc #0
 sta trkpntb
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx eighth
 ldy trk1data,x
 lda (vol1),y
 ldx second+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx sixth+1
 ldy trk2data,x
 lda (vol2),y
 ldx fourth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 ldy dither
 beq sid4ok1
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4ok1
 lda #255
 clc
sid4ok1
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx delay
dllp9
 dex
 bne dllp9
 
 lda #$95
 sta dmacmd

 ldy trk1data
 lda (vol1),y
 ldx third+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx seventh+1
 ldy trk2data,x
 lda (vol2),y
 ldx fifth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 ldy dither
 beq sid4ok2
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4ok2
 lda #255
sid4ok2
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx delay
dllp10
 dex
 bne dllp10
 
 sec
 lda trkpntl
 sbc endl
 lda trkpnth
 sbc endh
 lda trkpntb
 sbc endb
 bcc sid4ud2
 ldx samplenum
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid4lp1
 ldx #0
 jsr retrig
 lda #0
 sta second
 sta third
 sta fourth
 sta fifth
 sta sixth
 sta seventh
 sta eighth
 sta stepl
 sta steph
 jsr sv2
 jmp sid4ud2

sid4lp1
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl
 lda msbsaddr,x
 adc msblppnt,x
 sta starth
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb
 lda lsblplen,x
 adc startl
 sta endl
 lda msblplen,x
 adc starth
 sta endh
 lda bnklplen,x
 adc startb
 sta endb
 ldx #0
 jsr retrig

sid4ud2
 lda fraction+1
 adc stepl+1
 sta fraction+1
 lda trkpntl+1
 adc steph+1
 sta trkpntl+1
 sta dmalo
 lda trkpnth+1
 adc #0
 sta trkpnth+1
 sta dmahi
 lda trkpntb+1
 adc #0
 sta trkpntb+1
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx second
 ldy trk1data,x
 lda (vol1),y
 ldx fourth+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx eighth+1
 ldy trk2data,x
 lda (vol2),y
 ldx sixth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 ldy dither
 beq sid4ok3
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4ok3
 lda #255
 clc
sid4ok3
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx delay
dllp11
 dex
 bne dllp11
 
 lda #$95
 sta dmacmd

 ldx third
 ldy trk1data,x
 lda (vol1),y
 ldx fifth+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldy trk2data
 lda (vol2),y
 ldx seventh+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 ldy dither
 beq sid4ok4
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4ok4
 lda #255
sid4ok4
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx delay
dllp12
 dex
 bne dllp12 

 sec
 lda trkpntl+1
 sbc endl+1
 lda trkpnth+1
 sbc endh+1
 lda trkpntb+1
 sbc endb+1
 bcc sid4ud3
 ldx samplenum+1
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid4lp2
 ldx #1
 jsr retrig
 lda #0
 sta second+1
 sta third+1
 sta fourth+1
 sta fifth+1
 sta sixth+1
 sta seventh+1
 sta eighth+1
 sta stepl+1
 sta steph+1
 jsr sv2
 jmp sid4ud3

sid4lp2
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+1
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+1
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+1
 lda lsblplen,x
 adc startl+1
 sta endl+1
 lda msblplen,x
 adc starth+1
 sta endh+1
 lda bnklplen,x
 adc startb+1
 sta endb+1
 ldx #1
 jsr retrig

sid4ud3
 lda fraction+2
 adc stepl+2
 sta fraction+2
 lda trkpntl+2
 adc steph+2
 sta trkpntl+2
 sta dmalo
 lda trkpnth+2
 adc #0
 sta trkpnth+2
 sta dmahi
 lda trkpntb+2
 adc #0
 sta trkpntb+2
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx fourth
 ldy trk1data,x
 lda (vol1),y
 ldx sixth+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx second+1
 ldy trk2data,x
 lda (vol2),y
 ldx eighth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 ldy dither
 beq sid4ok5
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4ok5
 lda #255
 clc
sid4ok5
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx delay
dllp13
 dex
 bne dllp13
 
 lda #$95
 sta dmacmd

 ldx fifth
 ldy trk1data,x
 lda (vol1),y
 ldx seventh+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx third+1
 ldy trk2data,x
 lda (vol2),y
 ldy trk3data
 adc (vol3),y
 lsr
 adc tempa
 ldy dither
 beq sid4ok6
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4ok6
 lda #255
sid4ok6
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx delay
dllp14
 dex
 bne dllp14
 
 sec
 lda trkpntl+2
 sbc endl+2
 lda trkpnth+2
 sbc endh+2
 lda trkpntb+2
 sbc endb+2
 bcc sid4ud4
 ldx samplenum+2
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid4lp3
 ldx #2
 jsr retrig
 lda #0
 sta second+2
 sta third+2
 sta fourth+2
 sta fifth+2
 sta sixth+2
 sta seventh+2
 sta eighth+2
 sta stepl+2
 sta steph+2
 jsr sv2
 jmp sid4ud4

sid4lp3
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+2
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+2
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+2
 lda lsblplen,x
 adc startl+2
 sta endl+2
 lda msblplen,x
 adc starth+2
 sta endh+2
 lda bnklplen,x
 adc startb+2
 sta endb+2
 ldx #2
 jsr retrig

sid4ud4
 lda fraction+3
 adc stepl+3
 sta fraction+3
 lda trkpntl+3
 adc steph+3
 sta trkpntl+3
 sta dmalo
 lda trkpnth+3
 adc #0
 sta trkpnth+3
 sta dmahi
 lda trkpntb+3
 adc #0
 sta trkpntb+3
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx sixth
 ldy trk1data,x
 lda (vol1),y
 ldx eighth+3 
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx fourth+1
 ldy trk2data,x
 lda (vol2),y
 ldx second+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 ldy dither
 beq sid4ok7
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4ok7
 lda #255
 clc
sid4ok7
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx delay
dllp15
 dex
 bne dllp15
 
 lda #$95
 sta dmacmd

 ldx seventh
 ldy trk1data,x
 lda (vol1),y
 ldy trk4data
 adc (vol4),y
 lsr
 sta tempa
 ldx fifth+1
 ldy trk2data,x
 lda (vol2),y
 ldx third+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 ldy dither
 beq sid4ok8
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4ok8
 lda #255
sid4ok8
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx delay
dllp16
 dex
 bne dllp16
 
 sec
 lda trkpntl+3
 sbc endl+3
 lda trkpnth+3
 sbc endh+3
 lda trkpntb+3
 sbc endb+3
 bcc sid4chkt
 ldx samplenum+3
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid4lp4
 ldx #3
 jsr retrig
 lda #0
 sta second+3
 sta third+3
 sta fourth+3
 sta fifth+3
 sta sixth+3
 sta seventh+3
 sta eighth+3
 sta stepl+3
 sta steph+3
 jsr sv2
 jmp sid4chkt

sid4lp4
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+3
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+3
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+3
 lda lsblplen,x
 adc startl+3
 sta endl+3
 lda msblplen,x
 adc starth+3
 sta endh+3
 lda bnklplen,x
 adc startb+3
 sta endb+3
 ldx #3
 jsr retrig

sid4chkt
 lda $dd0d
 and #$01
 bne sid4exit
 jmp sid4ud1

sid4exit
 lda #$09
 sta $dd0e
 rts

; Mixer for 8 bit SID in PWM mode

mixer8mono
 lda #$49
 sta sid+18 

sid8ud1
 lda #<trk1data
 sta dmaadl
 clc
 lda fraction
 adc stepl
 sta fraction
 lda trkpntl
 adc steph
 sta trkpntl
 sta dmalo
 lda trkpnth
 adc #0
 sta trkpnth
 sta dmahi
 lda trkpntb
 adc #0
 sta trkpntb
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx eighth
 ldy trk1data,x
 lda (vol1),y
 ldx second+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx sixth+1
 ldy trk2data,x
 lda (vol2),y
 ldx fourth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa

 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 lda #$41
 sta sid8clklo
 sta sid8clkhi

 ldx delay
dllp17
 dex
 bne dllp17

 lda #$95
 sta dmacmd

 clc
 ldy trk1data
 lda (vol1),y
 ldx third+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx seventh+1
 ldy trk2data,x
 lda (vol2),y
 ldx fifth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 lda #$41
 sta sid8clklo
 sta sid8clkhi

 ldx delay
dllp18
 dex
 bne dllp18
 
 sec
 lda trkpntl
 sbc endl
 lda trkpnth
 sbc endh
 lda trkpntb
 sbc endb
 bcc sid8ud2
 ldx samplenum
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid8lp1
 ldx #0
 jsr retrig
 lda #0
 sta second
 sta third
 sta fourth
 sta fifth
 sta sixth
 sta seventh
 sta eighth
 sta stepl
 sta steph
 jsr sv2
 jmp sid8ud2

sid8lp1
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl
 lda msbsaddr,x
 adc msblppnt,x
 sta starth
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb
 lda lsblplen,x
 adc startl
 sta endl
 lda msblplen,x
 adc starth
 sta endh
 lda bnklplen,x
 adc startb
 sta endb
 ldx #0
 jsr retrig

sid8ud2
 lda fraction+1
 adc stepl+1
 sta fraction+1
 lda trkpntl+1
 adc steph+1
 sta trkpntl+1
 sta dmalo
 lda trkpnth+1
 adc #0
 sta trkpnth+1
 sta dmahi
 lda trkpntb+1
 adc #0
 sta trkpntb+1
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx second
 ldy trk1data,x
 lda (vol1),y
 ldx fourth+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx eighth+1
 ldy trk2data,x
 lda (vol2),y
 ldx sixth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 lda #$41
 sta sid8clklo
 sta sid8clkhi

 ldx delay
dllp19
 dex
 bne dllp19 

 lda #$95
 sta dmacmd

 clc
 ldx third
 ldy trk1data,x
 lda (vol1),y
 ldx fifth+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldy trk2data
 lda (vol2),y
 ldx seventh+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 lda #$41
 sta sid8clklo
 sta sid8clkhi

 ldx delay
dllp20
 dex
 bne dllp20
 
 sec
 lda trkpntl+1
 sbc endl+1
 lda trkpnth+1
 sbc endh+1
 lda trkpntb+1
 sbc endb+1
 bcc sid8ud3
 ldx samplenum+1
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid8lp2
 ldx #1
 jsr retrig
 lda #0
 sta second+1
 sta third+1
 sta fourth+1
 sta fifth+1
 sta sixth+1
 sta seventh+1
 sta eighth+1
 sta stepl+1
 sta steph+1
 jsr sv2
 jmp sid8ud3

sid8lp2
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+1
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+1
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+1
 lda lsblplen,x
 adc startl+1
 sta endl+1
 lda msblplen,x
 adc starth+1
 sta endh+1
 lda bnklplen,x
 adc startb+1
 sta endb+1
 ldx #1
 jsr retrig

sid8ud3
 lda fraction+2
 adc stepl+2
 sta fraction+2
 lda trkpntl+2
 adc steph+2
 sta trkpntl+2
 sta dmalo
 lda trkpnth+2
 adc #0
 sta trkpnth+2
 sta dmahi
 lda trkpntb+2
 adc #0
 sta trkpntb+2
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx fourth
 ldy trk1data,x
 lda (vol1),y
 ldx sixth+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx second+1
 ldy trk2data,x
 lda (vol2),y
 ldx eighth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 lda #$41
 sta sid8clklo
 sta sid8clkhi

 ldx delay
dllp21
 dex
 bne dllp21

 lda #$95
 sta dmacmd

 clc
 ldx fifth
 ldy trk1data,x
 lda (vol1),y
 ldx seventh+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx third+1
 ldy trk2data,x
 lda (vol2),y
 ldy trk3data
 adc (vol3),y
 lsr
 adc tempa
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 lda #$41
 sta sid8clklo
 sta sid8clkhi

 ldx delay
dllp22
 dex
 bne dllp22
 
 sec
 lda trkpntl+2
 sbc endl+2
 lda trkpnth+2
 sbc endh+2
 lda trkpntb+2
 sbc endb+2
 bcc sid8ud4
 ldx samplenum+2
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid8lp3
 ldx #2
 jsr retrig
 lda #0
 sta second+2
 sta third+2
 sta fourth+2
 sta fifth+2
 sta sixth+2
 sta seventh+2
 sta eighth+2
 sta stepl+2
 sta steph+2
 jsr sv2
 jmp sid8ud4

sid8lp3
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+2
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+2
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+2
 lda lsblplen,x
 adc startl+2
 sta endl+2
 lda msblplen,x
 adc starth+2
 sta endh+2
 lda bnklplen,x
 adc startb+2
 sta endb+2
 ldx #2
 jsr retrig

sid8ud4
 lda fraction+3
 adc stepl+3
 sta fraction+3
 lda trkpntl+3
 adc steph+3
 sta trkpntl+3
 sta dmalo
 lda trkpnth+3
 adc #0
 sta trkpnth+3
 sta dmahi
 lda trkpntb+3
 adc #0
 sta trkpntb+3
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx sixth
 ldy trk1data,x
 lda (vol1),y
 ldx eighth+3 
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx fourth+1
 ldy trk2data,x
 lda (vol2),y
 ldx second+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 lda #$41
 sta sid8clklo
 sta sid8clkhi

 ldx delay
dllp23
 dex
 bne dllp23
 
 lda #$95
 sta dmacmd

 clc
 ldx seventh
 ldy trk1data,x
 lda (vol1),y
 ldy trk4data
 adc (vol4),y
 lsr
 sta tempa
 ldx fifth+1
 ldy trk2data,x
 lda (vol2),y
 ldx third+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 lda #$41
 sta sid8clklo
 sta sid8clkhi

 ldx delay2
dllp24
 dex
 bne dllp24
 
 sec
 lda trkpntl+3
 sbc endl+3
 lda trkpnth+3
 sbc endh+3
 lda trkpntb+3
 sbc endb+3
 bcc sid8chkt
 ldx samplenum+3
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid8lp4
 ldx #3
 jsr retrig
 lda #0
 sta second+3
 sta third+3
 sta fourth+3
 sta fifth+3
 sta sixth+3
 sta seventh+3
 sta eighth+3
 sta stepl+3
 sta steph+3
 jsr sv2
 jmp sid8chkt

sid8lp4
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+3
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+3
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+3
 lda lsblplen,x
 adc startl+3
 sta endl+3
 lda msblplen,x
 adc starth+3
 sta endh+3
 lda bnklplen,x
 adc startb+3
 sta endb+3
 ldx #3
 jsr retrig

sid8chkt
 lda $dd0d
 and #$01
 bne sid8exit
 jmp sid8ud1

sid8exit
 lda #$09
 sta $dd0e
 lda #$41
 sta sid+18
 rts

; Mixer for 8 bit User Port DAC

userud1
 lda #<trk1data
 sta dmaadl
 clc
 lda fraction
 adc stepl
 sta fraction
 lda trkpntl
 adc steph
 sta trkpntl
 sta dmalo
 lda trkpnth
 adc #0
 sta trkpnth
 sta dmahi
 lda trkpntb
 adc #0
 sta trkpntb
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx eighth
 ldy trk1data,x
 lda (vol1),y
 ldx second+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx sixth+1
 ldy trk2data,x
 lda (vol2),y
 ldx fourth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 sta userout

 ldx delay
dllp25
 dex
 bne dllp25
 
 lda #$95
 sta dmacmd

 ldy trk1data
 lda (vol1),y
 ldx third+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx seventh+1
 ldy trk2data,x
 lda (vol2),y
 ldx fifth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 sta userout

 ldx delay
dllp26
 dex
 bne dllp26
 
 sec
 lda trkpntl
 sbc endl
 lda trkpnth
 sbc endh
 lda trkpntb
 sbc endb
 bcc userud2
 ldx samplenum
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne userlp1
 ldx #0
 jsr retrig
 lda #0
 sta second
 sta third
 sta fourth
 sta fifth
 sta sixth
 sta seventh
 sta eighth
 sta stepl
 sta steph
 jsr sv2
 jmp userud2

userlp1
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl
 lda msbsaddr,x
 adc msblppnt,x
 sta starth
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb
 lda lsblplen,x
 adc startl
 sta endl
 lda msblplen,x
 adc starth
 sta endh
 lda bnklplen,x
 adc startb
 sta endb
 ldx #0
 jsr retrig

userud2
 lda fraction+1
 adc stepl+1
 sta fraction+1
 lda trkpntl+1
 adc steph+1
 sta trkpntl+1
 sta dmalo
 lda trkpnth+1
 adc #0
 sta trkpnth+1
 sta dmahi
 lda trkpntb+1
 adc #0
 sta trkpntb+1
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx second
 ldy trk1data,x
 lda (vol1),y
 ldx fourth+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx eighth+1
 ldy trk2data,x
 lda (vol2),y
 ldx sixth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 sta userout

 ldx delay
dllp27
 dex
 bne dllp27
 
 lda #$95
 sta dmacmd
 
 ldx third
 ldy trk1data,x
 lda (vol1),y
 ldx fifth+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldy trk2data
 lda (vol2),y
 ldx seventh+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 sta userout

 ldx delay
dllp28
 dex
 bne dllp28
 
 sec
 lda trkpntl+1
 sbc endl+1
 lda trkpnth+1
 sbc endh+1
 lda trkpntb+1
 sbc endb+1
 bcc userud3
 ldx samplenum+1
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne userlp2
 ldx #1
 jsr retrig
 lda #0
 sta second+1
 sta third+1
 sta fourth+1
 sta fifth+1
 sta sixth+1
 sta seventh+1
 sta eighth+1
 sta stepl+1
 sta steph+1
 jsr sv2
 jmp userud3

userlp2
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+1
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+1
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+1
 lda lsblplen,x
 adc startl+1
 sta endl+1
 lda msblplen,x
 adc starth+1
 sta endh+1
 lda bnklplen,x
 adc startb+1
 sta endb+1
 ldx #1
 jsr retrig

userud3
 lda fraction+2
 adc stepl+2
 sta fraction+2
 lda trkpntl+2
 adc steph+2
 sta trkpntl+2
 sta dmalo
 lda trkpnth+2
 adc #0
 sta trkpnth+2
 sta dmahi
 lda trkpntb+2
 adc #0
 sta trkpntb+2
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx fourth
 ldy trk1data,x
 lda (vol1),y
 ldx sixth+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx second+1
 ldy trk2data,x
 lda (vol2),y
 ldx eighth+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 sta userout

 ldx delay
dllp29
 dex
 bne dllp29
 
 lda #$95
 sta dmacmd

 ldx fifth
 ldy trk1data,x
 lda (vol1),y
 ldx seventh+3
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx third+1
 ldy trk2data,x
 lda (vol2),y
 ldy trk3data
 adc (vol3),y
 lsr
 adc tempa
 sta userout

 ldx delay
dllp30
 dex
 bne dllp30
 
 sec
 lda trkpntl+2
 sbc endl+2
 lda trkpnth+2
 sbc endh+2
 lda trkpntb+2
 sbc endb+2
 bcc userud4
 ldx samplenum+2
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne userlp3
 ldx #2
 jsr retrig
 lda #0
 sta second+2
 sta third+2
 sta fourth+2
 sta fifth+2
 sta sixth+2
 sta seventh+2
 sta eighth+2
 sta stepl+2
 sta steph+2
 jsr sv2
 jmp userud4

userlp3
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+2
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+2
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+2
 lda lsblplen,x
 adc startl+2
 sta endl+2
 lda msblplen,x
 adc starth+2
 sta endh+2
 lda bnklplen,x
 adc startb+2
 sta endb+2
 ldx #2
 jsr retrig

userud4
 lda fraction+3
 adc stepl+3
 sta fraction+3
 lda trkpntl+3
 adc steph+3
 sta trkpntl+3
 sta dmalo
 lda trkpnth+3
 adc #0
 sta trkpnth+3
 sta dmahi
 lda trkpntb+3
 adc #0
 sta trkpntb+3
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx sixth
 ldy trk1data,x
 lda (vol1),y
 ldx eighth+3 
 ldy trk4data,x
 adc (vol4),y
 lsr
 sta tempa
 ldx fourth+1
 ldy trk2data,x
 lda (vol2),y
 ldx second+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 sta userout

 ldx delay
dllp31
 dex
 bne dllp31
 
 lda #$95
 sta dmacmd

 ldx seventh
 ldy trk1data,x
 lda (vol1),y
 ldy trk4data
 adc (vol4),y
 lsr
 sta tempa
 ldx fifth+1
 ldy trk2data,x
 lda (vol2),y
 ldx third+2
 ldy trk3data,x
 adc (vol3),y
 lsr
 adc tempa
 sta userout

 ldx delay
dllp32
 dex
 bne dllp32
 
 sec
 lda trkpntl+3
 sbc endl+3
 lda trkpnth+3
 sbc endh+3
 lda trkpntb+3
 sbc endb+3
 bcc userchkt
 ldx samplenum+3
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne userlp4
 ldx #3
 jsr retrig
 lda #0
 sta second+3
 sta third+3
 sta fourth+3
 sta fifth+3
 sta sixth+3
 sta seventh+3
 sta eighth+3
 sta stepl+3
 sta steph+3
 jsr sv2
 jmp userchkt

userlp4
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+3
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+3
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+3
 lda lsblplen,x
 adc startl+3
 sta endl+3
 lda msblplen,x
 adc starth+3
 sta endh+3
 lda bnklplen,x
 adc startb+3
 sta endb+3
 ldx #3
 jsr retrig

userchkt
 lda $dd0d
 and #$01
 bne userexit
 jmp userud1

userexit
 lda #$09
 sta $dd0e
 rts

; Driver for SID 4 bit mode, in stereo (Dither available)

sid4sud1
 lda #<trk1data
 sta dmaadl
 clc
 lda fraction
 adc stepl
 sta fraction
 lda trkpntl
 adc steph
 sta trkpntl
 sta dmalo
 lda trkpnth
 adc #0
 sta trkpnth
 sta dmahi
 lda trkpntb
 adc #0
 sta trkpntb
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx eighth
 ldy trk1data,x
 lda (vol1),y
 ldx second+3
 ldy trk4data,x
 adc (vol4),y
 ldy dither
 beq sid4sok1a
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok1a
 lda #255
 clc
sid4sok1a
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx sixth+1
 ldy trk2data,x
 lda (vol2),y
 ldx fourth+2
 ldy trk3data,x
 adc (vol3),y
 ldy dither
 beq sid4sok1b
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok1b
 lda #255
 clc
sid4sok1b
 tay
 lda divide16,y
 ora #$90
 ldy #0
 sta (sid4outright),y

 ldx delay
dllp33
 dex
 bne dllp33
 
 lda #$95
 sta dmacmd

 ldy trk1data
 lda (vol1),y
 ldx third+3
 ldy trk4data,x
 adc (vol4),y
 ldy dither
 beq sid4sok2a
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok2a
 lda #255
 clc
sid4sok2a
 tay
 lda divide16,y
 ora #$90
 sta sid4out
 ldx seventh+1
 ldy trk2data,x
 lda (vol2),y
 ldx fifth+2
 ldy trk3data,x
 adc (vol3),y
 ldy dither
 beq sid4sok2b
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok2b
 lda #255
sid4sok2b
 tay
 lda divide16,y
 ora #$90
 ldy #0
 sta (sid4outright),y

 ldx delay
dllp34
 dex
 bne dllp34
 
 sec
 lda trkpntl
 sbc endl
 lda trkpnth
 sbc endh
 lda trkpntb
 sbc endb
 bcc sid4sud2
 ldx samplenum
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid4slp1
 ldx #0
 jsr retrig
 lda #0
 sta second
 sta third
 sta fourth
 sta fifth
 sta sixth
 sta seventh
 sta eighth
 sta stepl
 sta steph
 jsr sv2
 jmp sid4sud2

sid4slp1
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl
 lda msbsaddr,x
 adc msblppnt,x
 sta starth
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb
 lda lsblplen,x
 adc startl
 sta endl
 lda msblplen,x
 adc starth
 sta endh
 lda bnklplen,x
 adc startb
 sta endb
 ldx #0
 jsr retrig

sid4sud2
 lda fraction+1
 adc stepl+1
 sta fraction+1
 lda trkpntl+1
 adc steph+1
 sta trkpntl+1
 sta dmalo
 lda trkpnth+1
 adc #0
 sta trkpnth+1
 sta dmahi
 lda trkpntb+1
 adc #0
 sta trkpntb+1
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx second
 ldy trk1data,x
 lda (vol1),y
 ldx fourth+3
 ldy trk4data,x
 adc (vol4),y
 ldy dither
 beq sid4sok3a
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok3a
 lda #255
 clc
sid4sok3a
 tay
 lda divide16,y
 ora #$90
 sta sid4out
 ldx eighth+1
 ldy trk2data,x
 lda (vol2),y
 ldx sixth+2
 ldy trk3data,x
 adc (vol3),y
 ldy dither
 beq sid4sok3b
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok3b
 lda #255
 clc
sid4sok3b
 tay
 lda divide16,y
 ora #$90
 ldy #0
 sta (sid4outright),y

 ldx delay
dllp35
 dex
 bne dllp35
 
 lda #$95
 sta dmacmd

 ldx third
 ldy trk1data,x
 lda (vol1),y
 ldx fifth+3
 ldy trk4data,x
 adc (vol4),y
 ldy dither
 beq sid4sok4a
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok4a
 lda #255
 clc
sid4sok4a
 tay
 lda divide16,y
 ora #$90
 sta sid4out
 ldy trk2data
 lda (vol2),y
 ldx seventh+2
 ldy trk3data,x
 adc (vol3),y
 ldy dither
 beq sid4sok4b
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok4b
 lda #255
sid4sok4b
 tay
 lda divide16,y
 ora #$90
 ldy #0
 sta (sid4outright),y

 ldx delay
dllp36
 dex
 bne dllp36 

 sec
 lda trkpntl+1
 sbc endl+1
 lda trkpnth+1
 sbc endh+1
 lda trkpntb+1
 sbc endb+1
 bcc sid4sud3
 ldx samplenum+1
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid4slp2
 ldx #1
 jsr retrig
 lda #0
 sta second+1
 sta third+1
 sta fourth+1
 sta fifth+1
 sta sixth+1
 sta seventh+1
 sta eighth+1
 sta stepl+1
 sta steph+1
 jsr sv2
 jmp sid4sud3

sid4slp2
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+1
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+1
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+1
 lda lsblplen,x
 adc startl+1
 sta endl+1
 lda msblplen,x
 adc starth+1
 sta endh+1
 lda bnklplen,x
 adc startb+1
 sta endb+1
 ldx #1
 jsr retrig

sid4sud3
 lda fraction+2
 adc stepl+2
 sta fraction+2
 lda trkpntl+2
 adc steph+2
 sta trkpntl+2
 sta dmalo
 lda trkpnth+2
 adc #0
 sta trkpnth+2
 sta dmahi
 lda trkpntb+2
 adc #0
 sta trkpntb+2
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx fourth
 ldy trk1data,x
 lda (vol1),y
 ldx sixth+3
 ldy trk4data,x
 adc (vol4),y
 ldy dither
 beq sid4sok5a
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok5a
 lda #255
 clc
sid4sok5a
 tay
 lda divide16,y
 ora #$90
 sta sid4out
 ldx second+1
 ldy trk2data,x
 lda (vol2),y
 ldx eighth+2
 ldy trk3data,x
 adc (vol3),y
 ldy dither
 beq sid4sok5b
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok5b
 lda #255
 clc
sid4sok5b
 tay
 lda divide16,y
 ora #$90
 ldy #0
 sta (sid4outright),y

 ldx delay
dllp37
 dex
 bne dllp37
 
 lda #$95
 sta dmacmd

 ldx fifth
 ldy trk1data,x
 lda (vol1),y
 ldx seventh+3
 ldy trk4data,x
 adc (vol4),y
 ldy dither
 beq sid4sok6a
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok6a
 lda #255
 clc
sid4sok6a
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx third+1
 ldy trk2data,x
 lda (vol2),y
 ldy trk3data
 adc (vol3),y
 ldy dither
 beq sid4sok6b
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok6b
 lda #255
sid4sok6b
 tay
 lda divide16,y
 ora #$90
 ldy #0
 sta (sid4outright),y

 ldx delay
dllp38
 dex
 bne dllp38
 
 sec
 lda trkpntl+2
 sbc endl+2
 lda trkpnth+2
 sbc endh+2
 lda trkpntb+2
 sbc endb+2
 bcc sid4sud4
 ldx samplenum+2
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid4slp3
 ldx #2
 jsr retrig
 lda #0
 sta second+2
 sta third+2
 sta fourth+2
 sta fifth+2
 sta sixth+2
 sta seventh+2
 sta eighth+2
 sta stepl+2
 sta steph+2
 jsr sv2
 jmp sid4sud4

sid4slp3
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+2
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+2
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+2
 lda lsblplen,x
 adc startl+2
 sta endl+2
 lda msblplen,x
 adc starth+2
 sta endh+2
 lda bnklplen,x
 adc startb+2
 sta endb+2
 ldx #2
 jsr retrig

sid4sud4
 lda fraction+3
 adc stepl+3
 sta fraction+3
 lda trkpntl+3
 adc steph+3
 sta trkpntl+3
 sta dmalo
 lda trkpnth+3
 adc #0
 sta trkpnth+3
 sta dmahi
 lda trkpntb+3
 adc #0
 sta trkpntb+3
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx sixth
 ldy trk1data,x
 lda (vol1),y
 ldx eighth+3 
 ldy trk4data,x
 adc (vol4),y
 ldy dither
 beq sid4sok7a
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok7a
 lda #255
 clc
sid4sok7a
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx fourth+1
 ldy trk2data,x
 lda (vol2),y
 ldx second+2
 ldy trk3data,x
 adc (vol3),y
 ldy dither
 beq sid4sok7b
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok7b
 lda #255
 clc
sid4sok7b
 tay
 lda divide16,y
 ora #$90
 ldy #0
 sta (sid4outright),y

 ldx delay
dllp39
 dex
 bne dllp39
 
 lda #$95
 sta dmacmd

 ldx seventh
 ldy trk1data,x
 lda (vol1),y
 ldy trk4data
 adc (vol4),y
 ldy dither
 beq sid4sok8a
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok8a
 lda #255
 clc
sid4sok8a
 tay
 lda divide16,y
 ora #$90
 sta sid4out

 ldx fifth+1
 ldy trk2data,x
 lda (vol2),y
 ldx third+2
 ldy trk3data,x
 adc (vol3),y
 ldy dither
 beq sid4sok8b
 sta tempa
 lda sidnoise
 and #$0f
 adc tempa
 bcc sid4sok8b
 lda #255
 clc
sid4sok8b
 tay
 lda divide16,y
 ora #$90
 ldy #0
 sta (sid4outright),y

 ldx delay
dllp40
 dex
 bne dllp40
 
 sec
 lda trkpntl+3
 sbc endl+3
 lda trkpnth+3
 sbc endh+3
 lda trkpntb+3
 sbc endb+3
 bcc sid4schkt
 ldx samplenum+3
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid4slp4
 ldx #3
 jsr retrig
 lda #0
 sta second+3
 sta third+3
 sta fourth+3
 sta fifth+3
 sta sixth+3
 sta seventh+3
 sta eighth+3
 sta stepl+3
 sta steph+3
 jsr sv2
 jmp sid4schkt

sid4slp4
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+3
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+3
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+3
 lda lsblplen,x
 adc startl+3
 sta endl+3
 lda msblplen,x
 adc starth+3
 sta endh+3
 lda bnklplen,x
 adc startb+3
 sta endb+3
 ldx #3
 jsr retrig

sid4schkt
 lda $dd0d
 and #$01
 bne sid4sexit
 jmp sid4sud1

sid4sexit
 lda #$09
 sta $dd0e
 rts

; Mixer for 8 bit SID, PWM mode, in stereo

mixer8stereo
 lda #$49
 sta sid+18
 ldy #18
 sta (rightsid),y
sid8sud1
 lda #<trk1data
 sta dmaadl
 clc
 lda fraction
 adc stepl
 sta fraction
 lda trkpntl
 adc steph
 sta trkpntl
 sta dmalo
 lda trkpnth
 adc #0
 sta trkpnth
 sta dmahi
 lda trkpntb
 adc #0
 sta trkpntb
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx eighth
 ldy trk1data,x
 lda (vol1),y
 ldx second+3
 ldy trk4data,x
 adc (vol4),y
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 ldx sixth+1
 ldy trk2data,x
 lda (vol2),y
 ldx fourth+2
 ldy trk3data,x
 adc (vol3),y
 tax
 and #$f0
 ldy #0
 sta (sid8outhiright),y
 txa
 asl
 asl
 asl
 asl
 sta (sid8outloright),y
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y
 lda #$41
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y

 ldx delay
dllp41
 dex
 bne dllp41

 lda #$95
 sta dmacmd

 clc
 ldy trk1data
 lda (vol1),y
 ldx third+3
 ldy trk4data,x
 adc (vol4),y
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 ldx seventh+1
 ldy trk2data,x
 lda (vol2),y
 ldx fifth+2
 ldy trk3data,x
 adc (vol3),y
 tax
 and #$f0
 ldy #0
 sta (sid8outhiright),y
 txa
 asl
 asl
 asl
 asl
 sta (sid8outloright),y
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y
 lda #$41
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y

 ldx delay
dllp42
 dex
 bne dllp42
 
 sec
 lda trkpntl
 sbc endl
 lda trkpnth
 sbc endh
 lda trkpntb
 sbc endb
 bcc sid8sud2
 ldx samplenum
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid8slp1
 ldx #0
 jsr retrig
 lda #0
 sta second
 sta third
 sta fourth
 sta fifth
 sta sixth
 sta seventh
 sta eighth
 sta stepl
 sta steph
 jsr sv2
 jmp sid8sud2

sid8slp1
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl
 lda msbsaddr,x
 adc msblppnt,x
 sta starth
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb
 lda lsblplen,x
 adc startl
 sta endl
 lda msblplen,x
 adc starth
 sta endh
 lda bnklplen,x
 adc startb
 sta endb
 ldx #0
 jsr retrig

sid8sud2
 lda fraction+1
 adc stepl+1
 sta fraction+1
 lda trkpntl+1
 adc steph+1
 sta trkpntl+1
 sta dmalo
 lda trkpnth+1
 adc #0
 sta trkpnth+1
 sta dmahi
 lda trkpntb+1
 adc #0
 sta trkpntb+1
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx second
 ldy trk1data,x
 lda (vol1),y
 ldx fourth+3
 ldy trk4data,x
 adc (vol4),y
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 ldx eighth+1
 ldy trk2data,x
 lda (vol2),y
 ldx sixth+2
 ldy trk3data,x
 adc (vol3),y
 tax
 and #$f0
 ldy #0
 sta (sid8outhiright),y
 txa
 asl
 asl
 asl
 asl
 sta (sid8outloright),y
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y
 lda #$41
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y

 ldx delay
dllp43
 dex
 bne dllp43

 lda #$95
 sta dmacmd

 clc
 ldx third
 ldy trk1data,x
 lda (vol1),y
 ldx fifth+3
 ldy trk4data,x
 adc (vol4),y
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 ldy trk2data
 lda (vol2),y
 ldx seventh+2
 ldy trk3data,x
 adc (vol3),y
 tax
 and #$f0
 ldy #0
 sta (sid8outhiright),y
 txa
 asl
 asl
 asl
 asl
 sta (sid8outloright),y
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y
 lda #$41
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y

 ldx delay
dllp44
 dex
 bne dllp44
 
 sec
 lda trkpntl+1
 sbc endl+1
 lda trkpnth+1
 sbc endh+1
 lda trkpntb+1
 sbc endb+1
 bcc sid8sud3
 ldx samplenum+1
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid8slp2
 ldx #1
 jsr retrig
 lda #0
 sta second+1
 sta third+1
 sta fourth+1
 sta fifth+1
 sta sixth+1
 sta seventh+1
 sta eighth+1
 sta stepl+1
 sta steph+1
 jsr sv2
 jmp sid8sud3

sid8slp2
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+1
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+1
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+1
 lda lsblplen,x
 adc startl+1
 sta endl+1
 lda msblplen,x
 adc starth+1
 sta endh+1
 lda bnklplen,x
 adc startb+1
 sta endb+1
 ldx #1
 jsr retrig

sid8sud3
 lda fraction+2
 adc stepl+2
 sta fraction+2
 lda trkpntl+2
 adc steph+2
 sta trkpntl+2
 sta dmalo
 lda trkpnth+2
 adc #0
 sta trkpnth+2
 sta dmahi
 lda trkpntb+2
 adc #0
 sta trkpntb+2
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx fourth
 ldy trk1data,x
 lda (vol1),y
 ldx sixth+3
 ldy trk4data,x
 adc (vol4),y
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 ldx second+1
 ldy trk2data,x
 lda (vol2),y
 ldx eighth+2
 ldy trk3data,x
 adc (vol3),y
 tax
 and #$f0
 ldy #0
 sta (sid8outhiright),y
 txa
 asl
 asl
 asl
 asl
 sta (sid8outloright),y
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y
 lda #$41
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y

 ldx delay
dllp45
 dex
 bne dllp45

 lda #$95
 sta dmacmd

 clc
 ldx fifth
 ldy trk1data,x
 lda (vol1),y
 ldx seventh+3
 ldy trk4data,x
 adc (vol4),y
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 ldx third+1
 ldy trk2data,x
 lda (vol2),y
 ldy trk3data
 adc (vol3),y
 tax
 and #$f0
 ldy #0
 sta (sid8outhiright),y
 txa
 asl
 asl
 asl
 asl
 sta (sid8outloright),y
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y
 lda #$41
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y

 ldx delay
dllp46
 dex
 bne dllp46 

 sec
 lda trkpntl+2
 sbc endl+2
 lda trkpnth+2
 sbc endh+2
 lda trkpntb+2
 sbc endb+2
 bcc sid8sud4
 ldx samplenum+2
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid8slp3
 ldx #2
 jsr retrig
 lda #0
 sta second+2
 sta third+2
 sta fourth+2
 sta fifth+2
 sta sixth+2
 sta seventh+2
 sta eighth+2
 sta stepl+2
 sta steph+2
 jsr sv2
 jmp sid8sud4

sid8slp3
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+2
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+2
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+2
 lda lsblplen,x
 adc startl+2
 sta endl+2
 lda msblplen,x
 adc starth+2
 sta endh+2
 lda bnklplen,x
 adc startb+2
 sta endb+2
 ldx #2
 jsr retrig

sid8sud4
 lda fraction+3
 adc stepl+3
 sta fraction+3
 lda trkpntl+3
 adc steph+3
 sta trkpntl+3
 sta dmalo
 lda trkpnth+3
 adc #0
 sta trkpnth+3
 sta dmahi
 lda trkpntb+3
 adc #0
 sta trkpntb+3
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx sixth
 ldy trk1data,x
 lda (vol1),y
 ldx eighth+3 
 ldy trk4data,x
 adc (vol4),y
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 ldx fourth+1
 ldy trk2data,x
 lda (vol2),y
 ldx second+2
 ldy trk3data,x
 adc (vol3),y
 tax
 and #$f0
 ldy #0
 sta (sid8outhiright),y
 txa
 asl
 asl
 asl
 asl
 sta (sid8outloright),y
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y
 lda #$41
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y

 ldx delay
dllp47
 dex
 bne dllp47
 
 lda #$95
 sta dmacmd

 clc
 ldx seventh
 ldy trk1data,x
 lda (vol1),y
 ldy trk4data
 adc (vol4),y
 tax
 and #$f0
 sta sid8outhi
 txa
 asl
 asl
 asl
 asl
 sta sid8outlo
 ldx fifth+1
 ldy trk2data,x
 lda (vol2),y
 ldx third+2
 ldy trk3data,x
 adc (vol3),y
 tax
 and #$f0
 ldy #0
 sta (sid8outhiright),y
 txa
 asl
 asl
 asl
 asl
 sta (sid8outloright),y
 lda #$49
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y
 lda #$41
 sta sid8clklo
 sta sid8clkhi
 sta (sid8clkloright),y
 sta (sid8clkhiright),y

 ldx delay2
dllp48
 dex
 bne dllp48
 
 sec
 lda trkpntl+3
 sbc endl+3
 lda trkpnth+3
 sbc endh+3
 lda trkpntb+3
 sbc endb+3
 bcc sid8schkt
 ldx samplenum+3
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne sid8slp4
 ldx #3
 jsr retrig
 lda #0
 sta second+3
 sta third+3
 sta fourth+3
 sta fifth+3
 sta sixth+3
 sta seventh+3
 sta eighth+3
 sta stepl+3
 sta steph+3
 jsr sv2
 jmp sid8schkt

sid8slp4
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+3
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+3
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+3
 lda lsblplen,x
 adc startl+3
 sta endl+3
 lda msblplen,x
 adc starth+3
 sta endh+3
 lda bnklplen,x
 adc startb+3
 sta endb+3
 ldx #3
 jsr retrig

sid8schkt
 lda $dd0d
 and #$01
 bne sid8sexit
 jmp sid8sud1

sid8sexit
 lda #$09
 sta $dd0e
 lda #$41
 sta sid+18
 ldy #18
 sta (rightsid),y
 rts

; Mixer for Digimax card, in stereo

digiud1
 lda #<trk1data
 sta dmaadl
 clc
 lda fraction
 adc stepl
 sta fraction
 lda trkpntl
 adc steph
 sta trkpntl
 sta dmalo
 lda trkpnth
 adc #0
 sta trkpnth
 sta dmahi
 lda trkpntb
 adc #0
 sta trkpntb
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx eighth
 ldy trk1data,x
 lda (vol1),y
 ldx second+3
 ldy trk4data,x
 adc (vol4),y
 ldx #left
 stx digitrack
 sta userout

 ldx sixth+1
 ldy trk2data,x
 lda (vol2),y
 ldx fourth+2
 ldy trk3data,x
 adc (vol3),y
 ldx #right
 stx digitrack
 sta userout
 lda #$95
 sta dmacmd

 ldy trk1data
 lda (vol1),y
 ldx third+3
 ldy trk4data,x
 adc (vol4),y
 ldx #left
 stx digitrack
 sta userout

 ldx seventh+1
 ldy trk2data,x
 lda (vol2),y
 ldx fifth+2
 ldy trk3data,x
 adc (vol3),y
 ldx #right
 stx digitrack
 sta userout

 sec
 lda trkpntl
 sbc endl
 lda trkpnth
 sbc endh
 lda trkpntb
 sbc endb
 bcc digiud2
 ldx samplenum
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne digilp1
 ldx #0
 jsr retrig
 lda #0
 sta second
 sta third
 sta fourth
 sta fifth
 sta sixth
 sta seventh
 sta eighth
 sta stepl
 sta steph
 jsr sv2
 jmp digiud2

digilp1
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl
 lda msbsaddr,x
 adc msblppnt,x
 sta starth
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb
 lda lsblplen,x
 adc startl
 sta endl
 lda msblplen,x
 adc starth
 sta endh
 lda bnklplen,x
 adc startb
 sta endb
 ldx #0
 jsr retrig

digiud2
 lda fraction+1
 adc stepl+1
 sta fraction+1
 lda trkpntl+1
 adc steph+1
 sta trkpntl+1
 sta dmalo
 lda trkpnth+1
 adc #0
 sta trkpnth+1
 sta dmahi
 lda trkpntb+1
 adc #0
 sta trkpntb+1
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx second
 ldy trk1data,x
 lda (vol1),y
 ldx fourth+3
 ldy trk4data,x
 adc (vol4),y
 ldx #left
 stx digitrack
 sta userout

 ldx eighth+1
 ldy trk2data,x
 lda (vol2),y
 ldx sixth+2
 ldy trk3data,x
 adc (vol3),y
 ldx #right
 stx digitrack
 sta userout

 lda #$95
 sta dmacmd

 ldx third
 ldy trk1data,x
 lda (vol1),y
 ldx fifth+3
 ldy trk4data,x
 adc (vol4),y
 ldx #left
 stx digitrack
 sta userout

 ldy trk2data
 lda (vol2),y
 ldx seventh+2
 ldy trk3data,x
 adc (vol3),y
 ldx #right
 stx digitrack
 sta userout

 sec
 lda trkpntl+1
 sbc endl+1
 lda trkpnth+1
 sbc endh+1
 lda trkpntb+1
 sbc endb+1
 bcc digiud3
 ldx samplenum+1
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne digilp2
 ldx #1
 jsr retrig
 lda #0
 sta second+1
 sta third+1
 sta fourth+1
 sta fifth+1
 sta sixth+1
 sta seventh+1
 sta eighth+1
 sta stepl+1
 sta steph+1
 jsr sv2
 jmp digiud3

digilp2
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+1
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+1
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+1
 lda lsblplen,x
 adc startl+1
 sta endl+1
 lda msblplen,x
 adc starth+1
 sta endh+1
 lda bnklplen,x
 adc startb+1
 sta endb+1
 ldx #1
 jsr retrig

digiud3
 lda fraction+2
 adc stepl+2
 sta fraction+2
 lda trkpntl+2
 adc steph+2
 sta trkpntl+2
 sta dmalo
 lda trkpnth+2
 adc #0
 sta trkpnth+2
 sta dmahi
 lda trkpntb+2
 adc #0
 sta trkpntb+2
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx fourth
 ldy trk1data,x
 lda (vol1),y
 ldx sixth+3
 ldy trk4data,x
 adc (vol4),y
 ldx #left
 stx digitrack
 sta userout

 ldx second+1
 ldy trk2data,x
 lda (vol2),y
 ldx eighth+2
 ldy trk3data,x
 adc (vol3),y
 ldx #right
 stx digitrack
 sta userout

 lda #$95
 sta dmacmd

 ldx fifth
 ldy trk1data,x
 lda (vol1),y
 ldx seventh+3
 ldy trk4data,x
 adc (vol4),y
 ldx #left
 stx digitrack
 sta userout

 ldx third+1
 ldy trk2data,x
 lda (vol2),y
 ldy trk3data
 adc (vol3),y
 ldx #right
 stx digitrack
 sta userout

 sec
 lda trkpntl+2
 sbc endl+2
 lda trkpnth+2
 sbc endh+2
 lda trkpntb+2
 sbc endb+2
 bcc digiud4
 ldx samplenum+2
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne digilp3
 ldx #2
 jsr retrig
 lda #0
 sta second+2
 sta third+2
 sta fourth+2
 sta fifth+2
 sta sixth+2
 sta seventh+2
 sta eighth+2
 sta stepl+2
 sta steph+2
 jsr sv2
 jmp digiud4

digilp3
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+2
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+2
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+2
 lda lsblplen,x
 adc startl+2
 sta endl+2
 lda msblplen,x
 adc starth+2
 sta endh+2
 lda bnklplen,x
 adc startb+2
 sta endb+2
 ldx #2
 jsr retrig

digiud4
 lda fraction+3
 adc stepl+3
 sta fraction+3
 lda trkpntl+3
 adc steph+3
 sta trkpntl+3
 sta dmalo
 lda trkpnth+3
 adc #0
 sta trkpnth+3
 sta dmahi
 lda trkpntb+3
 adc #0
 sta trkpntb+3
 sta dmabnk
 lda #8
 sta dmadal

 clc
 ldx sixth
 ldy trk1data,x
 lda (vol1),y
 ldx eighth+3 
 ldy trk4data,x
 adc (vol4),y
 ldx #left
 stx digitrack
 sta userout

 ldx fourth+1
 ldy trk2data,x
 lda (vol2),y
 ldx second+2
 ldy trk3data,x
 adc (vol3),y
 ldx #right
 stx digitrack
 sta userout

 lda #$95
 sta dmacmd

 ldx seventh
 ldy trk1data,x
 lda (vol1),y
 ldy trk4data
 adc (vol4),y
 ldx #left
 stx digitrack
 sta userout

 ldx fifth+1
 ldy trk2data,x
 lda (vol2),y
 ldx third+2
 ldy trk3data,x
 adc (vol3),y
 ldx #right
 stx digitrack
 sta userout

 sec
 lda trkpntl+3
 sbc endl+3
 lda trkpnth+3
 sbc endh+3
 lda trkpntb+3
 sbc endb+3
 bcc digichkt
 ldx samplenum+3
 lda lsblplen,x
 ora msblplen,x
 ora bnklplen,x
 bne digilp4
 ldx #3
 jsr retrig
 lda #0
 sta second+3
 sta third+3
 sta fourth+3
 sta fifth+3
 sta sixth+3
 sta seventh+3
 sta eighth+3
 sta stepl+3
 sta steph+3
 jsr sv2
 jmp digichkt

digilp4
 clc
 lda lsbsaddr,x
 adc lsblppnt,x
 sta startl+3
 lda msbsaddr,x
 adc msblppnt,x
 sta starth+3
 lda bnksaddr,x
 adc bnklppnt,x
 sta startb+3
 lda lsblplen,x
 adc startl+3
 sta endl+3
 lda msblplen,x
 adc starth+3
 sta endh+3
 lda bnklplen,x
 adc startb+3
 sta endb+3
 ldx #3
 jsr retrig

digichkt
 lda $dd0d
 and #$01
 bne digiexit
 jmp digiud1

digiexit
 lda #$09
 sta $dd0e
 rts


