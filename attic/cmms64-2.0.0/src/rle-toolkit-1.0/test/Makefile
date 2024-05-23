TARGET=c64
CC=cl65
AS=ca65
LD=cl65
RM=rm -f
CFLAGS=-Oirs -t $(TARGET)
AFLAGS=
RLEDIR=../cc65
RLEPACK=../posix/rlepack$(EXESUFFIX)
IMAGE=cyberwing

%.o: %.c
	$(CC) -c $(CFLAGS) $<

all: loadkoala.prg


OBJS = \
	loadkoala.o \
	$(RLEDIR)/rle.lib


loadkoala.prg: $(OBJS) $(IMAGE).rle
	$(LD) -m loadkoala.map -Ln loadkoala.lab -t $(TARGET) -o $@ $(AFLAGS) $(OBJS)

$(IMAGE).rle: $(IMAGE).koa
	$(RLEPACK) $^ $@

.PHONY: clean distclean

clean:
	$(RM) *.o
	$(RM) loadkoala.prg loadkoala.map loadkoala.lab
	$(RM) $(IMAGE).rle 


distclean: clean
	$(RM) *~
