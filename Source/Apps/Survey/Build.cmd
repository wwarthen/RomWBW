@echo off
setlocal

set TOOLS=..\..\..\Tools

set PATH=%TOOLS%\zxcc;%PATH%

set CPMDIR80=%TOOLS%/cpm/

:: zxcc MAC survey.asm -$PO || exit /b
:: zxcc MLOAD25 survey || exit /b

zxcc M80 -,=survey/L/R
zxcc L80 -survey,survey/N/E

copy /Y survey.com ..\..\..\Binary\Apps\ || exit /b
