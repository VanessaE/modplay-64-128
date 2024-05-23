TARGET=c64
CC=cl65
AS=ca65
LD=cl65
AR=ar65
C1541=c1541
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=


%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<


all: rle.lib test.prg


RLEOBJS = \
	rle.o \
	rlepack.o \
	rleunpack.o

TESTOBJS= \
	test.o \
	rle.lib


rle.lib: $(RLEOBJS)
	$(AR) a $@ $^


test.prg: $(TESTOBJS)
	$(LD) -m test.map -Ln test.lab -t $(TARGET) -o test.prg $(AFLAGS) $^


.PHONY: clean distclean

clean:
	rm -f *.o rle.lib
	rm -f test.prg test.map test.lab


distclean: clean
	rm -f *~
