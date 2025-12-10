#!/usr/bin/env python3
import os
import sys
import glob
import gzip

# Supported file extensions
SUPPORTED_EXTS = ('.vgm', '.vgz')

def is_supported_file(filename):
    """Check if filename has a supported extension"""
    return filename.lower().endswith(SUPPORTED_EXTS)

# Collect all VGM/VGZ files from command-line arguments
files = []
if len(sys.argv) > 1:
    # Process each argument
    for arg in sys.argv[1:]:
        if os.path.isdir(arg):
            # If it's a directory, recursively find all supported files
            for root, dirs, filenames in os.walk(arg):
                for filename in filenames:
                    if is_supported_file(filename):
                        files.append(os.path.join(root, filename))
        elif os.path.isfile(arg) and is_supported_file(arg):
            # If it's a supported file, add it directly
            files.append(arg)
        else:
            # Treat as glob pattern
            matched = glob.glob(arg)
            files.extend([f for f in matched if os.path.isfile(f) and is_supported_file(f)])
else:
    # No arguments: default to current directory (non-recursive)
    files = [f for f in os.listdir('.') if is_supported_file(f)]

files = sorted(set(files))  # Remove duplicates and sort

print("File           Ver   SN76489  YM2612   YM2151   YM3812   YMF262   AY-3-8910")
print("=" * 80)

for filename in files:
    try:
        # Read file - decompress if .vgz
        if filename.lower().endswith('.vgz'):
            with gzip.open(filename, 'rb') as f:
                data = f.read(128)
        else:
            with open(filename, 'rb') as f:
                data = f.read(128)
        
        if len(data) < 120:
            continue
        
        # Verify VGM header signature
        if data[0:4] != b'Vgm ':
            continue
            
        version = int.from_bytes(data[0x08:0x0C], "little")
        
        # Determine actual header size from VGM data offset field
        vgm_data_offset = int.from_bytes(data[0x34:0x38], "little")
        if vgm_data_offset == 0:
            header_size = 0x40  # v1.50 or earlier
        else:
            header_size = 0x34 + vgm_data_offset
        
        # Read chip clocks that are always present (in all VGM versions)
        sn = int.from_bytes(data[0x0C:0x10], "little")
        ym2612 = int.from_bytes(data[0x2C:0x30], "little")
        ym2151 = int.from_bytes(data[0x30:0x34], "little")
        
        # Read extended chip clocks only if they're within the header
        ym3812 = 0
        ymf262 = 0
        ay = 0
        
        if version >= 0x151:
            # YM3812 (OPL2) at offset 0x50
            if header_size > 0x53:
                ym3812 = int.from_bytes(data[0x50:0x54], "little")
            
            # YMF262 (OPL3) at offset 0x5C
            if header_size > 0x5F:
                ymf262 = int.from_bytes(data[0x5C:0x60], "little")
            
            # AY-3-8910 at offset 0x74
            if header_size > 0x77:
                ay = int.from_bytes(data[0x74:0x78], "little")
        
        # Format output
        short_name = os.path.basename(filename)[:14].ljust(14)
        v_str = f"{(version>>8) & 0xFF}.{version & 0xFF:02d}".ljust(5)
        sn_str = "YES" if sn else "   "
        ym2612_str = "YES" if ym2612 else "   "
        ym2151_str = "YES" if ym2151 else "   "
        ym3812_str = "YES" if ym3812 else "   "
        ymf262_str = "YES" if ymf262 else "   "
        ay_str = "YES" if ay else "   "
        
        print(f"{short_name} {v_str} {sn_str:8} {ym2612_str:8} {ym2151_str:8} {ym3812_str:8} {ymf262_str:8} {ay_str:8}")
    except Exception as e:
        print(f"{filename}: ERROR - {e}")
