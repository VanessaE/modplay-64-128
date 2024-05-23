#!/bin/bash

# This file acts as, essentially, a Makefile as found in most Linux/UNIX 
# programs.  Just run this to build CMMS in the 'bin' directory.

# Depends:  Probably any Linux or UNIX variant, CMMS source code in 
# ~/cmms64-2.0.0/src (duh), and xa65 and bash somewhere in your $PATH.

# This line tells the shell to dump out if any of the commands below returns and error
set -e


XA="`which xa` -O PETSCII -M -W -C -o "
#COMPRESS="`which blassic` etc/compress.bas"
COMPRESS="src/backpack/posix/backpack -s 2 "

echo -e "\n\n******************************************************************************"
echo -e "**  Starting build...\n"

echo "Compressor command: \`$COMPRESS\`"
echo " Assembler command: \`$XA\`"

workdir="`pwd`"

echo -e "\nrm -rf dist bin compressed-skins\n"
rm -rf dist bin work

echo -e "Going up one level...\n"
echo "cd .."
cd ..

echo -e "\nCreating source code archive..."
echo -e "zip -9 -r cmms64-2.0.0-src.zip cmms64-2.0.0\n"
zip -9 -r cmms64-2.0.0-src.zip cmms64-2.0.0

echo -e "\nEntering directory $workdir ..."
echo -e "cd \"$workdir\"\n"
cd "$workdir"

echo -e "mkdir -p dist bin work\n"
mkdir -p dist bin work

echo -e "mv ../cmms64-2.0.0-src.zip dist"
mv ../cmms64-2.0.0-src.zip dist

echo -e "\nBuilding compression program..."

echo -e "\nEntering directory $workdir/src ..."
echo -e "cd \"$workdir/src/backpack/posix\" "
cd "$workdir/src/backpack/posix"

echo -e "\nmake clean\n"
make clean
echo -e "\nmake\n"
make

echo -e "\nEntering directory $workdir/src ..."
echo -e "cd \"$workdir/src\"\n"
cd "$workdir/src"

echo -e "$XA ../bin/boot bootloader.xa"
$XA ../bin/boot bootloader.xa
echo -e "$XA ../bin/reu.mem reu.xa"
$XA ../bin/reu.mem reu.xa
echo -e "$XA ../work/div16table.bin div16table.xa"
$XA ../work/div16table.bin div16table.xa
echo -e "$XA ../bin/reciptable.bin reciptable.xa"
$XA ../bin/reciptable.bin reciptable.xa
echo -e "$XA ../work/widgetmap.bin widgetmap.xa"
$XA ../work/widgetmap.bin widgetmap.xa
echo -e "$XA ../work/squaretable.bin squaretable.xa"
$XA ../work/squaretable.bin squaretable.xa
echo -e "$XA ../bin/cmms-cfg default-cfg.xa"
$XA ../bin/cmms-cfg default-cfg.xa
echo -e "$XA ../bin/main.prg main.xa"
$XA ../bin/main.prg main.xa

echo -e "\nCompile finished.\n"

echo -e "Leaving directory $workdir/src ..."
echo -e "cd \"$workdir\"\n"
cd "$workdir"

echo -e "Compressing Splash screen, tables, and Skin images...\n"
echo "$COMPRESS etc/splash.koa bin/splash.lz"
$COMPRESS etc/splash.koa bin/splash.lz
echo "$COMPRESS etc/pointers.spr bin/pointers.lz"
$COMPRESS etc/pointers.spr bin/pointers.lz
echo "$COMPRESS work/div16table.bin bin/div16table.lz"
$COMPRESS work/div16table.bin bin/div16table.lz
echo "$COMPRESS work/widgetmap.bin bin/widgetmap.lz"
$COMPRESS work/widgetmap.bin bin/widgetmap.lz
echo "$COMPRESS work/squaretable.bin bin/squaretable.lz"
$COMPRESS work/squaretable.bin bin/squaretable.lz

