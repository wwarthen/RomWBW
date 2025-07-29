#
# order is actually important, because of build dependencies
#

.PHONY: doc prop shared bp images rom zrc z1rcc zzrcc zrc512 fz80 ez512

.ONESHELL:
.SHELLFLAGS = -ce

all: prop shared bp images rom zrc z1rcc zzrcc zrc512 fz80 ez512

doc:
	$(MAKE) --directory Doc $(ACTION)

prop:
	$(MAKE) --directory Prop $(ACTION)

shared:
	$(MAKE) --directory HDIAG $(ACTION)
	$(MAKE) --directory CBIOS $(ACTION)
	$(MAKE) --directory CPM22 $(ACTION)
	$(MAKE) --directory QPM $(ACTION)
	$(MAKE) --directory ZCPR $(ACTION)
	$(MAKE) --directory ZCPR-DJ $(ACTION)
	$(MAKE) --directory ZSDOS $(ACTION)
	$(MAKE) --directory ZSDOS2 $(ACTION)
	$(MAKE) --directory CPM3 $(ACTION)
	$(MAKE) --directory ZPM3 $(ACTION)
	$(MAKE) --directory BPBIOS $(ACTION)
	$(MAKE) --directory CPNET $(ACTION)
	$(MAKE) --directory pSys $(ACTION)
	$(MAKE) --directory Apps $(ACTION)
	$(MAKE) --directory Forth $(ACTION)
	$(MAKE) --directory TastyBasic $(ACTION)
	$(MAKE) --directory Fonts $(ACTION)
	$(MAKE) --directory RomDsk $(ACTION)

images:
	$(MAKE) --directory Images $(ACTION)

rom:
	@$(MAKE) --directory HBIOS $(ACTION)

zrc:
	$(MAKE) --directory ZRC $(ACTION)

z1rcc:
	$(MAKE) --directory Z1RCC $(ACTION)

zzrcc:
	$(MAKE) --directory ZZRCC $(ACTION)

zrc512:
	$(MAKE) --directory ZRC512 $(ACTION)

fz80:
	$(MAKE) --directory FZ80 $(ACTION)

ez512:
	$(MAKE) --directory EZ512 $(ACTION)

clean: ACTION=clean
clean: all

diff: ACTION=diff
diff: all
