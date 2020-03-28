/*
 * expand_inmem.c - in-memory decompression implementation
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
#include "expand_inmem.h"
#include "lib.h"
#include "frame.h"

#define BLOCK_SIZE 65536

/**
 * Get maximum decompressed size of compressed data
 *
 * @param pFileData compressed data
 * @param nFileSize compressed size in bytes
 *
 * @return maximum decompressed size
 */
size_t lzsa_get_max_decompressed_size_inmem(const unsigned char *pFileData, size_t nFileSize) {
   const unsigned char *pCurFileData = pFileData;
   const unsigned char *pEndFileData = pCurFileData + nFileSize;
   int nFormatVersion = 0;
   size_t nMaxDecompressedSize = 0;
   const int nHeaderSize = lzsa_get_header_size();

   /* Check header */
   if ((pCurFileData + nHeaderSize) > pEndFileData ||
       lzsa_decode_header(pCurFileData, nHeaderSize, &nFormatVersion) != 0)
      return -1;

   pCurFileData += nHeaderSize;

   while (pCurFileData < pEndFileData) {
      unsigned int nBlockDataSize = 0;
      int nIsUncompressed = 0;
      const int nFrameSize = lzsa_get_frame_size();

      /* Decode frame header */
      if ((pCurFileData + nFrameSize) > pEndFileData ||
          lzsa_decode_frame(pCurFileData, nFrameSize, &nBlockDataSize, &nIsUncompressed) != 0)
         return -1;
      pCurFileData += nFrameSize;

      if (!nBlockDataSize)
         break;

      /* Add one potentially full block to the decompressed size */
      nMaxDecompressedSize += BLOCK_SIZE;

      if ((pCurFileData + nBlockDataSize) > pEndFileData)
         return -1;

      pCurFileData += nBlockDataSize;
   }

   return nMaxDecompressedSize;
}

/**
 * Decompress data in memory
 *
 * @param pFileData compressed data
 * @param pOutBuffer buffer for decompressed data
 * @param nFileSize compressed size in bytes
 * @param nMaxOutBufferSize maximum capacity of decompression buffer
 * @param nFlags compression flags (LZSA_FLAG_xxx)
 * @param pFormatVersion pointer to format version, updated if this function is successful
 *
 * @return actual decompressed size, or -1 for error
 */
size_t lzsa_decompress_inmem(unsigned char *pFileData, unsigned char *pOutBuffer, size_t nFileSize, size_t nMaxOutBufferSize, const unsigned int nFlags, int *pFormatVersion) {
   unsigned char *pCurFileData = pFileData;
   const unsigned char *pEndFileData = pCurFileData + nFileSize;
   unsigned char *pCurOutBuffer = pOutBuffer;
   const unsigned char *pEndOutBuffer = pCurOutBuffer + nMaxOutBufferSize;
   int nPreviousBlockSize;
   const int nHeaderSize = lzsa_get_header_size();

   if (nFlags & LZSA_FLAG_RAW_BLOCK) {
      return (size_t)lzsa_decompressor_expand_block(pFileData, (int)nFileSize, pOutBuffer, 0, (int)nMaxOutBufferSize, *pFormatVersion, nFlags);
   }

   /* Check header */
   if ((pCurFileData + nHeaderSize) > pEndFileData ||
      lzsa_decode_header(pCurFileData, nHeaderSize, pFormatVersion) != 0)
      return -1;

   pCurFileData += nHeaderSize;
   nPreviousBlockSize = 0;

   while (pCurFileData < pEndFileData) {
      unsigned int nBlockDataSize = 0;
      int nIsUncompressed = 0;
      const int nFrameSize = lzsa_get_frame_size();

      /* Decode frame header */
      if ((pCurFileData + nFrameSize) > pEndFileData ||
          lzsa_decode_frame(pCurFileData, nFrameSize, &nBlockDataSize, &nIsUncompressed) != 0)
         return -1;
      pCurFileData += nFrameSize;

      if (!nBlockDataSize)
         break;

      if (!nIsUncompressed) {
         int nDecompressedSize;

         /* Decompress block */
         if ((pCurFileData + nBlockDataSize) > pEndFileData)
            return -1;

         nDecompressedSize = lzsa_decompressor_expand_block(pCurFileData, nBlockDataSize, pCurOutBuffer - nPreviousBlockSize, nPreviousBlockSize, (int)(pEndOutBuffer - pCurOutBuffer + nPreviousBlockSize), *pFormatVersion, nFlags);
         if (nDecompressedSize < 0)
            return -1;

         pCurOutBuffer += nDecompressedSize;
         nPreviousBlockSize = nDecompressedSize;
      }
      else {
         /* Copy uncompressed block */
         if ((pCurFileData + nBlockDataSize) > pEndFileData)
            return -1;
         if ((pCurOutBuffer + nBlockDataSize) > pEndOutBuffer)
            return -1;
         memcpy(pCurOutBuffer, pCurFileData, nBlockDataSize);
         pCurOutBuffer += nBlockDataSize;
      }

      pCurFileData += nBlockDataSize;
   }

   return (int)(pCurOutBuffer - pOutBuffer);
}
