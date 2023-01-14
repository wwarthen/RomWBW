@echo off
setlocal

pushd HDIAG && call Build || exit /b & popd
pushd CBIOS && call Build || exit /b & popd
pushd CPM22 && call Build || exit /b & popd
pushd ZCPR && call Build || exit /b & popd
pushd ZCPR-DJ && call Build || exit /b & popd
pushd ZSDOS && call Build || exit /b & popd
pushd CPM3 && call Build || exit /b & popd
pushd ZPM3 && call Build || exit /b & popd
pushd pSys && call Build || exit /b & popd
pushd Apps && call Build || exit /b & popd
pushd Forth && call Build || exit /b & popd
pushd TastyBasic && call Build || exit /b & popd
pushd Fonts && call Build || exit /b & popd
pushd RomDsk && call Build || exit /b & popd
