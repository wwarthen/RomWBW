rem findfile.sub 9/5/2012 dwg - make findfile.com from sources
if not exist findfile.rel z80mu rmac findfile 
if not exist printers.rel z80mu rmac printers
if not exist terminal.rel z80mu rmac terminal
if not exist memory.rel   z80mu rmac memory
if not exist banner.rel   z80mu rmac banner
if not exist identity.rel z80mu rmac identity
if not exist hbios.rel    z80mu rmac hbios
if not exist findfile.cpm z80mu link findfile,hbios,identity,banner,memory,printers,terminal
if not exist findfile.cpm rename findfile.com findfile.cpm
dir findfile.cpm

