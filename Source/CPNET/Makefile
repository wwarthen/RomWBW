OBJECTS = cpn12mt.lbr cpn3mt.lbr cpn12duo.lbr cpn3duo.lbr
DEST = ../../Binary/CPNET/
TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

ZXCC=../../$(TOOLS)/$(UNAME)/zxcc
export CPMDIR80=../../$(TOOLS)/cpm/

cpn12%.lbr: CPNETVER=cpnet12
cpn3%.lbr: CPNETVER=cpnet3
%mt.lbr: HWVER=mt011
%duo.lbr: HWVER=duo

%.lbr:
	cd $(HWVER)/$(CPNETVER) ; \
	$(ZXCC) NULU --O -$(*F) -\<30 --A -*.* --L --X ; \
	mv $@ ../..
