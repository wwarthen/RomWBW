/*
 * shrink_inmem.c - in-memory compression implementation
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
#include "shrink_inmem.h"
#include "shrink_context.h"
#include "frame.h"
#include "format.h"
#include "lib.h"

/**
 * Get maximum compressed size of input(source) data
 *
 * @param nInputSize input(source) size in bytes
 *
 * @return maximum compressed size
 */
size_t lzsa_get_max_compressed_size_inmem(size_t nInputSize) {
   return lzsa_get_header_size() + ((nInputSize + (BLOCK_SIZE - 1)) >> 16) * lzsa_get_frame_size() + nInputSize + lzsa_get_frame_size() /* footer */;
}

/**
 * Compress memory
 *
 * @param pInputData pointer to input(source) data to compress
 * @param pOutBuffer buffer for compressed data
 * @param nInputSize input(source) size in bytes
 * @param nMaxOutBufferSize maximum capacity of compression buffer
 * @param nFlags compression flags (LZSA_FLAG_xxx)
 * @param nMinMatchSize minimum match size
 * @param nFormatVersion version of format to use (1-2)
 *
 * @return actual compressed size, or -1 for error
 */
size_t lzsa_compress_inmem(unsigned char *pInputData, unsigned char *pOutBuffer, size_t nInputSize, size_t nMaxOutBufferSize,
                             const unsigned int nFlags, const int nMinMatchSize, const int nFormatVersion) {
   lzsa_compressor compressor;
   size_t nOriginalSize = 0;
   size_t nCompressedSize = 0L;
   int nResult;
   int nError = 0;

   nResult = lzsa_compressor_init(&compressor, BLOCK_SIZE * 2, nMinMatchSize, nFormatVersion, nFlags);
   if (nResult != 0) {
      return -1;
   }

   if ((nFlags & LZSA_FLAG_RAW_BLOCK) == 0) {
      int nHeaderSize = lzsa_encode_header(pOutBuffer, (int)nMaxOutBufferSize, nFormatVersion);
      if (nHeaderSize < 0)
         nError = LZSA_ERROR_COMPRESSION;
      else {
         nCompressedSize += nHeaderSize;
      }
   }

   int nPreviousBlockSize = 0;
   int nNumBlocks = 0;

   while (nOriginalSize < nInputSize && !nError) {
      int nInDataSize;

      nInDataSize = (int)(nInputSize - nOriginalSize);
      if (nInDataSize > BLOCK_SIZE)
         nInDataSize = BLOCK_SIZE;

      if (nInDataSize > 0) {
         if ((nFlags & LZSA_FLAG_RAW_BLOCK) != 0 && nNumBlocks) {
            nError = LZSA_ERROR_RAW_TOOLARGE;
            break;
         }

         int nOutDataSize;
         int nOutDataEnd = (int)(nMaxOutBufferSize - (lzsa_get_frame_size() + nCompressedSize + lzsa_get_frame_size() /* footer */));
         int nFrameSize = lzsa_get_frame_size();

         if ((nFlags & LZSA_FLAG_RAW_BLOCK) != 0) {
            nFrameSize = 0;
            nOutDataEnd = (int)(nMaxOutBufferSize - nCompressedSize);
         }

         if (nOutDataEnd > BLOCK_SIZE)
            nOutDataEnd = BLOCK_SIZE;

         nOutDataSize = lzsa_compressor_shrink_block(&compressor, pInputData + nOriginalSize - nPreviousBlockSize, nPreviousBlockSize, nInDataSize, pOutBuffer + nFrameSize + nCompressedSize, nOutDataEnd);
         if (nOutDataSize >= 0) {
            /* Write compressed block */

            if ((nFlags & LZSA_FLAG_RAW_BLOCK) == 0) {
               int nBlockheaderSize = lzsa_encode_compressed_block_frame(pOutBuffer + nCompressedSize, (int)(nMaxOutBufferSize - nCompressedSize), nOutDataSize);
               if (nBlockheaderSize < 0)
                  nError = LZSA_ERROR_COMPRESSION;
               else {
                  nCompressedSize += nBlockheaderSize;
               }
            }

            if (!nError) {
               nOriginalSize += nInDataSize;
               nCompressedSize += nOutDataSize;
            }
         }
         else {
            /* Write uncompressible, literal block */

            if ((nFlags & LZSA_FLAG_RAW_BLOCK) != 0) {
               nError = LZSA_ERROR_RAW_UNCOMPRESSED;
               break;
            }

            int nBlockheaderSize = lzsa_encode_uncompressed_block_frame(pOutBuffer + nCompressedSize, (int)(nMaxOutBufferSize - nCompressedSize), nInDataSize);
            if (nBlockheaderSize < 0)
               nError = LZSA_ERROR_COMPRESSION;
            else {
               if ((size_t)nInDataSize > (nMaxOutBufferSize - (nCompressedSize + nBlockheaderSize)))
                  nError = LZSA_ERROR_DST;
               else {
                  memcpy(pOutBuffer + nBlockheaderSize + nCompressedSize, pInputData + nOriginalSize, nInDataSize);

                  nOriginalSize += nInDataSize;
                  nCompressedSize += nBlockheaderSize + nInDataSize;
               }
            }
         }

         nPreviousBlockSize = nInDataSize;
         nNumBlocks++;
      }
   }

   if (!nError) {
      int nFooterSize;

      if ((nFlags & LZSA_FLAG_RAW_BLOCK) != 0) {
         nFooterSize = 0;
      }
      else {
         nFooterSize = lzsa_encode_footer_frame(pOutBuffer + nCompressedSize, (int)(nMaxOutBufferSize - nCompressedSize));
         if (nFooterSize < 0)
            nError = LZSA_ERROR_COMPRESSION;
      }

      nCompressedSize += nFooterSize;
   }

   lzsa_compressor_destroy(&compressor);

   if (nError) {
      return -1;
   }
   else {
      return nCompressedSize;
   }
}

