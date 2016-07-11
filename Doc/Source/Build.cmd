@echo off
setlocal

pushd "RomWBW User Guide" && call Build && popd
pushd "RomWBW System Guide" && call Build && popd

if exist "RomWBW User Guide\Main.pdf" copy "RomWBW User Guide\Main.pdf" "..\RomWBW User Guide.pdf"
if exist "RomWBW System Guide\Main.pdf" copy "RomWBW System Guide\Main.pdf" "..\RomWBW System Guide.pdf"

