@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zxcc;%PATH%

set CPMDIR80=%TOOLS%/cpm/

zxcc z80asm -zmd/fm
zxcc l80 -zmd,zmd/n/e

zxcc z80asm -zmap/fm
zxcc l80 -zmap,zmap/n/e

zxcc z80asm -znews/fm
zxcc l80 -znews,znews/n/e

zxcc z80asm -znewp/fm
zxcc l80 -znewp,znewp/n/e

zxcc z80asm -zfors/fm
zxcc l80 -zfors,zfors/n/e

zxcc z80asm -zforp/fm
zxcc l80 -zforp,zforp/n/e

zxcc z80asm -zmdel/fm
zxcc l80 -zmdel,zmdel/n/e

zxcc z80asm -zmdhb/fh
zxcc mload25 -zmd=zmd.com,zmdhb

copy /Y zmd.com ..\..\..\Binary\Apps\ || exit /b

