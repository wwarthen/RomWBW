@echo off
setlocal

ren zmdsubs.rel zmdsubs.rel.sav
if exist *.rel del *.rel
ren zmdsubs.rel.sav zmdsubs.rel
if exist *.hex del *.hex
if exist *.prn del *.prn
if exist *.lst del *.lst
if exist *.com del *.com
