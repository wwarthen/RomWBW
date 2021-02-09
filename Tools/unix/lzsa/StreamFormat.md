# Stream format

The stream format is composed of:

* a header
* one or more frames
* a footer

# Header format

The 3-bytes LZSA header contains a signature and a traits byte:

    0    1                2
    0x7b 0x9e             7 6 5 4 3 2 1
                          V V V Z Z Z Z
    <--- signature --->   <- traits ->

Trait bits:

* V: 3 bit code that indicates which block data encoding is used. 0 is LZSA1 and 1 is LZSA2.
* Z: these bits in the traits are set to 0 for LZSA1 and LZSA2.

# Frame format

Each frame contains a 3-bytes length followed by block data that expands to up to 64 Kb of decompressed data. The block data is encoded either as LZSA1 or LZSA2 depending on the V bits of the traits byte in the header.

    0    1    2
    DSZ0 DSZ1 U|DSZ2

* DSZ0 (length byte 0) contains bits 0-7 of the block data size
* DSZ1 (length byte 1) contains bits 8-15 of the block data size
* DSZ2 (bit 0 of length byte 2) contains bit 16 of the block data size
* U (bit 7 of length byte 2) is set if the block data is uncompressed, and clear if the block data is compressed.
* Bits 1..6 of length byte 2 are currently undefined and must be set to 0.

# Footer format

The stream ends with the EOD frame: the 3 length bytes are set to 0x00, 0x00, 0x00, and no block data follows.

