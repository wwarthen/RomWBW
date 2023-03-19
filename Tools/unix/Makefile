#
# build the tools for linux and Darwin
#
UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
	SUFFIX=linux
endif
ifeq ($(UNAME), Darwin)
	SUFFIX=osx
endif

SUBDIRS = bst uz80as zxcc cpmtools bin2asm lzsa

all:
	@chmod +x casefn.sh
	@$(foreach subdir,$(SUBDIRS),$(MAKE) --directory $(subdir) all;)

clean:
	@$(foreach subdir,$(SUBDIRS),$(MAKE) --directory $(subdir) clean;)