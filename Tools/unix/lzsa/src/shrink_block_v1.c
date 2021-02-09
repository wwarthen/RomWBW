/*
 * shrink_block_v1.c - LZSA1 block compressor implementation
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
#include "lib.h"
#include "shrink_block_v1.h"
#include "format.h"

/**
 * Get the number of extra bits required to represent a literals length
 *
 * @param nLength literals length
 *
 * @return number of extra bits required
 */
static inline int lzsa_get_literals_varlen_size_v1(const int nLength) {
   if (nLength < LITERALS_RUN_LEN_V1) {
      return 0;
   }
   else {
      if (nLength < 256)
         return 8;
      else {
         if (nLength < 512)
            return 16;
         else
            return 24;
      }
   }
}

/**
 * Write extra literals length bytes to output (compressed) buffer. The caller must first check that there is enough
 * room to write the bytes.
 *
 * @param pOutData pointer to output buffer
 * @param nOutOffset current write index into output buffer
 * @param nLength literals length
 */
static inline int lzsa_write_literals_varlen_v1(unsigned char *pOutData, int nOutOffset, int nLength) {
   if (nLength >= LITERALS_RUN_LEN_V1) {
      if (nLength < 256)
         pOutData[nOutOffset++] = nLength - LITERALS_RUN_LEN_V1;
      else {
         if (nLength < 512) {
            pOutData[nOutOffset++] = 250;
            pOutData[nOutOffset++] = nLength - 256;
         }
         else {
            pOutData[nOutOffset++] = 249;
            pOutData[nOutOffset++] = nLength & 0xff;
            pOutData[nOutOffset++] = (nLength >> 8) & 0xff;
         }
      }
   }

   return nOutOffset;
}

/**
 * Get the number of extra bits required to represent an encoded match length
 *
 * @param nLength encoded match length (actual match length - MIN_MATCH_SIZE_V1)
 *
 * @return number of extra bits required
 */
static inline int lzsa_get_match_varlen_size_v1(const int nLength) {
   if (nLength < MATCH_RUN_LEN_V1) {
      return 0;
   }
   else {
      if ((nLength + MIN_MATCH_SIZE_V1) < 256)
         return 8;
      else {
         if ((nLength + MIN_MATCH_SIZE_V1) < 512)
            return 16;
         else
            return 24;
      }
   }
}

/**
 * Write extra encoded match length bytes to output (compressed) buffer. The caller must first check that there is enough
 * room to write the bytes.
 *
 * @param pOutData pointer to output buffer
 * @param nOutOffset current write index into output buffer
 * @param nLength encoded match length (actual match length - MIN_MATCH_SIZE_V1)
 */
static inline int lzsa_write_match_varlen_v1(unsigned char *pOutData, int nOutOffset, int nLength) {
   if (nLength >= MATCH_RUN_LEN_V1) {
      if ((nLength + MIN_MATCH_SIZE_V1) < 256)
         pOutData[nOutOffset++] = nLength - MATCH_RUN_LEN_V1;
      else {
         if ((nLength + MIN_MATCH_SIZE_V1) < 512) {
            pOutData[nOutOffset++] = 239;
            pOutData[nOutOffset++] = nLength + MIN_MATCH_SIZE_V1 - 256;
         }
         else {
            pOutData[nOutOffset++] = 238;
            pOutData[nOutOffset++] = (nLength + MIN_MATCH_SIZE_V1) & 0xff;
            pOutData[nOutOffset++] = ((nLength + MIN_MATCH_SIZE_V1) >> 8) & 0xff;
         }
      }
   }

   return nOutOffset;
}

/**
 * Get offset encoding cost in bits
 *
 * @param nMatchOffset offset to get cost of
 *
 * @return cost in bits
 */
static inline int lzsa_get_offset_cost_v1(const unsigned int nMatchOffset) {
   return (nMatchOffset <= 256) ? 8 : 16;
}

