srcdir=         .

libdir=         ${exec_prefix}/lib
BINDIR=         ${exec_prefix}/bin
MANDIR=         ${datarootdir}/man
includedir=     ${prefix}/include
exec_prefix=    ${prefix}
prefix=         /usr/local
datarootdir=	${prefix}/share

INSTALL=        /usr/bin/install -c
INSTALL_DATA=   ${INSTALL} -m 644
CC=		gcc
CFLAGS=		-g -O2 -pipe -Wall -Wno-unused -Wshadow -Wbad-function-cast -Wmissing-prototypes -Wstrict-prototypes -Wcast-align -Wcast-qual -Wpointer-arith -Wwrite-strings -Wmissing-declarations -Wnested-externs -Wundef -pedantic -fno-common
LDFLAGS=         -g
DEFFORMAT=      ibm-3740
DISKDEFS=	${datarootdir}/diskdefs
DEVICE=         posix
FSED_CPM=       fsed.cpm
EXEEXT =        
OBJEXT =        .o
LIBS=           -lcurses  
LDDEPS=		
CPPFLAGS=	 -DDISKDEFS=\"$(DISKDEFS)\" -DFORMAT=\"$(DEFFORMAT)\"
#
# I'm only a novice and I haven't worked out how to autoconf this one
#

#MAKEDEPEND=	mkdep -d
MAKEDEPEND=	gcc -MM
#MAKEDEPEND=	makedepend -f-

DEVICEOBJ=	device_$(DEVICE)$(OBJEXT) 

ALL=		cpmls$(EXEEXT) cpmrm$(EXEEXT) cpmcp$(EXEEXT) \
		cpmchmod$(EXEEXT) cpmchattr$(EXEEXT) mkfs.cpm$(EXEEXT) \
		fsck.cpm$(EXEEXT) $(FSED_CPM)

all:		$(ALL)

LibDsk/libdsk.a:
		cd LibDsk && make

cpmls$(EXEEXT):		cpmls$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LDDEPS)
		$(CC) $(LDFLAGS) -o $@ cpmls$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LIBS)

cpmrm$(EXEEXT):		cpmrm$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LDDEPS)
		$(CC) $(LDFLAGS) -o $@ cpmrm$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LIBS)

cpmcp$(EXEEXT):		cpmcp$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LDDEPS)
		$(CC) $(LDFLAGS) -o $@ cpmcp$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LIBS)

cpmchmod$(EXEEXT):	cpmchmod$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LDDEPS)
		$(CC) $(LDFLAGS) -o $@ cpmchmod$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LIBS)

cpmchattr$(EXEEXT):	cpmchattr$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LDDEPS)
		$(CC) $(LDFLAGS) -o $@ cpmchattr$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LIBS)

mkfs.cpm$(EXEEXT):	mkfs.cpm$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LDDEPS)
		$(CC) $(LDFLAGS) -o $@ mkfs.cpm$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LIBS)

fsck.cpm$(EXEEXT):	fsck.cpm$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LDDEPS)
		$(CC) $(LDFLAGS) -o $@ fsck.cpm$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LIBS)

fsed.cpm$(EXEEXT):	fsed.cpm$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LDDEPS)
		$(CC) $(LDFLAGS) -o $@ fsed.cpm$(OBJEXT) cpmfs$(OBJEXT) getopt$(OBJEXT) getopt1$(OBJEXT) $(DEVICEOBJ) $(LIBS)

fsck.test:	fsck.cpm
		-./fsck.cpm -f ibm-3740 -n badfs/status
		-./fsck.cpm -f ibm-3740 -n badfs/extno
		-./fsck.cpm -f ibm-3740 -n badfs/lcr
		-./fsck.cpm -f ibm-3740 -n badfs/name
		-./fsck.cpm -f ibm-3740 -n badfs/extension
		-./fsck.cpm -f ibm-3740 -n badfs/blocknumber
		-./fsck.cpm -f ibm-3740 -n badfs/recordcount
		-./fsck.cpm -f ibm-3740 -n badfs/hugecom
		-./fsck.cpm -f ibm-3740 -n badfs/timestamps
		-./fsck.cpm -f ibm-3740 -n badfs/multipleblocks
		-./fsck.cpm -f ibm-3740 -n badfs/doubleext
		-./fsck.cpm -f pcw -n badfs/label

install:	all
		$(INSTALL) -s -m 755 cpmls $(BINDIR)/cpmls
		$(INSTALL) -s -m 755 cpmcp $(BINDIR)/cpmcp
		$(INSTALL) -s -m 755 cpmrm $(BINDIR)/cpmrm
		$(INSTALL) -s -m 755 cpmchmod $(BINDIR)/cpmchmod
		$(INSTALL) -s -m 755 cpmchattr $(BINDIR)/cpmchattr
		$(INSTALL) -s -m 755 mkfs.cpm $(BINDIR)/mkfs.cpm
		$(INSTALL) -s -m 755 fsck.cpm $(BINDIR)/fsck.cpm
		[ $(FSED_CPM) != '' ] && $(INSTALL) -s -m 755 fsed.cpm $(BINDIR)/fsed.cpm
		$(INSTALL_DATA) diskdefs ${prefix}/share/diskdefs
		$(INSTALL_DATA) cpmls.1 $(MANDIR)/man1/cpmls.1
		$(INSTALL_DATA) cpmcp.1 $(MANDIR)/man1/cpmcp.1
		$(INSTALL_DATA) cpmrm.1 $(MANDIR)/man1/cpmrm.1
		$(INSTALL_DATA) cpmchmod.1 $(MANDIR)/man1/cpmchmod.1
		$(INSTALL_DATA) cpmchattr.1 $(MANDIR)/man1/cpmchattr.1
		$(INSTALL_DATA) mkfs.cpm.1 $(MANDIR)/man1/mkfs.cpm.1
		$(INSTALL_DATA) fsck.cpm.1 $(MANDIR)/man1/fsck.cpm.1
		$(INSTALL_DATA) fsed.cpm.1 $(MANDIR)/man1/fsed.cpm.1
		$(INSTALL_DATA) cpm.5 $(MANDIR)/man5/cpm.5

clean:
		rm -f *$(OBJEXT)

distclean:	clean
		rm -rf $(ALL) autom4te.cache config.log config.cache config.h config.status Makefile *.out 

tar:		distclean
		(b=`pwd`; b=`basename $$b`; cd ..; tar zcvf $$b.tar.gz $$b)

depend:
		$(MAKEDEPEND) $(CPPFLAGS) *.c >.depend

include .depend
