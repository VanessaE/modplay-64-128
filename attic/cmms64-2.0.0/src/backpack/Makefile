.PHONY: all clean cc65 posix test
all: cc65 posix test

cc65:
	make -C cc65

posix:
	make -C posix

test: cc65
	make -C test

clean:
	make -C cc65 clean
	make -C posix clean
	make -C test clean

distclean:
	make -C cc65 distclean
	make -C posix distclean
	make -C test distclean
