@echo off
setlocal

pushd Apps && call Clean.cmd && popd
pushd CPM22 && call Clean.cmd && popd
pushd ZCPR && call Clean.cmd && popd
pushd ZCPR-DJ && call Clean.cmd && popd
pushd ZSDOS && call Clean.cmd && popd
pushd CBIOS && call Clean.cmd && popd

pushd BPBIOS && call Clean.cmd && popd

pushd HBIOS && call Clean.cmd && popd
