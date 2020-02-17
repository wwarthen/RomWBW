@echo off
setlocal

set TOOLS=../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zx;%PATH%

set TASMTABS=%TOOLS%\tasm32

set ZXBINDIR=%TOOLS%/cpm/bin/
set ZXLIBDIR=%TOOLS%/cpm/lib/
set ZXINCDIR=%TOOLS%/cpm/include/

call :asm ccpb03 || goto :eof
call :asm bdosb01 || goto :eof

zx MAC -CCP.ASM -$PO
zx MLOAD25 -CCP.BIN=CCP.HEX

zx MAC -BDOS.ASM -$PO
zx MLOAD25 -BDOS.BIN=BDOS.HEX

zx MAC -CCP22.ASM -$PO
zx MLOAD25 -CCP22.BIN=CCP22.HEX

zx MAC -BDOS22.ASM -$PO
zx MLOAD25 -BDOS22.BIN=BDOS22.HEX

zx MAC -OS2CCP.ASM -$PO
zx MLOAD25 -OS2CCP.BIN=OS2CCP.HEX

zx MAC -OS3BDOS.ASM -$PO
zx MLOAD25 -OS3BDOS.BIN=OS3BDOS.HEX

tasm -t80 -g3 -fFF loader.asm loader.bin loader.lst

copy /b os2ccp.bin + os3bdos.bin + ..\cbios\cbios_wbw.bin cpm_wbw.bin
copy /b os2ccp.bin + os3bdos.bin + ..\cbios\cbios_una.bin cpm_una.bin

copy /b loader.bin + cpm_wbw.bin cpm_wbw.sys
copy /b loader.bin + cpm_una.bin cpm_una.sys

goto :eof

:asm
echo.
echo Building %1...
tasm -t80 -b -g3 -fFF %1.asm %1.bin %1.lst
goto :eof
