@echo off
setlocal

::
:: NOTE: Pandoc and Latex (MiKTeX or TexLive) must be installed
:: and available on commandline for this build to work!!!
::

set TOOLS=..\..\Tools
set PATH=%TOOLS%\m4;%TOOLS%\gpp;%PATH%

if not "%1"=="" (call :GenDoc %1 & goto :eof)

call :GenDoc GettingStarted
:: call :GenDoc UserGuide
call :GenDoc Applications
:: call :GenDoc Errata
:: call :GenDoc ZSystem
call :GenDoc Architecture
call :GenDoc Catalog
call :GenDoc ROM_Applications

if exist GettingStarted.pdf copy GettingStarted.pdf "..\..\Doc\RomWBW Getting Started.pdf" || exit /b
if exist GettingStarted.gfm copy GettingStarted.gfm ..\..\ReadMe.md || exit /b
if exist GettingStarted.txt copy GettingStarted.txt ..\..\ReadMe.txt || exit /b
if exist Applications.pdf copy Applications.pdf "..\..\Doc\RomWBW Applications.pdf" || exit /b
if exist Architecture.pdf copy Architecture.pdf "..\..\Doc\RomWBW Architecture.pdf" || exit /b
if exist Catalog.pdf copy Catalog.pdf "..\..\Doc\RomWBW Disk Catalog.pdf" || exit /b
if exist ROM_Applications.pdf copy ROM_Applications.pdf "..\..\Doc\ROM Applications.pdf" || exit /b

echo.
goto :eof

:GenDoc

echo.

echo Processing document %1.md...

::gpp -o %1.tmp %1.md
::gpp -o %1.tmp -U "\\" "" "{" "}{" "}" "{" "}" "#" "" %1.md
::gpp -o %1.tmp -U "" "" "(" "," ")" "(" ")" "#" "" -M "#" "\n" " " " " "\n" "(" ")" %1.md
gpp -o %1.tmp -U "$" "$" "{" "}{" "}$" "{" "}" "@@@" "" -M "$" "$" "{" "}{" "}$" "{" "}" %1.md

:: pandoc %1.tmp -f markdown -s -o %1.tex --default-image-extension=pdf || exit /b
:: pause
:: rem texify --pdf --clean %1.ltx || exit /b
:: texify --pdf %1.tex || exit /b
:: goto :eof

pandoc %1.tmp -f markdown -t pdf -s -o %1.pdf --default-image-extension=pdf || exit /b
pandoc %1.tmp -f markdown -t html -s -o %1.html --default-image-extension=png || exit /b
pandoc %1.tmp -f markdown -t dokuwiki -s -o %1.dw --default-image-extension=png || exit /b
pandoc %1.tmp -f markdown -t gfm -s -o %1.gfm --default-image-extension=png || exit /b
pandoc %1.tmp -f markdown -t plain -s -o %1.txt --default-image-extension=png || exit /b

goto :eof