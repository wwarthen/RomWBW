SHELL := /bin/sh
SHELLFLAGS := -c -e -x
.ONESHELL:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --always-make
ZCCRELFLAGS := -SO3 --max-allocs-per-node600000 --allow-unsafe-read --opt-code-speed

SRC := ./source-doc/
LIBS := -I./$(SRC)base-drv/
ZCCFLAGS := +z80 -vn -startup=0 -clib=sdcc_iy  -compiler=sdcc -Cs--std=c23 -Cs--Werror  $(ZCCRELFLAGS) $(LIBS)

ZCC_PATH := $(shell command -v zcc)
DOCKER_PATH := $(shell command -v docker)
ZCC := $(shell command -v zcc >/dev/null 2>&1 && echo zcc || echo 'docker run -w /host/${PWD} -v /:/host/ -u $(shell id -u ${USER}):$(shell id -g ${USER}) -t z88dk/z88dk:20250224 zcc')

ifeq ($(ZCC_PATH),)
    ifeq ($(DOCKER_PATH),)
			.DEFAULT_GOAL := skip
    else
        $(info ZCC is set to use Docker to run zcc)
    endif
else
    $(info ZCC is set to $(ZCC_PATH))
endif

ASSDIR := ./

all: $(ASSDIR)base-drv.s $(ASSDIR)scsi-drv.s $(ASSDIR)ufi-drv.s $(ASSDIR)keyboard.s

skip:
	@echo "Unable to compile ch376 native to assembly.  Install docker or z88dk."
	exit 0

clean:
	@rm -rf base-drv/*.s
	rm -rf base-drv/*.asm
	rm -rf scsi-drv/*.s
	rm -rf scsi-drv/*.asm
	rm -rf ufi-drv/*.s
	rm -rf ufi-drv/*.asm
	rm -rf keyboard/*.s
	rm -rf keyboard/*.asm
	rm ufi-drv.s
	rm scsi-drv.s
	rm base-drv.s
	rm keyboard.s

.PRECIOUS: $(ASSDIR)%.c.asm
$(ASSDIR)%.c.s: $(ASSDIR)%.c.asm
	@mkdir -p $(dir $@)
	echo "Converting $< to $@"
	${SRC}convert-for-uz80as.sh $< $@

define compile
	@set -e
	mkdir -p $(dir $@)
	$(ZCC) $(ZCCFLAGS) --c-code-in-asm --assemble-only $< -o $@
	echo "Compiled $(notdir $@) from $(notdir $<)"
endef

FIRMWARE_ALT = kyb-init ch376_init scsi-init ufi-init hbios-driver-storage

define build_subsystem =
$$(ASSDIR)$(1).s:
	@echo "Creating $(1).s"
	echo "; Generated File -- not to be modify directly" > $$(ASSDIR)$(1).s
	for dep in $$^; do
		dep=$$$${dep#*/}
		dep=$$$${dep#*/}
		filename=$$$${dep##*/}
		basename=$$$${filename%.*.*}
		if echo "$(FIRMWARE_ALT)" | grep -w -q "$$$${basename}"; then
			if [ -n "$$$${dep%%*.asm}" ]; then
				echo '#include "'ch376-native/$(1)/$$$${dep}'"' >> $$(ASSDIR)$(1).s
			else
				echo '#include "'ch376-native/source-doc/$(1)/$$$${dep}'"' >> $$(ASSDIR)$(1).s
			fi
		else
			echo '#IF (!CHNATIVEEZ80)' >> $$(ASSDIR)$(1).s
			if [ -n "$$$${dep%%*.asm}" ]; then
				echo '#include "'ch376-native/$(1)/$$$${dep}'"' >> $$(ASSDIR)$(1).s
			else
				echo '#include "'ch376-native/source-doc/$(1)/$$$${dep}'"' >> $$(ASSDIR)$(1).s
			fi
			echo '#ENDIF' >> $$(ASSDIR)$(1).s
		fi
	done

$$(ASSDIR)$(1)/%.c.asm: $$(SRC)$(1)/%.c; $$(compile)
# $$(ASSDIR)$(1)/%.asm: $$(SRC)$(1)/%.asm; echo $$@ $$<

$(1)_C_FILES := $$(wildcard $$(SRC)$(1)/*.c)
$(1)_ASM_FILES := $$(wildcard $$(SRC)$(1)/*.asm)
$(1)_C_S_FILES := $$(patsubst ./source-doc/%, ./%, $$($(1)_C_FILES:.c=.c.s))
./$(1).s: $$($(1)_C_S_FILES) $$($(1)_ASM_FILES)
endef

$(eval $(call build_subsystem,base-drv))
$(eval $(call build_subsystem,scsi-drv))
$(eval $(call build_subsystem,keyboard))
$(eval $(call build_subsystem,ufi-drv))

.PHONY: format
format: SHELL:=/bin/bash
format:
	@find \( -name "*.c" -o -name "*.h" \) -exec echo "formating {}" \; -exec clang-format -i {} \;
