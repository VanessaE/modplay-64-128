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
	$(MAKE) c64_disks
	$(MAKE) c128_disks
	$(MAKE) mod_disks

clean:
	rm -f bin/*.prg
	rm -f src/*.o
	rm -f etc/*.rle
	rm -f disk-images/*

mod_disks:
	$(eval DISK_IMG := disk-images/more-mods-1.d81)

	$(CC1541) -n 'more mods 1' -i m1											\
				-f 'Happy as Fish'		-w 'mods/Happy As Fish.mod'				\
				-f 'Hazy Day'			-w 'mods/Hazy Day.mod'					\
				-f 'Amazed Endtune'		-w 'mods/Amazed (End Tune).mod'			\
				-f 'Street Jungle'		-w 'mods/Street Jungle.mod'				\
																				$(DISK_IMG)

	$(eval DISK_IMG := disk-images/more-mods-2.d81)

	$(CC1541) -n 'more mods 2' -i m2											\
				-f 'Hall of Hobbits'	-w 'mods/Hall of Hobbits (Remix).mod'	\
				-f "Molecule's Rvng"	-w "mods/Molecule's Revenge.mod"		\
				-f 'Boesendorfer'		-w 'mods/Boesendorfer.mod'				\
																				$(DISK_IMG)

c64:
	@echo -e '\nBuilding Modplay 64...\n'

	etc/trim-whitespc.sh 40 etc/splash-64.seq          $(TMPDIR)/splash-64-t.seq
	etc/compress-rle.sh  40 $(TMPDIR)/splash-64-t.seq  etc/splash-64.rle   etc/splash-64.seq

	acme $(OPTIONS) -o bin/mp64 src/booter.s
	acme $(OPTIONS) -l etc/mp64-sym.txt -o bin/mp64.main src/modplay.s

c64_scpu:
	@echo -e '\nBuilding Modplay 64 (SuperCPU edition)...\n'

	etc/trim-whitespc.sh 40 etc/splash-64.seq          $(TMPDIR)/splash-64-t.seq
	etc/compress-rle.sh  40 $(TMPDIR)/splash-64-t.seq  etc/splash-64.rle   etc/splash-64.seq

	acme $(OPTIONS) -Dscpu=1 -o bin/mp64-scpu src/booter.s
	acme $(OPTIONS) -Dscpu=1 -l etc/mp64-sym.txt -o bin/mp64-scpu.main src/modplay.s

c64_disks: c64 c64_scpu
	$(MAKE) gen_release_disk_img PLATFORM=64 ACCEL=""
	$(MAKE) gen_release_disk_img PLATFORM=64 ACCEL="-scpu"

c128:
	@echo -e '\nBuilding Modplay 128...\n'

	etc/trim-whitespc.sh 80 etc/splash-128.seq   $(TMPDIR)/splash-128-t.seq
	etc/compress-rle.sh  80 $(TMPDIR)/splash-128-t.seq etc/splash-128.rle etc/splash-128.seq

	acme $(OPTIONS) -Dc128=1 -o bin/mp128 src/booter.s
	acme $(OPTIONS) -Dc128=1 -l etc/mp128-sym.txt -o bin/mp128-scpu.main src/modplay.s

	acme $(OPTIONS) --format plain -Dc128=1 -o src/c128-boot-sect.o src/c128-boot-sect.s

c128_scpu:
	@echo -e '\nBuilding Modplay 128 (SuperCPU edition)...\n'

	etc/trim-whitespc.sh 80 etc/splash-128.seq   $(TMPDIR)/splash-128-t.seq
	etc/compress-rle.sh  80 $(TMPDIR)/splash-128-t.seq etc/splash-128.rle etc/splash-128.seq

	acme $(OPTIONS) -Dc128=1 -Dscpu=1 -o bin/mp128-scpu src/booter.s
	acme $(OPTIONS) -Dc128=1 -Dscpu=1 -l etc/mp128-sym.txt -o bin/mp128.main src/modplay.s

	acme $(OPTIONS) --format plain -Dc128=1 -Dscpu=1 -o src/c128-boot-sect.o src/c128-boot-sect.s

c128_disks: c128 c128_scpu
	$(MAKE) gen_release_disk_img PLATFORM=128 ACCEL=""
	$(MAKE) gen_release_disk_img PLATFORM=128 ACCEL="-scpu"

gen_release_disk_img:
	$(eval SW := -D4)
	$(eval DISK_FORMAT := d64)
	$(eval INTLV := -s 9)
	$(eval PROGINTLV := -s 6)

ifeq ($(PLATFORM),128)
	$(eval SW := -D7)
	$(eval DISK_FORMAT := d71)
	$(eval INTLV := -s 7)
	$(eval PROGINTLV := -s 4)
endif

ifeq ($(PLATFORM),64)
	$(eval SEP := -)
endif

	$(eval PRG := mp$(PLATFORM))
	$(eval DISK_IMG := disk-images/$(PRG)$(SEP)v2$(ACCEL).$(DISK_FORMAT))

	rm -f $(DISK_IMG)

	export SW DISK_IMG PRG DISK_FORMAT ACCEL

	$(CC1541) -n 'mp$(PRG) v$(VERSION_STRING) $(ACCEL)' -i '$(VERSION_ID)'  $(DISK_IMG)

ifeq ($(PLATFORM),128)
	$(CC1541) -p 1,0,0,'src/c128-boot-sect.o'  $(DISK_IMG)
endif

	$(CC1541)	\
		$(PROGINTLV) -f $(PRG)$(ACCEL)			-w bin/$(PRG)$(ACCEL)		\
		$(PROGINTLV) -f $(PRG)$(ACCEL).main		-w bin/$(PRG)$(ACCEL).main	\
					-f '----------------'		-L							\
					-f 'a few mod files:'		-L							\
					-f '                '		-L							\
		$(INTLV)	-f 'Acidbat II'				-w 'mods/Acidbat II.mod'	\
		$(INTLV)	-f 'Cutie Pie'				-w 'mods/Cutie Pie.mod'		\
		$(INTLV)	-f 'Fun Tune'				-w 'mods/Fun Tune.mod'		\
																			$(DISK_IMG)

ifeq ($(PLATFORM),128)
	$(CC1541) $(INTLV)	-f 'On the Telly'	-w 'mods/On the Telly.mod' \
		$(INTLV) -f 'Skate or Die'	\
			-w 'mods/Skate or Die Intro (cover by Delorean).mod'		$(DISK_IMG)
endif
