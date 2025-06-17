@echo off
setlocal

set TOOLS=..\..\..\Tools
set PATH=%PATH%;%TOOLS%\zxcc;%TOOLS%\cpmtools;
set CPMDIR80=%TOOLS%/cpm/

zxcc Z80ASM -BPBUILD/RFS || exit /b
zxcc SLRNK -BPBUILD/N,/A:100,/D:23E0,BPBUILD,B:SLINK0,B:VLIBS/S,B:Z3LIBS/S,B:SYSLIBS/S,/E || exit /b

zxcc Z80ASM -BPCNFG/RFS || exit /b
zxcc SLRNK -BPCNFG/N,/A:100,/D:3A55,BPCNFG,B:VLIBS/S,B:Z3LIBS/S,B:SYSLIBS/S,/E || exit /b

zxcc Z80ASM -BPSWAP/RFS || exit /b
zxcc SLRNK -BPSWAP/N,/A:100,/D:0854,BPSWAP,B:VLIBS/S,B:Z3LIBS/S,B:SYSLIBS/S,/E || exit /b

zxcc Z80ASM -BPSYSGEN/RFS || exit /b
zxcc SLRNK -BPSYSGEN/N,/A:100,/D:08CD,BPSYSGEN,B:Z3LIBS/S,B:SYSLIBS/S,/E || exit /b

zxcc Z80ASM -CONFZ4/RFS || exit /b
zxcc SLRNK -CONFZ4/N,/A:100,/D:080A,CONFZ4,B:Z3LIBS/S,B:SYSLIBS/S,/E || exit /b

zxcc Z80ASM -HASHINI/RFS || exit /b
zxcc SLRNK -HASHINI/N,/A:100,/D:09E5,HASHINI,B:Z3LIBS/S,B:SYSLIBS/S,/E || exit /b

zxcc Z80ASM -LDSYS/RFS || exit /b
zxcc SLRNK -LDSYS/N,/A:100,/D:0CF8,LDSYS,B:VLIBS/S,B:Z3LIBS/S,B:SYSLIBS/S,/E || exit /b

zxcc Z80ASM -SHOWHD/RFS || exit /b
zxcc SLRNK -SHOWHD/N,/A:100,/D:064D,SHOWHD,B:SYSLIBS/S,/E || exit /b

zxcc Z80ASM -SIZERAM/RFS || exit /b
zxcc SLRNK -SIZERAM/N,/A:100,/D:0750,SIZERAM,B:VLIBS/S,B:Z3LIBS/S,B:SYSLIBS/S,/E || exit /b

zxcc Z80ASM -ZSCFG2/RFS || exit /b
zxcc SLRNK -ZSCFG2/N,/A:100,/D:145E,ZSCFG2,B:VLIBS/S,B:Z3LIBS/S,B:SYSLIBS/S,/E || exit /b

















:: zxcc Z80ASM 
:: zxcc ZMAC -zcpr33.z80 -/P || exit /b
