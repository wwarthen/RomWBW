rem rem.sub 7/22/2012 dwg - build rem from sources

if not exist rem.rel erase rem.cpm
if not exist rem.rel erase rem.com
if not exist rem.rel z80mu rmac rem
if not exist rem.cpm z80mu link rem
if not exist rem.cpm rename rem.com rem.cpm
dir rem.cpm

