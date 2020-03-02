/*
 * shrink_block_v2.c - LZSA2 block compressor implementation
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
#include "shrink_block_v2.h"
#include "format.h"

/**
 * Write 4-bit nibble to output (compressed) buffer
 *
 * @param pOutData pointer to output buffer
 * @param nOutOffset current write index into output buffer
 * @param nMaxOutDataSize maximum size of output buffer, in bytes
 * @param nCurNibbleOffset write index into output buffer, of current byte being filled with nibbles
 * @param nCurFreeNibbles current number of free nibbles in byte
 * @param nNibbleValue value to write (0..15)
 */
static int lzsa_write_nibble_v2(unsigned char *pOutData, int nOutOffset, const int nMaxOutDataSize, int *nCurNibbleOffset, int *nCurFreeNibbles, int nNibbleValue) {
   if (nOutOffset < 0) return -1;

   if ((*nCurNibbleOffset) == -1) {
      if (nOutOffset >= nMaxOutDataSize) return -1;
      (*nCurNibbleOffset) = nOutOffset;
      (*nCurFreeNibbles) = 2;
      pOutData[nOutOffset++] = 0;
   }

   pOutData[*nCurNibbleOffset] = (pOutData[*nCurNibbleOffset] << 4) | (nNibbleValue & 0x0f);
   (*nCurFreeNibbles)--;
   if ((*nCurFreeNibbles) == 0) {
      (*nCurNibbleOffset) = -1;
   }

   return nOutOffset;
}

/**
 * Get the number of extra bits required to represent a literals length
 *
 * @param nLength literals length
 *
 * @return number of extra bits required
 */