/**
 * Attempt to pick optimal matches using a forward arrivals parser, so as to produce the smallest possible output that decompresses to the same input
 *
 * @param pCompressor compression context
 * @param nStartOffset current offset in input window (typically the number of previously compressed bytes)
 * @param nEndOffset offset to end finding matches at (typically the size of the total input window in bytes
 */
static void lzsa_optimize_forward_v1(lzsa_compressor *pCompressor, lzsa_match *pBestMatch, const int nStartOffset, const int nEndOffset, const int nReduce) {
   lzsa_arrival *arrival = pCompressor->arrival - (nStartOffset << ARRIVALS_PER_POSITION_SHIFT);
   const int nMinMatchSize = pCompressor->min_match_size;
   const int nFavorRatio = (pCompressor->flags & LZSA_FLAG_FAVOR_RATIO) ? 1 : 0;
   const int nModeSwitchPenalty = nFavorRatio ? 0 : MODESWITCH_PENALTY;
   const int nDisableScore = nReduce ? 0 : (2 * BLOCK_SIZE);
   int i, j, n;

   if ((nEndOffset - nStartOffset) > BLOCK_SIZE) return;

   memset(arrival + (nStartOffset << ARRIVALS_PER_POSITION_SHIFT), 0, sizeof(lzsa_arrival) * ((nEndOffset - nStartOffset + 1) << ARRIVALS_PER_POSITION_SHIFT));

   arrival[nStartOffset << ARRIVALS_PER_POSITION_SHIFT].from_slot = -1;

   for (i = nStartOffset; i != nEndOffset; i++) {
      lzsa_arrival* cur_arrival = &arrival[i << ARRIVALS_PER_POSITION_SHIFT];
      int m;

      for (j = 0; j < NARRIVALS_PER_POSITION_V1 && cur_arrival[j].from_slot; j++) {
         int nPrevCost = cur_arrival[j].cost;
         int nCodingChoiceCost = nPrevCost + 8 /* literal */;
         int nScore = cur_arrival[j].score + 1;
         int nNumLiterals = cur_arrival[j].num_literals + 1;

         if (nNumLiterals == LITERALS_RUN_LEN_V1 || nNumLiterals == 256 || nNumLiterals == 512) {
            nCodingChoiceCost += 8;
         }

         if (nNumLiterals == 1)
            nCodingChoiceCost += nModeSwitchPenalty;

         lzsa_arrival *pDestSlots = &arrival[(i + 1) << ARRIVALS_PER_POSITION_SHIFT];
         for (n = 0; n < NARRIVALS_PER_POSITION_V1 /* we only need the literals + short match cost + long match cost cases */; n++) {
            lzsa_arrival *pDestArrival = &pDestSlots[n];

            if (pDestArrival->from_slot == 0 ||
               nCodingChoiceCost < pDestArrival->cost ||
               (nCodingChoiceCost == pDestArrival->cost && nScore < (pDestArrival->score + nDisableScore))) {
               memmove(&arrival[((i + 1) << ARRIVALS_PER_POSITION_SHIFT) + n + 1],
                  &arrival[((i + 1) << ARRIVALS_PER_POSITION_SHIFT) + n],
                  sizeof(lzsa_arrival) * (NARRIVALS_PER_POSITION_V1 - n - 1));

               pDestArrival->cost = nCodingChoiceCost;
               pDestArrival->from_pos = i;
               pDestArrival->from_slot = j + 1;
               pDestArrival->match_len = 0;
               pDestArrival->num_literals = nNumLiterals;
               pDestArrival->score = nScore;
               pDestArrival->rep_offset = cur_arrival[j].rep_offset;
               break;
            }
         }
      }

      const lzsa_match *match = pCompressor->match + ((i - nStartOffset) << MATCHES_PER_INDEX_SHIFT_V1);
      int nNumArrivalsForThisPos = j;

      for (m = 0; m < NMATCHES_PER_INDEX_V1 && match[m].length; m++) {
         int nMatchLen = match[m].length;
         int nMatchOffsetCost = lzsa_get_offset_cost_v1(match[m].offset);
         int nStartingMatchLen, k;

         if ((i + nMatchLen) > nEndOffset)
            nMatchLen = nEndOffset - i;

         if (nMatchLen >= LEAVE_ALONE_MATCH_SIZE)
            nStartingMatchLen = nMatchLen;
         else
            nStartingMatchLen = nMinMatchSize;
         for (k = nStartingMatchLen; k <= nMatchLen; k++) {
            int nMatchLenCost = lzsa_get_match_varlen_size_v1(k - MIN_MATCH_SIZE_V1);

            lzsa_arrival *pDestSlots = &arrival[(i + k) << ARRIVALS_PER_POSITION_SHIFT];

            for (j = 0; j < nNumArrivalsForThisPos; j++) {
               int nPrevCost = cur_arrival[j].cost;
               int nCodingChoiceCost = nPrevCost + 8 /* token */ /* the actual cost of the literals themselves accumulates up the chain */ + nMatchOffsetCost + nMatchLenCost;
               int exists = 0;

               if (!cur_arrival[j].num_literals)
                  nCodingChoiceCost += nModeSwitchPenalty;

               for (n = 0;
                  n < NARRIVALS_PER_POSITION_V1 && pDestSlots[n].from_slot && pDestSlots[n].cost <= nCodingChoiceCost;
                  n++) {
                  if (lzsa_get_offset_cost_v1(pDestSlots[n].rep_offset) == nMatchOffsetCost) {
                     exists = 1;
                     break;
                  }
               }

               if (!exists) {
                  int nScore = cur_arrival[j].score + 5;

                  for (n = 0; n < NARRIVALS_PER_POSITION_V1 /* we only need the literals + short match cost + long match cost cases */; n++) {
                     lzsa_arrival *pDestArrival = &pDestSlots[n];

                     if (pDestArrival->from_slot == 0 ||
                        nCodingChoiceCost < pDestArrival->cost ||
                        (nCodingChoiceCost == pDestArrival->cost && nScore < (pDestArrival->score + nDisableScore))) {
                        memmove(&pDestSlots[n + 1],
                           &pDestSlots[n],
                           sizeof(lzsa_arrival) * (NARRIVALS_PER_POSITION_V1 - n - 1));

                        pDestArrival->cost = nCodingChoiceCost;
                        pDestArrival->from_pos = i;
                        pDestArrival->from_slot = j + 1;
                        pDestArrival->match_len = k;
                        pDestArrival->num_literals = 0;
                        pDestArrival->score = nScore;
                        pDestArrival->rep_offset = match[m].offset;
                        j = NARRIVALS_PER_POSITION_V1;
                        break;
                     }
                  }
               }
            }
         }
      }
   }

   lzsa_arrival *end_arrival = &arrival[(i << ARRIVALS_PER_POSITION_SHIFT) + 0];

   while (end_arrival->from_slot > 0 && end_arrival->from_pos >= 0) {
      if (end_arrival->from_pos >= nEndOffset) return;
      pBestMatch[end_arrival->from_pos].length = end_arrival->match_len;
      if (end_arrival->match_len)
         pBestMatch[end_arrival->from_pos].offset = end_arrival->rep_offset;
      else
         pBestMatch[end_arrival->from_pos].offset = 0;

      end_arrival = &arrival[(end_arrival->from_pos << ARRIVALS_PER_POSITION_SHIFT) + (end_arrival->from_slot - 1)];
   }
}

