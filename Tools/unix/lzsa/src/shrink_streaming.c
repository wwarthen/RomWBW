/*
 * shrink_streaming.c - streaming compression implementation
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
#include "shrink_streaming.h"
#include "format.h"
#include "frame.h"
#include "lib.h"
#ifdef _WIN32
#include <windows.h>
#else
#include <stdio.h>
#endif

/**
 * Delete file
 *
 * @param pszInFilename name of file to delete
 */
static void lzsa_delete_file(const char *pszInFilename) {
#ifdef _WIN32
   DeleteFileA(pszInFilename);
#else
   remove(pszInFilename);
#endif
}

/*-------------- File API -------------- */

/**
 * Compress file
 *
 * @param pszInFilename name of input(source) file to compress
 * @param pszOutFilename name of output(compressed) file to generate
 * @param pszDictionaryFilename name of dictionary file, or NULL for none
 * @param nFlags compression flags (LZSA_FLAG_xxx)
 * @param nMinMatchSize minimum match size
 * @param nFormatVersion version of format to use (1-2)
 * @param progress progress function, called after compressing each block, or NULL for none
 * @param pOriginalSize pointer to returned input(source) size, updated when this function is successful
 * @param pCompressedSize pointer to returned output(compressed) size, updated when this function is successful
 * @param pCommandCount pointer to returned token(compression commands) count, updated when this function is successful
 * @param pSafeDist pointer to return safe distance for raw blocks, updated when this function is successful
 * @param pStats pointer to compression stats that are filled if this function is successful, or NULL
 *
 * @return LZSA_OK for success, or an error value from lzsa_status_t
 */
lzsa_status_t lzsa_compress_file(const char *pszInFilename, const char *pszOutFilename, const char *pszDictionaryFilename, const unsigned int nFlags, const int nMinMatchSize, const int nFormatVersion,
      void(*progress)(long long nOriginalSize, long long nCompressedSize), long long *pOriginalSize, long long *pCompressedSize, int *pCommandCount, int *pSafeDist, lzsa_stats *pStats) {
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
      lzsa_delete_file(pszOutFilename);
      return nStatus;
   }

   nStatus = lzsa_compress_stream(&inStream, &outStream, pDictionaryData, nDictionaryDataSize, nFlags, nMinMatchSize, nFormatVersion, progress, pOriginalSize, pCompressedSize, pCommandCount, pSafeDist, pStats);

   lzsa_dictionary_free(&pDictionaryData);
   outStream.close(&outStream);
   inStream.close(&inStream);

   if (nStatus) {
      lzsa_delete_file(pszOutFilename);
   }

   return nStatus;
}

/*-------------- Streaming API -------------- */

/**
 * Compress stream
 *
 * @param pInStream input(source) stream to compress
 * @param pOutStream output(compressed) stream to write to
 * @param pDictionaryData dictionary contents, or NULL for none
 * @param nDictionaryDataSize size of dictionary contents, or 0
 * @param nFlags compression flags (LZSA_FLAG_xxx)
 * @param nMinMatchSize minimum match size
 * @param nFormatVersion version of format to use (1-2)
 * @param progress progress function, called after compressing each block, or NULL for none
 * @param pOriginalSize pointer to returned input(source) size, updated when this function is successful
 * @param pCompressedSize pointer to returned output(compressed) size, updated when this function is successful
 * @param pCommandCount pointer to returned token(compression commands) count, updated when this function is successful
 * @param pSafeDist pointer to return safe distance for raw blocks, updated when this function is successful
 * @param pStats pointer to compression stats that are filled if this function is successful, or NULL
 *
 * @return LZSA_OK for success, or an error value from lzsa_status_t
 */
