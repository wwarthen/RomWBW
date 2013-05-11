@echo off
setlocal

echo Cleaning Source...
pushd Source
call Clean.cmd
popd

echo Cleaning Apps...
pushd Apps\Source
call Clean.cmd
popd

choice /m "Clean Output directories?"
if errorlevel 2 goto :eof
echo Cleaning Output...
if exist Output\*.* del Output\*.* /Q
if exist Apps\Output\*.* del Apps\Output\*.* /Q