/**
 * Attempt to minimize the number of commands issued in the compressed data block, in order to speed up decompression without
 * impacting the compression ratio
 *
 * @param pCompressor compression context
 * @param pInWindow pointer to input data window (previously compressed bytes + bytes to compress)
 * @param pBestMatch optimal matches to emit
 * @param nStartOffset current offset in input window (typically the number of previously compressed bytes)
 * @param nEndOffset offset to end finding matches at (typically the size of the total input window in bytes
 *
 * @return non-zero if the number of tokens was reduced, 0 if it wasn't
 */
static int lzsa_optimize_command_count_v1(lzsa_compressor *pCompressor, const unsigned char *pInWindow, lzsa_match *pBestMatch, const int nStartOffset, const int nEndOffset) {
   int i;
   int nNumLiterals = 0;
   int nDidReduce = 0;

   for (i = nStartOffset; i < nEndOffset; ) {
      lzsa_match *pMatch = pBestMatch + i;

      if (pMatch->length == 0 &&
         (i + 1) < nEndOffset &&
         pBestMatch[i + 1].length >= MIN_MATCH_SIZE_V1 &&
         pBestMatch[i + 1].length < MAX_VARLEN &&
         pBestMatch[i + 1].offset &&
         i >= pBestMatch[i + 1].offset &&
         (i + pBestMatch[i + 1].length + 1) <= nEndOffset &&
         !memcmp(pInWindow + i - (pBestMatch[i + 1].offset), pInWindow + i, pBestMatch[i + 1].length + 1)) {
         int nCurLenSize = lzsa_get_match_varlen_size_v1(pBestMatch[i + 1].length - MIN_MATCH_SIZE_V1);
         int nReducedLenSize = lzsa_get_match_varlen_size_v1(pBestMatch[i + 1].length + 1 - MIN_MATCH_SIZE_V1);

         if ((nReducedLenSize - nCurLenSize) <= 8) {
            /* Merge */
            pBestMatch[i].length = pBestMatch[i + 1].length + 1;
            pBestMatch[i].offset = pBestMatch[i + 1].offset;
            pBestMatch[i + 1].length = 0;
            pBestMatch[i + 1].offset = 0;
            nDidReduce = 1;
            continue;
         }
      }

      if (pMatch->length >= MIN_MATCH_SIZE_V1) {
         if (pMatch->length <= 9 /* Don't waste time considering large matches, they will always win over literals */ &&
            (i + pMatch->length) < nEndOffset /* Don't consider the last token in the block, we can only reduce a match inbetween other tokens */) {
            int nNextIndex = i + pMatch->length;
            int nNextLiterals = 0;

            while (nNextIndex < nEndOffset && pBestMatch[nNextIndex].length < MIN_MATCH_SIZE_V1) {
               nNextLiterals++;
               nNextIndex++;
            }

            /* This command is a match, is followed by 'nNextLiterals' literals and then by another match, or the end of the input. Calculate this command's current cost (excluding 'nNumLiterals' bytes) */
            if ((8 /* token */ + lzsa_get_literals_varlen_size_v1(nNumLiterals) + ((pMatch->offset <= 256) ? 8 : 16) /* match offset */ + lzsa_get_match_varlen_size_v1(pMatch->length - MIN_MATCH_SIZE_V1) +
               8 /* token */ + lzsa_get_literals_varlen_size_v1(nNextLiterals)) >=
               (8 /* token */ + (pMatch->length << 3) + lzsa_get_literals_varlen_size_v1(nNumLiterals + pMatch->length + nNextLiterals))) {
               /* Reduce */
               int nMatchLen = pMatch->length;
               int j;

               for (j = 0; j < nMatchLen; j++) {
                  pBestMatch[i + j].length = 0;
               }

               nDidReduce = 1;
               continue;
            }
         }

         if ((i + pMatch->length) <= nEndOffset && pMatch->offset > 0 && pMatch->length >= MIN_MATCH_SIZE_V1 &&
            pBestMatch[i + pMatch->length].offset > 0 &&
            pBestMatch[i + pMatch->length].length >= MIN_MATCH_SIZE_V1 &&
            (pMatch->length + pBestMatch[i + pMatch->length].length) >= LEAVE_ALONE_MATCH_SIZE &&
            (pMatch->length + pBestMatch[i + pMatch->length].length) <= MAX_VARLEN &&
            (i + pMatch->length) > pMatch->offset &&
            (i + pMatch->length) > pBestMatch[i + pMatch->length].offset &&
            (i + pMatch->length + pBestMatch[i + pMatch->length].length) <= nEndOffset &&
            !memcmp(pInWindow + i - pMatch->offset + pMatch->length,
               pInWindow + i + pMatch->length - pBestMatch[i + pMatch->length].offset,
               pBestMatch[i + pMatch->length].length)) {

            int nCurPartialSize = lzsa_get_match_varlen_size_v1(pMatch->length - MIN_MATCH_SIZE_V1);
            nCurPartialSize += 8 /* token */ + lzsa_get_literals_varlen_size_v1(0) + ((pBestMatch[i + pMatch->length].offset <= 256) ? 8 : 16) /* match offset */ + lzsa_get_match_varlen_size_v1(pBestMatch[i + pMatch->length].length - MIN_MATCH_SIZE_V1);

            int nReducedPartialSize = lzsa_get_match_varlen_size_v1(pMatch->length + pBestMatch[i + pMatch->length].length - MIN_MATCH_SIZE_V1);

            if (nCurPartialSize >= nReducedPartialSize) {
               int nMatchLen = pMatch->length;

               /* Join */

               pMatch->length += pBestMatch[i + nMatchLen].length;
               pBestMatch[i + nMatchLen].offset = 0;
               pBestMatch[i + nMatchLen].length = -1;
               continue;
            }
         }

         i += pMatch->length;
         nNumLiterals = 0;
      }
      else {
         nNumLiterals++;
         i++;
      }
   }

   return nDidReduce;
}

