@echo off
setlocal

pushd Source && call Clean && popd

if exist "RomWBW User Guide.pdf" del "RomWBW User Guide.pdf"
if exist "RomWBW System Guide.pdf" del "RomWBW System Guide.pdf"
