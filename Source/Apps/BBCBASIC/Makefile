OBJECTS = bbcbasic.com
DOCS = bbcbasic.txt
DEST = ../../../Binary/Apps
DOCDEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.rel

include $(TOOLS)/Makefile.inc

bbcbasic.com: dist.rel main.rel exec.rel eval.rel asmb.rel cmos.rel math.rel hook.rel data.rel
	$(ZXCC) SLRNK -/V,/A:0100,DIST,MAIN,EXEC,EVAL,ASMB,MATH,HOOK,CMOS,/P:4B00,DATA,BBCBASIC/N,/E
