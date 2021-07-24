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

SUBDIRS = bst uz80as zx cpmtools bin2asm lzsa

all:
	@chmod +x casefn.sh
	@$(foreach subdir,$(SUBDIRS),$(MAKE) --directory $(subdir) all || exit 1;)

clobber:
	@$(foreach subdir,$(SUBDIRS),$(MAKE) --directory $(subdir) clobber || exit 1;)

clean:
	@$(foreach subdir,$(SUBDIRS),$(MAKE) --directory $(subdir) clean || exit 1;)
