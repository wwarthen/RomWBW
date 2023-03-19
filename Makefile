all:
	$(MAKE) --directory Tools
	$(MAKE) --directory Source

clean:
	$(MAKE) --directory Tools clean
	$(MAKE) --directory Source clean
	$(MAKE) --directory Binary clean
	rm -f make.log

clobber: clean

diff:
	$(MAKE) --directory Source diff

dist:
	$(MAKE) ROM_PLATFORM=dist 2>&1 | tee make.log
	$(MAKE) --directory Source clean
	$(MAKE) --directory Tools clean
