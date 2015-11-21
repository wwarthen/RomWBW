@echo off
setlocal

pushd Source && call BuildCommon && popd
pushd Hardware && call Build && popd