rem cpmname.sub  9/5/2012 dwg - build cpmname from sources

if not exist cpmname.asm erase cpmname.cpm
if not exist cpmname.asm erase cpmname.o
if not exist cpmname.asm z80mu cc cpmname
if not exist cpmname.o   erase cpmname.cpm
if not exist cpmname.o   z80mu as cpmname

if not exist cnamept1.asm erase cpmname.cpm
if not exist cnamept1.asm erase cnamept1.o
if not exist cnamept1.asm z80mu cc cnamept1
if not exist cnamept1.o   erase cpmname.cpm
if not exist cnamept1.o   z80mu as cnamept1

if not exist cnamept2.asm erase cpmname.cpm
if not exist cnamept2.asm erase cnamept2.o
if not exist cnamept2.asm z80mu cc cnamept2
if not exist cnamept2.o   erase cpmname.cpm
if not exist cnamept2.o   z80mu as cnamept2

if not exist cnamept3.asm erase cpmname.cpm
if not exist cnamept3.asm erase cnamept3.o
if not exist cnamept3.asm z80mu cc cnamept3
if not exist cnamept3.o   erase cpmname.cpm
if not exist cnamept3.o   z80mu as cnamept3

if not exist cnamept4.asm erase cpmname.cpm
if not exist cnamept4.asm erase cnamept4.o
if not exist cnamept4.asm z80mu cc cnamept4
if not exist cnamept4.o   erase cpmname.cpm
if not exist cnamept4.o   z80mu as cnamept4

if not exist bdoscall.o   erase cpmname.cpm
if not exist bdoscall.o   z80mu as bdoscall

if not exist bioscall.o   erase cpmname.cpm
if not exist bioscall.o   z80mu as bioscall

if not exist cmemory.asm  erase cpmname.cpm
if not exist cmemory.asm  erase cmemory.o
if not exist cmemory.asm  z80mu cc cmemory
if not exist cmemory.o    erase cpmname.cpm
if not exist cmemory.o    z80mu as cmemory

if not exist ctermcap.asm erase cpmname.cpm
if not exist ctermcap.asm erase ctermcap.o
if not exist ctermcap.asm z80mu cc ctermcap
if not exist ctermcap.o   erase cpmname.cpm
if not exist ctermcap.o   z80mu as ctermcap

if not exist diagnose.o   erase cpmname.cpm
if not exist diagnose.o   z80mu as diagnose

if not exist cpmname.cpm  z80mu ln cpmname.o ctermcap.o cnamept1.o cnamept2.o cnamept3.o cnamept4.o cmemory.o diagnose.o bioscall.o bdoscall.o c.lib
if not exist cpmanme.cpm  rename cpmname.com cpmname.cpm

dir cpmname.cpm
