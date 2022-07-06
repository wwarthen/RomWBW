all:
	$(MAKE) --directory Tools
	$(MAKE) --directory Source

clean:
	$(MAKE) --directory Tools clean
	$(MAKE) --directory Source clean
	$(MAKE) --directory Binary clean

clobber: clean

diff:
	$(MAKE) --directory Source diff

dist:
	$(MAKE) ROM_PLATFORM=dist
	$(MAKE) --directory Source clean
	$(MAKE) --directory Tools clean
