@echo off
setlocal

if exist bios3.spr del bios3.spr
if exist bnkbios3.spr del bnkbios3.spr
if exist zpmbios3.spr del zpmbios3.spr
if exist *.rel del *.rel
if exist cpmldr.com del cpmldr.com
if exist *.err del *.err
if exist *.lst del *.lst
if exist *.sym del *.sym
if exist *.sys del *.sys
if exist *.bin del *.bin
if exist gencpm.dat del gencpm.dat
if exist options.lib del options.lib
if exist ldropts.lib del ldropts.lib
