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

OBJECTS = zx.o cpmdrv.o cpmglob.o cpmparse.o cpmredir.o \
	drdos.o util.o xlt.o zxbdos.o zxcbdos.o zxdbdos.o z80.o
UNUSED = dirent.o

all: zx $(DEST)
	cp bios.bin zx $(DEST)

$(DEST):
	mkdir -p $(DEST)

clean:
	-rm -f $(OBJECTS) config.h

clobber: clean
	-rm -f $(DEST)/zx $(DEST)/bios.bin zx

$(OBJECTS): config.h

zx:	 $(OBJECTS)
	$(CC) -o zx $(OBJECTS)

config.h: config.h.$(SUFFIX)
	cp config.h.$(SUFFIX) config.h
