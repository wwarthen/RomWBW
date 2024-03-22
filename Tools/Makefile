#
# build the tools for linux and Darwin
#

.ONESHELL:
.SHELLFLAGS = -cex

UNAME := $(shell uname)

all:
	$(MAKE) --directory unix

clean:
	$(MAKE) --directory unix clean
	@rm -rf $(UNAME)
