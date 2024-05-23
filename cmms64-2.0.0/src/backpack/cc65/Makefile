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


all: backpack.lib


LIBOBJS = \
	back.o \
	backunpack.o


backpack.lib: $(LIBOBJS)
	$(AR) a $@ $^


.PHONY: clean distclean

clean:
	rm -f *.o
	rm -f backpack.lib


distclean: clean
	rm -f *~
