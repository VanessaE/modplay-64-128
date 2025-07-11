VERSION_MAJOR=0
VERSION_MINOR=0
BUILD_NO := $(shell git rev-list --count HEAD)

X64=/home/vanessa/.local/bin/x64sc
X128=/home/vanessa/.local/bin/x128

OPTIONS=-Wno-label-indent -v3 --format cbm \
	-Dversion_major=$(VERSION_MAJOR) -Dversion_minor=$(VERSION_MINOR) -Dbuild_no=$(BUILD_NO) 

TMPDIR=/tmp/mp-trim-ws-compress-tmp
VERSION_STRING=$(VERSION_MAJOR).$(VERSION_MINOR)
VERSION_ID=$(VERSION_MAJOR)$(VERSION_MINOR)

CC1541=/home/vanessa/.local/bin/cc1541 # change this to point to your copy
EXOMIZER=/home/vanessa/Commodore-related/Software/PC-tools/exomizer/src/exomizer

PRE_DECRUNCH_128=bit $d7 bpl notvdc lda \#$0b sta $d011 lda \#1 sta $d030 notvdc: nop

BASE_DIR=/home/vanessa/Commodore-related/Software/My Creations/modplay-v2.0

all:
	rm -f "$(TMPDIR)/*"

	$(MAKE) clean

	$(MAKE) c64
	$(MAKE) c64_scpu
	$(MAKE) c128
	$(MAKE) c128_scpu

	$(MAKE) gen_release_disk_image
	$(MAKE) gen_release_disk_image MACHINE=128

	$(MAKE) gen_mod_disks

	@echo -e '\nFinished, version $(VERSION_MAJOR).$(VERSION_MINOR), build #$(BUILD_NO)'

	@echo "Launching VICE and auto-starting..."

	$(X64) -warp -autostart "$(BASE_DIR)/disk-images/modplay64v0.d64" -10 ~/Commodore-related/Software/disk-images-misc/cmd-hd-x64sc.dhd &

	$(X128) -warp -8 "$(BASE_DIR)/disk-images/modplay128v0.d71" -10 ~/Commodore-related/Software/disk-images-misc/cmd-hd-x128.dhd &

