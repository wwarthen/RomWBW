/*
 * lzsa.c - command line compression utility for the LZSA format
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#include <sys/timeb.h>
#else
#include <sys/time.h>
#endif
#include "lib.h"

#define OPT_VERBOSE        1
#define OPT_RAW            2
#define OPT_FAVOR_RATIO    4
#define OPT_RAW_BACKWARD   8
#define OPT_STATS          16

#define TOOL_VERSION "1.3.6"

/*---------------------------------------------------------------------------*/

#ifdef _WIN32
LARGE_INTEGER hpc_frequency;
BOOL hpc_available = FALSE;
#endif

static void do_init_time() {
#ifdef _WIN32
   hpc_frequency.QuadPart = 0;
   hpc_available = QueryPerformanceFrequency(&hpc_frequency);
#endif
}

static long long do_get_time() {
   long long nTime;

#ifdef _WIN32
   if (hpc_available) {
      LARGE_INTEGER nCurTime;

      /* Use HPC hardware for best precision */
      QueryPerformanceCounter(&nCurTime);
      nTime = (long long)(nCurTime.QuadPart * 1000000LL / hpc_frequency.QuadPart);
   }
   else {
      struct _timeb tb;
      _ftime(&tb);

      nTime = ((long long)tb.time * 1000LL + (long long)tb.millitm) * 1000LL;
   }
#else
   struct timeval tm;
   gettimeofday(&tm, NULL);

   nTime = (long long)tm.tv_sec * 1000000LL + (long long)tm.tv_usec;
#endif
   return nTime;
}

/*---------------------------------------------------------------------------*/

static void compression_progress(long long nOriginalSize, long long nCompressedSize) {
   if (nOriginalSize >= 1024 * 1024) {
      fprintf(stdout, "\r%lld => %lld (%g %%)     \b\b\b\b\b", nOriginalSize, nCompressedSize, (double)(nCompressedSize * 100.0 / nOriginalSize));
      fflush(stdout);
   }
}

static int do_compress(const char *pszInFilename, const char *pszOutFilename, const char *pszDictionaryFilename, const unsigned int nOptions, const int nMinMatchSize, const int nFormatVersion) {
   long long nStartTime = 0LL, nEndTime = 0LL;
   long long nOriginalSize = 0LL, nCompressedSize = 0LL;
   int nCommandCount = 0, nSafeDist = 0;
   int nFlags;
   lzsa_status_t nStatus;
   lzsa_stats stats;

   nFlags = 0;
   if (nOptions & OPT_FAVOR_RATIO)
      nFlags |= LZSA_FLAG_FAVOR_RATIO;
   if (nOptions & OPT_RAW)
      nFlags |= LZSA_FLAG_RAW_BLOCK;
   if (nOptions & OPT_RAW_BACKWARD)
      nFlags |= LZSA_FLAG_RAW_BACKWARD;

   if (nOptions & OPT_VERBOSE) {
      nStartTime = do_get_time();
   }

   nStatus = lzsa_compress_file(pszInFilename, pszOutFilename, pszDictionaryFilename, nFlags, nMinMatchSize, nFormatVersion, compression_progress, &nOriginalSize, &nCompressedSize, &nCommandCount, &nSafeDist, &stats);

   if ((nOptions & OPT_VERBOSE)) {
      nEndTime = do_get_time();
   }

   switch (nStatus) {
      case LZSA_ERROR_SRC: fprintf(stderr, "error reading '%s'\n", pszInFilename); break;
      case LZSA_ERROR_DST: fprintf(stderr, "error writing '%s'\n", pszOutFilename); break;
      case LZSA_ERROR_DICTIONARY: fprintf(stderr, "error reading dictionary '%s'\n", pszDictionaryFilename); break;
      case LZSA_ERROR_MEMORY: fprintf(stderr, "out of memory\n"); break;
      case LZSA_ERROR_COMPRESSION: fprintf(stderr, "internal compression error\n"); break;
      case LZSA_ERROR_RAW_TOOLARGE: fprintf(stderr, "error: raw blocks can only be used with files <= 64 Kb\n"); break;
      case LZSA_ERROR_RAW_UNCOMPRESSED: fprintf(stderr, "error: incompressible data needs to be <= 64 Kb in raw blocks\n"); break;
      case LZSA_OK: break;
      default: fprintf(stderr, "unknown compression error %d\n", nStatus); break;
   }

   if (nStatus)
      return 100;

   if ((nOptions & OPT_VERBOSE)) {
      double fDelta = ((double)(nEndTime - nStartTime)) / 1000000.0;
      double fSpeed = ((double)nOriginalSize / 1048576.0) / fDelta;
      fprintf(stdout, "\rCompressed '%s' in %g seconds, %.02g Mb/s, %d tokens (%g bytes/token), %lld into %lld bytes ==> %g %%\n",
         pszInFilename, fDelta, fSpeed, nCommandCount, (double)nOriginalSize / (double)nCommandCount,
         nOriginalSize, nCompressedSize, (double)(nCompressedSize * 100.0 / nOriginalSize));
      if (nOptions & OPT_RAW) {
         fprintf(stdout, "Safe distance: %d (0x%X)\n", nSafeDist, nSafeDist);
      }
   }

   if (nOptions & OPT_STATS) {
      if (stats.literals_divisor > 0)
         fprintf(stdout, "Literals: min: %d avg: %d max: %d count: %d\n", stats.min_literals, stats.total_literals / stats.literals_divisor, stats.max_literals, stats.literals_divisor);
      else
         fprintf(stdout, "Literals: none\n");
      if (stats.match_divisor > 0) {
         fprintf(stdout, "Offsets: min: %d avg: %d max: %d reps: %d count: %d\n", stats.min_offset, stats.total_offsets / stats.match_divisor, stats.max_offset, stats.num_rep_offsets, stats.match_divisor);
         fprintf(stdout, "Match lens: min: %d avg: %d max: %d count: %d\n", stats.min_match_len, stats.total_match_lens / stats.match_divisor, stats.max_match_len, stats.match_divisor);
      }
      else {
         fprintf(stdout, "Offsets: none\n");
         fprintf(stdout, "Match lens: none\n");
      }
      if (stats.rle1_divisor > 0) {
         fprintf(stdout, "RLE1 lens: min: %d avg: %d max: %d count: %d\n", stats.min_rle1_len, stats.total_rle1_lens / stats.rle1_divisor, stats.max_rle1_len, stats.rle1_divisor);
      }
      else {
         fprintf(stdout, "RLE1 lens: none\n");
      }
      if (stats.rle2_divisor > 0) {
         fprintf(stdout, "RLE2 lens: min: %d avg: %d max: %d count: %d\n", stats.min_rle2_len, stats.total_rle2_lens / stats.rle2_divisor, stats.max_rle2_len, stats.rle2_divisor);
      }
      else {
         fprintf(stdout, "RLE2 lens: none\n");
      }
   }
   return 0;
}

