#
# cpmtools makefile stripped down to remove autoconf
#

UNAME := $(shell uname)
DEST = ../../$(UNAME)

CC = gcc
CFLAGS = -g 

DEFFORMAT = ibm-3740
DEVICE = posix
DISKDEFS=$(shell cd ../../cpmtools ; pwd)/diskdefs
DEFFORMAT=wbw_fd144

# Locate the ncurses libs or try a guess if pkg-config does not exist
NCURSESLIBS=$(shell if env pkg-config --libs ncurses ; then : ; else echo -lncurses ; fi)

CPPFLAGS = -DDISKDEFS=\"$(DISKDEFS)\" -DFORMAT=\"$(DEFFORMAT)\"

DEVICEOBJ =	device_posix.o 

OBJECTS = cpmls cpmrm cpmcp cpmchmod cpmchattr mkfs.cpm fsck.cpm fsed.cpm

all: $(OBJECTS) $(DEST)
	cp -p $(OBJECTS) $(DEST)

cpmls:	cpmls.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)
	$(CC) $(LDFLAGS) -o $@ cpmls.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)

cpmrm:	cpmrm.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)
	$(CC) $(LDFLAGS) -o $@ cpmrm.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)

cpmcp:	cpmcp.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)
	$(CC) $(LDFLAGS) -o $@ cpmcp.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)

cpmchmod: cpmchmod.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)
	$(CC) $(LDFLAGS) -o $@ cpmchmod.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)

cpmchattr: cpmchattr.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)
	$(CC) $(LDFLAGS) -o $@ cpmchattr.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)

mkfs.cpm: mkfs.cpm.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)
	$(CC) $(LDFLAGS) -o $@ mkfs.cpm.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)

fsck.cpm: fsck.cpm.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)
	$(CC) $(LDFLAGS) -o $@ fsck.cpm.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)

fsed.cpm: fsed.cpm.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ)
	$(CC) $(LDFLAGS) -o $@ fsed.cpm.o cpmfs.o getopt.o getopt1.o $(DEVICEOBJ) $(NCURSESLIBS)

$(DEST):
	mkdir -p $(DEST)

clean:
	-rm -f *.o $(OBJECTS)
