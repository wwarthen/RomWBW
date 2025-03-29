@echo off
setlocal

set TOOLS=../../../Tools

set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%

set TASMTABS=%TOOLS%\tasm32

set CPMDIR80=%TOOLS%/cpm/

:: These variations of ZDE are built here as reference copies.  They
:: are not copied anywhere else during the build.
:: The resulting .COM files are manually
:: copied to /Source/Images/d_ws/u1 as needed.

zxcc ZMAC -ZDE16 -/P -/H || exit /b
zxcc MLOAD25 ZDE16 || exit /b
copy /Y zde16.com ..\..\..\Binary\Apps\ZDE\ || exit /b

zxcc ZMAC ZDE16A.PAT -/H || exit /b
zxcc MLOAD25 ZDE16A=ZDE16.COM,ZDE16A.HEX || exit /b
copy /Y zde16a.com ..\..\..\Binary\Apps\ZDE\ || exit /b

zxcc ZMAC -ZDE17 -/P -/H || exit /b
zxcc MLOAD25 ZDE17 || exit /b
copy /Y zde17.com ..\..\..\Binary\Apps\ZDE\ || exit /b

zxcc ZMAC -ZDE18 -/P -/H || exit /b
zxcc MLOAD25 ZDE18 || exit /b
copy /Y zde18.com ..\..\..\Binary\Apps\ZDE\ || exit /b

zxcc ZMAC -ZDE19 -/P -/H || exit /b
zxcc MLOAD25 ZDE19 || exit /b
copy /Y zde19.com ..\..\..\Binary\Apps\ZDE\ || exit /b