/*---------------------------------------------------------------------------*/

static int do_decompress(const char *pszInFilename, const char *pszOutFilename, const char *pszDictionaryFilename, const unsigned int nOptions, int nFormatVersion) {
   long long nStartTime = 0LL, nEndTime = 0LL;
   long long nOriginalSize = 0LL, nCompressedSize = 0LL;
   lzsa_status_t nStatus;
   int nFlags;

   nFlags = 0;
   if (nOptions & OPT_RAW)
      nFlags |= LZSA_FLAG_RAW_BLOCK;
   if (nOptions & OPT_RAW_BACKWARD)
      nFlags |= LZSA_FLAG_RAW_BACKWARD;

   if (nOptions & OPT_VERBOSE) {
      nStartTime = do_get_time();
   }

   nStatus = lzsa_decompress_file(pszInFilename, pszOutFilename, pszDictionaryFilename, nFlags, nFormatVersion, &nOriginalSize, &nCompressedSize);

   switch (nStatus) {
   case LZSA_ERROR_SRC: fprintf(stderr, "error reading '%s'\n", pszInFilename); break;
   case LZSA_ERROR_DST: fprintf(stderr, "error writing '%s'\n", pszOutFilename); break;
   case LZSA_ERROR_DICTIONARY: fprintf(stderr, "error reading dictionary '%s'\n", pszDictionaryFilename); break;
   case LZSA_ERROR_MEMORY: fprintf(stderr, "out of memory\n"); break;
   case LZSA_ERROR_DECOMPRESSION: fprintf(stderr, "internal decompression error\n"); break;
   case LZSA_ERROR_FORMAT: fprintf(stderr, "invalid magic number or format version in input file\n"); break;
   case LZSA_OK: break;
   default: fprintf(stderr, "unknown decompression error %d\n", nStatus); break;
   }

   if (nStatus) {
      fprintf(stderr, "decompression error for '%s'\n", pszInFilename);
      return 100;
   }
   else {
      if (nOptions & OPT_VERBOSE) {
         nEndTime = do_get_time();
         double fDelta = ((double)(nEndTime - nStartTime)) / 1000000.0;
         double fSpeed = ((double)nOriginalSize / 1048576.0) / fDelta;
         fprintf(stdout, "Decompressed '%s' in %g seconds, %g Mb/s\n",
            pszInFilename, fDelta, fSpeed);
      }

      return 0;
   }
}

/*---------------------------------------------------------------------------*/

typedef struct {
   FILE *f;
   void *pCompareDataBuf;
   size_t nCompareDataSize;
} compare_stream_t;

void comparestream_close(lzsa_stream_t *stream) {
   if (stream->obj) {
      compare_stream_t *pCompareStream = (compare_stream_t *)stream->obj;
      if (pCompareStream->pCompareDataBuf) {
         free(pCompareStream->pCompareDataBuf);
         pCompareStream->pCompareDataBuf = NULL;
      }
      
      fclose(pCompareStream->f);
      free(pCompareStream);

      stream->obj = NULL;
      stream->read = NULL;
      stream->write = NULL;
      stream->eof = NULL;
      stream->close = NULL;
   }
}

size_t comparestream_read(lzsa_stream_t *stream, void *ptr, size_t size) {
   return 0;
}

