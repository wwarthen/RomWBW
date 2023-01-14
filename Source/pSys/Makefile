OBJECTS = psys.img
TOOLS = ../../Tools
DEST = ../../Binary
OTHERS = *.bin *.lst *.img
include $(TOOLS)/Makefile.inc

trk0.bin: loader.bin bios.bin boot.dat fill.dat
	cat loader.bin bios.bin boot.dat fill.dat > trk0.bin

psys.img: trk0.bin psys.vol blank.vol
	cat trk0.bin psys.vol trk0.bin blank.vol > psys.img