lzsa_status_t lzsa_compress_stream(lzsa_stream_t *pInStream, lzsa_stream_t *pOutStream, const void *pDictionaryData, int nDictionaryDataSize,
                                   const unsigned int nFlags, const int nMinMatchSize, const int nFormatVersion,
                                   void(*progress)(long long nOriginalSize, long long nCompressedSize), long long *pOriginalSize, long long *pCompressedSize, int *pCommandCount, int *pSafeDist, lzsa_stats *pStats) {
   unsigned char *pInData, *pOutData;
   lzsa_compressor compressor;
   long long nOriginalSize = 0LL, nCompressedSize = 0LL;
   int nResult;
   unsigned char cFrameData[16];
   int nError = 0;
   int nRawPadding = (nFlags & LZSA_FLAG_RAW_BLOCK) ? 8 : 0;

   pInData = (unsigned char*)malloc(BLOCK_SIZE * 2);
   if (!pInData) {
      return LZSA_ERROR_MEMORY;
   }
   memset(pInData, 0, BLOCK_SIZE * 2);

   pOutData = (unsigned char*)malloc(BLOCK_SIZE);
   if (!pOutData) {
      free(pInData);
      pInData = NULL;

      return LZSA_ERROR_MEMORY;
   }
   memset(pOutData, 0, BLOCK_SIZE);

   nResult = lzsa_compressor_init(&compressor, BLOCK_SIZE * 2, nMinMatchSize, nFormatVersion, nFlags);
   if (nResult != 0) {
      free(pOutData);
      pOutData = NULL;

      free(pInData);
      pInData = NULL;

      return LZSA_ERROR_MEMORY;
   }

   if ((nFlags & LZSA_FLAG_RAW_BLOCK) == 0) {
      int nHeaderSize = lzsa_encode_header(cFrameData, 16, nFormatVersion);
      if (nHeaderSize < 0)
         nError = LZSA_ERROR_COMPRESSION;
      else {
         if (pOutStream->write(pOutStream, cFrameData, nHeaderSize) != nHeaderSize)
            nError = LZSA_ERROR_DST;
         nCompressedSize += (long long)nHeaderSize;
      }
   }

   int nPreviousBlockSize = 0;
   int nNumBlocks = 0;

   while (!pInStream->eof(pInStream) && !nError) {
      int nInDataSize;

      if (nPreviousBlockSize) {
         memcpy(pInData + BLOCK_SIZE - nPreviousBlockSize, pInData + BLOCK_SIZE, nPreviousBlockSize);
      }
      else if (nDictionaryDataSize && pDictionaryData) {
         nPreviousBlockSize = nDictionaryDataSize;
         memcpy(pInData + BLOCK_SIZE - nPreviousBlockSize, pDictionaryData, nPreviousBlockSize);
      }

      nInDataSize = (int)pInStream->read(pInStream, pInData + BLOCK_SIZE, BLOCK_SIZE);
      if (nInDataSize > 0) {
         if ((nFlags & LZSA_FLAG_RAW_BLOCK) != 0 && nNumBlocks) {
            nError = LZSA_ERROR_RAW_TOOLARGE;
            break;
         }
         nDictionaryDataSize = 0;

         int nOutDataSize;

         nOutDataSize = lzsa_compressor_shrink_block(&compressor, pInData + BLOCK_SIZE - nPreviousBlockSize, nPreviousBlockSize, nInDataSize, pOutData, ((nInDataSize + nRawPadding) >= BLOCK_SIZE) ? BLOCK_SIZE : (nInDataSize + nRawPadding));
         if (nOutDataSize >= 0) {
            /* Write compressed block */

            if ((nFlags & LZSA_FLAG_RAW_BLOCK) == 0) {
               int nBlockheaderSize = lzsa_encode_compressed_block_frame(cFrameData, 16, nOutDataSize);
               if (nBlockheaderSize < 0)
                  nError = LZSA_ERROR_COMPRESSION;
               else {
                  nCompressedSize += (long long)nBlockheaderSize;
                  if (pOutStream->write(pOutStream, cFrameData, nBlockheaderSize) != (size_t)nBlockheaderSize) {
                     nError = LZSA_ERROR_DST;
                  }
               }
            }

            if (!nError) {
               if (pOutStream->write(pOutStream, pOutData, (size_t)nOutDataSize) != (size_t)nOutDataSize) {
                  nError = LZSA_ERROR_DST;
               }
               else {
                  nOriginalSize += (long long)nInDataSize;
                  nCompressedSize += (long long)nOutDataSize;
               }
            }
         }
         else {
            /* Write uncompressible, literal block */

            if ((nFlags & LZSA_FLAG_RAW_BLOCK) != 0) {
               nError = LZSA_ERROR_RAW_UNCOMPRESSED;
               break;
            }

            int nBlockheaderSize = lzsa_encode_uncompressed_block_frame(cFrameData, 16, nInDataSize);
            if (nBlockheaderSize < 0)
               nError = LZSA_ERROR_COMPRESSION;
            else {
               if (pOutStream->write(pOutStream, cFrameData, nBlockheaderSize) != (size_t)nBlockheaderSize) {
                  nError = LZSA_ERROR_DST;
               }
               else {
                  if (pOutStream->write(pOutStream, pInData + BLOCK_SIZE, (size_t)nInDataSize) != (size_t)nInDataSize) {
                     nError = LZSA_ERROR_DST;
                  }
                  else {
                     nOriginalSize += (long long)nInDataSize;
                     nCompressedSize += (long long)nBlockheaderSize + (long long)nInDataSize;
                  }
               }
            }
         }

         nPreviousBlockSize = nInDataSize;
         nNumBlocks++;
      }

      if (!nError && !pInStream->eof(pInStream)) {
         if (progress)
            progress(nOriginalSize, nCompressedSize);
      }
   }

   if (!nError) {
      int nFooterSize;

      if ((nFlags & LZSA_FLAG_RAW_BLOCK) != 0) {
         nFooterSize = 0;
      }
      else {
         nFooterSize = lzsa_encode_footer_frame(cFrameData, 16);
         if (nFooterSize < 0)
            nError = LZSA_ERROR_COMPRESSION;
      }

      if (pOutStream->write(pOutStream, cFrameData, nFooterSize) != nFooterSize)
         nError = LZSA_ERROR_DST;
      nCompressedSize += (long long)nFooterSize;
   }

   if (progress)
      progress(nOriginalSize, nCompressedSize);

   int nCommandCount = lzsa_compressor_get_command_count(&compressor);
   int nSafeDist = compressor.safe_dist;

   if (pStats)
      *pStats = compressor.stats;

   lzsa_compressor_destroy(&compressor);

   free(pOutData);
   pOutData = NULL;

   free(pInData);
   pInData = NULL;

   if (nError) {
      return nError;
   }
   else {
      if (pOriginalSize)
         *pOriginalSize = nOriginalSize;
      if (pCompressedSize)
         *pCompressedSize = nCompressedSize;
      if (pCommandCount)
         *pCommandCount = nCommandCount;
      if (pSafeDist)
         *pSafeDist = nSafeDist;
      return LZSA_OK;
   }
}