size_t comparestream_write(lzsa_stream_t *stream, void *ptr, size_t size) {
   compare_stream_t *pCompareStream = (compare_stream_t *)stream->obj;

   if (!pCompareStream->pCompareDataBuf || pCompareStream->nCompareDataSize < size) {
      pCompareStream->nCompareDataSize = size;
      pCompareStream->pCompareDataBuf = realloc(pCompareStream->pCompareDataBuf, pCompareStream->nCompareDataSize);
      if (!pCompareStream->pCompareDataBuf)
         return 0;
   }

   size_t nReadBytes = fread(pCompareStream->pCompareDataBuf, 1, size, pCompareStream->f);
   if (nReadBytes != size) {
      return 0;
   }

   if (memcmp(ptr, pCompareStream->pCompareDataBuf, size)) {
      return 0;
   }

   return size;
}

int comparestream_eof(lzsa_stream_t *stream) {
   compare_stream_t *pCompareStream = (compare_stream_t *)stream->obj;
   return feof(pCompareStream->f);
}

int comparestream_open(lzsa_stream_t *stream, const char *pszCompareFilename, const char *pszMode) {
   compare_stream_t *pCompareStream;

   pCompareStream = (compare_stream_t*)malloc(sizeof(compare_stream_t));
   if (!pCompareStream)
      return -1;

   pCompareStream->pCompareDataBuf = NULL;
   pCompareStream->nCompareDataSize = 0;
   pCompareStream->f = (FILE*)fopen(pszCompareFilename, pszMode);

   if (pCompareStream->f) {
      stream->obj = pCompareStream;
      stream->read = comparestream_read;
      stream->write = comparestream_write;
      stream->eof = comparestream_eof;
      stream->close = comparestream_close;
      return 0;
   }
   else {
      free(pCompareStream);
      return -1;
   }
}

static int do_compare(const char *pszInFilename, const char *pszOutFilename, const char *pszDictionaryFilename, const unsigned int nOptions, int nFormatVersion) {
   lzsa_stream_t inStream, compareStream;
   long long nStartTime = 0LL, nEndTime = 0LL;
   long long nOriginalSize = 0LL;
   long long nCompressedSize = 0LL;
   void *pDictionaryData = NULL;
   int nDictionaryDataSize = 0;
   lzsa_status_t nStatus;
   int nFlags;

   if (lzsa_filestream_open(&inStream, pszInFilename, "rb") < 0) {
      fprintf(stderr, "error opening compressed input file\n");
      return 100;
   }

   if (comparestream_open(&compareStream, pszOutFilename, "rb") < 0) {
      fprintf(stderr, "error opening original uncompressed file\n");
      inStream.close(&inStream);
      return 100;
   }

   nStatus = lzsa_dictionary_load(pszDictionaryFilename, &pDictionaryData, &nDictionaryDataSize);
   if (nStatus) {
      compareStream.close(&compareStream);
      inStream.close(&inStream);
      fprintf(stderr, "error reading dictionary '%s'\n", pszDictionaryFilename);
      return 100;
   }

   nFlags = 0;
   if (nOptions & OPT_RAW)
      nFlags |= LZSA_FLAG_RAW_BLOCK;
   if (nOptions & OPT_RAW_BACKWARD)
      nFlags |= LZSA_FLAG_RAW_BACKWARD;

   if (nOptions & OPT_VERBOSE) {
      nStartTime = do_get_time();
   }

   nStatus = lzsa_decompress_stream(&inStream, &compareStream, pDictionaryData, nDictionaryDataSize, nFlags, nFormatVersion, &nOriginalSize, &nCompressedSize);

   switch (nStatus) {
   case LZSA_ERROR_SRC: fprintf(stderr, "error reading '%s'\n", pszInFilename); break;
   case LZSA_ERROR_DST: fprintf(stderr, "error comparing compressed file '%s' with original '%s'\n", pszInFilename, pszOutFilename); break;
   case LZSA_ERROR_MEMORY: fprintf(stderr, "out of memory\n"); break;
   case LZSA_ERROR_DECOMPRESSION: fprintf(stderr, "internal decompression error\n"); break;
   case LZSA_ERROR_FORMAT: fprintf(stderr, "invalid magic number or format version in input file\n"); break;
   case LZSA_OK: break;
   default: fprintf(stderr, "unknown decompression error %d\n", nStatus); break;
   }

   lzsa_dictionary_free(&pDictionaryData);
   compareStream.close(&compareStream);
   inStream.close(&inStream);

   if (nStatus) {
      return 100;
   }
   else {
      if (nOptions & OPT_VERBOSE) {
         nEndTime = do_get_time();
         double fDelta = ((double)(nEndTime - nStartTime)) / 1000000.0;
         double fSpeed = ((double)nOriginalSize / 1048576.0) / fDelta;
         fprintf(stdout, "Compared '%s' in %g seconds, %g Mb/s\n",
            pszInFilename, fDelta, fSpeed);
      }

      return 0;
   }
}

/*---------------------------------------------------------------------------*/

