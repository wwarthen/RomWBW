rem mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
rem  $Id: testtabs.bat 1.3 1998/02/25 12:27:04 toma Exp $
rem mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
rem  Run TASM on all the table test files.   Those that have
rem  extended instuctions use the -x option.

tasm -48 -x test48.asm
tasm -65 -x test65.asm
tasm -51    test51.asm
tasm -85    test85.asm
tasm -80 -x testz80.asm
tasm -05 -x test05.asm
tasm -3210  test3210.asm
tasm -3225  test3225.asm
tasm -68 -x test68.asm
tasm -70    test70.asm
tasm -96 -x test96.asm