for i in skins/multicolor/*.koa; do
	file=`echo $i|cut -f 3 -d "/"|cut -f 1 -d "." `
	infile="skins/multicolor/"$file".koa"
	outfile="work/"$file".mz"
	echo "$COMPRESS $infile $outfile"
	$COMPRESS $infile $outfile
done

for i in skins/hires/*.ip64h; do
	file=`echo $i|cut -f 3 -d "/"|cut -f 1 -d "." `
	infile="skins/hires/"$file".ip64h"
	outfile="work/"$file".hz"
	echo "$COMPRESS $infile $outfile"
	$COMPRESS $infile $outfile
done

echo -e "\nPreparing and compressing Widget images..."

echo ""
echo "echo -e -n \"\\\0000\\\0010\" >work/widgetsmc.bin"
echo -e -n "\\0000\\0010" >work/widgetsmc.bin  # New load address = $0800 in octal
echo "dd if=etc/widgets.koa of=work/widgetsmc.bin count=1913 bs=1 skip=2 oflag=append conv=notrunc"
dd if=etc/widgets.koa of=work/widgetsmc.bin count=1913 bs=1 skip=2 oflag=append conv=notrunc
echo -e "\ndd if=etc/widgets.koa of=work/widgetsmc.bin count=238 bs=1 skip=8002 oflag=append conv=notrunc"
dd if=etc/widgets.koa of=work/widgetsmc.bin count=238 bs=1 skip=8002 oflag=append conv=notrunc
echo -e "$COMPRESS work/widgetsmc.bin bin/widgets-mc.lz"
$COMPRESS work/widgetsmc.bin bin/widgets-mc.lz

echo ""
echo "echo -e -n \"\\\0000\\\0010\" >work/widgetshr.bin"
echo -e -n "\\0000\\0010" >work/widgetshr.bin  # New load address = $0800 in octal
echo "dd if=etc/widgets.ip64h of=work/widgetshr.bin count=1913 bs=1 skip=2 oflag=append conv=notrunc"
dd if=etc/widgets.ip64h of=work/widgetshr.bin count=1913 bs=1 skip=2 oflag=append conv=notrunc
echo -e "\ndd if=etc/widgets.ip64h of=work/widgetshr.bin count=238 bs=1 skip=8002 oflag=append conv=notrunc"
dd if=etc/widgets.ip64h of=work/widgetshr.bin count=238 bs=1 skip=8002 oflag=append conv=notrunc
echo -e "\n$COMPRESS work/widgetshr.bin bin/widgets-hr.lz"
$COMPRESS work/widgetshr.bin bin/widgets-hr.lz

echo -e "\nPreparing and compressing fallback CG screen...\n"

echo "echo -e -n \"\\\0000\\\0010\" >work/cgscreen.bin"
echo -e -n "\\0000\\0010" >work/cgscreen.bin  # New load address = $0800 in octal
echo "dd if=images-src/screen.chars of=work/cgscreen.bin skip=2 conv=notrunc oflag=append bs=1"
dd if=images-src/screen.chars of=work/cgscreen.bin skip=2 bs=1
echo -e "\ndd if=images-src/screen.colors of=work/cgscreen.bin skip=2 conv=notrunc oflag=append bs=1"
dd if=images-src/screen.colors of=work/cgscreen.bin skip=2 conv=notrunc oflag=append bs=1
echo -e "echo -e -n \"\\\0017\" >>work/cgscreen.bin  # Color code 15 in octal"
echo -e -n "\\0017" >>work/cgscreen.bin  # Color code 15 in octal
echo -e "$COMPRESS work/cgscreen.bin bin/cgscreen.lz"
$COMPRESS work/cgscreen.bin bin/cgscreen.lz

echo -e "\nCopying default skin and fonts...\n"

echo "cp work/highfi*.mz bin"
cp work/highfi*.mz bin
echo "cp fonts/* bin"
cp fonts/* bin

echo -e "\nCreating final distribution archives..."
echo -e "\nzip -j -9 dist/cmms64-2.0.0.zip bin/boot\n"
zip -j -9 dist/cmms64-2.0.0.zip bin/boot

echo -e "\nzip -j -9 -g dist/cmms64-2.0.0.zip bin/* docs/* -x \*/boot \n"
zip -j -9 -g dist/cmms64-2.0.0.zip bin/* docs/* -x \*/boot

echo -e "\nzip -j -9 -r dist/cmms64-2.0.0-skins.zip \`ls work/*-1* work/*-2* |sort -V\` -x \*highfi\*.mz\n"
zip -j -9 -r dist/cmms64-2.0.0-skins.zip `ls work/*-1* work/*-2* |sort -V` -x \*highfi\*.mz

echo -e "\nls -l dist\n"
ls -l dist

echo -e "\nzipinfo -t dist/cmms64-2.0.0.zip\n"
zipinfo -t dist/cmms64-2.0.0.zip

echo -e "\nDone.\n"
