#OBJECTS = xm.com xmuf.com
OBJECTS = xm.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.hex

include $(TOOLS)/Makefile.inc

xm.com: xmdm125.hex xmhb.hex
	$(ZXCC) $(CPM)/MLOAD25 XM=xmdm125,xmhb

#xmuf.com: xmdm125.hex xmuf.hex
#	$(ZXCC) $(CPM)/MLOAD25 XMUF=xmdm125,xmuf
