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

zx MAC -stdio -CCP.ASM -$PO
zx MLOAD25 -stdio -CCP.BIN=CCP.HEX

zx MAC -stdio -BDOS.ASM -$PO
zx MLOAD25 -stdio -BDOS.BIN=BDOS.HEX

zx MAC -stdio -CCP22.ASM -$PO
zx MLOAD25 -stdio -CCP22.BIN=CCP22.HEX

zx MAC -stdio -BDOS22.ASM -$PO
zx MLOAD25 -stdio -BDOS22.BIN=BDOS22.HEX

zx MAC -stdio -OS2CCP.ASM -$PO
zx MLOAD25 -stdio -OS2CCP.BIN=OS2CCP.HEX

zx MAC -stdio -OS3BDOS.ASM -$PO
zx MLOAD25 -stdio -OS3BDOS.BIN=OS3BDOS.HEX

goto :eof

:asm
echo.
echo Building %1...
tasm -t80 -b -g3 -fFF %1.asm %1.bin %1.lst
goto :eof
