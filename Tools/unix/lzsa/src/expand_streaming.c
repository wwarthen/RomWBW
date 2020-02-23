/*
 * expand_streaming.c - streaming decompression definitions
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
#include "expand_streaming.h"
#include "format.h"
#include "frame.h"
#include "lib.h"

/*-------------- File API -------------- */

/**
 * Decompress file
 *
 * @param pszInFilename name of input(compressed) file to decompress
 * @param pszOutFilename name of output(decompressed) file to generate
 * @param pszDictionaryFilename name of dictionary file, or NULL for none
 * @param nFlags compression flags (LZSA_FLAG_RAW_BLOCK to decompress a raw block, or 0)
 * @param nFormatVersion default version of format to use (1-2). This is used when decompressing a raw block, otherwise the version is extracted from the source file
 * @param pOriginalSize pointer to returned output(decompressed) size, updated when this function is successful
 * @param pCompressedSize pointer to returned input(compressed) size, updated when this function is successful
 *
 * @return LZSA_OK for success, or an error value from lzsa_status_t
 */
lzsa_status_t lzsa_decompress_file(const char *pszInFilename, const char *pszOutFilename, const char *pszDictionaryFilename, const unsigned int nFlags, int nFormatVersion,
                                   long long *pOriginalSize, long long *pCompressedSize) {
   lzsa_stream_t inStream, outStream;
   void *pDictionaryData = NULL;
   int nDictionaryDataSize = 0;
   lzsa_status_t nStatus;

   if (lzsa_filestream_open(&inStream, pszInFilename, "rb") < 0) {
      return LZSA_ERROR_SRC;
   }

   if (lzsa_filestream_open(&outStream, pszOutFilename, "wb") < 0) {
      inStream.close(&inStream);
      return LZSA_ERROR_DST;
   }

   nStatus = lzsa_dictionary_load(pszDictionaryFilename, &pDictionaryData, &nDictionaryDataSize);
   if (nStatus) {
      outStream.close(&outStream);
      inStream.close(&inStream);
      return nStatus;
   }

   nStatus = lzsa_decompress_stream(&inStream, &outStream, pDictionaryData, nDictionaryDataSize, nFlags, nFormatVersion, pOriginalSize, pCompressedSize);

   lzsa_dictionary_free(&pDictionaryData);
   outStream.close(&outStream);
   inStream.close(&inStream);

   return nStatus;
}

/*-------------- Streaming API -------------- */

/**
 * Decompress stream
 *
 * @param pInStream input(compressed) stream to decompress
 * @param pOutStream output(decompressed) stream to write to
 * @param pDictionaryData dictionary contents, or NULL for none
 * @param nDictionaryDataSize size of dictionary contents, or 0
 * @param nFlags compression flags (LZSA_FLAG_RAW_BLOCK to decompress a raw block, or 0)
 * @param nFormatVersion default version of format to use (1-2). This is used when decompressing a raw block, otherwise the version is extracted from the source file
 * @param pOriginalSize pointer to returned output(decompressed) size, updated when this function is successful
 * @param pCompressedSize pointer to returned input(compressed) size, updated when this function is successful
 *
 * @return LZSA_OK for success, or an error value from lzsa_status_t
 */
