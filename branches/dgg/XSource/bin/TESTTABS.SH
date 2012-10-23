#!/bin/sh
#rem mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
#rem  $Id: testtabs.bat 1.3 1998/02/25 12:27:04 toma Exp $
#rem mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
#rem  Run TASM on all the table test files.   Those that have
#rem  extended instuctions use the -x option.

./TASM -48 -x TEST48.ASM
./TASM -65 -x TEST65.ASM
./TASM -51    TEST51.ASM
./TASM -85    TEST85.ASM
./TASM -80 -x TESTz80.ASM
./TASM -05 -x TEST05.ASM
./TASM -3210  TEST3210.ASM
./TASM -3225  TEST3225.ASM
./TASM -68 -x TEST68.ASM
./TASM -70    TEST70.ASM
./TASM -96 -x TEST96.ASM

