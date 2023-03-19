OBJECTS = psys.img psystest.img
TOOLS = ../../Tools
DEST = ../../Binary
OTHERS = *.bin *.lst *.img
NOCOPY = psystest.img
include $(TOOLS)/Makefile.inc

trk0.bin: loader.bin bios.bin boot.dat fill.bin
	cat $+ >$@

psys.img: ../Images/hd1k_prefix.dat trk0.bin psys.vol trk0.bin blank.vol
	cat $+  >$@

testldr.bin: loader.asm
	$(TASM) -dTESTBIOS $< $@ testldr.lst

testfill.bin: fill.asm
	$(TASM) -dTESTBIOS $< $@ testfill.lst


psystest.img: ../Images/hd1k_prefix.dat testldr.bin bios.bin biostest.dat testfill.bin
	cat $+ >$@
