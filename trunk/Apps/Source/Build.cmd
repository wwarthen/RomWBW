@echo off

setlocal

set PATH=..\..\tools\zx;%PATH%
set ZXBINDIR=../../tools/cpm/bin/
set ZXLIBDIR=../../tools/cpm/lib/
set ZXINCDIR=../../tools/cpm/include/

set OUTDIR=..\Output\
set COREAPPS=ACCESS CPMNAME FINDFILE MAP META MULTIFMT REM SETLABEL SYSGEN TERMTYPE VIEW

echo.
echo Building DWG.REL...
echo.
set TGT=dwg.rel
if exist %TGT% del %TGT%
zx rmac printers
zx rmac memory
zx rmac banner
zx rmac terminal
zx rmac identity
zx rmac hbios
zx lib %TGT%=printers,memory,banner,terminal,identity,hbios
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building DWG.LIB...
echo.
set TGT=dwg.lib
if exist %TGT% del %TGT%
zx as bioscall
zx as bdoscall
zx as diagnose
zx cz --o cmemory.a80 --DTINY cmemory
zx as cmemory.a80
zx cz --o cbanner.a80 --DTINY cbanner
zx as cbanner.a80
zx cz --o ctermcap.a80 --DTINY ctermcap
zx as ctermcap.a80
zx cz --o clogical.a80 --DTINY clogical
zx as clogical.a80
zx as asmiface
zx cz --o sectorio.a80 --DTINY sectorio
zx as sectorio.a80
zx libutil --o dwg.lib cbanner.o clogical.o ctermcap.o sectorio.o asmiface.o 
zx libutil --o dwg.lib dwg.lib bioscall.o bdoscall.o diagnose.o cmemory.o clogical.o
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building ACCESS.COM...
echo.
set TGT=access.com
if exist %TGT% del %TGT%
zx rmac access
zx link access,dwg
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building CPMNAME.COM...
echo.
set TGT=cpmname.com
if exist %TGT% del %TGT%
zx cz --o cpmname.a80 --DTINY cpmname
zx as cpmname.a80
zx ln cpmname.o --ldwg --lt --lc
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building FINDFILE.COM...
echo.
set TGT=findfile.com
if exist %TGT% del %TGT%
zx rmac findfile 
zx link findfile,dwg
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building MAP.COM...
echo.
set TGT=map.com
if exist %TGT% del %TGT%
zx cz --o map.a80 --DTINY map
zx as map.a80
zx ln map.o --ldwg --lt --lc
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building META.COM...
echo.
set TGT=meta.com
if exist %TGT% del %TGT%
zx cz --o meta.a80 --DTINY meta
zx as meta.a80
zx ln meta.o --ldwg --lt --lc
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building MULTIFMT.COM...
echo.
set TGT=multifmt.com
if exist %TGT% del %TGT%
zx cz --o multifmt.a80 --DTINY multifmt
zx as multifmt.a80
zx ln multifmt.o --ldwg --lt --lc
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building REM.COM...
echo.
set TGT=rem.com
if exist %TGT% del %TGT%
zx rmac rem
zx link rem
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building SETLABEL.COM...
echo.
set TGT=setlabel.com
if exist %TGT% del %TGT%
zx rmac setlabel
zx link setlabel,dwg
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building SYSGEN.COM...
echo.
set TGT=sysgen.com
if exist %TGT% del %TGT%
zx cz --o sysgen.a80 --DTINY sysgen
zx as sysgen.a80
zx ln sysgen.o --ldwg --lt --lc
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building TERMTYPE.COM...
echo.
set TGT=termtype.com
if exist %TGT% del %TGT%
zx cz --o termtype.a80 --DTINY termtype
zx as termtype.a80
zx ln termtype.o --ldwg --lt --lc
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building VIEW.COM...
echo.
set TGT=view.com
if exist %TGT% del %TGT%
zx cz --o view.a80 --DTINY view
zx as view.a80
zx ln view.o --ldwg --lt --lc
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Building N8VIDTST.COM / TMSSTAT.COM...
echo.
zx cz --o n8chars.a80 --DTINY n8chars
zx as n8chars.a80
zx cz --o tms9918.a80 --DTINY tms9918
zx as tms9918.a80

set TGT=n8vidtst.com
if exist %TGT% del %TGT%
zx cz --o n8vidtst.a80 --DTINY n8vidtst
zx as n8vidtst.a80
zx ln n8vidtst.o n8chars.o tms9918.o --ldwg --lt --lc
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

set TGT=tmsstat.com
if exist %TGT% del %TGT%
zx cz --o tmsstat.a80 --DTINY tmsstat
zx as tmsstat.a80
zx ln tmsstat.o n8chars.o tms9918.o --ldwg --lt --lc
if not exist %TGT% echo *** Failed to build %TGT% ***  && pause

echo.
echo Generating Output...
echo.
if exist %OUTDIR%\*.* del /f /q %OUTDIR%\*.*
for %%f in (%COREAPPS%) do echo %%f... && copy %%f.COM %OUTDIR%
echo DWG-APPS.MAN... && copy DWG-APPS.MAN %OUTDIR%