static inline int lzsa_get_literals_varlen_size_v2(const int nLength) {
   if (nLength < LITERALS_RUN_LEN_V2) {
      return 0;
   }
   else {
      if (nLength < (LITERALS_RUN_LEN_V2 + 15)) {
         return 4;
      }
      else {
         if (nLength < 256)
            return 4+8;
         else {
            return 4+24;
         }
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
static inline int lzsa_write_literals_varlen_v2(unsigned char *pOutData, int nOutOffset, const int nMaxOutDataSize, int *nCurNibbleOffset, int *nCurFreeNibbles, int nLength) {
   if (nLength >= LITERALS_RUN_LEN_V2) {
      if (nLength < (LITERALS_RUN_LEN_V2 + 15)) {
         nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, nCurNibbleOffset, nCurFreeNibbles, nLength - LITERALS_RUN_LEN_V2);
      }
      else {
         nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, nCurNibbleOffset, nCurFreeNibbles, 15);
         if (nOutOffset < 0) return -1;

         if (nLength < 256)
            pOutData[nOutOffset++] = nLength - 18;
         else {
            pOutData[nOutOffset++] = 239;
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
 * @param nLength encoded match length (actual match length - MIN_MATCH_SIZE_V2)
 *
 * @return number of extra bits required
 */
static inline int lzsa_get_match_varlen_size_v2(const int nLength) {
   if (nLength < MATCH_RUN_LEN_V2) {
      return 0;
   }
   else {
      if (nLength < (MATCH_RUN_LEN_V2 + 15))
         return 4;
      else {
         if ((nLength + MIN_MATCH_SIZE_V2) < 256)
            return 4+8;
         else {
            return 4 + 24;
         }
      }
   }
}

/**
 * Write extra encoded match length bytes to output (compressed) buffer. The caller must first check that there is enough
 * room to write the bytes.
 *
 * @param pOutData pointer to output buffer
 * @param nOutOffset current write index into output buffer
 * @param nLength encoded match length (actual match length - MIN_MATCH_SIZE_V2)
 */
static inline int lzsa_write_match_varlen_v2(unsigned char *pOutData, int nOutOffset, const int nMaxOutDataSize, int *nCurNibbleOffset, int *nCurFreeNibbles, int nLength) {
   if (nLength >= MATCH_RUN_LEN_V2) {
      if (nLength < (MATCH_RUN_LEN_V2 + 15)) {
         nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, nCurNibbleOffset, nCurFreeNibbles, nLength - MATCH_RUN_LEN_V2);
      }
      else {
         nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, nCurNibbleOffset, nCurFreeNibbles, 15);
         if (nOutOffset < 0) return -1;

         if ((nLength + MIN_MATCH_SIZE_V2) < 256)
            pOutData[nOutOffset++] = nLength + MIN_MATCH_SIZE_V2 - 24;
         else {
            pOutData[nOutOffset++] = 233;
            pOutData[nOutOffset++] = (nLength + MIN_MATCH_SIZE_V2) & 0xff;
            pOutData[nOutOffset++] = ((nLength + MIN_MATCH_SIZE_V2) >> 8) & 0xff;
         }
      }
   }

   return nOutOffset;
}

/**
 * Insert forward rep candidate
 *
 * @param pCompressor compression context
 * @param pInWindow pointer to input data window (previously compressed bytes + bytes to compress)
 * @param i input data window position whose matches are being considered
 * @param nMatchOffset match offset to use as rep candidate
 * @param nStartOffset current offset in input window (typically the number of previously compressed bytes)
 * @param nEndOffset offset to end finding matches at (typically the size of the total input window in bytes
 * @param nMatchesPerArrival number of arrivals to record per input buffer position
 * @param nDepth current insertion depth
 */
static void lzsa_insert_forward_match_v2(lzsa_compressor *pCompressor, const unsigned char *pInWindow, const int i, const int nMatchOffset, const int nStartOffset, const int nEndOffset, const int nMatchesPerArrival, int nDepth) {
   lzsa_arrival *arrival = pCompressor->arrival - (nStartOffset << MATCHES_PER_ARRIVAL_SHIFT);
   int j;

   if (nDepth >= 10) return;

   for (j = 0; j < nMatchesPerArrival && arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].from_slot; j++) {
      int nRepOffset = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_offset;

      if (nMatchOffset != nRepOffset && nRepOffset && arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_len >= MIN_MATCH_SIZE_V2) {
         int nRepPos = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_pos;
         int nRepLen = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_len;

         if (nRepPos > nMatchOffset &&
            (nRepPos - nMatchOffset + nRepLen) <= (nEndOffset - LAST_LITERALS) &&
            !memcmp(pInWindow + nRepPos - nRepOffset, pInWindow + nRepPos - nMatchOffset, nRepLen)) {
            int nCurRepLen = nRepLen;

            int nMaxRepLen = nEndOffset - nRepPos;
            if (nMaxRepLen > LCP_MAX)
               nMaxRepLen = LCP_MAX;
            while ((nCurRepLen + 8) < nMaxRepLen && !memcmp(pInWindow + nRepPos + nCurRepLen, pInWindow + nRepPos - nMatchOffset + nCurRepLen, 8))
               nCurRepLen += 8;
            while ((nCurRepLen + 4) < nMaxRepLen && !memcmp(pInWindow + nRepPos + nCurRepLen, pInWindow + nRepPos - nMatchOffset + nCurRepLen, 4))
               nCurRepLen += 4;
            while (nCurRepLen < nMaxRepLen && pInWindow[nRepPos + nCurRepLen] == pInWindow[nRepPos - nMatchOffset + nCurRepLen])
               nCurRepLen++;

            lzsa_match *fwd_match = pCompressor->match + ((nRepPos - nStartOffset) << MATCHES_PER_INDEX_SHIFT_V2);
            int exists = 0;
            int r;

            for (r = 0; r < NMATCHES_PER_INDEX_V2 && fwd_match[r].length >= MIN_MATCH_SIZE_V2; r++) {
               if (fwd_match[r].offset == nMatchOffset) {
                  exists = 1;

                  if (fwd_match[r].length < nCurRepLen) {
                     fwd_match[r].length = nCurRepLen;
                     lzsa_insert_forward_match_v2(pCompressor, pInWindow, nRepPos, nMatchOffset, nStartOffset, nEndOffset, nMatchesPerArrival, nDepth + 1);
                  }
                  break;
               }
            }

            if (!exists && r < NMATCHES_PER_INDEX_V2) {
               fwd_match[r].offset = nMatchOffset;
               fwd_match[r].length = nCurRepLen;

               lzsa_insert_forward_match_v2(pCompressor, pInWindow, nRepPos, nMatchOffset, nStartOffset, nEndOffset, nMatchesPerArrival, nDepth + 1);
            }
         }
      }
   }
}

/**
 * Attempt to pick optimal matches using a forward arrivals parser, so as to produce the smallest possible output that decompresses to the same input
 *
 * @param pCompressor compression context
 * @param pInWindow pointer to input data window (previously compressed bytes + bytes to compress)
 * @param pBestMatch pointer to buffer for outputting optimal matches
 * @param nStartOffset current offset in input window (typically the number of previously compressed bytes)
 * @param nEndOffset offset to end finding matches at (typically the size of the total input window in bytes
 * @param nReduce non-zero to reduce the number of tokens when the path costs are equal, zero not to
 * @param nInsertForwardReps non-zero to insert forward repmatch candidates, zero to use the previously inserted candidates
 * @param nMatchesPerArrival number of arrivals to record per input buffer position
 */
static void lzsa_optimize_forward_v2(lzsa_compressor *pCompressor, const unsigned char *pInWindow, lzsa_match *pBestMatch, const int nStartOffset, const int nEndOffset, const int nReduce, const int nInsertForwardReps, const int nMatchesPerArrival) {
   lzsa_arrival *arrival = pCompressor->arrival - (nStartOffset << MATCHES_PER_ARRIVAL_SHIFT);
   const int nFavorRatio = (pCompressor->flags & LZSA_FLAG_FAVOR_RATIO) ? 1 : 0;
   const int nMinMatchSize = pCompressor->min_match_size;
   const int nDisableScore = nReduce ? 0 : (2 * BLOCK_SIZE);
   const int nLeaveAloneMatchSize = (nMatchesPerArrival == NMATCHES_PER_ARRIVAL_V2_SMALL) ? LEAVE_ALONE_MATCH_SIZE_SMALL : LEAVE_ALONE_MATCH_SIZE;
   int i, j, n;

   if ((nEndOffset - nStartOffset) > BLOCK_SIZE) return;

   memset(arrival + (nStartOffset << MATCHES_PER_ARRIVAL_SHIFT), 0, sizeof(lzsa_arrival) * ((nEndOffset - nStartOffset + 1) << MATCHES_PER_ARRIVAL_SHIFT));

   for (i = (nStartOffset << MATCHES_PER_ARRIVAL_SHIFT); i != ((nEndOffset + 1) << MATCHES_PER_ARRIVAL_SHIFT); i++) {
      arrival[i].cost = 0x40000000;
   }

   arrival[nStartOffset << MATCHES_PER_ARRIVAL_SHIFT].from_slot = -1;

   for (i = nStartOffset; i != nEndOffset; i++) {
      int m;

      for (j = 0; j < nMatchesPerArrival && arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].from_slot; j++) {
         const int nPrevCost = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].cost & 0x3fffffff;
         int nCodingChoiceCost = nPrevCost + 8 /* literal */;
         int nNumLiterals = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].num_literals + 1;

         if (nNumLiterals == LITERALS_RUN_LEN_V2) {
            nCodingChoiceCost += 4;
         }
         else if (nNumLiterals == (LITERALS_RUN_LEN_V2 + 15)) {
            nCodingChoiceCost += 8;
         }
         else if (nNumLiterals == 256) {
            nCodingChoiceCost += 16;
         }

         if (!nFavorRatio && nNumLiterals == 1)
            nCodingChoiceCost += MODESWITCH_PENALTY;

         lzsa_arrival *pDestSlots = &arrival[(i + 1) << MATCHES_PER_ARRIVAL_SHIFT];
         if (nCodingChoiceCost <= pDestSlots[nMatchesPerArrival - 1].cost) {
            int exists = 0;
            for (n = 0;
               n < nMatchesPerArrival && pDestSlots[n].cost <= nCodingChoiceCost;
               n++) {
               if (pDestSlots[n].rep_offset == arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_offset) {
                  exists = 1;
                  break;
               }
            }

            if (!exists) {
               int nScore = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].score + 1;
               for (n = 0; n < nMatchesPerArrival; n++) {
                  lzsa_arrival *pDestArrival = &pDestSlots[n];
                  if (nCodingChoiceCost < pDestArrival->cost ||
                     (nCodingChoiceCost == pDestArrival->cost && nScore < (pDestArrival->score + nDisableScore))) {

                     if (pDestArrival->from_slot) {
                        int z;

                        for (z = n; z < nMatchesPerArrival - 1; z++) {
                           if (pDestSlots[z].rep_offset == arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_offset)
                              break;
                        }

                        memmove(&pDestSlots[n + 1],
                           &pDestSlots[n],
                           sizeof(lzsa_arrival) * (z - n));
                     }

                     pDestArrival->cost = nCodingChoiceCost;
                     pDestArrival->from_pos = i;
                     pDestArrival->from_slot = j + 1;
                     pDestArrival->match_offset = 0;
                     pDestArrival->match_len = 0;
                     pDestArrival->num_literals = nNumLiterals;
                     pDestArrival->score = nScore;
                     pDestArrival->rep_offset = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_offset;
                     pDestArrival->rep_pos = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_pos;
                     pDestArrival->rep_len = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_len;
                     break;
                  }
               }
            }
         }
      }

      lzsa_match *match = pCompressor->match + ((i - nStartOffset) << MATCHES_PER_INDEX_SHIFT_V2);

      int nMinRepLen[NMATCHES_PER_ARRIVAL_V2_BIG];
      memset(nMinRepLen, 0, nMatchesPerArrival * sizeof(int));

      for (m = 0; m < NMATCHES_PER_INDEX_V2 && match[m].length; m++) {
         int nMatchLen = match[m].length & 0x7fff;
         int nMatchOffset = match[m].offset;
         int nScorePenalty = ((match[m].length & 0x8000) >> 15);
         int nNoRepmatchOffsetCost = (nMatchOffset <= 32) ? 4 : ((nMatchOffset <= 512) ? 8 : ((nMatchOffset <= (8192 + 512)) ? 12 : 16));
         int nStartingMatchLen, k;
         int nMaxRepLen[NMATCHES_PER_ARRIVAL_V2_BIG];

         if ((i + nMatchLen) > (nEndOffset - LAST_LITERALS))
            nMatchLen = nEndOffset - LAST_LITERALS - i;

         for (j = 0; j < nMatchesPerArrival && arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].from_slot; j++) {
            int nRepOffset = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_offset;
            int nCurMaxRepLen = 0;

            if (nRepOffset) {
               if (nMatchOffset == nRepOffset)
                  nCurMaxRepLen = nMatchLen;
               else {
                  if (i > nRepOffset &&
                     (i - nRepOffset + nMatchLen) <= (nEndOffset - LAST_LITERALS)) {
                     nCurMaxRepLen = nMinRepLen[j];
                     while ((nCurMaxRepLen + 8) < nMatchLen && !memcmp(pInWindow + i - nRepOffset + nCurMaxRepLen, pInWindow + i + nCurMaxRepLen, 8))
                        nCurMaxRepLen += 8;
                     while ((nCurMaxRepLen + 4) < nMatchLen && !memcmp(pInWindow + i - nRepOffset + nCurMaxRepLen, pInWindow + i + nCurMaxRepLen, 4))
                        nCurMaxRepLen += 4;
                     while (nCurMaxRepLen < nMatchLen && pInWindow[i - nRepOffset + nCurMaxRepLen] == pInWindow[i + nCurMaxRepLen])
                        nCurMaxRepLen++;
                     nMinRepLen[j] = nCurMaxRepLen;
                  }
               }
            }

            nMaxRepLen[j] = nCurMaxRepLen;
         }
         while (j < nMatchesPerArrival)
            nMaxRepLen[j++] = 0;

         if (nInsertForwardReps)
            lzsa_insert_forward_match_v2(pCompressor, pInWindow, i, nMatchOffset, nStartOffset, nEndOffset, nMatchesPerArrival, 0);

         int nMatchLenCost = 0;
         if (nMatchLen >= nLeaveAloneMatchSize) {
            nStartingMatchLen = nMatchLen;
            nMatchLenCost = 4 + 24;
         }
         else {
            nStartingMatchLen = nMinMatchSize;
            nMatchLenCost = 0;
         }

         for (k = nStartingMatchLen; k <= nMatchLen; k++) {
            if (k == (MATCH_RUN_LEN_V2 + MIN_MATCH_SIZE_V2)) {
               nMatchLenCost = 4;
            }
            else {
               if (k == (MATCH_RUN_LEN_V2 + 15 + MIN_MATCH_SIZE_V2))
                  nMatchLenCost = 4 + 8;
               else {
                  if (k == 256)
                     nMatchLenCost = 4 + 24;
               }
            }

            lzsa_arrival *pDestSlots = &arrival[(i + k) << MATCHES_PER_ARRIVAL_SHIFT];
            int nInsertedNoRepMatchCandidate = 0;

            for (j = 0; j < nMatchesPerArrival && arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].from_slot; j++) {
               const int nPrevCost = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].cost & 0x3fffffff;
               int nRepCodingChoiceCost = nPrevCost + 8 /* token */ /* the actual cost of the literals themselves accumulates up the chain */ + nMatchLenCost;

               if (nRepCodingChoiceCost <= pDestSlots[nMatchesPerArrival - 1].cost) {
                  int nRepOffset = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].rep_offset;

                  if (nMatchOffset != nRepOffset && !nInsertedNoRepMatchCandidate) {
                     int nCodingChoiceCost = nRepCodingChoiceCost + nNoRepmatchOffsetCost;

                     if (!nFavorRatio && !arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].num_literals)
                        nCodingChoiceCost += MODESWITCH_PENALTY;

                     if (nCodingChoiceCost <= pDestSlots[nMatchesPerArrival - 1].cost) {
                        int exists = 0;
                        int nScore = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].score + 3 + nScorePenalty;

                        for (n = 0;
                           n < nMatchesPerArrival && pDestSlots[n].cost <= nCodingChoiceCost;
                           n++) {
                           if (pDestSlots[n].rep_offset == nMatchOffset &&
                              (!nInsertForwardReps || pDestSlots[n].cost != nCodingChoiceCost || pDestSlots[n].rep_pos >= i || nScore >= (pDestSlots[n].score + nDisableScore) ||
                                 pDestSlots[nMatchesPerArrival - 1].from_slot)) {
                              exists = 1;
                              break;
                           }
                        }

                        if (!exists) {
                           for (n = 0; n < nMatchesPerArrival - 1; n++) {
                              lzsa_arrival *pDestArrival = &pDestSlots[n];

                              if (nCodingChoiceCost < pDestArrival->cost ||
                                 (nCodingChoiceCost == pDestArrival->cost && nScore < (pDestArrival->score + nDisableScore))) {
                                 if (pDestArrival->from_slot) {
                                    int z;

                                    for (z = n; z < nMatchesPerArrival - 1; z++) {
                                       if (pDestSlots[z].rep_offset == nMatchOffset)
                                          break;
                                    }

                                    if (z == (nMatchesPerArrival - 1) && pDestSlots[z].from_slot && pDestSlots[z].match_len < MIN_MATCH_SIZE_V2)
                                       z--;

                                    memmove(&pDestSlots[n + 1],
                                       &pDestSlots[n],
                                       sizeof(lzsa_arrival) * (z - n));
                                 }

                                 pDestArrival->cost = nCodingChoiceCost;
                                 pDestArrival->from_pos = i;
                                 pDestArrival->from_slot = j + 1;
                                 pDestArrival->match_offset = nMatchOffset;
                                 pDestArrival->match_len = k;
                                 pDestArrival->num_literals = 0;
                                 pDestArrival->score = nScore;
                                 pDestArrival->rep_offset = nMatchOffset;
                                 pDestArrival->rep_pos = i;
                                 pDestArrival->rep_len = k;
                                 nInsertedNoRepMatchCandidate = 1;
                                 break;
                              }
                           }
                        }
                     }
                  }

                  /* If this coding choice doesn't rep-match, see if we still get a match by using the current repmatch offset for this arrival. This can occur (and not have the
                   * matchfinder offer the offset in the first place, or have too many choices with the same cost to retain the repmatchable offset) when compressing regions
                   * of identical bytes, for instance. Checking for this provides a big compression win on some files. */

                  if (nMaxRepLen[j] >= k) {
                     int exists = 0;

                     /* A match is possible at the rep offset; insert the extra coding choice. */

                     for (n = 0;
                        n < nMatchesPerArrival && pDestSlots[n].cost <= nRepCodingChoiceCost;
                        n++) {
                        if (pDestSlots[n].rep_offset == nRepOffset) {
                           exists = 1;
                           break;
                        }
                     }

                     if (!exists) {
                        int nScore = arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + j].score + 2;

                        for (n = 0; n < nMatchesPerArrival; n++) {
                           lzsa_arrival *pDestArrival = &pDestSlots[n];

                           if (nRepCodingChoiceCost < pDestArrival->cost ||
                              (nRepCodingChoiceCost == pDestArrival->cost && nScore < (pDestArrival->score + nDisableScore))) {
                              if (pDestArrival->from_slot) {
                                 int z;

                                 for (z = n; z < nMatchesPerArrival - 1; z++) {
                                    if (pDestSlots[z].rep_offset == nRepOffset)
                                       break;
                                 }

                                 memmove(&pDestSlots[n + 1],
                                    &pDestSlots[n],
                                    sizeof(lzsa_arrival) * (z - n));
                              }

                              pDestArrival->cost = nRepCodingChoiceCost;
                              pDestArrival->from_pos = i;
                              pDestArrival->from_slot = j + 1;
                              pDestArrival->match_offset = nRepOffset;
                              pDestArrival->match_len = k;
                              pDestArrival->num_literals = 0;
                              pDestArrival->score = nScore;
                              pDestArrival->rep_offset = nRepOffset;
                              pDestArrival->rep_pos = i;
                              pDestArrival->rep_len = k;
                              break;
                           }
                        }
                     }
                  }
               }
               else {
                  break;
               }
            }
         }

         if (nMatchLen >= LCP_MAX && ((m + 1) >= NMATCHES_PER_INDEX_V2 || match[m + 1].length < LCP_MAX))
            break;
      }
   }

   lzsa_arrival *end_arrival = &arrival[(i << MATCHES_PER_ARRIVAL_SHIFT) + 0];

   while (end_arrival->from_slot > 0 && end_arrival->from_pos >= 0) {
      if (end_arrival->from_pos >= nEndOffset) return;
      pBestMatch[end_arrival->from_pos].length = end_arrival->match_len;
      pBestMatch[end_arrival->from_pos].offset = end_arrival->match_offset;
      end_arrival = &arrival[(end_arrival->from_pos << MATCHES_PER_ARRIVAL_SHIFT) + (end_arrival->from_slot - 1)];
   }
}

