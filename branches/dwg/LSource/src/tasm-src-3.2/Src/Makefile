#############################################################################
#  $Id: makefile.unx 1.6 1998/03/03 01:58:24 toma Exp $
#############################################################################
#
# File:         makefile.unx
# Description:  Make TASM in the LINUX environment (GNU make)
#
# Thomas N. Anderson, Squak Valley Software 
#
# Invoked as:
#
#       make -f makefile.unx
#
# or copy makefile.unx to makefile and invoke as:
#
#       make
#
#
#
# For debug
#CFLAGS+=-ggdb
CFLAGS+=-Wall -O
CC=gcc
RM=rm -f

# Where to find current working files
TASMDOSPATH=/dosc/tasmnew

CFILES=tasmmain.c tasm.c macro.c parse.c rules.c str.c lookup.c  \
       wrtobj.c fname.c errlog.c
HFILES=tasm.h

TABLES=tasm05.tab     \
       tasm3210.tab   \
       tasm3225.tab   \
       tasm48.tab     \
       tasm51.tab     \
       tasm65.tab     \
       tasm68.tab     \
       tasm70.tab     \
       tasm80.tab     \
       tasm85.tab     \
       tasm96.tab     

TESTFILES=\
	test05.asm     \
	test3210.asm   \
	test3225.asm   \
	test48.asm     \
	test51.asm     \
        test65.asm     \
        test68.asm     \
        test70.asm     \
        testz80.asm    \
        test85.asm     \
        test96.asm     \
	testtabs.sh

SOURCES=$(CFILES) $(HFILES)

DOCS=tasmman.htm tasmtabs.htm readme.txt relnotes.txt orderfrm.txt orderfrm.htm


OFILES=$(CFILES:%.c=%.o)



# LINUX version of TASM.
all: tasm
tasm: $(OFILES)

import: 
	getdos.sh $(SOURCES)
	getdos.sh $(TABLES)
	getdos.sh $(DOCS)
	getdos.sh $(TESTFILES)
	# Replace readme.txt with the LINUX version
	rm readme.txt
	getdos.sh readmel.txt
	mv        readmel.txt readme.txt

tar:
	tar -cvf tasm.tar tasm $(TABLES) $(DOCS) $(TESTFILES)
	gzip tasm.tar
	mv   tasm.tar.gz tasm.taz
	tar -cvf tasmsrc.tar tasm $(SOURCES) makefile.unx
	gzip tasmsrc.tar
	mv   tasmsrc.tar.gz tasmsrc.taz

clean:
	rm -f *.o tasm

#################################################################
# Dependencies

tasmmain.o:   	tasmmain.c tasm.h

tasm.o: 	tasm.c tasm.h 

macro.o: 	macro.c tasm.h 

parse.o: 	parse.c tasm.h

str.o: 		str.c   tasm.h

lookup.o: 	lookup.c  tasm.h

wrtobj.o:	wrtobj.c tasm.h

fname.o:	fname.c tasm.h

rules.o:	rules.c tasm.h

errlog.o:	errlog.c tasm.h

