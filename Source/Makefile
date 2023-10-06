#
# order is actually important, because of build dependencies
#
BUILDPROP := 1
UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
# Inhibit building Propeller on unsupported
# Linux host architectures such as ARM eg. Raspberry Pi
	BUILDPROP := 0
	ARCH := $(shell uname -m)
	ifeq ($(ARCH), x86_64)
		BUILDPROP := 1
	endif
	ifeq ($(ARCH), i686)
		BUILDPROP := 1
	endif
	ifeq ($(ARCH), i386)
		BUILDPROP := 1
	endif
	ifeq ($(ARCH), x86)
		BUILDPROP := 1
	endif
# Add here any more supported x86 based
# uname machine strings for building Propeller
endif

.PHONY: doc prop shared bp images rom zrc zzrc

all: prop shared images rom zrc zzrc

doc:
	$(MAKE) --directory Doc $(ACTION)

prop:
ifeq ($(BUILDPROP), 1)
	$(MAKE) --directory Prop $(ACTION)
else
	$(info Builing Propeller is not supported on this $(ARCH) host Linux OS)
endif

shared:
	$(MAKE) --directory HDIAG $(ACTION)
	$(MAKE) --directory CBIOS $(ACTION)
	$(MAKE) --directory CPM22 $(ACTION)
	$(MAKE) --directory QPM $(ACTION)
	$(MAKE) --directory ZCPR $(ACTION)
	$(MAKE) --directory ZCPR-DJ $(ACTION)
	$(MAKE) --directory ZSDOS $(ACTION)
	$(MAKE) --directory CPM3 $(ACTION)
	$(MAKE) --directory ZPM3 $(ACTION)
	$(MAKE) --directory pSys $(ACTION)
	$(MAKE) --directory Apps $(ACTION)
	$(MAKE) --directory Forth $(ACTION)
	$(MAKE) --directory TastyBasic $(ACTION)
	$(MAKE) --directory Fonts $(ACTION)
	$(MAKE) --directory RomDsk $(ACTION)

bp:
	$(MAKE) --directory BPBIOS $(ACTION)

images:
	$(MAKE) --directory Images $(ACTION)

rom:
	$(MAKE) --directory HBIOS $(ACTION)

zrc:
	$(MAKE) --directory ZRC $(ACTION)

zzrc:
	$(MAKE) --directory ZZRC $(ACTION)


clean: ACTION=clean

clean: all

diff: ACTION=diff

diff: all
