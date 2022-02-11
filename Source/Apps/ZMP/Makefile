OBJECTS = zmp.com *.ovr *.hlp zmp.doc
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.hex
NODELETE = *.ovr zmp.doc *.hlp

include $(TOOLS)/Makefile.inc

zmp.com: zmo-rw01.hex
	$(ZXCC) MLOAD25 -ZMP.COM=ZMPX.COM,ZMO-RW01
