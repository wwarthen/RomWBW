UNAME := $(shell uname)
VER := $(shell git describe --tags --abbrev=0)
APPDIR := $(wildcard ../../../Binary/Apps)
BINDIR := ../../../Tools/$(UNAME)

ROMIMAGE := tastybasic.bin
ROMDEPS := tastybasic.asm romwbwio.asm
CPMCMD := tastybasic.com
CPMDEPS := tastybasic.asm cpmio.asm
CPMAPP := $(APPDIR)/tbasic.com
CPMIMAGE := tastybasic.img

export PATH := $(BINDIR):${PATH}

all: $(ROMIMAGE) $(CPMCMD) | $(APPDIR)

clean clobber:
	@rm -f *.lst *.img *.com *.bin $(CPMAPP)
$(ROMIMAGE): $(ROMDEPS)
	@uz80as -dROMWBW -d"VERSION \"$(VER)\"" tastybasic.asm tastybasic.bin tastybasic.bin.lst

$(CPMIMAGE): $(CPMCMD)
	@mkfs.cpm -f wbw_fd144 tastybasic.img
	@cpmcp -f wbw_fd144 tastybasic.img tastybasic.com 0:tbasic.com

$(CPMCMD): $(CPMDEPS)
	@uz80as -dCPM -d"VERSION \"$(VER)\"" tastybasic.asm tastybasic.com tastybasic.com.lst

$(APPDIR): $(CPMCMD)
	@cat $(CPMCMD) > $(CPMAPP)

.PHONY: clean clobber $(APPDIR)
