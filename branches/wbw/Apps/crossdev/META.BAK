rem meta.bat 2/14/2013 dwg - build meta.cpm using native tools via z80mu

if not exist asmiface.o erase meta.cpm
if not exist asmiface.o z80mu as asmiface
rem dir asmiface.*
rem pause

if not exist bdoscall.o erase meta.cpm
if not exist bdoscall.o z80mu as bdoscall
rem dir bdoscall.*
rem pause

if not exist bioscall.o erase meta.cpm
if not exist bioscall.o z80mu as bioscall
rem dir bioscall*
rem pause

if not exist cbanner.asm erase meta.cpm
if not exist cbanner.asm erase cbanner.o
if not exist cbanner.asm z80mu cc cbanner
if not exist cbanner.o   erase meta.cpm
if not exist cbanner.o   z80mu as cbanner
rem dir cbanner.*
rem pause

if not exist clogical.asm erase meta.cpm
if not exist clogical.asm erase clogical.o
if not exist clogical.asm z80mu cc clogical
if not exist clogical.o   erase meta.cpm
if not exist clogical.o   z80mu as clogical
rem dir clogical.*
rem pause
if not exist ctermcap.asm erase meta.cpm
if not exist ctermcap.asm erase ctermcap.o
if not exist ctermcap.asm z80mu cc ctermcap
if not exist ctermcap.o   erase meta.cpm
if not exist ctermcap.o   z80mu as ctermcap
rem dir ctermcap.*
rem pause
if not exist diagnose.o erase meta.cpm
if not exist diagnose.o z80mu as diagnose
rem dir diagnose.*
rem pause
if not exist sectorio.asm erase meta.cpm
if not exist sectorio.asm erase sectorio.o
if not exist sectorio.asm z80mu cc sectorio
if not exist sectorio.o   erase meta.cpm
if not exist sectorio.o   z80mu as sectorio
rem dir sectorio.*
rem pause

if not exist meta.asm erase meta.cpm
if not exist meta.asm erase meta.o
if not exist meta.asm z80mu cc meta
if not exist meta.o   erase meta.cpm
if not exist meta.o   z80mu as meta
rem dir meta.*
rem pause
if not exist meta.cpm z80mu ln meta.o asmiface.o bioscall.o bdoscall.o cbanner.o clogical.o diagnose.o ctermcap.o sectorio.o c.lib
if not exist meta.cpm rename meta.com meta.cpm
rem dir meta.*
dir meta.cpm