static void generate_compressible_data(unsigned char *pBuffer, size_t nBufferSize, int nMinMatchSize, unsigned int nSeed, int nNumLiteralValues, float fMatchProbability) {
   size_t nIndex = 0;
   int nMatchProbability = (int)(fMatchProbability * 1023.0f);

   srand(nSeed);
   
   if (nIndex >= nBufferSize) return;
   pBuffer[nIndex++] = rand() % nNumLiteralValues;

   while (nIndex < nBufferSize) {
      if ((rand() & 1023) >= nMatchProbability) {
         size_t nLiteralCount = rand() & 127;
         if (nLiteralCount > (nBufferSize - nIndex))
            nLiteralCount = nBufferSize - nIndex;

         while (nLiteralCount--)
            pBuffer[nIndex++] = rand() % nNumLiteralValues;
      }
      else {
         size_t nMatchLength = nMinMatchSize + (rand() & 1023);
         size_t nMatchOffset;

         if (nMatchLength > (nBufferSize - nIndex))
            nMatchLength = nBufferSize - nIndex;
         if (nMatchLength > nIndex)
            nMatchLength = nIndex;

         if (nMatchLength < nIndex)
            nMatchOffset = rand() % (nIndex - nMatchLength);
         else
            nMatchOffset = 0;

         while (nMatchLength--) {
            pBuffer[nIndex] = pBuffer[nIndex - nMatchOffset];
            nIndex++;
         }
      }
   }
}

static void xor_data(unsigned char *pBuffer, size_t nBufferSize, unsigned int nSeed, float fXorProbability) {
   size_t nIndex = 0;
   int nXorProbability = (int)(fXorProbability * 1023.0f);

   srand(nSeed);

   if (nIndex >= nBufferSize) return;

   while (nIndex < nBufferSize) {
      if ((rand() & 1023) < nXorProbability) {
         pBuffer[nIndex] ^= 0xff;
      }
      nIndex++;
   }
}

