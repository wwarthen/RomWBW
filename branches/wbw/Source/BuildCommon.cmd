@echo off
setlocal

pushd CPM22 && call Build && popd
pushd ZCPR && call Build && popd
pushd ZCPR-DJ && call Build && popd
pushd Apps && call Build && popd
