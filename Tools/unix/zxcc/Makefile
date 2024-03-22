#
# hacked up brute force makefile for linux and osx
#
UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
	SUFFIX=linux
endif
ifeq ($(UNAME), Darwin)
	SUFFIX=darwin
endif

DEST = ../../$(UNAME)
CFLAGS = -g # -DDEBUG

OBJECTS = zxcc.o cpmdrv.o cpmglob.o cpmparse.o cpmredir.o \
	drdos.o util.o xlt.o zxbdos.o zxcbdos.o zxdbdos.o z80.o track.o
UNUSED = dirent.o

all: zxcc $(DEST)
	cp -p bios.bin zxcc $(DEST)

$(DEST):
	mkdir -p $(DEST)

clean:
	-rm -f $(OBJECTS) config.h zxcc bios.bin

$(OBJECTS): config.h bios.bin

zxcc:	 $(OBJECTS)
	$(CC) -o zxcc $(OBJECTS)

config.h: config.h.$(SUFFIX)
	cp config.h.$(SUFFIX) config.h

bios.bin: cpm/bios.bin
	cp cpm/bios.bin .
