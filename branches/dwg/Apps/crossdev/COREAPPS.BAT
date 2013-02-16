rem coreapps.bat 2/15/2013 dwg - build all core apps using batch files

if not exist access.cpm call access.bat
if not exist access.cpm pause

if not exist cpmname.cpm call cpmname.bat
if not exist cpmname.cpm pause

if not exist findfile.cpm call findfile.bat
if not exist findfile.cpm pause

if not exist map.cpm call map.bat
if not exist map.cpm pause

if not exist meta.cpm call meta.bat
if not exist meta.cpm pause

if not exist multifmt.cpm call multifmt.bat
if not exist multifmt.cpm pause

if not exist rem.cpm call makerem.bat
if not exist rem.cpm pause

if not exist setlabel.cpm call setlabel.bat
if not exist setlabel.cpm pause

if not exist sysgen.cpm call sysgen.bat
if not exist sysgen.cpm pause

if not exist termtype.cpm call termtype.bat
if not exist termtype.cpm pause

if not exist view.cpm call view.bat
if not exist view.cpm pause

rem All Core Apps Built
dir *.cpm /w

