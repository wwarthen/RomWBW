@echo off
setlocal

set TOOLS=%~dp0..\..\Tools

set PATH=%TOOLS%\zxcc;%PATH%
set CPMDIR80=%TOOLS%\cpm\

zxcc nulu --O -cpn12mt "-<30" --A mt011/cpnet12/*.* --L --X || exit /b
zxcc nulu --O -cpn3mt "-<30" --A mt011/cpnet3/*.* --L --X || exit /b
zxcc nulu --O -cpn12duo "-<30" --A duo/cpnet12/*.* --L --X || exit /b
zxcc nulu --O -cpn3duo "-<30" --A duo/cpnet3/*.* --L --X || exit /b
zxcc nulu --O -cpn12ser "-<30" --A serial/cpnet12/*.* --L --X || exit /b
zxcc nulu --O -cpn3ser "-<30" --A serial/cpnet3/*.* --L --X || exit /b

copy *.lbr ..\..\Binary\CPNET
