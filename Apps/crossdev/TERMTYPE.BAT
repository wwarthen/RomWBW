rem termtype.sub 7/22/2012 dwg - build termtype from sources

if not exist termtype.asm erase termtype.cpm
if not exist termtype.asm erase termtype.o
if not exist termtype.asm z80mu cc termtype
if not exist termtype.o   erase termtype.cpm
if not exist termtype.o   z80mu as termtype

if not exist asmiface.o erase termtype.cpm
if not exist asmiface.o z80mu as asmiface

if not exist ctermcap.asm erase termtype.cpm
if not exist ctermcap.asm erase termtype.o
if not exist ctermcap.asm z80mu cc ctermcap
if not exist ctermcap.o   erase termtype.cpm
if not exist ctermcap.o   z80mu as ctermcap

if not exist diagnose.o erase termtype.cpm
if not exist diagnose.o z80mu as diagnose

if not exist termtype.cpm z80mu ln termtype.o asmiface.o ctermcap.o diagnose.o c.lib
if not exist termtype.cpm rename termtype.com termtype.cpm

dir termtype.cpm