/**
 * Get compressed data block size
 *
 * @param pCompressor compression context
 * @param pBestMatch optimal matches to emit
 * @param nStartOffset current offset in input window (typically the number of previously compressed bytes)
 * @param nEndOffset offset to end finding matches at (typically the size of the total input window in bytes
 *
 * @return size of compressed data that will be written to output buffer
 */
static int lzsa_get_compressed_size_v1(lzsa_compressor *pCompressor, lzsa_match *pBestMatch, const int nStartOffset, const int nEndOffset) {
   int i;
   int nNumLiterals = 0;
   int nCompressedSize = 0;

   for (i = nStartOffset; i < nEndOffset; ) {
      const lzsa_match *pMatch = pBestMatch + i;

      if (pMatch->length >= MIN_MATCH_SIZE_V1) {
         int nMatchOffset = pMatch->offset;
         int nMatchLen = pMatch->length;
         int nEncodedMatchLen = nMatchLen - MIN_MATCH_SIZE_V1;
         int nTokenLongOffset = (nMatchOffset <= 256) ? 0x00 : 0x80;
         int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v1(nNumLiterals) + (nNumLiterals << 3) + (nTokenLongOffset ? 16 : 8) /* match offset */ + lzsa_get_match_varlen_size_v1(nEncodedMatchLen);

         nCompressedSize += nCommandSize;
         nNumLiterals = 0;
         i += nMatchLen;
      }
      else {
         nNumLiterals++;
         i++;
      }
   }

   {
      int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v1(nNumLiterals) + (nNumLiterals << 3);

      nCompressedSize += nCommandSize;
      nNumLiterals = 0;
   }

   if (pCompressor->flags & LZSA_FLAG_RAW_BLOCK) {
      nCompressedSize += 8 * 4;
   }

   return nCompressedSize;
}

