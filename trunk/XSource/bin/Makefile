#!/bin/sh
#rem mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
#rem  $Id: testtabs.bat 1.3 1998/02/25 12:27:04 toma Exp $
#rem mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
#rem  Run TASM on all the table test files.   Those that have
#rem  extended instuctions use the -x option.

AS = ./TASM
OBJS = TEST48.obj TEST65.obj TEST51.obj TEST85.obj TESTZ80.obj
OBJS2= TEST05.obj TEST3210.obj TEST3225.obj TEST68.obj TEST70.obj TEST96.obj

all:	$(OBJS) $(OBJS2)
#	./TASM -48 -x TEST48.ASM
#	./TASM -65 -x TEST65.ASM
#	./TASM -51    TEST51.ASM
#	./TASM -85    TEST85.ASM
#	./TASM -80 -x TESTZ80.ASM
#	./TASM -05 -x TEST05.ASM
#	./TASM -3210  TEST3210.ASM
#	./TASM -3225  TEST3225.ASM
#	./TASM -68 -x TEST68.ASM
#	./TASM -70    TEST70.ASM
#	./TASM -96 -x TEST96.ASM

TEST48.obj:	TEST48.ASM
	$(AS) -48 -x $<

TEST65.obj:	TEST65.ASM
	$(AS) -65 -x $<

TEST51.obj:	TEST51.ASM
	$(AS) -51 $<

TEST85.obj:	TEST85.asm
	$(AS) -85 $<

TESTZ80.obj:	TESTZ80.ASM
	$(AS) -80 -x $<

TEST05.obj:	TEST05.ASM
	$(AS) -05 -x $<

TEST3210.obj:	TEST3210.ASM
	$(AS) -3210 $<

TEST3225.obj:	TEST3225.ASM
	$(AS) -3225 $<

TEST68.obj:	TEST68.ASM
	$(AS) -68 -x $<

TEST70.obj:	TEST70.ASM
	$(AS) -70 $<

TEST96.obj:	TEST96.ASM
	$(AS) -96 -x $<

clean:
	rm -r -f *.obj
	rm -r -f *.lst
	rm -r -f *.sym


