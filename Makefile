OPTIONS = -Wno-label-indent -v3
C1541 = /home/vanessa/.local/bin/c1541 # change this to point to your copy, part of VICE

all:

	rm -f /tmp/mp-trim-ws-compress-tmp/*

	$(MAKE) clean
	$(MAKE) c64_disk
	$(MAKE) c128_disk
	$(MAKE) mod_disks

clean:
	rm -f src/*.o
	rm -f etc/*l.seq
	$(MAKE) distclean

distclean:
	rm -f bin/*
	rm -f disk-images/*

mod_disks:
	$(C1541) -format 'more mods 1',mm d81 disk-images/more-mods-1.d81
	$(C1541) -format 'more mods 2',mm d81 disk-images/more-mods-2.d81

	$(C1541) -attach disk-images/more-mods-1.d81 -write 'mods/Happy As Fish.mod'           happyasfish.mod
	$(C1541) -attach disk-images/more-mods-1.d81 -write 'mods/Hazy Day.mod'                'hazy day.mod'
	$(C1541) -attach disk-images/more-mods-1.d81 -write 'mods/Amazed (End Tune).mod'       'amazed endtn.mod'
	$(C1541) -attach disk-images/more-mods-1.d81 -write 'mods/Street Jungle.mod'           'streetjungle.mod'

	$(C1541) -attach disk-images/more-mods-2.d81 -write 'mods/Hall of Hobbits (Remix).mod' 'hall hobbits.mod'
	$(C1541) -attach disk-images/more-mods-2.d81 -write "mods/Molecule's Revenge.mod"      'molculs rvng.mod'
	$(C1541) -attach disk-images/more-mods-2.d81 -write 'mods/Boesendorfer.mod'            'boesendorfer.mod'

c64:
	@echo -e '\nBuilding Modplay 64...\n'

	etc/trim-whitespc.sh 40 etc/splash-64.seq   etc/splash-64-t.seq
	etc/compress-rle.sh  40 etc/splash-64-t.seq etc/splash-64.rle   etc/splash-64.seq

	etc/trim-whitespc.sh 40 etc/main-64.seq   etc/main-64-t.seq
	etc/compress-rle.sh  40 etc/main-64-t.seq etc/main-64.rle etc/main-64.seq

	acme $(OPTIONS) -o src/autorun-hdr.o src/autorun-hdr.s
	acme $(OPTIONS) -o src/display-splash.o src/display-splash.s
	acme $(OPTIONS) -o src/main.o src/main.s

	cat src/autorun-hdr.o \
		src/display-splash.o \
		src/main.o \
		> bin/mp64.prg

c64_disk: c64
	$(MAKE) gen_release_disk_img MACHINE=64

c128:
	@echo -e '\nBuilding Modplay 128...\n'

	etc/trim-whitespc.sh 80 etc/splash-128.seq   etc/splash-128-t.seq
	etc/compress-rle.sh  80 etc/splash-128-t.seq etc/splash-128.rle etc/splash-128.seq

	etc/trim-whitespc.sh 80 etc/main-128.seq   etc/main-128-t.seq
	etc/compress-rle.sh  80 etc/main-128-t.seq etc/main-128.rle etc/main-128.seq

	acme $(OPTIONS) -Dc128=1 -o src/autorun-hdr-128.o src/autorun-hdr.s
	acme $(OPTIONS) -Dc128=1 -o src/display-splash-128.o src/display-splash.s
	acme $(OPTIONS) -Dc128=1 -o src/main-128.o src/main.s

	cat src/autorun-hdr-128.o \
		src/display-splash-128.o \
		src/main-128.o \
		> bin/mp128.prg

c128_disk: c128
	$(MAKE) gen_release_disk_img MACHINE=128

gen_release_disk_img:
	$(eval SW := -D4)
	$(eval DISK_FORMAT := d64)

ifeq ($(MACHINE),128)
	$(eval SW := -D7)
	$(eval DISK_FORMAT := d71)
endif

ifeq ($(MACHINE),64)
	$(eval SEP := -)
endif

	$(eval PRG := mp$(MACHINE))
	$(eval DISK_IMG := disk-images/modplay$(MACHINE)$(SEP)v2.$(DISK_FORMAT))

	rm -f $(DISK_IMG)

	export SW DISK_IMG PRG DISK_FORMAT
	
	$(C1541) -format 'modplay $(MACHINE) v2.0',20 $(DISK_FORMAT) $(DISK_IMG)

	$(C1541) -attach $(DISK_IMG) -write bin/$(PRG).prg $(PRG)

	touch empty.seq
	$(C1541) -attach $(DISK_IMG) -write empty.seq				'----------------'
	$(C1541) -attach $(DISK_IMG) -write empty.seq				' load with Xxx1 '
	$(C1541) -attach $(DISK_IMG) -write empty.seq				'-------------- -'
	$(C1541) -attach $(DISK_IMG) -write empty.seq				'a few mod filesX'
	$(C1541) -attach $(DISK_IMG) -write empty.seq				'                '
	$(C1541) -attach $(DISK_IMG) -write 'mods/Acidbat II.mod'	'acidbat ii.mod'
	$(C1541) -attach $(DISK_IMG) -write 'mods/On the Telly.mod'	'on the telly.mod'
	$(C1541) -attach $(DISK_IMG) -write 'mods/Cutie Pie.mod'	'cutie pie.mod'

	# fix-up some of the filenames since c1541's CBMfs emulation gets in the way
	$(C1541) -attach $(DISK_IMG) -bpoke 18 1 80 44 -bpoke 18 1 82 44 # change "XxX1" to ",x,1"
	$(C1541) -attach $(DISK_IMG) -bpoke 18 1 115 45                  # fix missing "-"
	$(C1541) -attach $(DISK_IMG) -bpoke 18 1 148 58                  # fix missing ":"

ifeq ($(MACHINE),128)
	$(C1541) -attach $(DISK_IMG) -write 'mods/Cybernoid 1.mod'   'cybernoid 1.mod'
endif

	rm empty.seq