clean:
	rm -f bin/*
	rm -f src/*.o
	rm -f disk-images/*

c64:
	@echo -e '\nBuilding Modplay 64...\n'
	acme $(OPTIONS) -o /tmp/mp.ignore.me -l /tmp/mp64.sym.initial src/constants-com.h

	acme $(OPTIONS) -o src/mp64.main.o -l /tmp/mp64-symbols.txt /tmp/mp64.sym.initial src/modplay.s
	acme $(OPTIONS) -o src/mp64.o /tmp/mp64-symbols.txt src/booter-64.s

	$(EXOMIZER) sfx 0x0801 -s 'lda #81 sta $$07e7' -X 'sty $$dbe7' -o bin/mp64 src/mp64.o
	$(EXOMIZER) mem -o bin/mp64.main src/mp64.main.o

	sort -dbf /tmp/mp64-symbols.txt > etc/mp64-symbols.txt

c128:
	@echo -e '\nBuilding Modplay 128...\n'
	acme $(OPTIONS) -Dc128=1 -o /tmp/mp.ignore.me -l /tmp/mp128.sym.initial src/constants-com.h

	acme $(OPTIONS) -Dc128=1 -o src/mp128.main.o -l /tmp/mp128-symbols.txt /tmp/mp128.sym.initial src/modplay.s
	acme $(OPTIONS) -Dc128=1 -o src/mp128.o /tmp/mp128-symbols.txt src/booter-128.s

	acme $(OPTIONS) -Dc128=1 --format plain -o src/c128-boot-sect.o src/c128-boot-sect.s

	$(EXOMIZER) sfx 0x1c01 -t 128 -s '$(value PRE_DECRUNCH_128)' -o bin/mp128 src/mp128.o
	$(EXOMIZER) mem -o bin/mp128.main src/mp128.main.o

	sort -dbf /tmp/mp128-symbols.txt > etc/mp128-symbols.txt

c64_scpu:
	@echo -e '\nBuilding Modplay 64 (SuperCPU edition)...\n'

	acme $(OPTIONS) -Dscpu=1 -o /tmp/mp.ignore.me -l /tmp/mp64-s.sym src/constants-com.h
	acme $(OPTIONS) -Dscpu=1 -o src/mp64.main-scpu.o -l /tmp/mp64+scpu-symbols.txt /tmp/mp64-s.sym src/modplay.s

	$(EXOMIZER) mem -o bin/mp64.main-scpu src/mp64.main-scpu.o

	sort -dbf /tmp/mp64+scpu-symbols.txt > etc/mp64+scpu-symbols.txt

c128_scpu:
	@echo -e '\nBuilding Modplay 128 (SuperCPU edition)...\n'

	acme $(OPTIONS) -Dc128=1 -Dscpu=1 -o /tmp/mp.ignore.me -l /tmp/mp128-s.sym src/constants-com.h
	acme $(OPTIONS) -Dc128=1 -Dscpu=1 -o src/mp128.main-scpu.o -l /tmp/mp128+scpu-symbols.txt /tmp/mp128-s.sym src/modplay.s

	$(EXOMIZER) mem -o bin/mp128.main-scpu src/mp128.main-scpu.o

	sort -dbf /tmp/mp128+scpu-symbols.txt > etc/mp128+scpu-symbols.txt

gen_release_disk_image:

ifeq ($(MACHINE),128)
	$(eval DISK_FORMAT := d71)
	$(eval INTLV := 6)
	$(eval PROGINTLV := 4)
else
	$(eval MACHINE := 64)
	$(eval DISK_FORMAT := d64)
	$(eval INTLV := 11)
	$(eval PROGINTLV := 6)
endif

	$(eval DISK_IMG := disk-images/modplay$(MACHINE)v$(VERSION_MAJOR).$(DISK_FORMAT))

	rm -f $(DISK_IMG)

	export DISK_IMG

	$(CC1541) -n 'modplay $(MACHINE) v$(VERSION_STRING)' -i '$(VERSION_ID)' \
																		$(DISK_IMG)

ifeq ($(MACHINE),128)

	$(CC1541) -p 1,0,0,'src/c128-boot-sect.o'  $(DISK_IMG)

	$(CC1541) -t -r 18 -b 5 -s $(PROGINTLV) \
				-f 'mp128' 					-w 'bin/mp128'					\
																		$(DISK_IMG)
	$(CC1541) -b 4 -r 19 -c -s $(PROGINTLV) \
				-f 'mp128.main'				-w 'bin/mp128.main'				\
																		$(DISK_IMG)
	$(CC1541) -r 15 -c -s $(PROGINTLV) \
				-f 'mp128.main-scpu'		-w 'bin/mp128.main-scpu'		\
																		$(DISK_IMG)

	$(CC1541) -c -S $(INTLV) -v \
				-f 'Acidbat II'				-w 'mods/Acidbat II.mod'		\
				-f 'Fun Tune'				-w 'mods/Fun Tune.mod'			\
				-f 'Dark Castle Pt.1'		-w 'mods/Dark Castle (Part 1).mod' \
				-f 'Empty Spaces II'		-w 'mods/Empty Spaces II.mod'	\
				-f 'Skate or Die'	\
					-w 'mods/Skate or Die Intro (cover by Delorean).mod'	\
																		$(DISK_IMG)

else

	$(CC1541) -t -r 18 -b 7 -s $(PROGINTLV) \
				-f 'mp64' 					-w 'bin/mp64'					\
																		$(DISK_IMG)
	$(CC1541) -t -r 19 -s $(PROGINTLV) \
				-f 'mp64.main'				-w 'bin/mp64.main'				\
																		$(DISK_IMG)
	$(CC1541) -r 13 -s $(PROGINTLV) \
				-f 'mp64.main-scpu'			-w 'bin/mp64.main-scpu'			\
																		$(DISK_IMG)

	$(CC1541) -S $(INTLV) -v \
				-f 'Acidbat II'				-w 'mods/Acidbat II.mod'		\
				-f 'Fun Tune'				-w 'mods/Fun Tune.mod'			\
																		$(DISK_IMG)
endif

gen_mod_disks:
	$(eval DISK_IMG := disk-images/mods-1.d81)

	$(CC1541) -t -n 'mods 1' -i m1											\
				-f 'Bodveizer'				-w 'mods/Bodveizer.mod'			\
				-f 'Boesendorfer'			-w 'mods/Boesendorfer.mod'		\
				-f 'Cybernoid 1'			-w 'mods/Cybernoid 1.mod'		\
				-f 'Cybernoid 2'			-w 'mods/Cybernoid 2.mod'		\
				-f 'Empty Spaces II'		-w 'mods/Empty Spaces II.mod'	\
				-f 'Laxity'					-w 'mods/Laxity.mod'			\
				-f 'Street Jungle'			-w 'mods/Street Jungle.mod'		\
																		$(DISK_IMG)

	$(eval DISK_IMG := disk-images/mods-2.d81)

	$(CC1541) -t -n 'mods 2' -i m2											\
				-f 'Ace II'					-w 'mods/Ace II.mod'			\
				-f 'Airwolf (2)'			-w 'mods/Airwolf (2).mod'		\
				-f 'Amazed Endtune'			-w 'mods/Amazed (End Tune).mod'	\
				-f 'Cutie Pie'				-w 'mods/Cutie Pie.mod'			\
				-f 'Dark Castle Pt.1'		-w 'mods/Dark Castle (Part 1).mod' \
				-f 'Hazy Day'				-w 'mods/Hazy Day.mod'			\
				-f 'Roadkill'				-w 'mods/Roadkill.mod'			\
				-f "Molecule's Rvng"		-w "mods/Molecule's Revenge.mod" \
				-f 'Skate or Die'	\
					-w 'mods/Skate or Die Intro (cover by Delorean).mod'	\
																		$(DISK_IMG)

	$(eval DISK_IMG := disk-images/mods-3.d81)

	$(CC1541) -t -n 'mods 3' -i m3												\
				-f 'On the Telly'			-w 'mods/On the Telly.mod'		\
				-f 'Hall of Hobbits'		-w 'mods/Hall of Hobbits (Remix).mod' \
				-f 'Happy as Fish'			-w 'mods/Happy As Fish.mod'		\
																			$(DISK_IMG)
