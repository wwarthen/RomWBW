@echo off
setlocal

echo Cleaning Source...
pushd Source
call Clean.cmd
popd

echo Cleaning Apps\core...
pushd Apps\core
del /q *.*
popd

echo Cleaning Apps\crossdev...
pushd Apps\crossdev
call Clean.bat
popd

choice /m "Clean Output directory?"
if errorlevel 2 goto :eof
echo Cleaning Output...
if exist Output\*.* del Output\*.* /Q