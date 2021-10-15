@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zx;%PATH%

set ZXBINDIR=%TOOLS%\cpm\bin\
set ZXLIBDIR=%TOOLS%\cpm\lib\
set ZXINCDIR=%TOOLS%\cpm\include\

zx z80asm -zmd/fm
zx l80 -zmd,zmd/n/e

zx z80asm -zmap/fm
zx l80 -zmap,zmap/n/e

zx z80asm -znews/fm
zx l80 -znews,znews/n/e

zx z80asm -znewp/fm
zx l80 -znewp,znewp/n/e

zx z80asm -zfors/fm
zx l80 -zfors,zfors/n/e

zx z80asm -zforp/fm
zx l80 -zforp,zforp/n/e

zx z80asm -zmdel/fm
zx l80 -zmdel,zmdel/n/e

zx z80asm -zmdhb/fh
zx mload25 -zmd=zmd.com,zmdhb

copy /Y zmd.com ..\..\..\Binary\Apps\ || exit /b

