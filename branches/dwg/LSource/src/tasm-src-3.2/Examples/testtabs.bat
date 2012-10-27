@echo off
rem mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
rem  $Id: testtabs.bat 1.3 1998/02/25 12:27:04 toma Exp $
rem mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
rem  Run TASM on all the table test files.   Those that have
rem  extended instuctions use the -x option.

rem If TASMTABS is defined then use it to compute the full path to the   
rem  the TASM executable.  Otherwise assume it is in the PATH or local
rem  directory.

IF DEFINED TASMTABS (
    set TASMEXE=%TASMTABS%\tasm
) ELSE ( 
    set TASMEXE=tasm
)


rem Assemble a sample file for each supported processor.

"%TASMEXE%" -48   -x test48.asm
"%TASMEXE%" -65   -x test65.asm
"%TASMEXE%" -51      test51.asm
"%TASMEXE%" -85      test85.asm
"%TASMEXE%" -80   -x testz80.asm
"%TASMEXE%" -05   -x test05.asm
"%TASMEXE%" -3210    test3210.asm
"%TASMEXE%" -3225    test3225.asm
"%TASMEXE%" -68   -x test68.asm
"%TASMEXE%" -70      test70.asm
"%TASMEXE%" -96   -x test96.asm

pause

