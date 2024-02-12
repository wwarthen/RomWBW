@echo off
setlocal

set TOOLS=%~dp0..\..\Tools

set PATH=%TOOLS%\zxcc;%PATH%
set CPMDIR80=%TOOLS%\cpm\

pushd duo\cpnet12
zxcc nulu --O -cpn12duo "-<30" --A -*.* --L --X || exit /b
move cpn12duo.lbr ..\.. || exit /b
popd

pushd duo\cpnet3
zxcc nulu --O -cpn3duo "-<30" --A -*.* --L --X || exit /b
move cpn3duo.lbr ..\.. || exit /b
popd

pushd mt011\cpnet12
zxcc nulu --O -cpn12mt "-<30" --A -*.* --L --X || exit /b
move cpn12mt.lbr ..\.. || exit /b
popd

pushd mt011\cpnet3
zxcc nulu --O -cpn3mt "-<30" --A -*.* --L --X || exit /b
move cpn3mt.lbr ..\.. || exit /b
popd

copy *.lbr ..\..\Binary\CPNET