/**
 * Emit block of compressed data
 *
 * @param pCompressor compression context
 * @param pBestMatch optimal matches to emit
 * @param pInWindow pointer to input data window (previously compressed bytes + bytes to compress)
 * @param nStartOffset current offset in input window (typically the number of previously compressed bytes)
 * @param nEndOffset offset to end finding matches at (typically the size of the total input window in bytes
 * @param pOutData pointer to output buffer
 * @param nMaxOutDataSize maximum size of output buffer, in bytes
 *
 * @return size of compressed data in output buffer, or -1 if the data is uncompressible
 */
static int lzsa_write_block_v1(lzsa_compressor *pCompressor, lzsa_match *pBestMatch, const unsigned char *pInWindow, const int nStartOffset, const int nEndOffset, unsigned char *pOutData, const int nMaxOutDataSize) {
   int i;
   int nNumLiterals = 0;
   int nInFirstLiteralOffset = 0;
   int nOutOffset = 0;

   for (i = nStartOffset; i < nEndOffset; ) {
      const lzsa_match *pMatch = pBestMatch + i;

      if (pMatch->length >= MIN_MATCH_SIZE_V1) {
         int nMatchOffset = pMatch->offset;
         int nMatchLen = pMatch->length;
         int nEncodedMatchLen = nMatchLen - MIN_MATCH_SIZE_V1;
         int nTokenLiteralsLen = (nNumLiterals >= LITERALS_RUN_LEN_V1) ? LITERALS_RUN_LEN_V1 : nNumLiterals;
         int nTokenMatchLen = (nEncodedMatchLen >= MATCH_RUN_LEN_V1) ? MATCH_RUN_LEN_V1 : nEncodedMatchLen;
         int nTokenLongOffset = (nMatchOffset <= 256) ? 0x00 : 0x80;
         int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v1(nNumLiterals) + (nNumLiterals << 3) + (nTokenLongOffset ? 16 : 8) /* match offset */ + lzsa_get_match_varlen_size_v1(nEncodedMatchLen);

         if ((nOutOffset + (nCommandSize >> 3)) > nMaxOutDataSize)
            return -1;
         if (nMatchOffset < MIN_OFFSET || nMatchOffset > MAX_OFFSET)
            return -1;

         pOutData[nOutOffset++] = nTokenLongOffset | (nTokenLiteralsLen << 4) | nTokenMatchLen;
         nOutOffset = lzsa_write_literals_varlen_v1(pOutData, nOutOffset, nNumLiterals);

         if (nNumLiterals < pCompressor->stats.min_literals || pCompressor->stats.min_literals == -1)
            pCompressor->stats.min_literals = nNumLiterals;
         if (nNumLiterals > pCompressor->stats.max_literals)
            pCompressor->stats.max_literals = nNumLiterals;
         pCompressor->stats.total_literals += nNumLiterals;
         pCompressor->stats.literals_divisor++;

         if (nNumLiterals != 0) {
            memcpy(pOutData + nOutOffset, pInWindow + nInFirstLiteralOffset, nNumLiterals);
            nOutOffset += nNumLiterals;
            nNumLiterals = 0;
         }

         pOutData[nOutOffset++] = (-nMatchOffset) & 0xff;
         if (nTokenLongOffset) {
            pOutData[nOutOffset++] = (-nMatchOffset) >> 8;
         }
         nOutOffset = lzsa_write_match_varlen_v1(pOutData, nOutOffset, nEncodedMatchLen);

         if (nMatchOffset < pCompressor->stats.min_offset || pCompressor->stats.min_offset == -1)
            pCompressor->stats.min_offset = nMatchOffset;
         if (nMatchOffset > pCompressor->stats.max_offset)
            pCompressor->stats.max_offset = nMatchOffset;
         pCompressor->stats.total_offsets += nMatchOffset;

         if (nMatchLen < pCompressor->stats.min_match_len || pCompressor->stats.min_match_len == -1)
            pCompressor->stats.min_match_len = nMatchLen;
         if (nMatchLen > pCompressor->stats.max_match_len)
            pCompressor->stats.max_match_len = nMatchLen;
         pCompressor->stats.total_match_lens += nMatchLen;
         pCompressor->stats.match_divisor++;

         if (nMatchOffset == 1) {
            if (nMatchLen < pCompressor->stats.min_rle1_len || pCompressor->stats.min_rle1_len == -1)
               pCompressor->stats.min_rle1_len = nMatchLen;
            if (nMatchLen > pCompressor->stats.max_rle1_len)
               pCompressor->stats.max_rle1_len = nMatchLen;
            pCompressor->stats.total_rle1_lens += nMatchLen;
            pCompressor->stats.rle1_divisor++;
         }
         else if (nMatchOffset == 2) {
            if (nMatchLen < pCompressor->stats.min_rle2_len || pCompressor->stats.min_rle2_len == -1)
               pCompressor->stats.min_rle2_len = nMatchLen;
            if (nMatchLen > pCompressor->stats.max_rle2_len)
               pCompressor->stats.max_rle2_len = nMatchLen;
            pCompressor->stats.total_rle2_lens += nMatchLen;
            pCompressor->stats.rle2_divisor++;
         }

         i += nMatchLen;

         if (pCompressor->flags & LZSA_FLAG_RAW_BLOCK) {
            int nCurSafeDist = (i - nStartOffset) - nOutOffset;
            if (nCurSafeDist >= 0 && pCompressor->safe_dist < nCurSafeDist)
               pCompressor->safe_dist = nCurSafeDist;
         }

         pCompressor->num_commands++;
      }
      else {
         if (nNumLiterals == 0)
            nInFirstLiteralOffset = i;
         nNumLiterals++;
         i++;
      }
   }

   {
      int nTokenLiteralsLen = (nNumLiterals >= LITERALS_RUN_LEN_V1) ? LITERALS_RUN_LEN_V1 : nNumLiterals;
      int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v1(nNumLiterals) + (nNumLiterals << 3);

      if ((nOutOffset + (nCommandSize >> 3)) > nMaxOutDataSize)
         return -1;

      if (pCompressor->flags & LZSA_FLAG_RAW_BLOCK)
         pOutData[nOutOffset++] = (nTokenLiteralsLen << 4) | 0x0f;
      else
         pOutData[nOutOffset++] = (nTokenLiteralsLen << 4) | 0x00;
      nOutOffset = lzsa_write_literals_varlen_v1(pOutData, nOutOffset, nNumLiterals);

      if (nNumLiterals < pCompressor->stats.min_literals || pCompressor->stats.min_literals == -1)
         pCompressor->stats.min_literals = nNumLiterals;
      if (nNumLiterals > pCompressor->stats.max_literals)
         pCompressor->stats.max_literals = nNumLiterals;
      pCompressor->stats.total_literals += nNumLiterals;
      pCompressor->stats.literals_divisor++;

      if (nNumLiterals != 0) {
         memcpy(pOutData + nOutOffset, pInWindow + nInFirstLiteralOffset, nNumLiterals);
         nOutOffset += nNumLiterals;
         nNumLiterals = 0;
      }

      if (pCompressor->flags & LZSA_FLAG_RAW_BLOCK) {
         int nCurSafeDist = (i - nStartOffset) - nOutOffset;
         if (nCurSafeDist >= 0 && pCompressor->safe_dist < nCurSafeDist)
            pCompressor->safe_dist = nCurSafeDist;
      }

      pCompressor->num_commands++;
   }

   if (pCompressor->flags & LZSA_FLAG_RAW_BLOCK) {
      /* Emit EOD marker for raw block */

      if ((nOutOffset + 4) > nMaxOutDataSize)
         return -1;

      pOutData[nOutOffset++] = 0;
      pOutData[nOutOffset++] = 238;
      pOutData[nOutOffset++] = 0;
      pOutData[nOutOffset++] = 0;
   }

   return nOutOffset;
}

