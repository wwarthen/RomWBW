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

SUBDIRS= bst uz80as zx cpmtools bin2asm lzsa

all:
	@for i in $(SUBDIRS) ; do \
		(cd $$i ; make all ) \
	done

clobber:
	@for i in $(SUBDIRS) ; do \
		(cd $$i ; make clobber ) \
	done

clean:
	@for i in $(SUBDIRS) ; do \
		(cd $$i ; make clean ) \
	done
