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

SUBDIRS = HDIAG

ifeq ($(BUILDPROP), 1)
SUBDIRS += Prop
else
$(info "Builing Propeller is not supported on this $(ARCH) host Linux OS")
endif

SUBDIRS += Apps
SUBDIRS += CBIOS
SUBDIRS += Forth
SUBDIRS += TastyBasic
SUBDIRS += Fonts
SUBDIRS += CPM22 ZCPR ZCPR-DJ ZSDOS CPM3 ZPM3 QPM
#SUBDIRS += BPBIOS
SUBDIRS += pSys
SUBDIRS += RomDsk
SUBDIRS += HBIOS
SUBDIRS += Images
SUBDIRS += ZRC
SUBDIRS += ZZRC
#SUBDIRS += Doc
TOOLS = ../Tools
include $(TOOLS)/Makefile.inc