static int do_self_test(const unsigned int nOptions, const int nMinMatchSize, int nFormatVersion) {
   unsigned char *pGeneratedData;
   unsigned char *pCompressedData;
   unsigned char *pTmpCompressedData;
   unsigned char *pTmpDecompressedData;
   size_t nGeneratedDataSize;
   size_t nMaxCompressedDataSize;
   unsigned int nSeed = 123;
   int nFlags;
   int i;

   nFlags = 0;
   if (nOptions & OPT_FAVOR_RATIO)
      nFlags |= LZSA_FLAG_FAVOR_RATIO;
   if (nOptions & OPT_RAW)
      nFlags |= LZSA_FLAG_RAW_BLOCK;
   if (nOptions & OPT_RAW_BACKWARD)
      nFlags |= LZSA_FLAG_RAW_BACKWARD;

   pGeneratedData = (unsigned char*)malloc(4 * BLOCK_SIZE);
   if (!pGeneratedData) {
      fprintf(stderr, "out of memory, %d bytes needed\n", 4 * BLOCK_SIZE);
      return 100;
   }

   nMaxCompressedDataSize = lzsa_get_max_compressed_size_inmem(4 * BLOCK_SIZE);
   pCompressedData = (unsigned char*)malloc(nMaxCompressedDataSize);
   if (!pCompressedData) {
      free(pGeneratedData);
      pGeneratedData = NULL;

      fprintf(stderr, "out of memory, %zd bytes needed\n", nMaxCompressedDataSize);
      return 100;
   }

   pTmpCompressedData = (unsigned char*)malloc(nMaxCompressedDataSize);
   if (!pTmpCompressedData) {
      free(pCompressedData);
      pCompressedData = NULL;
      free(pGeneratedData);
      pGeneratedData = NULL;

      fprintf(stderr, "out of memory, %zd bytes needed\n", nMaxCompressedDataSize);
      return 100;
   }

   pTmpDecompressedData = (unsigned char*)malloc(4 * BLOCK_SIZE);
   if (!pTmpDecompressedData) {
      free(pTmpCompressedData);
      pTmpCompressedData = NULL;
      free(pCompressedData);
      pCompressedData = NULL;
      free(pGeneratedData);
      pGeneratedData = NULL;

      fprintf(stderr, "out of memory, %d bytes needed\n", 4 * BLOCK_SIZE);
      return 100;
   }

   memset(pGeneratedData, 0, 4 * BLOCK_SIZE);
   memset(pCompressedData, 0, nMaxCompressedDataSize);
   memset(pTmpCompressedData, 0, nMaxCompressedDataSize);

   /* Test compressing with a too small buffer to do anything, expect to fail cleanly */
   for (i = 0; i < 12; i++) {
      generate_compressible_data(pGeneratedData, i, nMinMatchSize, nSeed, 256, 0.5f);
      lzsa_compress_inmem(pGeneratedData, pCompressedData, i, i, nFlags, nMinMatchSize, nFormatVersion);
   }

   size_t nDataSizeStep = 128;
   float fProbabilitySizeStep = 0.0005f;

   for (nGeneratedDataSize = 1024; nGeneratedDataSize <= ((size_t)((nOptions & OPT_RAW) ? BLOCK_SIZE : (4 * BLOCK_SIZE))); nGeneratedDataSize += nDataSizeStep) {
      float fMatchProbability;

      fprintf(stdout, "size %zd", nGeneratedDataSize);
      for (fMatchProbability = 0; fMatchProbability <= 0.995f; fMatchProbability += fProbabilitySizeStep) {
         int nNumLiteralValues[12] = { 1, 2, 3, 15, 30, 56, 96, 137, 178, 191, 255, 256 };
         float fXorProbability;

         fputc('.', stdout);
         fflush(stdout);

         for (i = 0; i < 12; i++) {
            /* Generate data to compress */
            generate_compressible_data(pGeneratedData, nGeneratedDataSize, nMinMatchSize, nSeed, nNumLiteralValues[i], fMatchProbability);

            /* Try to compress it, expected to succeed */
            size_t nActualCompressedSize = lzsa_compress_inmem(pGeneratedData, pCompressedData, nGeneratedDataSize, lzsa_get_max_compressed_size_inmem(nGeneratedDataSize),
               nFlags, nMinMatchSize, nFormatVersion);
            if (nActualCompressedSize == -1 || (int)nActualCompressedSize < (lzsa_get_header_size() + lzsa_get_frame_size() + lzsa_get_frame_size() /* footer */)) {
               free(pTmpDecompressedData);
               pTmpDecompressedData = NULL;
               free(pTmpCompressedData);
               pTmpCompressedData = NULL;
               free(pCompressedData);
               pCompressedData = NULL;
               free(pGeneratedData);
               pGeneratedData = NULL;

               fprintf(stderr, "\nself-test: error compressing size %zd, seed %d, match probability %f, literals range %d\n", nGeneratedDataSize, nSeed, fMatchProbability, nNumLiteralValues[i]);
               return 100;
            }

            /* Try to decompress it, expected to succeed */
            size_t nActualDecompressedSize;
            int nDecFormatVersion = nFormatVersion;
            nActualDecompressedSize = lzsa_decompress_inmem(pCompressedData, pTmpDecompressedData, nActualCompressedSize, nGeneratedDataSize, nFlags, &nDecFormatVersion);
            if (nActualDecompressedSize == -1) {
               free(pTmpDecompressedData);
               pTmpDecompressedData = NULL;
               free(pTmpCompressedData);
               pTmpCompressedData = NULL;
               free(pCompressedData);
               pCompressedData = NULL;
               free(pGeneratedData);
               pGeneratedData = NULL;

               fprintf(stderr, "\nself-test: error decompressing size %zd, seed %d, match probability %f, literals range %d\n", nGeneratedDataSize, nSeed, fMatchProbability, nNumLiteralValues[i]);
               return 100;
            }

            if (memcmp(pGeneratedData, pTmpDecompressedData, nGeneratedDataSize)) {
               free(pTmpDecompressedData);
               pTmpDecompressedData = NULL;
               free(pTmpCompressedData);
               pTmpCompressedData = NULL;
               free(pCompressedData);
               pCompressedData = NULL;
               free(pGeneratedData);
               pGeneratedData = NULL;

               fprintf(stderr, "\nself-test: error comparing decompressed and original data, size %zd, seed %d, match probability %f, literals range %d\n", nGeneratedDataSize, nSeed, fMatchProbability, nNumLiteralValues[i]);
               return 100;
            }

            /* Try to decompress corrupted data, expected to fail cleanly, without crashing or corrupting memory outside the output buffer */
            for (fXorProbability = 0.05f; fXorProbability <= 0.5f; fXorProbability += 0.05f) {
               memcpy(pTmpCompressedData, pCompressedData, nActualCompressedSize);
               xor_data(pTmpCompressedData + lzsa_get_header_size() + lzsa_get_frame_size(), nActualCompressedSize - lzsa_get_header_size() - lzsa_get_frame_size() - lzsa_get_frame_size() /* footer */, nSeed, fXorProbability);
               nDecFormatVersion = nFormatVersion;
               lzsa_decompress_inmem(pTmpCompressedData, pGeneratedData, nActualCompressedSize, nGeneratedDataSize, nFlags, &nDecFormatVersion);
            }
         }

         nSeed++;
      }

      fputc(10, stdout);
      fflush(stdout);

      nDataSizeStep <<= 1;
      if (nDataSizeStep > (128 * 4096))
         nDataSizeStep = 128 * 4096;
      fProbabilitySizeStep *= 1.25;
      if (fProbabilitySizeStep > (0.0005f * 4096))
         fProbabilitySizeStep = 0.0005f * 4096;
   }

   free(pTmpDecompressedData);
   pTmpDecompressedData = NULL;

   free(pTmpCompressedData);
   pTmpCompressedData = NULL;

   free(pCompressedData);
   pCompressedData = NULL;

   free(pGeneratedData);
   pGeneratedData = NULL;

   fprintf(stdout, "All tests passed.\n");
   return 0;
}

/*---------------------------------------------------------------------------*/

