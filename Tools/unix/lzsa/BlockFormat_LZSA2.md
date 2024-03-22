# Block data format (LZSA2)

Blocks encoded as LZSA2 are composed from consecutive commands. Each command follows this format:

* token: <XYZ|LL|MMM>
* optional extra literal length
* literal values
* match offset
* optional extra encoded match length

**token**

The token byte is broken down into three parts:

    7 6 5 4 3 2 1 0
    X Y Z L L M M M

* L: 2-bit literals length (0-2, or 3 if extended). If the number of literals for this command is 0 to 2, the length is encoded in the token and no extra bytes are required. Otherwise, a value of 3 is encoded and extra nibbles or bytes follow as 'optional extra literal length'
* M: 3-bit encoded match length (0-6, or 7 if extended). Likewise, if the encoded match length for this command is 0 to 6, it is directly stored, otherwise 7 is stored and extra nibbles or bytes follow as 'optional extra encoded match length'. Except for the last command in a block, a command always contains a match, so the encoded match length is the actual match length offset by the minimum, which is 2 bytes. For instance, an actual match length of 5 bytes to be copied, is encoded as 3.
* XYZ: 3-bit value that indicates how to decode the match offset

**optional extra literal length**

If the literals length is 3 or more, the 'L' bits in the token form the value 3, and an extra nibble is read:

* 0-14: the value is added to the 3 stored in the token, to compose the final literals length.
* 15: an extra byte follows

If an extra byte follows, it can have two possible types of value:

* 0-237: 18 is added to the value (3 from the token + 15 from the nibble), to compose the final literals length. For instance a length of 206 will be stored as 3 in the token + a nibble with the value of 15 + a single byte with the value of 188.
* 239: a second and third byte follow, forming a little-endian 16-bit value. The final literals value is that 16-bit value. For instance, a literals length of 1027 is stored as 3 in the token, a nibble with the value of 15, then byte values of 239, 3 and 4, as 3 + (4 * 256) = 1027.

**literal values**

Literal bytes, whose number is specified by the literals length, follow here. There can be zero literals in a command.

Important note: for blocks that are part of a stream, the last command in a block ends here, as it always contains literals only. For raw blocks, the last command does contain the match offset and match length, see the note below for EOD detection.

**match offset**

The match offset is decoded according to the XYZ bits in the token

    XYZ
    00Z 5-bit offset: read a nibble for offset bits 1-4 and use the inverted bit Z of the token as bit 0 of the offset. set bits 5-15 of the offset to 1.
    01Z 9-bit offset: read a byte for offset bits 0-7 and use the inverted bit Z for bit 8 of the offset. set bits 9-15 of the offset to 1.
    10Z 13-bit offset: read a nibble for offset bits 9-12 and use the inverted bit Z for bit 8 of the offset, then read a byte for offset bits 0-7. set bits 13-15 of the offset to 1. substract 512 from the offset to get the final value.
    110 16-bit offset: read a byte for offset bits 8-15, then another byte for offset bits 0-7.
    111 repeat offset: reuse the offset value of the previous match command.

The bit ordering and inversion helps optimize the decoder for size and speed on 8-bit CPUs.

**important note regarding match offsets: stored as negative values**

Note that the match offset is negative: it is added to the current decompressed location and not substracted, in order to locate the back-reference to copy. For this reason, as already indicated, unexpressed offset bits are set to 1 instead of 0.

**optional extra encoded match length**

If the encoded match length is 7 or more, the 'M' bits in the token form the value 7, and an extra nibble is read:

* 0-14: the value is added to the 3 stored in the token, and then the minmatch of 2 is added, to compose the final match length.
* 15: an extra byte follows

If an extra byte follows here, it can have two possible types of value:

* 0-231: 24 is added to the value (7 from the token + 15 from the nibble + minmatch of 2), to compose the final match length. For instance a length of 150 will be stored as 7 in the token + a nibble with the value of 15 + a single byte with the value of 126.
* 233: a second and third byte follow, forming a little-endian 16-bit value. The final encoded match length is that 16-bit value.

# End Of Data detection for raw blocks

When the LZSA2 block is part of a stream (see StreamFormat.md), as previously mentioned, the block ends after the literal values of the last command, without a match offset or match length.

However, in a raw LZSA2 block, the last command does include a 9-bit match offset (set to zero, to be ignored) and a EOD marker as the match length. The EOD match length marker is encoded as such: the 'M' bits in the token form the value 7, then a nibble with the value of 15 is present, then a single extra match length byte with the value of 232, indicating the end of the block. This allows the EOD test to exist in a rarely used code branch.

The EOD condition can be easily checked as part of the tri-state condition when handling long matches. When 24 is added to the match byte value:
- If the byte doesn't overflow, the final match length is ready
- If the byte overflows and equals zero, the EOD marker has been hit
- Otherwise, if the overflows and doesn't equal zero, a 16-bit match length must be read.

This tri-state test translates to only an addition and two branches on 8-bit CPUs.

The equivalent EOD condition in literal lengths (which would be byte 238, that would overflow to exactly 0 when adding 18) is never emitted, so for size-optimized decompressors, the same code can be used to read both types of lengths.

# Reading nibbles

When the specification indicates that a nibble (4 bit value) must be read:

* If there are no nibbles ready, read a byte immediately. Return the high 4 bits (bits 4-7) as the nibble and store the low 4 bits for later. Flag that a nibble is ready for next time.
* If a nibble is ready, return the previously stored low 4 bits (bits 0-3) and flag that no nibble is ready for next time.
