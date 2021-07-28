all:
	$(MAKE) --directory Tools/unix
	$(MAKE) --directory Source

clean:
	$(MAKE) --directory Tools/unix clean
	$(MAKE) --directory Source clean
	$(MAKE) --directory Binary clean

clobber:
	$(MAKE) --directory Tools/unix clobber
	$(MAKE) --directory Source  clobber
	$(MAKE) --directory Binary clobber
	rm -f typescript

diff:
	$(MAKE) --directory Source diff

dist:
	$(MAKE) ROM_PLATFORM=dist
