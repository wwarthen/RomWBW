OBJECTS = xm.com xmuf.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.hex

include $(TOOLS)/Makefile.inc

xm.com: xmdm125.HEX xmhb.HEX
	$(ZXCC) $(CPM)/MLOAD25 XM=xmdm125,xmhb

xmuf.com: xmdm125.HEX xmuf.HEX
	$(ZXCC) $(CPM)/MLOAD25 XMUF=xmdm125,xmuf