/**
 * Attempt to minimize the number of commands issued in the compressed data block, in order to speed up decompression without
 * impacting the compression ratio
 *
 * @param pCompressor compression context
 * @param pInWindow pointer to input data window (previously compressed bytes + bytes to compress)
 * @param pBestMatch optimal matches to evaluate and update
 * @param nStartOffset current offset in input window (typically the number of previously compressed bytes)
 * @param nEndOffset offset to end finding matches at (typically the size of the total input window in bytes
 *
 * @return non-zero if the number of tokens was reduced, 0 if it wasn't
 */
static int lzsa_optimize_command_count_v2(lzsa_compressor *pCompressor, const unsigned char *pInWindow, lzsa_match *pBestMatch, const int nStartOffset, const int nEndOffset) {
   int i;
   int nNumLiterals = 0;
   int nPrevRepMatchOffset = 0;
   int nRepMatchOffset = 0;
   int nRepMatchLen = 0;
   int nRepIndex = 0;
   int nDidReduce = 0;

   for (i = nStartOffset; i < nEndOffset; ) {
      lzsa_match *pMatch = pBestMatch + i;

      if (pMatch->length == 0 &&
         (i + 1) < (nEndOffset - LAST_LITERALS) &&
         pBestMatch[i + 1].length >= MIN_MATCH_SIZE_V2 &&
         pBestMatch[i + 1].length < MAX_VARLEN &&
         pBestMatch[i + 1].offset &&
         i >= pBestMatch[i + 1].offset &&
         (i + pBestMatch[i + 1].length + 1) <= (nEndOffset - LAST_LITERALS) &&
         !memcmp(pInWindow + i - (pBestMatch[i + 1].offset), pInWindow + i, pBestMatch[i + 1].length + 1)) {
         int nCurLenSize = lzsa_get_match_varlen_size_v2(pBestMatch[i + 1].length - MIN_MATCH_SIZE_V2);
         int nReducedLenSize = lzsa_get_match_varlen_size_v2(pBestMatch[i + 1].length + 1 - MIN_MATCH_SIZE_V2);

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

      if (pMatch->length >= MIN_MATCH_SIZE_V2) {
         if ((i + pMatch->length) < nEndOffset /* Don't consider the last match in the block, we can only reduce a match inbetween other tokens */) {
            int nNextIndex = i + pMatch->length;
            int nNextLiterals = 0;

            while (nNextIndex < nEndOffset && pBestMatch[nNextIndex].length < MIN_MATCH_SIZE_V2) {
               nNextLiterals++;
               nNextIndex++;
            }

            if (nNextIndex < nEndOffset && pBestMatch[nNextIndex].length >= MIN_MATCH_SIZE_V2) {
               /* This command is a match, is followed by 'nNextLiterals' literals and then by another match */

               if (nRepMatchOffset && pMatch->offset != nRepMatchOffset && (pBestMatch[nNextIndex].offset != pMatch->offset || pBestMatch[nNextIndex].offset == nRepMatchOffset ||
                  ((pMatch->offset <= 32) ? 4 : ((pMatch->offset <= 512) ? 8 : ((pMatch->offset <= (8192 + 512)) ? 12 : 16))) >
                  ((pBestMatch[nNextIndex].offset <= 32) ? 4 : ((pBestMatch[nNextIndex].offset <= 512) ? 8 : ((pBestMatch[nNextIndex].offset <= (8192 + 512)) ? 12 : 16))))) {
                  /* Check if we can change the current match's offset to be the same as the previous match's offset, and get an extra repmatch. This will occur when
                   * matching large regions of identical bytes for instance, where there are too many offsets to be considered by the parser, and when not compressing to favor the
                   * ratio (the forward arrivals parser already has this covered). */
                  if (i > nRepMatchOffset &&
                     (i - nRepMatchOffset + pMatch->length) <= (nEndOffset - LAST_LITERALS) &&
                     !memcmp(pInWindow + i - nRepMatchOffset, pInWindow + i - pMatch->offset, pMatch->length)) {
                     pMatch->offset = nRepMatchOffset;
                     nDidReduce = 1;
                  }
               }

               if (pBestMatch[nNextIndex].offset && pMatch->offset != pBestMatch[nNextIndex].offset && nRepMatchOffset != pBestMatch[nNextIndex].offset) {
                  /* Otherwise, try to gain a match forward as well */
                  if (i > pBestMatch[nNextIndex].offset && (i - pBestMatch[nNextIndex].offset + pMatch->length) <= (nEndOffset - LAST_LITERALS)) {
                     int nMaxLen = 0;
                     while (nMaxLen < pMatch->length && pInWindow[i - pBestMatch[nNextIndex].offset + nMaxLen] == pInWindow[i - pMatch->offset + nMaxLen])
                        nMaxLen++;
                     if (nMaxLen >= pMatch->length) {
                        /* Replace */
                        pMatch->offset = pBestMatch[nNextIndex].offset;
                        nDidReduce = 1;
                     }
                     else if (nMaxLen >= 2 && pMatch->offset != nRepMatchOffset) {
                        int nPartialSizeBefore, nPartialSizeAfter;

                        nPartialSizeBefore = lzsa_get_match_varlen_size_v2(pMatch->length - MIN_MATCH_SIZE_V2);
                        nPartialSizeBefore += (pMatch->offset <= 32) ? 4 : ((pMatch->offset <= 512) ? 8 : ((pMatch->offset <= (8192 + 512)) ? 12 : 16));
                        nPartialSizeBefore += lzsa_get_literals_varlen_size_v2(nNextLiterals);

                        nPartialSizeAfter = lzsa_get_match_varlen_size_v2(nMaxLen - MIN_MATCH_SIZE_V2);
                        nPartialSizeAfter += lzsa_get_literals_varlen_size_v2(nNextLiterals + (pMatch->length - nMaxLen)) + ((pMatch->length - nMaxLen) << 3);

                        if (nPartialSizeAfter < nPartialSizeBefore) {
                           int j;

                           /* We gain a repmatch that is shorter than the original match as this is the best we can do, so it is followed by extra literals, but
                            * we have calculated that this is shorter */
                           pMatch->offset = pBestMatch[nNextIndex].offset;
                           for (j = nMaxLen; j < pMatch->length; j++) {
                              pBestMatch[i + j].length = 0;
                           }
                           pMatch->length = nMaxLen;
                           nDidReduce = 1;
                        }
                     }
                  }
               }

               if (pMatch->length < 9 /* Don't waste time considering large matches, they will always win over literals */) {
                  /* Calculate this command's current cost (excluding 'nNumLiterals' bytes) */

                  int nCurCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNumLiterals) + lzsa_get_match_varlen_size_v2(pMatch->length - MIN_MATCH_SIZE_V2);
                  if (pMatch->offset != nRepMatchOffset)
                     nCurCommandSize += (pMatch->offset <= 32) ? 4 : ((pMatch->offset <= 512) ? 8 : ((pMatch->offset <= (8192 + 512)) ? 12 : 16));

                  /* Calculate the next command's current cost */
                  int nNextCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNextLiterals) + (nNextLiterals << 3) + lzsa_get_match_varlen_size_v2(pBestMatch[nNextIndex].length - MIN_MATCH_SIZE_V2);
                  if (pBestMatch[nNextIndex].offset != pMatch->offset)
                     nNextCommandSize += (pBestMatch[nNextIndex].offset <= 32) ? 4 : ((pBestMatch[nNextIndex].offset <= 512) ? 8 : ((pBestMatch[nNextIndex].offset <= (8192 + 512)) ? 12 : 16));

                  int nOriginalCombinedCommandSize = nCurCommandSize + nNextCommandSize;

                  /* Calculate the cost of replacing this match command by literals + the next command with the cost of encoding these literals (excluding 'nNumLiterals' bytes) */
                  int nReducedCommandSize = (pMatch->length << 3) + 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNumLiterals + pMatch->length + nNextLiterals) + (nNextLiterals << 3) + lzsa_get_match_varlen_size_v2(pBestMatch[nNextIndex].length - MIN_MATCH_SIZE_V2);
                  if (pBestMatch[nNextIndex].offset != nRepMatchOffset)
                     nReducedCommandSize += (pBestMatch[nNextIndex].offset <= 32) ? 4 : ((pBestMatch[nNextIndex].offset <= 512) ? 8 : ((pBestMatch[nNextIndex].offset <= (8192 + 512)) ? 12 : 16));

                  int nReplaceRepOffset = 0;
                  if (nRepMatchOffset && nRepMatchOffset != nPrevRepMatchOffset && nRepMatchLen >= MIN_MATCH_SIZE_V2 && nRepMatchOffset != pBestMatch[nNextIndex].offset && nRepIndex > pBestMatch[nNextIndex].offset &&
                     (nRepIndex - pBestMatch[nNextIndex].offset + nRepMatchLen) <= (nEndOffset - LAST_LITERALS) &&
                     !memcmp(pInWindow + nRepIndex - nRepMatchOffset, pInWindow + nRepIndex - pBestMatch[nNextIndex].offset, nRepMatchLen)) {
                     /* Replacing this match command by literals would let us create a repmatch */
                     nReplaceRepOffset = 1;
                     nReducedCommandSize -= (nRepMatchOffset <= 32) ? 4 : ((nRepMatchOffset <= 512) ? 8 : ((nRepMatchOffset <= (8192 + 512)) ? 12 : 16));
                  }

                  if (nOriginalCombinedCommandSize >= nReducedCommandSize) {
                     /* Reduce */
                     int nMatchLen = pMatch->length;
                     int j;

                     for (j = 0; j < nMatchLen; j++) {
                        pBestMatch[i + j].length = 0;
                     }

                     nDidReduce = 1;

                     if (nReplaceRepOffset) {
                        pBestMatch[nRepIndex].offset = pBestMatch[nNextIndex].offset;
                        nRepMatchOffset = pBestMatch[nNextIndex].offset;
                     }
                     continue;
                  }
               }
            }
         }

         if ((i + pMatch->length) <= nEndOffset && pMatch->offset > 0 && pMatch->length >= MIN_MATCH_SIZE_V2 &&
            pBestMatch[i + pMatch->length].offset > 0 &&
            pBestMatch[i + pMatch->length].length >= MIN_MATCH_SIZE_V2 &&
            (pMatch->length + pBestMatch[i + pMatch->length].length) >= LEAVE_ALONE_MATCH_SIZE &&
            (pMatch->length + pBestMatch[i + pMatch->length].length) <= MAX_VARLEN &&
            (i + pMatch->length) > pMatch->offset &&
            (i + pMatch->length) > pBestMatch[i + pMatch->length].offset &&
            (i + pMatch->length + pBestMatch[i + pMatch->length].length) <= nEndOffset &&
            !memcmp(pInWindow + i - pMatch->offset + pMatch->length,
               pInWindow + i + pMatch->length - pBestMatch[i + pMatch->length].offset,
               pBestMatch[i + pMatch->length].length)) {

            int nNextIndex = i + pMatch->length;
            int nNextLiterals = 0;

            while (nNextIndex < nEndOffset && pBestMatch[nNextIndex].length < MIN_MATCH_SIZE_V2) {
               nNextLiterals++;
               nNextIndex++;
            }

            int nCurPartialSize = lzsa_get_match_varlen_size_v2(pMatch->length - MIN_MATCH_SIZE_V2);

            nCurPartialSize += 8 /* token */ + lzsa_get_literals_varlen_size_v2(0) + lzsa_get_match_varlen_size_v2(pBestMatch[i + pMatch->length].length - MIN_MATCH_SIZE_V2);
            if (pBestMatch[i + pMatch->length].offset != pMatch->offset)
               nCurPartialSize += (pBestMatch[i + pMatch->length].offset <= 32) ? 4 : ((pBestMatch[i + pMatch->length].offset <= 512) ? 8 : ((pBestMatch[i + pMatch->length].offset <= (8192 + 512)) ? 12 : 16));

            if (pBestMatch[nNextIndex].offset != pBestMatch[i + pMatch->length].offset)
               nCurPartialSize += (pBestMatch[nNextIndex].offset <= 32) ? 4 : ((pBestMatch[nNextIndex].offset <= 512) ? 8 : ((pBestMatch[nNextIndex].offset <= (8192 + 512)) ? 12 : 16));

            int nReducedPartialSize = lzsa_get_match_varlen_size_v2(pMatch->length + pBestMatch[i + pMatch->length].length - MIN_MATCH_SIZE_V2);

            if (pBestMatch[nNextIndex].offset != pMatch->offset)
               nReducedPartialSize += (pBestMatch[nNextIndex].offset <= 32) ? 4 : ((pBestMatch[nNextIndex].offset <= 512) ? 8 : ((pBestMatch[nNextIndex].offset <= (8192 + 512)) ? 12 : 16));

            if (nCurPartialSize >= nReducedPartialSize) {
               int nMatchLen = pMatch->length;

               /* Join */

               pMatch->length += pBestMatch[i + nMatchLen].length;
               pBestMatch[i + nMatchLen].offset = 0;
               pBestMatch[i + nMatchLen].length = -1;
               nDidReduce = 1;
               continue;
            }
         }

         nPrevRepMatchOffset = nRepMatchOffset;
         nRepMatchOffset = pMatch->offset;
         nRepMatchLen = pMatch->length;
         nRepIndex = i;

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
static int lzsa_get_compressed_size_v2(lzsa_compressor *pCompressor, lzsa_match *pBestMatch, const int nStartOffset, const int nEndOffset) {
   int i;
   int nNumLiterals = 0;
   int nOutOffset = 0;
   int nRepMatchOffset = 0;
   int nCompressedSize = 0;

   for (i = nStartOffset; i < nEndOffset; ) {
      const lzsa_match *pMatch = pBestMatch + i;

      if (pMatch->length >= MIN_MATCH_SIZE_V2) {
         int nMatchOffset = pMatch->offset;
         int nMatchLen = pMatch->length;
         int nEncodedMatchLen = nMatchLen - MIN_MATCH_SIZE_V2;
         int nOffsetSize;

         if (nMatchOffset == nRepMatchOffset) {
            nOffsetSize = 0;
         }
         else {
            if (nMatchOffset <= 32) {
               nOffsetSize = 4;
            }
            else if (nMatchOffset <= 512) {
               nOffsetSize = 8;
            }
            else if (nMatchOffset <= (8192 + 512)) {
               nOffsetSize = 12;
            }
            else {
               nOffsetSize = 16;
            }
         }

         int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNumLiterals) + (nNumLiterals << 3) + nOffsetSize /* match offset */ + lzsa_get_match_varlen_size_v2(nEncodedMatchLen);
         nCompressedSize += nCommandSize;

         nNumLiterals = 0;
         nRepMatchOffset = nMatchOffset;
         i += nMatchLen;
      }
      else {
         nNumLiterals++;
         i++;
      }
   }

   {
      int nTokenLiteralsLen = (nNumLiterals >= LITERALS_RUN_LEN_V2) ? LITERALS_RUN_LEN_V2 : nNumLiterals;
      int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNumLiterals) + (nNumLiterals << 3);

      nCompressedSize += nCommandSize;
      nNumLiterals = 0;
   }

   if (pCompressor->flags & LZSA_FLAG_RAW_BLOCK) {
      nCompressedSize += (8 + 4 + 8);
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
static int lzsa_write_block_v2(lzsa_compressor *pCompressor, lzsa_match *pBestMatch, const unsigned char *pInWindow, const int nStartOffset, const int nEndOffset, unsigned char *pOutData, const int nMaxOutDataSize) {
   int i;
   int nNumLiterals = 0;
   int nInFirstLiteralOffset = 0;
   int nOutOffset = 0;
   int nCurNibbleOffset = -1, nCurFreeNibbles = 0;
   int nRepMatchOffset = 0;

   for (i = nStartOffset; i < nEndOffset; ) {
      const lzsa_match *pMatch = pBestMatch + i;

      if (pMatch->length >= MIN_MATCH_SIZE_V2) {
         int nMatchOffset = pMatch->offset;
         int nMatchLen = pMatch->length;
         int nEncodedMatchLen = nMatchLen - MIN_MATCH_SIZE_V2;
         int nTokenLiteralsLen = (nNumLiterals >= LITERALS_RUN_LEN_V2) ? LITERALS_RUN_LEN_V2 : nNumLiterals;
         int nTokenMatchLen = (nEncodedMatchLen >= MATCH_RUN_LEN_V2) ? MATCH_RUN_LEN_V2 : nEncodedMatchLen;
         int nTokenOffsetMode;
         int nOffsetSize;

         if (nMatchOffset == nRepMatchOffset) {
            nTokenOffsetMode = 0xe0;
            nOffsetSize = 0;
         }
         else {
            if (nMatchOffset <= 32) {
               nTokenOffsetMode = 0x00 | ((((-nMatchOffset) & 0x01) << 5) ^ 0x20);
               nOffsetSize = 4;
            }
            else if (nMatchOffset <= 512) {
               nTokenOffsetMode = 0x40 | ((((-nMatchOffset) & 0x100) >> 3) ^ 0x20);
               nOffsetSize = 8;
            }
            else if (nMatchOffset <= (8192 + 512)) {
               nTokenOffsetMode = 0x80 | ((((-(nMatchOffset - 512)) & 0x0100) >> 3) ^ 0x20);
               nOffsetSize = 12;
            }
            else {
               nTokenOffsetMode = 0xc0;
               nOffsetSize = 16;
            }
         }

         int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNumLiterals) + (nNumLiterals << 3) + nOffsetSize /* match offset */ + lzsa_get_match_varlen_size_v2(nEncodedMatchLen);

         if ((nOutOffset + ((nCommandSize + 7) >> 3)) > nMaxOutDataSize)
            return -1;
         if (nMatchOffset < MIN_OFFSET || nMatchOffset > MAX_OFFSET)
            return -1;

         pOutData[nOutOffset++] = nTokenOffsetMode | (nTokenLiteralsLen << 3) | nTokenMatchLen;
         nOutOffset = lzsa_write_literals_varlen_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, &nCurFreeNibbles, nNumLiterals);
         if (nOutOffset < 0) return -1;

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

         if (nTokenOffsetMode == 0x00 || nTokenOffsetMode == 0x20) {
            nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, &nCurFreeNibbles, ((-nMatchOffset) & 0x1e) >> 1);
            if (nOutOffset < 0) return -1;
         }
         else if (nTokenOffsetMode == 0x40 || nTokenOffsetMode == 0x60) {
            pOutData[nOutOffset++] = (-nMatchOffset) & 0xff;
         }
         else if (nTokenOffsetMode == 0x80 || nTokenOffsetMode == 0xa0) {
            nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, &nCurFreeNibbles, ((-(nMatchOffset - 512)) >> 9) & 0x0f);
            if (nOutOffset < 0) return -1;
            pOutData[nOutOffset++] = (-(nMatchOffset - 512)) & 0xff;
         }
         else if (nTokenOffsetMode == 0xc0) {
            pOutData[nOutOffset++] = (-nMatchOffset) >> 8;
            pOutData[nOutOffset++] = (-nMatchOffset) & 0xff;
         }

         if (nMatchOffset == nRepMatchOffset)
            pCompressor->stats.num_rep_offsets++;

         nRepMatchOffset = nMatchOffset;

         nOutOffset = lzsa_write_match_varlen_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, &nCurFreeNibbles, nEncodedMatchLen);
         if (nOutOffset < 0) return -1;

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
      int nTokenLiteralsLen = (nNumLiterals >= LITERALS_RUN_LEN_V2) ? LITERALS_RUN_LEN_V2 : nNumLiterals;
      int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNumLiterals) + (nNumLiterals << 3);

      if ((nOutOffset + ((nCommandSize + 7) >> 3)) > nMaxOutDataSize)
         return -1;

      if (pCompressor->flags & LZSA_FLAG_RAW_BLOCK)
         pOutData[nOutOffset++] = (nTokenLiteralsLen << 3) | 0x47;
      else
         pOutData[nOutOffset++] = (nTokenLiteralsLen << 3) | 0x00;
      nOutOffset = lzsa_write_literals_varlen_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, &nCurFreeNibbles, nNumLiterals);
      if (nOutOffset < 0) return -1;

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

      if (nOutOffset >= nMaxOutDataSize)
         return -1;
      pOutData[nOutOffset++] = 0;      /* Match offset */

      nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, &nCurFreeNibbles, 15);   /* Extended match length nibble */
      if (nOutOffset < 0) return -1;

      if ((nOutOffset + 1) > nMaxOutDataSize)
         return -1;

      pOutData[nOutOffset++] = 232;    /* EOD match length byte */
   }

   if (nCurNibbleOffset != -1) {
      nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, &nCurFreeNibbles, 0);
      if (nOutOffset < 0 || nCurNibbleOffset != -1)
         return -1;
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
static int lzsa_write_raw_uncompressed_block_v2(lzsa_compressor *pCompressor, const unsigned char *pInWindow, const int nStartOffset, const int nEndOffset, unsigned char *pOutData, const int nMaxOutDataSize) {
   int nCurNibbleOffset = -1, nCurFreeNibbles = 0;
   int nNumLiterals = nEndOffset - nStartOffset;
   int nTokenLiteralsLen = (nNumLiterals >= LITERALS_RUN_LEN_V2) ? LITERALS_RUN_LEN_V2 : nNumLiterals;
   int nOutOffset = 0;

   int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNumLiterals) + (nNumLiterals << 3) + 8 + 4 + 8;
   if ((nOutOffset + ((nCommandSize + 7) >> 3)) > nMaxOutDataSize)
      return -1;

   pCompressor->num_commands = 0;
   pOutData[nOutOffset++] = (nTokenLiteralsLen << 3) | 0x47;

   nOutOffset = lzsa_write_literals_varlen_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, &nCurFreeNibbles, nNumLiterals);
   if (nOutOffset < 0) return -1;

   if (nNumLiterals != 0) {
      memcpy(pOutData + nOutOffset, pInWindow + nStartOffset, nNumLiterals);
      nOutOffset += nNumLiterals;
      nNumLiterals = 0;
   }

   /* Emit EOD marker for raw block */

   pOutData[nOutOffset++] = 0;      /* Match offset */

   nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, &nCurFreeNibbles, 15);   /* Extended match length nibble */
   if (nOutOffset < 0) return -1;

   if ((nOutOffset + 1) > nMaxOutDataSize)
      return -1;

   pOutData[nOutOffset++] = 232;    /* EOD match length byte */

   pCompressor->num_commands++;

   if (nCurNibbleOffset != -1) {
      nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, &nCurFreeNibbles, 0);
      if (nOutOffset < 0 || nCurNibbleOffset != -1)
         return -1;
   }

   return nOutOffset;
}

