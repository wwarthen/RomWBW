rem access.sub 9/5/2012 dwg - build access from sources

if not exist access.rel   erase access.cpm
if not exist access.rel   z80mu rmac access

if not exist printers.rel erase access.cpm
if not exist printers.rel z80mu rmac printers

if not exist memory.rel   erase access.cpm 
if not exist memory.rel   z80mu rmac memory

if not exist banner.rel   erase access.cpm
if not exist banner.rel   z80mu rmac banner

if not exist access.cpm   z80mu link access,memory,banner,printers
if not exist access.cpm   rename access.com access.cpm

dir access.cpm
