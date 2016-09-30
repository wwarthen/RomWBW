@echo off
if exist *.prn del *.prn
if exist *.err del *.err
if exist *.img del *.img
if exist bp*.rel del bp*.rel
if exist *.bak del *.bak

setlocal & pushd ZCPR33 && call Clean.cmd & endlocal