/**
 * Select the most optimal matches, reduce the token count if possible, and then emit a block of compressed LZSA2 data
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
int lzsa_optimize_and_write_block_v2(lzsa_compressor *pCompressor, const unsigned char *pInWindow, const int nPreviousBlockSize, const int nInDataSize, unsigned char *pOutData, const int nMaxOutDataSize) {
   int nResult, nBaseCompressedSize;
   int nMatchesPerArrival = (nInDataSize < 65536) ? NMATCHES_PER_ARRIVAL_V2_BIG : NMATCHES_PER_ARRIVAL_V2_SMALL;

   /* Compress optimally without breaking ties in favor of less tokens */
   
   memset(pCompressor->best_match, 0, BLOCK_SIZE * sizeof(lzsa_match));
   lzsa_optimize_forward_v2(pCompressor, pInWindow, pCompressor->best_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, 0 /* reduce */, (nInDataSize < 65536) ? 1 : 0 /* insert forward reps */, nMatchesPerArrival);

   int nDidReduce;
   int nPasses = 0;
   do {
      nDidReduce = lzsa_optimize_command_count_v2(pCompressor, pInWindow, pCompressor->best_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
      nPasses++;
   } while (nDidReduce && nPasses < 20);

   nBaseCompressedSize = lzsa_get_compressed_size_v2(pCompressor, pCompressor->best_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
   lzsa_match *pBestMatch = pCompressor->best_match - nPreviousBlockSize;

   if (nBaseCompressedSize > 0 && nInDataSize < 65536) {
      int nReducedCompressedSize;

      /* Compress optimally and do break ties in favor of less tokens */
      memset(pCompressor->improved_match, 0, BLOCK_SIZE * sizeof(lzsa_match));
      lzsa_optimize_forward_v2(pCompressor, pInWindow, pCompressor->improved_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, 1 /* reduce */, 0 /* use forward reps */, nMatchesPerArrival);

      nPasses = 0;
      do {
         nDidReduce = lzsa_optimize_command_count_v2(pCompressor, pInWindow, pCompressor->improved_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
         nPasses++;
      } while (nDidReduce && nPasses < 20);

      nReducedCompressedSize = lzsa_get_compressed_size_v2(pCompressor, pCompressor->improved_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
      if (nReducedCompressedSize > 0 && nReducedCompressedSize <= nBaseCompressedSize) {
         /* Pick the parse with the reduced number of tokens as it didn't negatively affect the size */
         pBestMatch = pCompressor->improved_match - nPreviousBlockSize;
      }
   }

   nResult = lzsa_write_block_v2(pCompressor, pBestMatch, pInWindow, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, pOutData, nMaxOutDataSize);
   if (nResult < 0 && pCompressor->flags & LZSA_FLAG_RAW_BLOCK) {
      nResult = lzsa_write_raw_uncompressed_block_v2(pCompressor, pInWindow, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, pOutData, nMaxOutDataSize);
   }

   return nResult;
}
