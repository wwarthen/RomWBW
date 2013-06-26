@echo off

setlocal

echo Building Apps...
pushd Apps\Source
call Build.cmd
popd