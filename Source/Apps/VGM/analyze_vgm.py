#!/usr/bin/env python3
import sys

vgm_file = "C:/Users/miguel/Documents/development/RomWBW/Binary/Apps/Tunes/bgm.vgm"

with open(vgm_file, 'rb') as f:
    data = f.read()

print(f"File size: {len(data)} bytes")
print(f"\nVGM Header (first 64 bytes):")
for i in range(0, 64, 16):
    hex_str = ' '.join(f'{b:02X}' for b in data[i:i+16])
    print(f"{i:04X}: {hex_str}")

print(f"\nSearching for 0xA0 (AY write) commands...")
count_primary = 0
count_secondary = 0
i = 0x40  # Skip header

while i < len(data):
    if data[i] == 0xA0 and i+2 < len(data):
        reg = data[i+1]
        val = data[i+2]
        if reg & 0x80:
            count_secondary += 1
            if count_secondary <= 10:
                print(f"  Offset {i:04X}: Secondary chip - reg={reg:02X} (masked={reg&0x7F:02X}) val={val:02X}")
        else:
            count_primary += 1
            if count_primary <= 10:
                print(f"  Offset {i:04X}: Primary chip - reg={reg:02X} val={val:02X}")
    i += 1

print(f"\nSummary:")
print(f"  Primary chip (reg < 0x80): {count_primary} commands")
print(f"  Secondary chip (reg >= 0x80): {count_secondary} commands")
