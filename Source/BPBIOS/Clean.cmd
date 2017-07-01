@echo off
setlocal

if exist *.tmp del *.tmp
if exist *.prn del *.prn
if exist *.err del *.err
if exist *.img del *.img
if exist bp*.rel del bp*.rel
if exist zcpr33*.rel del zcpr33*.rel
if exist *.bak del *.bak

setlocal & cd ZCPR33 && call Clean.cmd & endlocal
