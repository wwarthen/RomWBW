@rem coreapps.bat 2/15/2013 dwg - build all core apps using batch files

@@if not exist access.cpm call access.bat
@@if not exist access.cpm echo WARNING ACCESS DIDN'T BUILD
@@if not exist access.cpm pause

@@if not exist cpmname.cpm call cpmname.bat
@@if not exist cpmname.cpm echo WARNING CPMNAME DIDN'T BUILD
@@if not exist cpmname.cpm pause

@if not exist findfile.cpm call findfile.bat
@if not exist findfile.cpm echo WARNING FINDFILE DIDN'T BUILD
@if not exist findfile.cpm pause

@if not exist map.cpm call map.bat
@if not exist map.cpm echo WARNING MAP DIDN'T BUILD
@if not exist map.cpm pause

@if not exist meta.cpm call meta.bat
@if not exist meta.cpm echo WARNING META DIDN'T BUILD
@if not exist meta.cpm pause

@if not exist multifmt.cpm call multifmt.bat
@if not exist multifmt.cpm echo WARNING MULTIFMT DIDN'T BUILD
@if not exist multifmt.cpm pause

@if not exist rem.cpm call makerem.bat
@if not exist rem.cpm echo WARNING REM DIDN'T BUILD
@if not exist rem.cpm pause

@if not exist setlabel.cpm call setlabel.bat
@if not exist setlabel.cpm echo WARNING SETLABEL DIDN'T BUILD
@if not exist setlabel.cpm pause

@if not exist sysgen.cpm call sysgen.bat
@if not exist sysgen.cpm echo WARNING SYSGEN DIDN'T BUILD
@if not exist sysgen.cpm pause

@if not exist termtype.cpm call termtype.bat
@if not exist termtype.cpm echo WARNING TERMTYPE DIDN'T BUILD
@if not exist termtype.cpm pause

@if not exist view.cpm call view.bat
@if not exist view.cpm echo WARNING VIEW DIDN'T BUILD
@if not exist view.cpm pause

@echo All Core Apps Built
@dir *.cpm

