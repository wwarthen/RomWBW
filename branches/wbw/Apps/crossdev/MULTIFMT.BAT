rem multifmt.bat 2/14/2013 dwg - build multifmt.cpm using native tools
@echo off
@if not exist asmiface.o   erase multifmt.cpm
@if not exist asmiface.o   z80mu as asmiface

@if not exist clogical.asm erase multifmt.cpm
@if not exist clogical.asm erase clogical.o
@if not exist clogical.asm z80mu cc clogical
@if not exist clogical.o   erase multifmt.cpm
@if not exist clogical.o   z80mu as clogical

@if not exist cmemory.asm  erase multifmt.cpm
@if not exist cmemory.asm  erase cmemory.o
@if not exist cmemory.asm  z80mu cc cmemory
@if not exist cmemory.o    erase multifmt.cpm
@if not exist cmemory.o    z80mu as cmemory

@if not exist ctermcap.asm erase multifmt.cpm
@if not exist ctermcap.asm erase ctermcap.o
@if not exist ctermcap.asm z80mu cc ctermcap
@if not exist ctermcap.o   erase multifmt.cpm
@if not exist ctermcap.o   z80mu as ctermcap

@if not exist diagnose.o   erase multifmt.cpm
@if not exist diagnose.o   z80mu as diagnose

@if not exist multifmt.asm erase multifmt.cpm
@if not exist multifmt.asm erase multifmt.o
@if not exist multifmt.asm z80mu cc multifmt
@if not exist multifmt.o   erase multifmt.cpm
@if not exist multifmt.o   z80mu as multifmt

@if not exist sectorio.asm erase multifmt.cpm
@if not exist sectorio.asm erase sectorio.o
@if not exist sectorio.asm z80mu cc sectorio
@if not exist sectorio.o   erase multifmt.cpm
@if not exist sectorio.o   z80mu as sectorio

@if not exist multifmt.cpm z80mu ln multifmt.o asmiface.o bioscall.o bdoscall.o clogical.o cmemory.o sectorio.o diagnose.o ctermcap.o c.lib
@if not exist multifmt.cpm rename multifmt.com multifmt.cpm

dir multifmt.cpm
