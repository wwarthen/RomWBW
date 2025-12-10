#!/usr/bin/env python3
import sys

filename = sys.argv[1] if len(sys.argv) > 1 else 'Tunes/shirakaw.vgm'
data = open(filename, 'rb').read(128)

print("VGM Header (first 64 bytes):")
for i in range(0, 64, 16):
    hex_str = ' '.join(f'{b:02X}' for b in data[i:i+16])
    print(f'{i:02X}: {hex_str}')

version = int.from_bytes(data[0x08:0x0C], "little")
print(f'\nVGM Version: {version:08X} (v{(version >> 8) & 0xFF}.{version & 0xFF:02d})')
print(f'\n0x0C (SN76489 clock): {int.from_bytes(data[0x0C:0x10], "little"):08X}')
print(f'0x2C (YM2612 clock): {int.from_bytes(data[0x2C:0x30], "little"):08X}')
print(f'0x30 (YM2151 clock): {int.from_bytes(data[0x30:0x34], "little"):08X}')
if version >= 0x151:
    print(f'0x74 (AY-3-8910 clock): {int.from_bytes(data[0x74:0x78], "little"):08X}')
else:
    print(f'0x74 (AY-3-8910 clock): N/A (requires VGM v1.51+)')
