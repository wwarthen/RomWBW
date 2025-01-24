@echo off
setlocal

::
:: NOTE: Pandoc, LuaLatex (MiKTeX or TexLive), and Roboto Font
:: must be installed and available on commandline for this build to work!!!
::
:: - Pandoc (https://pandoc.org/)
:: - MiKTeX (https://miktex.org/)
::   - Install Roboto font from MiKTeX Console
::

set TOOLS=..\..\Tools
set PATH=%TOOLS%\gpp;%PATH%

if not "%1"=="" (call :GenDoc %1 & goto :eof)

:: call :GenDoc ReadMe || exit /b
call :GenDoc Introduction || exit /b
call :GenDoc UserGuide || exit /b
call :GenDoc SystemGuide || exit /b
call :GenDoc Applications || exit /b
call :GenDoc Catalog || exit /b
call :GenDoc Hardware || exit /b

:: if exist ReadMe.gfm copy Readme.gfm ..\..\ReadMe.md || exit /b
:: if exist ReadMe.txt copy ReadMe.txt ..\..\ReadMe.txt || exit /b
if exist Introduction.gfm copy Introduction.gfm ..\..\ReadMe.md || exit /b
if exist Introduction.txt copy Introduction.txt ..\..\ReadMe.txt || exit /b
if exist Introduction.pdf copy Introduction.pdf "..\..\Doc\RomWBW Introduction.pdf" || exit /b
if exist UserGuide.pdf copy UserGuide.pdf "..\..\Doc\RomWBW User Guide.pdf" || exit /b
if exist SystemGuide.pdf copy SystemGuide.pdf "..\..\Doc\RomWBW System Guide.pdf" || exit /b
if exist Applications.pdf copy Applications.pdf "..\..\Doc\RomWBW Applications.pdf" || exit /b
if exist Catalog.pdf copy Catalog.pdf "..\..\Doc\RomWBW Disk Catalog.pdf" || exit /b
if exist Hardware.pdf copy Hardware.pdf "..\..\Doc\RomWBW Hardware.pdf" || exit /b

echo.
goto :eof

:GenDoc

echo.

echo Processing document %1...

gpp -o %1.tmp -U "$" "$" "{" "}{" "}$" "{" "}" "@@@" "" -M "$" "$" "{" "}{" "}$" "{" "}" %1.md || exit /b

::pandoc %1.tmp -f markdown -t latex -s -o %1.tex --default-image-extension=pdf || exit /b
::::rem texify --pdf --clean %1.ltx || exit /b
::texify --pdf --clean --engine=luatex --verbose %1.tex || exit /b
::goto :eof

pandoc %1.tmp -f markdown -t pdf -s -o %1.pdf --default-image-extension=pdf --pdf-engine=lualatex || exit /b
pandoc %1.tmp -f markdown -t html -s -o %1.html --default-image-extension=png --css pandoc.css --embed-resources || exit /b
pandoc %1.tmp -f markdown -t dokuwiki -s -o %1.dw --default-image-extension=png || exit /b
pandoc %1.tmp -f markdown -t gfm-yaml_metadata_block -s -o %1.gfm --default-image-extension=png || exit /b
::pandoc %1.tmp -f markdown -t gfm-yaml_metadata_block -s -o %1.txt --markdown-headings=setext --default-image-extension=png || exit /b
pandoc %1.tmp -f markdown -t plain+gutenberg -s -o %1.txt || exit /b

goto :eof
