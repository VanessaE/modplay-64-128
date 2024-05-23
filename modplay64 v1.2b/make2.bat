@echo off
:: iAN CooG/HokutoForce
cd original
bastext -o MP64.MAIN.bas
exobasic -N -r -p  MP64.MAIN.fix
set f=%@eval[%@filesize[MP64.MAIN.fix.out.prg]+2047]
if "%f" == "" set f=$301a
cbmcombine ..\filler mp64.division.prg mp64.signed.prg mp64.loaders.o.prg mp64.volumetab.prg mp64.tempotab.prg mp64.ascii.prg mp64.c64player.o.prg -o..\mpl6412_all
cd ..
dasm DIRLIST.S -oDIRLIST.prg -v2
dasm arptr.s -oarptr.prg -v2
cbmcombine mpl6412_all original\MP64.MAIN.fix.out.prg DIRLIST.prg arptr.prg -o mpl6412_all_fix
exomizer sfx basic,$801,%f%,$54FE mpl6412_all_fix  -omodplay12.prg -Di_load_addr=$801 -n
dasm modp_1filed.s -omodp_1filed.prg -v2
::call hfexo modp_1filed.prg $3c00
exomizer sfx $3c00 -o"modp_1filed.exo.prg" "modp_1filed.prg" -n
bastext -o whatsnew.bas
::cleanup
del original\mp64.main.fix
del original\MP64.MAIN.fix.out.prg
del DIRLIST.prg
del arptr.prg
del mpl6412_all
del mpl6412_all_fix
del modplay12.prg
del modp_1filed.prg
