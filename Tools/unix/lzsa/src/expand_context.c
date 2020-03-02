/*
 * expand_context.h - decompressor context definitions
 *
 * Copyright (C) 2019 Emmanuel Marty
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

/*
 * Uses the libdivsufsort library Copyright (c) 2003-2008 Yuta Mori
 *
 * Inspired by LZ4 by Yann Collet. https://github.com/lz4/lz4
 * With help, ideas, optimizations and speed measurements by spke <zxintrospec@gmail.com>
 * With ideas from Lizard by Przemyslaw Skibinski and Yann Collet. https://github.com/inikep/lizard
 * Also with ideas from smallz4 by Stephan Brumme. https://create.stephan-brumme.com/smallz4/
 *
 */

#include <stdlib.h>
#include <string.h>
#include "expand_context.h"
#include "expand_block_v1.h"
#include "expand_block_v2.h"
#include "lib.h"

/**
 * Decompress one data block
 *
 * @param pInBlock pointer to compressed data
 * @param nBlockSize size of compressed data, in bytes
 * @param pOutData pointer to output decompression buffer (previously decompressed bytes + room for decompressing this block)
 * @param nOutDataOffset starting index of where to store decompressed bytes in output buffer (and size of previously decompressed bytes)
 * @param nBlockMaxSize total size of output decompression buffer, in bytes
 * @param nFormatVersion version of format to use (1-2)
 * @param nFlags compression flags (LZSA_FLAG_xxx)
 *
 * @return size of decompressed data in bytes, or -1 for error
 */
int lzsa_decompressor_expand_block(unsigned char *pInBlock, int nBlockSize, unsigned char *pOutData, int nOutDataOffset, int nBlockMaxSize, const int nFormatVersion, const int nFlags) {
   int nDecompressedSize;

   if (nFlags & LZSA_FLAG_RAW_BACKWARD) {
      lzsa_reverse_buffer(pInBlock, nBlockSize);
   }

   if (nFormatVersion == 1)
      nDecompressedSize = lzsa_decompressor_expand_block_v1(pInBlock, nBlockSize, pOutData, nOutDataOffset, nBlockMaxSize);
   else if (nFormatVersion == 2)
      nDecompressedSize = lzsa_decompressor_expand_block_v2(pInBlock, nBlockSize, pOutData, nOutDataOffset, nBlockMaxSize);
   else
      nDecompressedSize = -1;

   if (nDecompressedSize != -1 && (nFlags & LZSA_FLAG_RAW_BACKWARD)) {
      lzsa_reverse_buffer(pOutData + nOutDataOffset, nDecompressedSize);
   }

   if (nFlags & LZSA_FLAG_RAW_BACKWARD) {
      lzsa_reverse_buffer(pInBlock, nBlockSize);
   }

   return nDecompressedSize;
}
