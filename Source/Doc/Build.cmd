@echo off
setlocal

::
:: NOTE: Pandoc and Latex (MiKTeX or TexLive) must be installed
:: and available on commandline for this build to work!!!
::

set TOOLS=..\..\Tools
set PATH=%TOOLS%\gpp;%PATH%

if not "%1"=="" (call :GenDoc %1 & goto :eof)

call :GenDoc ReadMe
call :GenDoc UserGuide
call :GenDoc SystemGuide
call :GenDoc Applications
call :GenDoc ROM_Applications
call :GenDoc Catalog
call :GenDoc Errata

if exist ReadMe.gfm copy Readme.gfm ..\..\ReadMe.md || exit /b
if exist ReadMe.txt copy ReadMe.txt ..\..\ReadMe.txt || exit /b
if exist UserGuide.pdf copy UserGuide.pdf "..\..\Doc\RomWBW User Guide.pdf" || exit /b
if exist SystemGuide.pdf copy SystemGuide.pdf "..\..\Doc\RomWBW System Guide.pdf" || exit /b
if exist Applications.pdf copy Applications.pdf "..\..\Doc\RomWBW Applications.pdf" || exit /b
if exist ROM_Applications.pdf copy ROM_Applications.pdf "..\..\Doc\RomWBW ROM Applications.pdf" || exit /b
if exist Catalog.pdf copy Catalog.pdf "..\..\Doc\RomWBW Disk Catalog.pdf" || exit /b
if exist Errata.pdf copy Errata.pdf "..\..\Doc\RomWBW Errata.pdf" || exit /b

echo.
goto :eof

:GenDoc

echo.

echo Processing document %1...

::gpp -o %1.tmp %1.md
::gpp -o %1.tmp -U "\\" "" "{" "}{" "}" "{" "}" "#" "" %1.md
::gpp -o %1.tmp -U "" "" "(" "," ")" "(" ")" "#" "" -M "#" "\n" " " " " "\n" "(" ")" %1.md
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