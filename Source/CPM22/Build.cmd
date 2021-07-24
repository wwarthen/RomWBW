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

zx MAC -CCP.ASM -$PO || exit /b
zx MLOAD25 -CCP.BIN=CCP.HEX || exit /b

zx MAC -BDOS.ASM -$PO || exit /b
zx MLOAD25 -BDOS.BIN=BDOS.HEX || exit /b

zx MAC -CCP22.ASM -$PO || exit /b
zx MLOAD25 -CCP22.BIN=CCP22.HEX || exit /b

zx MAC -BDOS22.ASM -$PO || exit /b
zx MLOAD25 -BDOS22.BIN=BDOS22.HEX || exit /b

zx MAC -OS2CCP.ASM -$PO || exit /b
zx MLOAD25 -OS2CCP.BIN=OS2CCP.HEX || exit /b

zx MAC -OS3BDOS.ASM -$PO || exit /b
zx MLOAD25 -OS3BDOS.BIN=OS3BDOS.HEX || exit /b

tasm -t80 -g3 -fFF loader.asm loader.bin loader.lst || exit /b

copy /b os2ccp.bin + os3bdos.bin + ..\cbios\cbios_wbw.bin cpm_wbw.bin || exit /b
copy /b os2ccp.bin + os3bdos.bin + ..\cbios\cbios_una.bin cpm_una.bin || exit /b

copy /b loader.bin + cpm_wbw.bin cpm_wbw.sys || exit /b
copy /b loader.bin + cpm_una.bin cpm_una.sys || exit /b

goto :eof

:asm
echo.
echo Building %1...
tasm -t80 -b -g3 -fFF %1.asm %1.bin %1.lst || exit /b
goto :eof
