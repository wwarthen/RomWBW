#
# build the tools for linux and Darwin
#

.ONESHELL:
.SHELLFLAGS = -cex

UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
	SUFFIX=linux
endif
ifeq ($(UNAME), Darwin)
	SUFFIX=osx
endif

SUBDIRS = OpenSpin uz80as zxcc cpmtools bin2asm lzsa

all:
	@chmod +x casefn.sh
	@$(foreach subdir,$(SUBDIRS),$(MAKE) --directory $(subdir) all;)

clean:
	@$(foreach subdir,$(SUBDIRS),$(MAKE) --directory $(subdir) clean;)