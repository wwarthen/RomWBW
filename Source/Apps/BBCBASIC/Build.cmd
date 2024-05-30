@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zxcc;%PATH%

set CPMDIR80=%TOOLS%/cpm/

zxcc z80asm -dist/FM
zxcc z80asm -main/FM
zxcc z80asm -exec/FM
zxcc z80asm -eval/FM
zxcc z80asm -asmb/FM
zxcc z80asm -cmos/FM
zxcc z80asm -math/FM
zxcc z80asm -hook/FM
zxcc z80asm -data/FM

zxcc slrnk -/v,/a:0100,dist,main,exec,eval,asmb,math,hook,cmos,/p:4B00,data,bbcbasic/n,/e

copy /Y bbcbasic.com ..\..\..\Binary\Apps\ || exit /b
copy /Y bbcbasic.txt ..\..\..\Binary\Apps\ || exit /b
