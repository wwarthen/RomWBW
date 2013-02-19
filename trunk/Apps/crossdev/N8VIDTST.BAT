if not exist n8vidtst.asm z80mu cc n8vidtst
if not exist n8vidtst.o   z80mu as n8vidtst
if not exist n8chars.asm  z80mu cc n8chars
if not exist n8chars.o    z80mu as n8chars
if not exist tms9918.asm  z80mu cc tms9918
if not exist tms9918.o    z80mu as tms9918
if not exist n8vidtst.cpm z80mu ln n8vidtst.o n8chars.o tms9918.o -lc
if not exist n8vidtst.cpm rename n8vidtst.com n8vidtst.cpm
dir n8vidtst.cpm
