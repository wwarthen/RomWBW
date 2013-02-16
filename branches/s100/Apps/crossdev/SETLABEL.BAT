rem setlabel.bat 2/15/2013 dwg - build setlabel.cpm using native tools

if not exist banner.rel    erase setlabel.cpm
if not exist banner.rel    z80mu rmac banner

if not exist identity.rel  erase setlabel.cpm
if not exist identity.rel  z80mu rmac identity

if not exist labelib.rel   erase setlabel.cpm
if not exist labelib.rel   z80mu rmac labelib

if not exist memory.rel    erase setlabel.cpm
if not exist memory.rel    z80mu rmac memory

if not exist metadata.rel  erase setlabel.cpm
if not exist metadata.rel  z80mu rmac metadata

if not exist printers.rel  erase setlabel.cpm
if not exist printers.rel  z80mu rmac printers

if not exist setlabel.rel  erase setlabel.cpm
if not exist setlabel.rel  z80mu rmac setlabel
if not exist setlabel.cpm  z80mu link setlabel,labelib,identity,printers,banner,metadata,memory
if not exist setlabel.cpm  rename setlabel.com setlabel.cpm

dir setlabel.cpm
