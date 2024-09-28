VERSION_MAJOR=0
VERSION_MINOR=0

OPTIONS=-Wno-label-indent -v3 --format cbm \
	-Dversion_major=$(VERSION_MAJOR) -Dversion_minor=$(VERSION_MINOR)
CC1541=/home/vanessa/.local/bin/cc1541 # change this to point to your copy
TMPDIR=/tmp/mp-trim-ws-compress-tmp
VERSION_STRING=$(VERSION_MAJOR).$(VERSION_MINOR)
VERSION_ID=$(VERSION_MAJOR)$(VERSION_MINOR)


all:
	rm -f "$(TMPDIR)/*"

	$(MAKE) clean

	etc/trim-whitespc.sh 40 etc/splash-40.seq          $(TMPDIR)/splash-40-t.seq
	etc/compress-rle.sh  40 $(TMPDIR)/splash-40-t.seq  etc/splash-40.rle   etc/splash-40.seq

	$(MAKE) c64
	$(MAKE) c64_scpu

	etc/trim-whitespc.sh 80 etc/splash-80.seq   $(TMPDIR)/splash-80-t.seq
	etc/compress-rle.sh  80 $(TMPDIR)/splash-80-t.seq etc/splash-80.rle etc/splash-80.seq

	$(MAKE) c128
	$(MAKE) c128_scpu

	$(MAKE) gen_release_disk_image

	$(MAKE) gen_mod_disks


clean:
	rm -f bin/*
	rm -f src/*.o
	rm -f etc/*.rle
	rm -f disk-images/*


c64:
	@echo -e '\nBuilding Modplay 64...\n'
	acme $(OPTIONS) -o bin/mp64 src/booter.s
	acme $(OPTIONS) -l etc/mp64-sym.txt -o bin/mp64.main src/modplay.s


c128:
	@echo -e '\nBuilding Modplay 128...\n'
	acme $(OPTIONS) -Dc128=1 -o bin/mp128 src/booter.s
	acme $(OPTIONS) -Dc128=1 -l etc/mp128-sym.txt -o bin/mp128.main src/modplay.s
	acme $(OPTIONS) --format plain -Dc128=1 -o src/c128-boot-sect.o src/c128-boot-sect.s


c64_scpu:
	@echo -e '\nBuilding Modplay 64 (SuperCPU edition)...\n'
	acme $(OPTIONS) -Dscpu=1 -l etc/mp64-sym-scpu.txt -o bin/mp64.main-scpu src/modplay.s


c128_scpu:
	@echo -e '\nBuilding Modplay 128 (SuperCPU edition)...\n'
	acme $(OPTIONS) -Dc128=1 -Dscpu=1 -l etc/mp128-sym-scpu.txt -o bin/mp128.main-scpu src/modplay.s


gen_release_disk_image:
	$(eval C64INTLV  := -s 6)
	$(eval C128INTLV := -s 4)

	$(eval DISK_IMG := disk-images/modplay-v$(VERSION_STRING).d64)

	rm -f $(DISK_IMG)

	export DISK_IMG

	$(CC1541) -n 'modplay v$(VERSION_STRING)' -i '$(VERSION_ID)' $(DISK_IMG)

	$(CC1541) -p 1,0,0,'src/c128-boot-sect.o'  $(DISK_IMG)

	$(CC1541) -t -r 18 -b 7 \
		$(C64INTLV)  -r 18 -f 'mp64' 			-w 'bin/mp64'				\
																		$(DISK_IMG)

	$(CC1541) -t -r 18 -b 5 \
		$(C128INTLV) -r 18 -f 'mp128' 			-w 'bin/mp128'				\
																		$(DISK_IMG)

	$(CC1541) -t -r 18 \
		$(C64INTLV) -f 'mp64.main'		-w 'bin/mp64.main'			\
																		$(DISK_IMG)

	$(CC1541) -r 18 \
			$(C64INTLV) -f 'mp64.main-scpu' -w 'bin/mp64.main-scpu'		\
																		$(DISK_IMG)

	$(CC1541) -b 4 \
		$(C128INTLV) -f 'mp128.main'			-w 'bin/mp128.main'			\
																		$(DISK_IMG)

	$(CC1541) -v \
		$(C128INTLV) -f 'mp128.main-scpu'		-w 'bin/mp128.main-scpu'	\
																		$(DISK_IMG)


gen_mod_disks:
	$(eval DISK_IMG := disk-images/mods-1.d81)

	$(CC1541) -n 'mods 1' -i m1												\
				-f 'Acidbat II'			-w 'mods/Acidbat II.mod'			\
				-f 'Cutie Pie'			-w 'mods/Cutie Pie.mod'				\
				-f 'Fun Tune'			-w 'mods/Fun Tune.mod'				\
				-f 'On the Telly'		-w 'mods/On the Telly.mod'			\
				-f 'Cybernoid 1'		-w 'mods/Cybernoid 1.mod'			\
				-f 'Cybernoid 2'		-w 'mods/Cybernoid 2.mod'			\
				-f 'Bodveizer'			-w 'mods/Bodveizer.mod'				\
				-f 'Dark Castle Pt.1'	-w 'mods/Dark Castle (Part 1).mod'	\
				-f 'Empty Spaces II'	-w 'mods/Empty Spaces II.mod'		\
				-f 'Laxity'				-w 'mods/Laxity.mod'				\
				-f 'Skate or Die'	\
					-w 'mods/Skate or Die Intro (cover by Delorean).mod'	$(DISK_IMG)

	$(eval DISK_IMG := disk-images/mods-2.d81)

	$(CC1541) -n 'mods 2' -i m2												\
				-f 'Happy as Fish'		-w 'mods/Happy As Fish.mod'			\
				-f 'Hazy Day'			-w 'mods/Hazy Day.mod'				\
				-f 'Amazed Endtune'		-w 'mods/Amazed (End Tune).mod'		\
				-f 'Street Jungle'		-w 'mods/Street Jungle.mod'			\
																			$(DISK_IMG)

	$(eval DISK_IMG := disk-images/mods-3.d81)

	$(CC1541) -n 'mods 3' -i m3												\
				-f 'Hall of Hobbits'	-w 'mods/Hall of Hobbits (Remix).mod' \
				-f "Molecule's Rvng"	-w "mods/Molecule's Revenge.mod"	\
				-f 'Boesendorfer'		-w 'mods/Boesendorfer.mod'			\
																			$(DISK_IMG)
