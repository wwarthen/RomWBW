OBJECTS = cpn12mt.lbr cpn3mt.lbr cpn12duo.lbr cpn3duo.lbr cpn12ser.lbr cpn3ser.lbr
DEST = ../../Binary/CPNET/
TOOLS = ../../Tools

include $(TOOLS)/Makefile.inc

cpn12%.lbr: CPNETVER=cpnet12
cpn3%.lbr: CPNETVER=cpnet3
%mt.lbr: HWVER=mt011
%duo.lbr: HWVER=duo
%ser.lbr: HWVER=serial

%.lbr:
	rm -f $@
	$(ZXCC) NULU --O -$(*F) -\<30 --X
	for f in `ls $(HWVER)/$(CPNETVER) | sort` ; \
	do \
	  $(ZXCC) NULU --O -$(*F) --A $(HWVER)/$(CPNETVER)/$$f --X ; \
	done