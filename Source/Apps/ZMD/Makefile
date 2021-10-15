OBJECTS = zmd.com
DEST = ../../../Binary/Apps
TOOLS = ../../../Tools
OTHERS = *.hex zmd.rel

include $(TOOLS)/Makefile.inc

zmd.com: zmd.rel zmdhb.hex
	$(ZXCC) $(CPM)/L80 -zmd,zmd/n/e
	$(ZXCC) $(CPM)/MLOAD25 -zmd=zmd.com,zmdhb
