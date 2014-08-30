@echo off
setlocal

echo Cleaning Source...
pushd Source
call Clean.cmd
popd

echo Cleaning Apps...
pushd Apps
call Clean.cmd
popd

echo Cleaning CPM22...
pushd CPM22
call Clean.cmd
popd

echo Cleaning ZCPR...
pushd ZCPR
call Clean.cmd
popd

echo Cleaning ZCPR-DJ...
pushd ZCPR-DJ
call Clean.cmd
popd

if exist *.img del *.img /Q
if exist debug.log del debug.log

choice /m "Clean Output directories?"
if errorlevel 2 goto :eof
echo Cleaning Output directories...
if exist Output\*.* del Output\*.* /Q
if exist OutputUNA\*.* del OutputUNA\*.* /Q
if exist OutputUNALOAD\*.* del OutputUNALOAD\*.* /Q
