@echo off
:: iAN CooG/HokutoForce
cd original
cd c
gentab
call memexo.bat
cd ..
bastext -o -2 MP64.MAIN.bas
exobasic -N -r -p  MP64.MAIN.fix
set f=%@eval[%@filesize[MP64.MAIN.fix.out.prg]+2047]
if "%f%" == "" set f=$2B76
cd ..
dasm mpl6412d.s -ompl6412_all_fix -v0
exomizer sfx basic,$801,%f%,$54FE mpl6412_all_fix -omodplay12.prg -Di_load_addr=$801 -n
dasm modp_1filed.s -omodp_1filed.prg -v0
::call hfexo modp_1filed.prg $5000
exomizer sfx $5000 -o"modp_1filed.exo.prg" "modp_1filed.prg" -n
bastext -o -2 whatsnew.bas
::cleanup
::quit
del original\c\m*.bin
del original\c\m*.exo
del original\mp64.main.fix
del original\MP64.MAIN.fix.out.prg
del mpl6412_all_fix
del modplay12.prg
del modp_1filed.prg


