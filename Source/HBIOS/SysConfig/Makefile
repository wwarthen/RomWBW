OBJECTS = sysconfig.com sysconfig.bin
DEST = ../../../Binary/Apps
NOCOPY = sysconfig.bin
TOOLS = ../../../Tools

include $(TOOLS)/Makefile.inc

USETASM=1

sysconfig.bin: TASMFLAGS=-dROMWBW

sysconfig.com: TASMFLAGS=-dCPM
