OBJECTS = xm.com xmold.com
#OBJECTS += xmuf.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.hex

include $(TOOLS)/Makefile.inc

xm.com: xmdm125.hex xmhb.hex
	$(ZXCC) MLOAD25 XM=xmdm125,xmhb

xmuf.com: xmdm125.hex xmuf.hex
	$(ZXCC) MLOAD25 XMUF=xmdm125,xmuf

xmold.com: xmdm125.hex xmhb_old.hex
	$(ZXCC) MLOAD25 XMOLD=xmdm125,xmhb_old
