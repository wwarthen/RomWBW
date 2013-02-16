rem build view.cpm(.com) using native 8-bit tools
if not exist bdoscall.o erase view.cpm
if not exist bdoscall.o z80mu as bdoscall
if not exist bioscall.o erase view.cpm
if not exist bioscall.o z80mu as bioscall
if not exist ctermcap.asm erase view.cpm
if not exist ctermcap.asm z80mu cc ctermcap
if not exist ctermcap.o erase view.cpm
if not exist ctermcap.o z80mu as ctermcap
if not exist diagnose.o erase view.cpm
if not exist diagnose.o z80mu as diagnose
if not exist view.asm   erase view.cpm
if not exist view.asm   z80mu cc view
if not exist view.o     erase view.cpm
if not exist view.o     z80mu as view
if not exist view.cpm z80mu ln view.o ctermcap.o diagnose.o bdoscall.o bioscall.o c.lib
if not exist view.cpm rename view.com view.cpm
dir view.cpm

