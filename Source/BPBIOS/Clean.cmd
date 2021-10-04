@echo off
setlocal

if exist *.tmp del *.tmp
if exist *.prn del *.prn
if exist *.err del *.err
if exist *.img del *.img
if exist bp*.rel del bp*.rel
if exist zcpr33*.rel del zcpr33*.rel
if exist *.bak del *.bak
if exist def-ww.lib del def-ww.lib

pushd ZCPR33 && call Clean.cmd & popd
