rem tmsstat.bat 2/15/2013 dwg - build tmsstat.cpm using native tools

if not exist tmsstat.asm z80mu cc tmsstat
if not exist tmsstat.o   z80mu as tmsstat
if not exist n8chars.asm z80mu cc n8chars
if not exist n8chars.o   z80mu as n8chars
if not exist tms9918.asm z80mu cc tms9918
if not exist tms9918.o   z80mu as tms9918
if not exist tmsstat.cpm z80mu ln tmsstat.o n8chars.o tms9918.o -lc
if not exist tmsstat.cpm rename tmsstat.com tmsstat.cpm
