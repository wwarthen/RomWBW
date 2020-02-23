# Block data format (LZSA1)

Blocks encoded as LZSA1 are composed from consecutive commands. Each command follows this format:

* token: <O|LLL|MMMM>
* optional extra literal length
* literal values
* match offset low
* optional match offset high
* optional extra encoded match length

**token**

The token byte is broken down into three parts:

    7 6 5 4 3 2 1 0
    O L L L M M M M

* L: 3-bit literals length (0-6, or 7 if extended). If the number of literals for this command is 0 to 6, the length is encoded in the token and no extra bytes are required. Otherwise, a value of 7 is encoded and extra bytes follow as 'optional extra literal length'
* M: 4-bit encoded match length (0-14, or 15 if extended). Likewise, if the encoded match length for this command is 0 to 14, it is directly stored, otherwise 15 is stored and extra bytes follow as 'optional extra encoded match length'. Except for the last command in a block, a command always contains a match, so the encoded match length is the actual match length offset by the minimum, which is 3 bytes. For instance, an actual match length of 10 bytes to be copied, is encoded as 7.
* O: set for a 2-bytes match offset, clear for a 1-byte match offset

**optional extra literal length**

If the literals length is 7 or more, the 'L' bits in the token form the value 7, and an extra byte follows here, with three possible types of value:

* 0-248: the value is added to the 7 stored in the token, to compose the final literals length. For instance a length of 206 will be stored as 7 in the token + a single byte with the value of 199, as 7 + 199 = 206.
* 250: a second byte follows. The final literals value is 256 + the second byte. For instance, a literals length of 499 is encoded as 7 in the token, a byte with the value of 250, and a final byte with the value of 243, as 256 + 243 = 499.
* 249: a second and third byte follow, forming a little-endian 16-bit value. The final literals value is that 16-bit value. For instance, a literals length of 1024 is stored as 7 in the token, then byte values of 249, 0 and 4, as (4 * 256) = 1024.

The extension byte values are chosen so that all three cases can be detected on 8-bit CPUs with a simple addition and overflow check.

**literal values**

Literal bytes, whose number is specified by the literals length, follow here. There can be zero literals in a command.

Important note: for blocks that are part of a stream, the last command in a block ends here, as it always contains literals only. For raw blocks, the last command does contain the match offset and match length, see the note below for EOD detection.

**match offset low**

The low 8 bits of the match offset follows.

**optional match offset high**

If the 'O' bit (bit 7) is set in the token, the high 8 bits of the match offset follow, otherwise they are understood to be all set to 1. For instance, a short offset of 0x70 is interpreted as 0xff70.

**important note regarding match offsets: stored as negative values**

Note that the match offset is negative: it is added to the current decompressed location and not substracted, in order to locate the back-reference to copy.

**optional extra encoded match length**

If the encoded match length is 15 or more, the 'M' bits in the token form the value 15, and an extra byte follows here, with three possible types of value.

* 0-237: the value is added to the 15 stored in the token. The final value is 3 + 15 + this byte.
* 239: a second byte follows. The final match length is 256 + the second byte.
* 238: a second and third byte follow, forming a little-endian 16-bit value. The final encoded match length is that 16-bit value.

Again, the extension byte values are chosen so that all cases can be detected with a simple addition and overflow check on 8-bit CPUs.

# End Of Data detection for raw blocks

When the LZSA1 block is part of a stream (see StreamFormat.md), as previously mentioned, the block ends after the literal values of the last command, without a match offset or match length.

However, in a raw LZSA1 block, the last command does include a 1-byte match offset (set to zero) and a match length. The match length is encoded as a long zero: the 'M' bits in the token form the value 15, then an extra match length byte is present, with the value 238 ("two match length bytes follow"). Finally, a two-byte zero match length follows, indicating the end of the block. EOD is the only time a zero match length (which normally would indicate a copy of 3 bytes) is encoded as a large 2-byte match value. This allows the EOD test to exist in a rarely used code branch.
