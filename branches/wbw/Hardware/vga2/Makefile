SPINC=		bstc.linux
SPINC_FLAGS=	-Ox -ls -e -p0 -d/dev/ttyS0
INCLUDES=	-L../lib

VERSION=	0.0.4

all:	vgademo

vgademo:	vgademo.spin vga8x8d.spin vt100.spin
	$(SPINC) $(SPINC_FLAGS) $(INCLUDES) -o $@ $<

clean:
	rm -f *.eeprom *.lst *.list *.bck *.o

dist:	clean
	cd .. && rm -f vgademo-$(VERSION).zip && \
	zip -r vgademo-$(VERSION).zip vga2
