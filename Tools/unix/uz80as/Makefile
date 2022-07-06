# ===========================================================================
# uz80as, an assembler for the Zilog Z80 and several other microprocessors.
# ===========================================================================

DEST = ../../`uname`
CC = gcc
CFLAGS = -g -fcommon

OBJECTS = ngetopt.o main.o options.o \
	utils.o err.o incl.o sym.o \
	expr.o exprint.o pp.o list.o \
	prtable.o uz80as.o targets.o \
	z80.o gbcpu.o \
	dp2200.o i4004.o \
	i8008.o i8048.o \
	i8051.o i8080.o \
	mos6502.o mc6800.o

SOURCES = \
	config.h \
	ngetopt.c ngetopt.h \
	main.c \
	options.c options.h \
	utils.c utils.h \
	err.c err.h \
	incl.c incl.h \
	sym.c sym.h \
	expr.c expr.h \
	exprint.c exprint.h \
	pp.c pp.h \
	list.c list.h \
	prtable.c prtable.h \
	uz80as.c uz80as.h \
	targets.c targets.h \
	z80.c \
	gbcpu.c \
	dp2200.c \
	i4004.c \
	i8008.c \
	i8048.c \
	i8051.c \
	i8080.c \
	mos6502.c \
	mc6800.c

all: uz80as $(DEST)
	cp -p uz80as $(DEST)

$(DEST):
	mkdir -p $(DEST)

clean:
	-rm -f $(OBJECTS) uz80as

uz80as: $(OBJECTS)
	$(CC) $(CFLAGS) -o uz80as $(OBJECTS) 

TESTS=test*.asm

test: uz80as
	echo "running tests"
	for i in $(TESTS) ; do \
		echo "====== $$i ======" ; \
		./uz80as $$i ; \
		cat $$(basename $$i .asm).lst ; \
	done

.c.o:
	$(CC) $(CFLAGS) -I. -c $< -o $@
