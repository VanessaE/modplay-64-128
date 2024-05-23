CC=gcc
CFLAGS=-O -Wall
LDFLAGS=
#EXESUFFIX=.exe
RM=rm -f


PACKOBJS= \
	backpack.o

UNPACKOBJS= \
	backunpack.o

PARSEOBJS= \
	backparse.o


%.o: %.c
	$(CC) -c $(CFLAGS) $<


all: backpack backunpack backparse

backpack: $(PACKOBJS)
	$(CC) $(LDFLAGS) -o $@ $^

backunpack: $(UNPACKOBJS)
	$(CC) $(LDFLAGS) -o $@ $^

backparse: $(PARSEOBJS)
	$(CC) $(LDFLAGS) -o $@ $^


.PHONY: clean distclean

clean:
	$(RM) backpack$(EXESUFFIX) backunpack$(EXESUFFIX) backparse$(EXESUFFIX) *.o

distclean: clean
	$(RM) *~
