# Makefile 1/31/2013 dwg - 

TASM := ../XSource/bin/TASM 
TASMTABS := .
export TASMTABS

ASMOPT80 := -t$(CPU) -g3
ASMOPT85 := -t85 -g3 

ASM80 := $(TASM) $(ASMOPT80)
ASM85 := $(TASM) $(ASMOPT85)
ASMIMG := $(TASM) $(ASMOPT80) -b -fE5

all:	zapple.bin cpm.bin bios.bin

tasm80.tab:	bin/TASM80.TAB
	cp bin/TASM80.TAB tasm80.tab

tasm85.tab:	bin/TASM85.TAB
	cp bin/TASM85.TAB tasm85.tab

cpm.bin:	cpm22.asm 
	$(ASMIMG) $< $@

bios.bin:	bios.asm s100iobd.inc
	$(ASMIMG) bios.asm $@

zapple.bin:	zapple.asm zapple.z80
	$(ASMIMG) zapple.asm $@

clean:
	rm -f *.lst *.bin
