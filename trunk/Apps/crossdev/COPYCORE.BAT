@echo off

echo.
echo Regenerate Core directory...
echo.

if exist ..\core\*.* del /q ..\core\*.*

copy ACCESS.CPM ..\core\*.COM
copy CPMNAME.CPM ..\core\*.COM
copy FINDFILE.CPM ..\core\*.COM
copy MAP.CPM ..\core\*.COM
copy META.CPM ..\core\*.COM
copy MULTIFMT.CPM ..\core\*.COM
copy REM.CPM ..\core\*.COM
copy SETLABEL.CPM ..\core\*.COM
copy SYSGEN.CPM ..\core\*.COM
copy TERMTYPE.CPM ..\core\*.COM
copy VIEW.CPM ..\core\*.COM
copy ..\doc\DWG-APPS.MAN ..\core\DWG-APPS.MAN