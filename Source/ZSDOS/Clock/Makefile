
TOOLS = ../../../Tools
PATH = %TOOLS%/tasm32;%TOOLS%/zxcc;%PATH%
TASMTABS = %TOOLS%/tasm32
CPMDIR80 = %TOOLS%/cpm/

# OBJECTS = bbcbasic.com
# DOCS = bbcbasic.txt
# DEST = ../../../Binary/Apps
# DOCDEST = ../../../Binary/Apps
# OTHERS = *.rel

include $(TOOLS)/Makefile.inc

WBWCLK:
	$(ZXCC) ZMAC -WBWCLK -/P


#set TOOLS=../../../Tools
#set PATH=%TOOLS%\tasm32;%TOOLS%\zxcc;%PATH%
#set TASMTABS=%TOOLS%\tasm32
#set CPMDIR80=%TOOLS%/cpm/
#zxcc ZMAC -WBWCLK -/P || exit /b

#OBJECTS = zmd.com
#DEST = ../../../Binary/Apps
#TOOLS = ../../../Tools
#OTHERS = *.hex zmd.rel
#include $(TOOLS)/Makefile.inc
#zmd.com: zmd.rel zmdhb.hex
#	$(ZXCC) L80 -zmd,zmd/n/e
#	$(ZXCC) MLOAD25 -zmd=zmd.com,zmdhb
