SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.ONESHELL:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

ZCCRELFLAGS=
ifdef RELEASE
ZCCRELFLAGS=-SO3 --max-allocs-per-node600000 --allow-unsafe-read --opt-code-speed
endif

SRC := ./source-doc/
LIBS := -I./$(SRC)base-drv/

ZCC := zcc +msx --vc -subtype=rom -startup=1 -crt0 $(SRC)crt.asm -compiler=sdcc -Cs--std=c23 -Cs--Werror  $(ZCCRELFLAGS) $(LIBS)

ASSDIR := ./

all: $(ASSDIR)base-drv.s $(ASSDIR)scsi-drv.s $(ASSDIR)ufi-drv.s

clean:
	@rm -rf base-drv
	@rm -rf scsi-drv
	@rm -rf ufi-drv

$(ASSDIR)base-drv.s:
	@echo "Creating base-drv.s"
	echo "; Generated File -- not to be modify directly" > $(ASSDIR)base-drv.s
	for dep in $^; do
		dep=$${dep#*/}
		dep=$${dep#*/}
		echo '#include "'ch376-native/base-drv/$${dep}'"' >> $(ASSDIR)base-drv.s
	done

$(ASSDIR)scsi-drv.s:
	@echo "Creating scsi-drv.s"
	echo "; Generated File -- not to be modify directly" > $(ASSDIR)scsi-drv.s
	for dep in $^; do
		dep=$${dep#*/}
		dep=$${dep#*/}
		echo '#include "'ch376-native/scsi-drv/$${dep}'"' >> $(ASSDIR)scsi-drv.s
	done

$(ASSDIR)ufi-drv.s:
	@echo "Creating ufi-drv.s"
	echo "; Generated File -- not to be modify directly" > $(ASSDIR)ufi-drv.s
	for dep in $^; do
		dep=$${dep#*/}
		dep=$${dep#*/}
		echo '#include "'ch376-native/ufi-drv/$${dep}'"' >> $(ASSDIR)ufi-drv.s
	done

$(ASSDIR)%.c.s: $(ASSDIR)%.c.asm
	@mkdir -p $(dir $@)
	echo "Converting $< to $@"
	${SRC}convert-for-uz80as.sh $< $@

$(ASSDIR)%.s: $(SRC)%.asm
	@mkdir -p $(dir $@)
	cp $< $@
	sed -i "1i\;\r\n; Generated from $< -- not to be modify directly\r\n;\r\n; " $@

define compile
	@mkdir -p $(dir $@)
	$(ZCC) --c-code-in-asm --assemble-only $< -o $@
	echo "Compiled $(notdir $@) from $(notdir $<)"
endef

$(ASSDIR)base-drv/%.c.asm: $(SRC)base-drv/%.c; $(compile)
$(ASSDIR)scsi-drv/%.c.asm: $(SRC)scsi-drv/%.c; $(compile)
$(ASSDIR)ufi-drv/%.c.asm: $(SRC)ufi-drv/%.c; $(compile)
$(ASSDIR)%.c.asm: $(SRC)%.c; $(compile)
$(ASSDIR)libraries/delay/%.c.asm: ../apps/libraries/delay/%.c; $(compile)
$(ASSDIR)libraries/usb/%.c.asm: ../apps/libraries/usb/%.c; $(compile)

.PHONY: format
format: SHELL:=/bin/bash
format:
	@clang-format --version
	find \( -name "*.c" -o -name "*.h" \) -exec echo "formating {}" \; -exec clang-format -i {} \;

ZSDCPP_FLAGS=-iquote"." -isystem"${ZCCCFG}/../../include/_DEVELOPMENT/sdcc" $(LIBS)

include ${SRC}depends.d

deps:
	@echo "" > ${SRC}/depends.d
	# C Dependencies
	(cd ${SRC} && find -name "*.c") | while read -r file; do
		file_no_ext="$${file%.*}"
		file_no_ext=$${file_no_ext#./}
		filename=$$(basename $$file_no_ext)
		from="$$filename.o"
		to="${ASSDIR}$$file_no_ext.c.s"
		sdcpp ${ZSDCPP_FLAGS} -MM -MF /tmp/deps.deps ./${SRC}$$file_no_ext.c
		sed "s+$$from+$$to+g" /tmp/deps.deps >> ${SRC}/depends.d
	done

	# configure base-drv.s to all .s files
	printf "##\r\n" >> ${SRC}/depends.d
	printf "./base-drv.s: " >> ${SRC}/depends.d
	(cd ${SRC}/base-drv && find -name "*.c") | while read -r file; do
		file_no_ext="$${file%.*}"
		file_no_ext=$${file_no_ext#./}
		filename=$$(basename $$file_no_ext)
		printf "base-drv/$$file.s " >> ${SRC}/depends.d
	done

	printf "\r\n" >> ${SRC}/depends.d
	# # configure scsi-drv.s to all .s files
	printf "##\r\n" >> ${SRC}/depends.d
	printf "./scsi-drv.s: " >> ${SRC}/depends.d
	(cd ${SRC}/scsi-drv && find -name "*.c") | while read -r file; do
		file_no_ext="$${file%.*}"
		file_no_ext=$${file_no_ext#./}
		filename=$$(basename $$file_no_ext)
		printf "scsi-drv/$$file.s " >> ${SRC}/depends.d
	done

	printf "\r\n" >> ${SRC}/depends.d
	# # configure ufi-drv.s to all .s files
	printf "##\r\n" >> ${SRC}/depends.d
	printf "./ufi-drv.s: " >> ${SRC}/depends.d
	(cd ${SRC}/ufi-drv && find -name "*.c") | while read -r file; do
		file_no_ext="$${file%.*}"
		file_no_ext=$${file_no_ext#./}
		filename=$$(basename $$file_no_ext)
		printf "ufi-drv/$$file.s " >> ${SRC}/depends.d
	done

	echo "" >> ${SRC}/depends.d

	echo "${SRC}depends.d created"
