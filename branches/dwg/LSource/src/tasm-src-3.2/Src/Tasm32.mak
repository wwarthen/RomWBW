# Microsoft Developer Studio Generated NMAKE File, Based on Tasm32.dsp
!IF "$(CFG)" == ""
CFG=Tasm32 - Win32 Debug
!MESSAGE No configuration specified. Defaulting to Tasm32 - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "Tasm32 - Win32 Release" && "$(CFG)" != "Tasm32 - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "Tasm32.mak" CFG="Tasm32 - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "Tasm32 - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "Tasm32 - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 

!IF  "$(CFG)" == "Tasm32 - Win32 Release"

OUTDIR=.\Release
INTDIR=.\Release
# Begin Custom Macros
OutDir=.\Release
# End Custom Macros

ALL : "$(OUTDIR)\Tasm32.exe"


CLEAN :
	-@erase "$(INTDIR)\Errlog.obj"
	-@erase "$(INTDIR)\Fname.obj"
	-@erase "$(INTDIR)\Lookup.obj"
	-@erase "$(INTDIR)\Macro.obj"
	-@erase "$(INTDIR)\Parse.obj"
	-@erase "$(INTDIR)\Rules.obj"
	-@erase "$(INTDIR)\Str.obj"
	-@erase "$(INTDIR)\Tasm.obj"
	-@erase "$(INTDIR)\Tasmmain.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\Wrtobj.obj"
	-@erase "$(OUTDIR)\Tasm32.exe"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP=cl.exe
CPP_PROJ=/nologo /ML /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /Fp"$(INTDIR)\Tasm32.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /c 

.c{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

RSC=rc.exe
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\Tasm32.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /incremental:no /pdb:"$(OUTDIR)\Tasm32.pdb" /machine:I386 /out:"$(OUTDIR)\Tasm32.exe" 
LINK32_OBJS= \
	"$(INTDIR)\Errlog.obj" \
	"$(INTDIR)\Fname.obj" \
	"$(INTDIR)\Lookup.obj" \
	"$(INTDIR)\Macro.obj" \
	"$(INTDIR)\Parse.obj" \
	"$(INTDIR)\Rules.obj" \
	"$(INTDIR)\Str.obj" \
	"$(INTDIR)\Tasm.obj" \
	"$(INTDIR)\Tasmmain.obj" \
	"$(INTDIR)\Wrtobj.obj"

"$(OUTDIR)\Tasm32.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "Tasm32 - Win32 Debug"

OUTDIR=.\Debug
INTDIR=.\Debug
# Begin Custom Macros
OutDir=.\Debug
# End Custom Macros

ALL : "$(OUTDIR)\Tasm32.exe"


CLEAN :
	-@erase "$(INTDIR)\Errlog.obj"
	-@erase "$(INTDIR)\Fname.obj"
	-@erase "$(INTDIR)\Lookup.obj"
	-@erase "$(INTDIR)\Macro.obj"
	-@erase "$(INTDIR)\Parse.obj"
	-@erase "$(INTDIR)\Rules.obj"
	-@erase "$(INTDIR)\Str.obj"
	-@erase "$(INTDIR)\Tasm.obj"
	-@erase "$(INTDIR)\Tasmmain.obj"
	-@erase "$(INTDIR)\vc60.idb"
	-@erase "$(INTDIR)\vc60.pdb"
	-@erase "$(INTDIR)\Wrtobj.obj"
	-@erase "$(OUTDIR)\Tasm32.exe"
	-@erase "$(OUTDIR)\Tasm32.ilk"
	-@erase "$(OUTDIR)\Tasm32.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

CPP=cl.exe
CPP_PROJ=/nologo /MLd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /Fp"$(INTDIR)\Tasm32.pch" /YX /Fo"$(INTDIR)\\" /Fd"$(INTDIR)\\" /FD /GZ /c 

.c{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.obj::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.c{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cpp{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

.cxx{$(INTDIR)}.sbr::
   $(CPP) @<<
   $(CPP_PROJ) $< 
<<

RSC=rc.exe
BSC32=bscmake.exe
BSC32_FLAGS=/nologo /o"$(OUTDIR)\Tasm32.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /incremental:yes /pdb:"$(OUTDIR)\Tasm32.pdb" /debug /machine:I386 /out:"$(OUTDIR)\Tasm32.exe" /pdbtype:sept 
LINK32_OBJS= \
	"$(INTDIR)\Errlog.obj" \
	"$(INTDIR)\Fname.obj" \
	"$(INTDIR)\Lookup.obj" \
	"$(INTDIR)\Macro.obj" \
	"$(INTDIR)\Parse.obj" \
	"$(INTDIR)\Rules.obj" \
	"$(INTDIR)\Str.obj" \
	"$(INTDIR)\Tasm.obj" \
	"$(INTDIR)\Tasmmain.obj" \
	"$(INTDIR)\Wrtobj.obj"

"$(OUTDIR)\Tasm32.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 


!IF "$(NO_EXTERNAL_DEPS)" != "1"
!IF EXISTS("Tasm32.dep")
!INCLUDE "Tasm32.dep"
!ELSE 
!MESSAGE Warning: cannot find "Tasm32.dep"
!ENDIF 
!ENDIF 


!IF "$(CFG)" == "Tasm32 - Win32 Release" || "$(CFG)" == "Tasm32 - Win32 Debug"
SOURCE=.\Errlog.c

"$(INTDIR)\Errlog.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\Fname.c

"$(INTDIR)\Fname.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\Lookup.c

"$(INTDIR)\Lookup.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\Macro.c

"$(INTDIR)\Macro.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\Parse.c

"$(INTDIR)\Parse.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\Rules.c

"$(INTDIR)\Rules.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\Str.c

"$(INTDIR)\Str.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\Tasm.c

"$(INTDIR)\Tasm.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\Tasmmain.c

"$(INTDIR)\Tasmmain.obj" : $(SOURCE) "$(INTDIR)"


SOURCE=.\Wrtobj.c

"$(INTDIR)\Wrtobj.obj" : $(SOURCE) "$(INTDIR)"



!ENDIF 

