#
# this makefile subsumes all the work done in BuildMsxDsk.cmd, BuildMsxDsk.ps1
#
# You may need to install packages: unzip, mtools
#

# Variables
DEST    = ../../Binary
OBJECTS = $(DEST)/msx_combo.dsk
MTOOLS  = mtools

# mtools settings
export MTOOLS_SKIP_CHECK := 1

# Define the 16 slices required for the RomWBW partition
SLICES = cpm22 zsdos nzcom cpm3 zpm3 wp games msx \
         blank blank blank blank blank blank blank blank

# Resolve full paths for the slice images
SLICE_FILES = $(foreach s,$(SLICES),$(DEST)/hd1k_$(s).img)

# Default target
all: $(OBJECTS)

# Rule to create the final .dsk file
$(OBJECTS): msximg/msx_sys.dsk
	@echo "Generating $@..."
	cat msximg/msx_mbr.dat $(SLICE_FILES) msximg/msx_sys.dsk msximg/msx_data.dsk > $@

# Rule to populate the FAT system partition
msximg/msx_sys.dsk: msximg.zip $(DEST)/MSX_std.rom
	unzip -o msximg.zip -d msximg
	$(MTOOLS) -c mcopy -i $@ -omv d_fat/* ::
	$(MTOOLS) -c mcopy -i $@ -omv $(DEST)/MSX_std.rom ::MSX-STD.ROM
	$(MTOOLS) -c mcopy -i $@ -omv $(DEST)/msx-ldr.com ::MSX-LDR.COM
	$(MTOOLS) -c mcopy -i $@ -omv $(DEST)/Apps/reboot.com ::REBOOT.COM

# Cleanup build artifacts
clean:
	rm -f $(OBJECTS)
	rm -rf msximg

.PHONY: all clean
