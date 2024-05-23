TARGET=c64
CC=cl65
AS=ca65
LD=cl65
RM=rm -f
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=
BACKDIR=../cc65
BACKPACK=../posix/backpack
IMAGE=cyberwing

%.o: %.c
	$(CC) -c $(CFLAGS) $<

all: loadkoala.prg


OBJS = \
	loadkoala.o \
	$(BACKDIR)/backpack.lib


loadkoala.prg: $(OBJS) $(IMAGE).bkp
	$(LD) -m loadkoala.map -Ln loadkoala.lab -t $(TARGET) -o $@ $(AFLAGS) $(OBJS)

$(IMAGE).bkp: $(IMAGE).koa
	$(BACKPACK) -s 2 $^ $@

.PHONY: clean distclean

clean:
	$(RM) *.o
	$(RM) loadkoala.prg loadkoala.map loadkoala.lab
	$(RM) $(IMAGE).bkp 


distclean: clean
	$(RM) *~
