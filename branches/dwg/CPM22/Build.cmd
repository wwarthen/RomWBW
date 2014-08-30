@echo off

setlocal

set PATH=..\Tools\tasm32;..\Tools\zx;%PATH%

set TASMTABS=..\Tools\tasm32

set ZXBINDIR=../tools/cpm/bin/
set ZXLIBDIR=../tools/cpm/lib/
set ZXINCDIR=../tools/cpm/include/

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

goto :eof

:asm
echo.
echo Building %1...
tasm -t80 -b -g3 -fFF %1.asm %1.bin %1.lst
goto :eof






@echo off

setlocal

set PATH=..\Tools\tasm32;..\Tools\zx;%PATH%

set TASMTABS=..\Tools\tasm32

set ZXBINDIR=../tools/cpm/bin/
set ZXLIBDIR=../tools/cpm/lib/
set ZXINCDIR=../tools/cpm/include/

call :asm SysCopy || goto :eof
call :asm Assign || goto :eof
call :asm Format || goto :eof
call :asm Talk || goto :eof

zx Z80ASM -SYSGEN/F

goto :eof

:asm
echo.
echo Building %1...
tasm -t80 -b -g3 -fFF %1.asm %1.com %1.lst
goto :eof