/**
 * Emit raw block of uncompressible data
 *
 * @param pCompressor compression context
 * @param pInWindow pointer to input data window (previously compressed bytes + bytes to compress)
 * @param nStartOffset current offset in input window (typically the number of previously compressed bytes)
 * @param nEndOffset offset to end finding matches at (typically the size of the total input window in bytes
 * @param pOutData pointer to output buffer
 * @param nMaxOutDataSize maximum size of output buffer, in bytes
 *
 * @return size of compressed data in output buffer, or -1 if the data is uncompressible
 */
static int lzsa_write_raw_uncompressed_block_v1(lzsa_compressor *pCompressor, const unsigned char *pInWindow, const int nStartOffset, const int nEndOffset, unsigned char *pOutData, const int nMaxOutDataSize) {
   int nNumLiterals = nEndOffset - nStartOffset;
   int nTokenLiteralsLen = (nNumLiterals >= LITERALS_RUN_LEN_V1) ? LITERALS_RUN_LEN_V1 : nNumLiterals;
   int nOutOffset = 0;

   int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v1(nNumLiterals) + (nNumLiterals << 3) + 4;
   if ((nOutOffset + (nCommandSize >> 3)) > nMaxOutDataSize)
      return -1;

   pCompressor->num_commands = 0;
   pOutData[nOutOffset++] = (nTokenLiteralsLen << 4) | 0x0f;
   
   nOutOffset = lzsa_write_literals_varlen_v1(pOutData, nOutOffset, nNumLiterals);

   if (nNumLiterals != 0) {
      memcpy(pOutData + nOutOffset, pInWindow + nStartOffset, nNumLiterals);
      nOutOffset += nNumLiterals;
      nNumLiterals = 0;
   }

   pCompressor->num_commands++;

   /* Emit EOD marker for raw block */

   pOutData[nOutOffset++] = 0;
   pOutData[nOutOffset++] = 238;
   pOutData[nOutOffset++] = 0;
   pOutData[nOutOffset++] = 0;

   return nOutOffset;
}

