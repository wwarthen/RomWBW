import struct

p = r"Tunes/gameov.vgm"
with open(p, 'rb') as f:
    data = f.read()

if len(data) < 0x20 or data[0:4] != b'Vgm ':
    print('Not a VGM file header')
    raise SystemExit

gd3_rel = struct.unpack_from('<I', data, 0x14)[0]
if gd3_rel == 0:
    print('No GD3 tag offset in header')
    raise SystemExit

gd3_off = 0x14 + gd3_rel
if gd3_off + 12 > len(data) or data[gd3_off:gd3_off+4] != b'Gd3 ':
    print('GD3 header not found at computed offset:', hex(gd3_off))
    raise SystemExit

ver = struct.unpack_from('<I', data, gd3_off+4)[0]
size = struct.unpack_from('<I', data, gd3_off+8)[0]
text = data[gd3_off+12:gd3_off+12+size]

s = text.decode('utf-16le', errors='ignore')
parts = s.split('\x00')
print('GD3 version:', hex(ver), 'size:', size)
for i, part in enumerate(parts[:16]):
    if part.strip():
        print(f"{i:02}: {part}")
