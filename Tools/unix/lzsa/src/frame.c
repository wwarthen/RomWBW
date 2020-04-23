/*
 * frame.c - frame implementation
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
#include "frame.h"

#define LZSA_ID_0   0x7b
#define LZSA_ID_1   0x9e

/**
 * Get compressed file header size
 *
 * @return file header size
 */
int lzsa_get_header_size(void) {
   return 3;
}

/**
 * Get compressed frame header size
 *
 * @return frame header size
 */
int lzsa_get_frame_size(void) {
   return 3;
}

/**
 * Encode file header
 *
 * @param pFrameData encoding buffer
 * @param nMaxFrameDataSize max encoding buffer size, in bytes
 *
 * @return number of encoded bytes, or -1 for failure
 */
int lzsa_encode_header(unsigned char *pFrameData, const int nMaxFrameDataSize, int nFormatVersion) {
   if (nMaxFrameDataSize >= 3 && (nFormatVersion == 1 || nFormatVersion == 2)) {
      pFrameData[0] = LZSA_ID_0;                         /* Magic number */
      pFrameData[1] = LZSA_ID_1;
      pFrameData[2] = (nFormatVersion == 2) ? 0x20 : 0;  /* Format version 1 */

      return 3;
   }
   else {
      return -1;
   }
}

/**
 * Encode compressed block frame header
 *
 * @param pFrameData encoding buffer
 * @param nMaxFrameDataSize max encoding buffer size, in bytes
 * @param nBlockDataSize compressed block's data size, in bytes
 *
 * @return number of encoded bytes, or -1 for failure
 */
int lzsa_encode_compressed_block_frame(unsigned char *pFrameData, const int nMaxFrameDataSize, const int nBlockDataSize) {
   if (nMaxFrameDataSize >= 3 && nBlockDataSize <= 0x7fffff) {
      pFrameData[0] = nBlockDataSize & 0xff;
      pFrameData[1] = (nBlockDataSize >> 8) & 0xff;
      pFrameData[2] = (nBlockDataSize >> 16) & 0x7f;

      return 3;
   }
   else {
      return -1;
   }
}

/**
 * Encode uncompressed block frame header
 *
 * @param pFrameData encoding buffer
 * @param nMaxFrameDataSize max encoding buffer size, in bytes
 * @param nBlockDataSize uncompressed block's data size, in bytes
 *
 * @return number of encoded bytes, or -1 for failure
 */
int lzsa_encode_uncompressed_block_frame(unsigned char *pFrameData, const int nMaxFrameDataSize, const int nBlockDataSize) {
   if (nMaxFrameDataSize >= 3 && nBlockDataSize <= 0x7fffff) {
      pFrameData[0] = nBlockDataSize & 0xff;
      pFrameData[1] = (nBlockDataSize >> 8) & 0xff;
      pFrameData[2] = ((nBlockDataSize >> 16) & 0x7f) | 0x80;   /* Uncompressed block */

      return 3;
   }
   else {
      return -1;
   }
}

/**
 * Encode terminal frame header
 *
 * @param pFrameData encoding buffer
 * @param nMaxFrameDataSize max encoding buffer size, in bytes
 *
 * @return number of encoded bytes, or -1 for failure
 */
int lzsa_encode_footer_frame(unsigned char *pFrameData, const int nMaxFrameDataSize) {
   if (nMaxFrameDataSize >= 3) {
      pFrameData[0] = 0x00;         /* EOD frame */
      pFrameData[1] = 0x00;
      pFrameData[2] = 0x00;

      return 3;
   }
   else {
      return -1;
   }
}

/**
 * Decode file header
 *
 * @param pFrameData data bytes
 * @param nFrameDataSize number of bytes to decode
 *
 * @return 0 for success, or -1 for failure
 */
int lzsa_decode_header(const unsigned char *pFrameData, const int nFrameDataSize, int *nFormatVersion) {
   if (nFrameDataSize != 3 ||
      pFrameData[0] != LZSA_ID_0 ||
      pFrameData[1] != LZSA_ID_1 ||
      (pFrameData[2] & 0x1f) != 0 ||
      ((pFrameData[2] & 0xe0) != 0x00 && (pFrameData[2] & 0xe0) != 0x20)) {
      return -1;
   }
   else {
      *nFormatVersion = (pFrameData[2] & 0xe0) ? 2 : 1;
      return 0;
   }
}

/**
 * Decode frame header
 *
 * @param pFrameData data bytes
 * @param nFrameDataSize number of bytes to decode
 * @param nBlockSize pointer to block size, updated if this function succeeds (set to 0 if this is the terminal frame)
 * @param nIsUncompressed pointer to compressed block flag, updated if this function succeeds
 *
 * @return 0 for success, or -1 for failure
 */
int lzsa_decode_frame(const unsigned char *pFrameData, const int nFrameDataSize, unsigned int *nBlockSize, int *nIsUncompressed) {
   if (nFrameDataSize == 3) {
      *nBlockSize = ((unsigned int)pFrameData[0]) |
         (((unsigned int)pFrameData[1]) << 8) |
         (((unsigned int)pFrameData[2]) << 16);

      *nIsUncompressed = ((*nBlockSize & 0x800000) != 0) ? 1 : 0;
      *nBlockSize &= 0x7fffff;
      return 0;
   }
   else {
      return -1;
   }
}
