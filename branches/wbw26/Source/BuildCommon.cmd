@echo off
setlocal

pushd Apps && call Build && popd
pushd CPM22 && call Build && popd
pushd ZCPR && call Build && popd
pushd ZCPR-DJ && call Build && popd
pushd ZSDOS && call Build && popd
