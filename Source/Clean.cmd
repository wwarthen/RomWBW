@echo off
setlocal

pushd HDIAG && call Clean.cmd & popd
pushd Apps && call Clean.cmd & popd
pushd CPM22 && call Clean.cmd & popd
pushd ZCPR && call Clean.cmd & popd
pushd ZCPR-DJ && call Clean.cmd & popd
pushd ZSDOS && call Clean.cmd & popd
pushd CBIOS && call Clean.cmd & popd
pushd CPM3 && call Clean.cmd & popd
pushd ZPM3 && call Clean.cmd & popd
pushd pSys && call Clean.cmd & popd
pushd Forth && call Clean.cmd & popd
pushd TastyBasic && call Clean & popd
pushd Fonts && call Clean.cmd & popd
pushd BPBIOS && call Clean.cmd & popd
pushd HBIOS && call Clean.cmd & popd
pushd Images && call Clean & popd
pushd Prop && call Clean & popd
pushd RomDsk && call Clean & popd
pushd Doc && call Clean & popd
pushd ZRC && call Clean & popd
pushd ZZRC && call Clean & popd