/**
 * Select the most optimal matches, reduce the token count if possible, and then emit a block of compressed LZSA1 data
 *
 * @param pCompressor compression context
 * @param pInWindow pointer to input data window (previously compressed bytes + bytes to compress)
 * @param nPreviousBlockSize number of previously compressed bytes (or 0 for none)
 * @param nInDataSize number of input bytes to compress
 * @param pOutData pointer to output buffer
 * @param nMaxOutDataSize maximum size of output buffer, in bytes
 *
 * @return size of compressed data in output buffer, or -1 if the data is uncompressible
 */
int lzsa_optimize_and_write_block_v1(lzsa_compressor *pCompressor, const unsigned char *pInWindow, const int nPreviousBlockSize, const int nInDataSize, unsigned char *pOutData, const int nMaxOutDataSize) {
   int nResult, nBaseCompressedSize;

   /* Compress optimally without breaking ties in favor of less tokens */

   memset(pCompressor->best_match, 0, BLOCK_SIZE * sizeof(lzsa_match));
   lzsa_optimize_forward_v1(pCompressor, pCompressor->best_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, 0 /* reduce */);

   int nDidReduce;
   int nPasses = 0;
   do {
      nDidReduce = lzsa_optimize_command_count_v1(pCompressor, pInWindow, pCompressor->best_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
      nPasses++;
   } while (nDidReduce && nPasses < 20);

   nBaseCompressedSize = lzsa_get_compressed_size_v1(pCompressor, pCompressor->best_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
   lzsa_match *pBestMatch = pCompressor->best_match - nPreviousBlockSize;

   if (nBaseCompressedSize > 0 && nInDataSize < 65536) {
      int nReducedCompressedSize;

      /* Compress optimally and do break ties in favor of less tokens */
      memset(pCompressor->improved_match, 0, BLOCK_SIZE * sizeof(lzsa_match));
      lzsa_optimize_forward_v1(pCompressor, pCompressor->improved_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, 1 /* reduce */);
      
      nPasses = 0;
      do {
         nDidReduce = lzsa_optimize_command_count_v1(pCompressor, pInWindow, pCompressor->improved_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
         nPasses++;
      } while (nDidReduce && nPasses < 20);

      nReducedCompressedSize = lzsa_get_compressed_size_v1(pCompressor, pCompressor->improved_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
      if (nReducedCompressedSize > 0 && nReducedCompressedSize <= nBaseCompressedSize) {
         /* Pick the parse with the reduced number of tokens as it didn't negatively affect the size */
         pBestMatch = pCompressor->improved_match - nPreviousBlockSize;
      }
   }

   nResult = lzsa_write_block_v1(pCompressor, pBestMatch, pInWindow, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, pOutData, nMaxOutDataSize);
   if (nResult < 0 && pCompressor->flags & LZSA_FLAG_RAW_BLOCK) {
      nResult = lzsa_write_raw_uncompressed_block_v1(pCompressor, pInWindow, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, pOutData, nMaxOutDataSize);
   }

   return nResult;
}
