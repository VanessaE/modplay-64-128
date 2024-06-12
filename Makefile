OPTIONS=-Wno-label-indent -v3 --format plain 
CC1541=/home/vanessa/.local/bin/cc1541 # change this to point to your copy
TMPDIR=/tmp/mp-trim-ws-compress-tmp

all:

	rm -f "$(TMPDIR)/*"

	$(MAKE) clean
	$(MAKE) c64_disk
	$(MAKE) c128_disk
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

	acme $(OPTIONS) -o src/autorun-64.o src/autorun-64.s
	acme $(OPTIONS) -o src/display-splash.o src/display-splash.s
	acme $(OPTIONS) -l etc/mp64-sym.txt -o src/mp64.o src/modplay.s

	cat src/autorun-64.o \
		src/display-splash.o \
		src/mp64.o \
		> bin/mp64.prg

c64_disk: c64
	$(MAKE) gen_release_disk_img MACHINE=64

c128:
	@echo -e '\nBuilding Modplay 128...\n'

	etc/trim-whitespc.sh 80 etc/splash-128.seq   $(TMPDIR)/splash-128-t.seq
	etc/compress-rle.sh  80 $(TMPDIR)/splash-128-t.seq etc/splash-128.rle etc/splash-128.seq

	acme $(OPTIONS) -Dc128=1 -o src/autorun-128.o src/autorun-128.s
	acme $(OPTIONS) -Dc128=1 -o src/display-splash-128.o src/display-splash.s
	acme $(OPTIONS) -Dc128=1 -l etc/mp128-sym.txt -o src/mp128.o src/modplay.s
	acme $(OPTIONS) -Dc128=1 -o src/c128-boot-sect.o src/c128-boot-sect.s

	cat src/autorun-128.o \
		src/display-splash-128.o \
		src/mp128.o \
		> bin/mp128.prg

c128_disk: c128
	$(MAKE) gen_release_disk_img MACHINE=128

gen_release_disk_img:
	$(eval SW := -D4)
	$(eval DISK_FORMAT := d64)

ifeq ($(MACHINE),128)
	$(eval SW := -D7)
	$(eval DISK_FORMAT := d71)
	$(eval INTLV := -s 5)
endif

ifeq ($(MACHINE),64)
	$(eval SEP := -)
endif

	$(eval PRG := mp$(MACHINE))
	$(eval DISK_IMG := disk-images/modplay$(MACHINE)$(SEP)v2.$(DISK_FORMAT))

	rm -f $(DISK_IMG)

	export SW DISK_IMG PRG DISK_FORMAT

	$(CC1541) -n 'modplay $(MACHINE) v2.0' -i 20  $(DISK_IMG)

ifeq ($(MACHINE),128)
	$(CC1541) -p 1,0,0,'src/c128-boot-sect.o'  $(DISK_IMG)
endif

	$(CC1541)	\
		$(INTLV)	-f $(PRG)				-w bin/$(PRG).prg			\
					-f '----------------'	-L							\
					-f ' load with ,x,1 '	-L							\
					-f '---- ------ ----'	-L							\
					-f 'a few mod files:'	-L							\
					-f '                '	-L							\
		$(INTLV)	-f 'Acidbat II'			-w 'mods/Acidbat II.mod'	\
		$(INTLV)	-f 'Cutie Pie'			-w 'mods/Cutie Pie.mod'		\
		$(INTLV)	-f 'Fun Tune'			-w 'mods/Fun Tune.mod'		\
																		$(DISK_IMG)

ifeq ($(MACHINE),128)
	$(CC1541) $(INTLV)	-f 'On the Telly'	-w 'mods/On the Telly.mod' \
		$(INTLV) -f 'Skate or Die'	\
			-w 'mods/Skate or Die Intro (cover by Delorean).mod'		$(DISK_IMG)
endif
