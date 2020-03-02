@echo off
setlocal

setlocal & cd CBIOS && call Build || exit /b 1 & endlocal
setlocal & cd CPM22 && call Build || exit /b 1 & endlocal
setlocal & cd ZCPR && call Build || exit /b 1 & endlocal
setlocal & cd ZCPR-DJ && call Build || exit /b 1 & endlocal
setlocal & cd ZSDOS && call Build || exit /b 1 & endlocal
setlocal & cd CPM3 && call Build || exit /b 1 & endlocal
setlocal & cd ZPM3 && call Build || exit /b 1 & endlocal
setlocal & cd Apps && call Build || exit /b 1 & endlocal
setlocal & cd Forth && call Build || exit /b 1 & endlocal
setlocal & cd Fonts && call Build || exit /b 1 & endlocal