lzsa_status_t lzsa_decompress_stream(lzsa_stream_t *pInStream, lzsa_stream_t *pOutStream, const void *pDictionaryData, int nDictionaryDataSize, const unsigned int nFlags, int nFormatVersion,
      long long *pOriginalSize, long long *pCompressedSize) {
   long long nOriginalSize = 0LL, nCompressedSize = 0LL;
   unsigned char cFrameData[16];
   unsigned char *pInBlock;
   unsigned char *pOutData;

   if ((nFlags & LZSA_FLAG_RAW_BLOCK) == 0) {
      const int nHeaderSize = lzsa_get_header_size();

      memset(cFrameData, 0, 16);
      if (pInStream->read(pInStream, cFrameData, nHeaderSize) != nHeaderSize) {
         return LZSA_ERROR_SRC;
      }

      if (lzsa_decode_header(cFrameData, nHeaderSize, &nFormatVersion) < 0) {
         return LZSA_ERROR_FORMAT;
      }

      nCompressedSize += (long long)nHeaderSize;
   }

   pInBlock = (unsigned char*)malloc(BLOCK_SIZE);
   if (!pInBlock) {
      return LZSA_ERROR_MEMORY;
   }

   pOutData = (unsigned char*)malloc(BLOCK_SIZE * 2);
   if (!pOutData) {
      free(pInBlock);
      pInBlock = NULL;

      return LZSA_ERROR_MEMORY;
   }

   int nDecompressionError = 0;
   int nPrevDecompressedSize = 0;
   int nNumBlocks = 0;

   while (!pInStream->eof(pInStream) && !nDecompressionError) {
      unsigned int nBlockSize = 0;
      int nIsUncompressed = 0;

      if (nPrevDecompressedSize != 0) {
         memcpy(pOutData + BLOCK_SIZE - nPrevDecompressedSize, pOutData + BLOCK_SIZE, nPrevDecompressedSize);
      }
      else if (nDictionaryDataSize && pDictionaryData) {
         nPrevDecompressedSize = nDictionaryDataSize;
         memcpy(pOutData + BLOCK_SIZE - nPrevDecompressedSize, pDictionaryData, nPrevDecompressedSize);
      }

      if ((nFlags & LZSA_FLAG_RAW_BLOCK) == 0) {
         const int nFrameSize = lzsa_get_frame_size();

         memset(cFrameData, 0, 16);
         if (pInStream->read(pInStream, cFrameData, nFrameSize) == nFrameSize) {
            if (lzsa_decode_frame(cFrameData, nFrameSize, &nBlockSize, &nIsUncompressed) < 0) {
               nDecompressionError = LZSA_ERROR_FORMAT;
               nBlockSize = 0;
            }

            nCompressedSize += (long long)nFrameSize;
         }
         else {
            nDecompressionError = LZSA_ERROR_SRC;
            nBlockSize = 0;
         }
      }
      else {
         if (!nNumBlocks)
            nBlockSize = BLOCK_SIZE;
         else
            nBlockSize = 0;
      }

      if (nBlockSize != 0) {
         int nDecompressedSize = 0;

         if ((int)nBlockSize > BLOCK_SIZE) {
            nDecompressionError = LZSA_ERROR_FORMAT;
            break;
         }
         size_t nReadBytes = pInStream->read(pInStream, pInBlock, nBlockSize);
         if (nFlags & LZSA_FLAG_RAW_BLOCK) {
            nBlockSize = (unsigned int)nReadBytes;
         }

         if (nReadBytes == nBlockSize) {
            nCompressedSize += (long long)nReadBytes;

            if (nIsUncompressed) {
               memcpy(pOutData + BLOCK_SIZE, pInBlock, nBlockSize);
               nDecompressedSize = nBlockSize;
            }
            else {
               nDecompressedSize = lzsa_decompressor_expand_block(pInBlock, nBlockSize, pOutData, BLOCK_SIZE, BLOCK_SIZE, nFormatVersion, nFlags);
               if (nDecompressedSize < 0) {
                  nDecompressionError = LZSA_ERROR_DECOMPRESSION;
                  break;
               }
            }

            if (nDecompressedSize != 0) {
               nOriginalSize += (long long)nDecompressedSize;

               if (pOutStream->write(pOutStream, pOutData + BLOCK_SIZE, nDecompressedSize) != nDecompressedSize)
                  nDecompressionError = LZSA_ERROR_DST;
               nPrevDecompressedSize = nDecompressedSize;
               nDecompressedSize = 0;
            }
         }
         else {
            break;
         }

         nNumBlocks++;
      }
      else {
         break;
      }
   }

   free(pOutData);
   pOutData = NULL;

   free(pInBlock);
   pInBlock = NULL;

   *pOriginalSize = nOriginalSize;
   *pCompressedSize = nCompressedSize;
   return nDecompressionError;
}