static int do_compr_benchmark(const char *pszInFilename, const char *pszOutFilename, const char *pszDictionaryFilename, const unsigned int nOptions, const int nMinMatchSize, int nFormatVersion) {
   size_t nFileSize, nMaxCompressedSize;
   unsigned char *pFileData;
   unsigned char *pCompressedData;
   int nFlags;
   int i;

   nFlags = 0;
   if (nOptions & OPT_FAVOR_RATIO)
      nFlags |= LZSA_FLAG_FAVOR_RATIO;
   if (nOptions & OPT_RAW)
      nFlags |= LZSA_FLAG_RAW_BLOCK;
   if (nOptions & OPT_RAW_BACKWARD)
      nFlags |= LZSA_FLAG_RAW_BACKWARD;

   if (pszDictionaryFilename) {
      fprintf(stderr, "in-memory benchmarking does not support dictionaries\n");
      return 100;
   }

   /* Read the whole original file in memory */

   FILE *f_in = fopen(pszInFilename, "rb");
   if (!f_in) {
      fprintf(stderr, "error opening '%s' for reading\n", pszInFilename);
      return 100;
   }

   fseek(f_in, 0, SEEK_END);
   nFileSize = (size_t)ftell(f_in);
   fseek(f_in, 0, SEEK_SET);

   pFileData = (unsigned char*)malloc(nFileSize);
   if (!pFileData) {
      fclose(f_in);
      fprintf(stderr, "out of memory for reading '%s', %zd bytes needed\n", pszInFilename, nFileSize);
      return 100;
   }

   if (fread(pFileData, 1, nFileSize, f_in) != nFileSize) {
      free(pFileData);
      fclose(f_in);
      fprintf(stderr, "I/O error while reading '%s'\n", pszInFilename);
      return 100;
   }

   fclose(f_in);

   /* Allocate max compressed size */

   nMaxCompressedSize = lzsa_get_max_compressed_size_inmem(nFileSize);

   pCompressedData = (unsigned char*)malloc(nMaxCompressedSize + 2048);
   if (!pCompressedData) {
      free(pFileData);
      fprintf(stderr, "out of memory for compressing '%s', %zd bytes needed\n", pszInFilename, nMaxCompressedSize);
      return 100;
   }

   memset(pCompressedData + 1024, 0, nMaxCompressedSize);

   long long nBestCompTime = -1;

   size_t nActualCompressedSize = 0;
   size_t nRightGuardPos = nMaxCompressedSize;

   for (i = 0; i < 5; i++) {
      unsigned char nGuard = 0x33 + i;
      int j;

      /* Write guard bytes around the output buffer, to help check for writes outside of it by the compressor */
      memset(pCompressedData, nGuard, 1024);
      memset(pCompressedData + 1024 + nRightGuardPos, nGuard, 1024);

      long long t0 = do_get_time();
      nActualCompressedSize = lzsa_compress_inmem(pFileData, pCompressedData + 1024, nFileSize, nRightGuardPos, nFlags, nMinMatchSize, nFormatVersion);
      long long t1 = do_get_time();
      if (nActualCompressedSize == -1) {
         free(pCompressedData);
         free(pFileData);
         fprintf(stderr, "compression error\n");
         return 100;
      }

      long long nCurDecTime = t1 - t0;
      if (nBestCompTime == -1 || nBestCompTime > nCurDecTime)
         nBestCompTime = nCurDecTime;

      /* Check guard bytes before the output buffer */
      for (j = 0; j < 1024; j++) {
         if (pCompressedData[j] != nGuard) {
            free(pCompressedData);
            free(pFileData);
            fprintf(stderr, "error, wrote outside of output buffer at %d!\n", j - 1024);
            return 100;
         }
      }

      /* Check guard bytes after the output buffer */
      for (j = 0; j < 1024; j++) {
         if (pCompressedData[1024 + nRightGuardPos + j] != nGuard) {
            free(pCompressedData);
            free(pFileData);
            fprintf(stderr, "error, wrote outside of output buffer at %d!\n", j);
            return 100;
         }
      }

      nRightGuardPos = nActualCompressedSize;
   }

   if (pszOutFilename) {
      FILE *f_out;

      /* Write whole compressed file out */

      f_out = fopen(pszOutFilename, "wb");
      if (f_out) {
         fwrite(pCompressedData + 1024, 1, nActualCompressedSize, f_out);
         fclose(f_out);
      }
   }

   free(pCompressedData);
   free(pFileData);

   fprintf(stdout, "compressed size: %zd bytes\n", nActualCompressedSize);
   fprintf(stdout, "compression time: %lld microseconds (%g Mb/s)\n", nBestCompTime, ((double)nActualCompressedSize / 1024.0) / ((double)nBestCompTime / 1000.0));

   return 0;
}

/*---------------------------------------------------------------------------*/

