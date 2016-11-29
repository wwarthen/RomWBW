@echo off
setlocal

if exist *.prn del *.prn
if exist *.err del *.err
if exist *.img del *.img
if exist bp*.rel del bp*.rel
if exist *.bak del *.bak

if exist zcpr33t.rel del zcpr33t.rel
if exist zcpr33n.rel del zcpr33n.rel

setlocal & cd ZCPR33 && call Clean.cmd & endlocal
