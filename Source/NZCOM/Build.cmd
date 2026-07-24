@echo off
setlocal

set TOOLS=..\..\Tools
set PATH=%PATH%;%TOOLS%\zxcc;%TOOLS%\cpmtools;
set CPMDIR80=%TOOLS%/cpm/

zxcc Z80ASM -NZCOM/RFS || exit /b
zxcc SLRNK -NZCOM/N,NZCOM/M,/A:100,NZCOM,B:Z3LIB11/S,B:SYSLIB36/S,/E || exit /b

zxcc Z80ASM -MKZCM/RFS || exit /b
zxcc SLRNK -MKZCM/N,MKZCM/M,/A:100,MKZCM,B:SYSLIB36/S,/E || exit /b

zxcc Z80ASM -NZBLITZ/FS || exit /b