static int do_dec_benchmark(const char *pszInFilename, const char *pszOutFilename, const char *pszDictionaryFilename, const unsigned int nOptions, int nFormatVersion) {
   size_t nFileSize, nMaxDecompressedSize;
   unsigned char *pFileData;
   unsigned char *pDecompressedData;
   int nFlags;
   int i;

   nFlags = 0;
   if (nOptions & OPT_RAW)
      nFlags |= LZSA_FLAG_RAW_BLOCK;
   if (nOptions & OPT_RAW_BACKWARD)
      nFlags |= LZSA_FLAG_RAW_BACKWARD;

   if (pszDictionaryFilename) {
      fprintf(stderr, "in-memory benchmarking does not support dictionaries\n");
      return 100;
   }

   /* Read the whole compressed file in memory */

   FILE *f_in = fopen(pszInFilename, "rb");
   if (!f_in) {
      fprintf(stderr, "error opening '%s' for reading\n", pszInFilename);
      return 100;
   }

   fseek(f_in, 0, SEEK_END);
   nFileSize = (size_t)ftell(f_in);
   fseek(f_in, 0, SEEK_SET);

   pFileData = (unsigned char*)malloc(nFileSize);
   if (!pFileData) {
      fclose(f_in);
      fprintf(stderr, "out of memory for reading '%s', %zd bytes needed\n", pszInFilename, nFileSize);
      return 100;
   }

   if (fread(pFileData, 1, nFileSize, f_in) != nFileSize) {
      free(pFileData);
      fclose(f_in);
      fprintf(stderr, "I/O error while reading '%s'\n", pszInFilename);
      return 100;
   }

   fclose(f_in);

   /* Allocate max decompressed size */

   if (nOptions & OPT_RAW)
      nMaxDecompressedSize = 65536;
   else
      nMaxDecompressedSize = lzsa_get_max_decompressed_size_inmem(pFileData, nFileSize);
   if (nMaxDecompressedSize == -1) {
      free(pFileData);
      fprintf(stderr, "invalid compressed format for file '%s'\n", pszInFilename);
      return 100;
   }

   pDecompressedData = (unsigned char*)malloc(nMaxDecompressedSize);
   if (!pDecompressedData) {
      free(pFileData);
      fprintf(stderr, "out of memory for decompressing '%s', %zd bytes needed\n", pszInFilename, nMaxDecompressedSize);
      return 100;
   }

   memset(pDecompressedData, 0, nMaxDecompressedSize);

   long long nBestDecTime = -1;

   size_t nActualDecompressedSize = 0;
   for (i = 0; i < 50; i++) {
      long long t0 = do_get_time();
      nActualDecompressedSize = lzsa_decompress_inmem(pFileData, pDecompressedData, nFileSize, nMaxDecompressedSize, nFlags, &nFormatVersion);
      long long t1 = do_get_time();
      if (nActualDecompressedSize == -1) {
         free(pDecompressedData);
         free(pFileData);
         fprintf(stderr, "decompression error\n");
         return 100;
      }

      long long nCurDecTime = t1 - t0;
      if (nBestDecTime == -1 || nBestDecTime > nCurDecTime)
         nBestDecTime = nCurDecTime;
   }

   if (pszOutFilename) {
      FILE *f_out;

      /* Write whole decompressed file out */

      f_out = fopen(pszOutFilename, "wb");
      if (f_out) {
         fwrite(pDecompressedData, 1, nActualDecompressedSize, f_out);
         fclose(f_out);
      }
   }

   free(pDecompressedData);
   free(pFileData);

   fprintf(stdout, "format: LZSA%d\n", nFormatVersion);
   fprintf(stdout, "decompressed size: %zd bytes\n", nActualDecompressedSize);
   fprintf(stdout, "decompression time: %lld microseconds (%g Mb/s)\n", nBestDecTime, ((double)nActualDecompressedSize / 1024.0) / ((double)nBestDecTime / 1000.0));

   return 0;
}

/*---------------------------------------------------------------------------*/

