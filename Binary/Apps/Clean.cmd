@echo off
setlocal

if exist *.com del *.com
if exist *.ovr del *.ovr
if exist *.doc del *.doc
if exist *.hlp del *.hlp
if exist Tunes\*.pt? del Tunes\*.pt?
if exist Tunes\*.mym del Tunes\*.mym
if exist Tunes\*.vgm del Tunes\*.vgm

pushd Test && call Clean || exit /b 1 & popd
