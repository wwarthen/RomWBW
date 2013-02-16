rem sysgen.bat 2/14/2013 dwg - build sysgen.cpm using native tools via z80mu
rem this is working very well now, very much like a makefile :-)

if not exist bdoscall.o   erase sysgen.cpm
if not exist bdoscall.o   z80mu as bdoscall

if not exist bioscall.o   erase sysgen.cpm
if not exist bioscall.o   z80mu as bioscall

if not exist ctermcap.asm erase sysgen.cpm
if not exist ctermcap.asm erase ctermcap.o
if not exist ctermcap.asm z80mu cc ctermcap
if not exist ctermcap.o   erase sysgen.cpm
if not exist ctermcap.o   z80mu as ctermcap

if not exist diagnose.o   erase sysgen.cpm
if not exist diagnose.o   z80mu as diagnose

if not exist sectorio.asm erase sysgen.cpm
if not exist sectorio.asm erase sectorio.o
if not exist sectorio.asm z80mu cc sectorio
if not exist sectorio.o   erase sysgen.cpm
if not exist sectorio.o   z80mu as sectorio

if not exist sysgen.asm   erase sysgen.cpm
if not exist sysgen.asm   erase sysgen.o
if not exist sysgen.asm   z80mu cc sysgen
if not exist sysgen.o     erase sysgen.cpm
if not exist sysgen.o     z80mu as sysgen

if not exist sysgen.cpm   z80mu ln sysgen.o sectorio.o ctermcap.o diagnose.o bdoscall.o bioscall.o c.lib
if not exist sysgen.cpm   rename sysgen.com sysgen.cpm

dir sysgen.cpm
