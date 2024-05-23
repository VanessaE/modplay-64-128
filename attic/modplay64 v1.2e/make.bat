@echo off
:: iAN CooG/HokutoForce
:: make     for basic version
:: make x   for compiled version
cd original
cd c
gentab
call memexo.bat
cd ..
bastext -o -2 MP64.MAIN.bas
if not %1x == x goto compile
exobasic -N -r -p MP64.MAIN.fix
goto nocomp
:compile
copy MP64.MAIN.fix compile\mp
cd compile
echo.
echo Enter mp as filename, exit Vice when done!
set vp=-cartexpert +sound +saveres -confirmexit +truedrive -virtualdev -warp
c:\c64\vice\x64 %vp% austro_compiler.prg
set vp=
pause
c:\msys\bin\dd if=CMP.P00 of=mp64 bs=1 skip=26
move mp64 ..\MP64.MAIN.fix.out.prg
cd ..
:nocomp
cd ..
dasm mpl6412e.s -ompl6412_all_fix -v0
::call hfexo mpl6412_all_fix $3500
exomizer sfx $3500 -o"mpl6412e.exo.prg" "mpl6412_all_fix" -n

bastext -o -2 whatsnew.bas
:cleanup
::quit
if exist original\c\m*.bin              del original\c\m*.bin
if exist original\c\m*.exo              del original\c\m*.exo
if exist original\mp64.main.fix         del original\mp64.main.fix
if exist original\MP64.MAIN.fix.out.prg del original\MP64.MAIN.fix.out.prg
if exist original\compile\mp            del original\compile\mp
if exist original\compile\?MP.P00       del original\compile\?MP.P00
if exist mpl6412_all_fix                del mpl6412_all_fix


