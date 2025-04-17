OBJECTS = zmp.com *.ovr zmp.cfg zmp.fon *.hlp zmp.doc
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.hex
NODELETE = *.ovr zmp.doc zmp.cfg zmp.fon *.hlp

include $(TOOLS)/Makefile.inc

zmp.com: zmo-wbw.hex
	$(ZXCC) MLOAD25 -ZMP.COM=ZMPX.COM,ZMO-WBW