int main(int argc, char **argv) {
   int i;
   const char *pszInFilename = NULL;
   const char *pszOutFilename = NULL;
   const char *pszDictionaryFilename = NULL;
   int nArgsError = 0;
   int nCommandDefined = 0;
   int nVerifyCompression = 0;
   int nMinMatchDefined = 0;
   int nFormatVersionDefined = 0;
   char cCommand = 'z';
   int nMinMatchSize = 0;
   unsigned int nOptions = OPT_FAVOR_RATIO;
   int nFormatVersion = 1;

   for (i = 1; i < argc; i++) {
      if (!strcmp(argv[i], "-d")) {
         if (!nCommandDefined) {
            nCommandDefined = 1;
            cCommand = 'd';
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-z")) {
         if (!nCommandDefined) {
            nCommandDefined = 1;
            cCommand = 'z';
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-c")) {
         if (!nVerifyCompression) {
            nVerifyCompression = 1;
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-cbench")) {
         if (!nCommandDefined) {
            nCommandDefined = 1;
            cCommand = 'B';
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-dbench")) {
         if (!nCommandDefined) {
            nCommandDefined = 1;
            cCommand = 'b';
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-test")) {
         if (!nCommandDefined) {
            nCommandDefined = 1;
            cCommand = 't';
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-D")) {
         if (!pszDictionaryFilename && (i + 1) < argc) {
            pszDictionaryFilename = argv[i + 1];
            i++;
         }
         else
            nArgsError = 1;
      }
      else if (!strncmp(argv[i], "-D", 2)) {
         if (!pszDictionaryFilename) {
            pszDictionaryFilename = argv[i] + 2;
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-m")) {
         if (!nMinMatchDefined && (i + 1) < argc) {
            char *pEnd = NULL;
            nMinMatchSize = (int)strtol(argv[i + 1], &pEnd, 10);
            if (pEnd && pEnd != argv[i + 1] && (nMinMatchSize >= 2 && nMinMatchSize <= 5)) {
               i++;
               nMinMatchDefined = 1;
               nOptions &= (~OPT_FAVOR_RATIO);
            }
            else {
               nArgsError = 1;
            }
         }
         else
            nArgsError = 1;
      }
      else if (!strncmp(argv[i], "-m", 2)) {
         if (!nMinMatchDefined) {
            char *pEnd = NULL;
            nMinMatchSize = (int)strtol(argv[i] + 2, &pEnd, 10);
            if (pEnd && pEnd != (argv[i]+2) && (nMinMatchSize >= 2 && nMinMatchSize <= 5)) {
               nMinMatchDefined = 1;
               nOptions &= (~OPT_FAVOR_RATIO);
            }
            else {
               nArgsError = 1;
            }
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "--prefer-ratio")) {
         if (!nMinMatchDefined) {
            nMinMatchSize = 0;
            nMinMatchDefined = 1;
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "--prefer-speed")) {
         if (!nMinMatchDefined) {
            nMinMatchSize = 3;
            nOptions &= (~OPT_FAVOR_RATIO);
            nMinMatchDefined = 1;
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-f")) {
         if (!nFormatVersionDefined && (i + 1) < argc) {
            char *pEnd = NULL;
            nFormatVersion = (int)strtol(argv[i + 1], &pEnd, 10);
            if (pEnd && pEnd != argv[i + 1] && (nFormatVersion >= 1 && nFormatVersion <= 2)) {
               i++;
               nFormatVersionDefined = 1;
            }
            else {
               nArgsError = 1;
            }
         }
         else
            nArgsError = 1;
      }
      else if (!strncmp(argv[i], "-f", 2)) {
         if (!nFormatVersionDefined) {
            char *pEnd = NULL;
            nFormatVersion = (int)strtol(argv[i] + 2, &pEnd, 10);
            if (pEnd && pEnd != (argv[i] + 2) && (nFormatVersion >= 1 && nFormatVersion <= 2)) {
               nFormatVersionDefined = 1;
            }
            else {
               nArgsError = 1;
            }
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-v")) {
         if ((nOptions & OPT_VERBOSE) == 0) {
            nOptions |= OPT_VERBOSE;
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-r")) {
         if ((nOptions & OPT_RAW) == 0) {
            nOptions |= OPT_RAW;
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-b")) {
         if ((nOptions & OPT_RAW_BACKWARD) == 0) {
            nOptions |= OPT_RAW_BACKWARD;
         }
         else
            nArgsError = 1;
      }
      else if (!strcmp(argv[i], "-stats")) {
      if ((nOptions & OPT_STATS) == 0) {
         nOptions |= OPT_STATS;
      }
      else
         nArgsError = 1;
      }
      else {
         if (!pszInFilename)
            pszInFilename = argv[i];
         else {
            if (!pszOutFilename)
               pszOutFilename = argv[i];
            else
               nArgsError = 1;
         }
      }
   }

   if (!nArgsError && (nOptions & OPT_RAW_BACKWARD) && !(nOptions & OPT_RAW)) {
      fprintf(stderr, "error: -b (compress backwards) requires -r (raw block format)\n");
      return 100;
   }

   if (!nArgsError && cCommand == 't') {
      return do_self_test(nOptions, nMinMatchSize, nFormatVersion);
   }

   if (nArgsError || !pszInFilename || !pszOutFilename) {
      fprintf(stderr, "lzsa command-line tool v" TOOL_VERSION " by Emmanuel Marty and spke\n");
      fprintf(stderr, "usage: %s [-c] [-d] [-v] [-r] <infile> <outfile>\n", argv[0]);
      fprintf(stderr, "       -c: check resulting stream after compressing\n");
      fprintf(stderr, "       -d: decompress (default: compress)\n");
      fprintf(stderr, "  -cbench: benchmark in-memory compression\n");
      fprintf(stderr, "  -dbench: benchmark in-memory decompression\n");
      fprintf(stderr, "    -test: run automated self-tests\n");
      fprintf(stderr, "   -stats: show compressed data stats\n");
      fprintf(stderr, "       -v: be verbose\n");
      fprintf(stderr, "       -f <value>: LZSA compression format (1-2)\n");
      fprintf(stderr, "       -r: raw block format (max. 64 Kb files)\n");
      fprintf(stderr, "       -b: compress backward (requires -r and a backward decompressor)\n");
      fprintf(stderr, "       -D <filename>: use dictionary file\n");
      fprintf(stderr, "       -m <value>: minimum match size (3-5) (default: 3)\n");
      fprintf(stderr, "       --prefer-ratio: favor compression ratio (default)\n");
      fprintf(stderr, "       --prefer-speed: favor decompression speed (same as -m3)\n");
      return 100;
   }

   do_init_time();

   if (cCommand == 'z') {
      int nResult = do_compress(pszInFilename, pszOutFilename, pszDictionaryFilename, nOptions, nMinMatchSize, nFormatVersion);
      if (nResult == 0 && nVerifyCompression) {
         return do_compare(pszOutFilename, pszInFilename, pszDictionaryFilename, nOptions, nFormatVersion);
      } else {
         return nResult;
      }
   }
   else if (cCommand == 'd') {
      return do_decompress(pszInFilename, pszOutFilename, pszDictionaryFilename, nOptions, nFormatVersion);
   }
   else if (cCommand == 'B') {
      return do_compr_benchmark(pszInFilename, pszOutFilename, pszDictionaryFilename, nOptions, nMinMatchSize, nFormatVersion);
   }
   else if (cCommand == 'b') {
      return do_dec_benchmark(pszInFilename, pszOutFilename, pszDictionaryFilename, nOptions, nFormatVersion);
   }
   else {
      return 100;
   }
}
