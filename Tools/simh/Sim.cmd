@echo off
set ROM=..\..\Binary\SBC_simh_std.rom
if not "%1"=="" set ROM=..\..\Binary\%1.rom
if not exist %ROM% goto romerr
:: start C:\Users\WWarthen\Bin\putty.exe -load "SIMH Telnet"
:: start /w altairz80.exe sim.cfg %ROM%
altairz80.exe sim.cfg %ROM%
goto :eof

:romerr
echo ROM Image %ROM% Not Found!
pause
goto :eof