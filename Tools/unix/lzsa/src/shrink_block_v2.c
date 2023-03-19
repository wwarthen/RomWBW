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
 * @param nNibbleValue value to write (0..15)
 */
static int lzsa_write_nibble_v2(unsigned char *pOutData, int nOutOffset, const int nMaxOutDataSize, int *nCurNibbleOffset, int nNibbleValue) {
   if (nOutOffset < 0) return -1;

   if ((*nCurNibbleOffset) == -1) {
      if (nOutOffset >= nMaxOutDataSize) return -1;
      (*nCurNibbleOffset) = nOutOffset;
      pOutData[nOutOffset++] = nNibbleValue << 4;
   }
   else {
      pOutData[*nCurNibbleOffset] = (pOutData[*nCurNibbleOffset]) | (nNibbleValue & 0x0f);
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
 * @param nMaxOutDataSize maximum size of output buffer, in bytes
 * @param nCurNibbleOffset write index into output buffer, of current byte being filled with nibbles
 * @param nLength literals length
 */
static inline int lzsa_write_literals_varlen_v2(unsigned char *pOutData, int nOutOffset, const int nMaxOutDataSize, int *nCurNibbleOffset, int nLength) {
   if (nLength >= LITERALS_RUN_LEN_V2) {
      if (nLength < (LITERALS_RUN_LEN_V2 + 15)) {
         nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, nCurNibbleOffset, nLength - LITERALS_RUN_LEN_V2);
      }
      else {
         nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, nCurNibbleOffset, 15);
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
 * @param nMaxOutDataSize maximum size of output buffer, in bytes
 * @param nCurNibbleOffset write index into output buffer, of current byte being filled with nibbles
 * @param nLength encoded match length (actual match length - MIN_MATCH_SIZE_V2)
 */
static inline int lzsa_write_match_varlen_v2(unsigned char *pOutData, int nOutOffset, const int nMaxOutDataSize, int *nCurNibbleOffset, int nLength) {
   if (nLength >= MATCH_RUN_LEN_V2) {
      if (nLength < (MATCH_RUN_LEN_V2 + 15)) {
         nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, nCurNibbleOffset, nLength - MATCH_RUN_LEN_V2);
      }
      else {
         nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, nCurNibbleOffset, 15);
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
 * @param nDepth current insertion depth
 */
static void lzsa_insert_forward_match_v2(lzsa_compressor *pCompressor, const unsigned char *pInWindow, const int i, const int nMatchOffset, const int nStartOffset, const int nEndOffset, int nDepth) {
   lzsa_arrival *arrival = pCompressor->arrival + ((i - nStartOffset) << ARRIVALS_PER_POSITION_SHIFT);
   const int *rle_len = (int*)pCompressor->intervals /* reuse */;
   lzsa_match* visited = ((lzsa_match*)pCompressor->pos_data) - nStartOffset /* reuse */;
   int j;

   for (j = 0; j < NARRIVALS_PER_POSITION_V2_BIG && arrival[j].from_slot; j++) {
      int nRepOffset = arrival[j].rep_offset;

      if (nMatchOffset != nRepOffset && nRepOffset && arrival[j].rep_len >= MIN_MATCH_SIZE_V2) {
         int nRepPos = arrival[j].rep_pos;
         int nRepLen = arrival[j].rep_len;

         if (nRepPos > nMatchOffset &&
            (nRepPos + nRepLen) <= nEndOffset &&
            pCompressor->match[((nRepPos - nStartOffset) << MATCHES_PER_INDEX_SHIFT_V2) + NMATCHES_PER_INDEX_V2 - 1].length == 0) {

            if (visited[nRepPos].offset != nMatchOffset || visited[nRepPos].length > nRepLen) {
               visited[nRepPos].offset = nMatchOffset;
               visited[nRepPos].length = nRepLen;

               if (pInWindow[nRepPos] == pInWindow[nRepPos - nMatchOffset]) {
                  int nLen0 = rle_len[nRepPos - nMatchOffset];
                  int nLen1 = rle_len[nRepPos];
                  int nMinLen = (nLen0 < nLen1) ? nLen0 : nLen1;

                  if (nMinLen >= nRepLen || !memcmp(pInWindow + nRepPos + nMinLen, pInWindow + nRepPos + nMinLen - nMatchOffset, nRepLen - nMinLen)) {
                     visited[nRepPos].length = 0;

                     lzsa_match* fwd_match = pCompressor->match + ((nRepPos - nStartOffset) << MATCHES_PER_INDEX_SHIFT_V2);
                     int r;

                     for (r = 0; r < NMATCHES_PER_INDEX_V2 && fwd_match[r].length >= MIN_MATCH_SIZE_V2; r++) {
                        if (fwd_match[r].offset == nMatchOffset) {
                           r = NMATCHES_PER_INDEX_V2;
                           break;
                        }
                     }

                     if (r < NMATCHES_PER_INDEX_V2) {
                        int nMaxRepLen = nEndOffset - nRepPos;
                        if (nMaxRepLen > LCP_MAX)
                           nMaxRepLen = LCP_MAX;
                        int nCurRepLen = (nMinLen > nRepLen) ? nMinLen : nRepLen;
                        if (nCurRepLen > nMaxRepLen)
                           nCurRepLen = nMaxRepLen;
                        const unsigned char* pInWindowMax = pInWindow + nRepPos + nMaxRepLen;
                        const unsigned char* pInWindowAtRepPos = pInWindow + nRepPos + nCurRepLen;
                        while ((pInWindowAtRepPos + 8) < pInWindowMax && !memcmp(pInWindowAtRepPos, pInWindowAtRepPos - nMatchOffset, 8))
                           pInWindowAtRepPos += 8;
                        while ((pInWindowAtRepPos + 4) < pInWindowMax && !memcmp(pInWindowAtRepPos, pInWindowAtRepPos - nMatchOffset, 4))
                           pInWindowAtRepPos += 4;
                        while (pInWindowAtRepPos < pInWindowMax && pInWindowAtRepPos[0] == pInWindowAtRepPos[-nMatchOffset])
                           pInWindowAtRepPos++;

                        nCurRepLen = (int)(pInWindowAtRepPos - (pInWindow + nRepPos));
                        fwd_match[r].offset = nMatchOffset;
                        fwd_match[r].length = nCurRepLen;

                        if (nDepth < 9)
                           lzsa_insert_forward_match_v2(pCompressor, pInWindow, nRepPos, nMatchOffset, nStartOffset, nEndOffset, nDepth + 1);
                     }
                  }
               }
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
 * @param nArrivalsPerPosition number of arrivals to record per input buffer position
 */
static void lzsa_optimize_forward_v2(lzsa_compressor *pCompressor, const unsigned char *pInWindow, lzsa_match *pBestMatch, const int nStartOffset, const int nEndOffset, const int nReduce, const int nInsertForwardReps, const int nArrivalsPerPosition) {
   lzsa_arrival *arrival = pCompressor->arrival - (nStartOffset << ARRIVALS_PER_POSITION_SHIFT);
   const int *rle_len = (int*)pCompressor->intervals /* reuse */;
   lzsa_match *visited = ((lzsa_match*)pCompressor->pos_data) - nStartOffset /* reuse */;
   char *nRepSlotHandledMask = pCompressor->rep_slot_handled_mask;
   char *nRepLenHandledMask = pCompressor->rep_len_handled_mask;
   const int nModeSwitchPenalty = (pCompressor->flags & LZSA_FLAG_FAVOR_RATIO) ? 0 : MODESWITCH_PENALTY;
   const int nMinMatchSize = pCompressor->min_match_size;
   const int nDisableScore = nReduce ? 0 : (2 * BLOCK_SIZE);
   const int nMaxRepInsertedLen = nReduce ? LEAVE_ALONE_MATCH_SIZE : 0;
   const int nLeaveAloneMatchSize = (nArrivalsPerPosition == NARRIVALS_PER_POSITION_V2_SMALL) ? LEAVE_ALONE_MATCH_SIZE_SMALL : LEAVE_ALONE_MATCH_SIZE;
   int i, j, n;

   if ((nEndOffset - nStartOffset) > BLOCK_SIZE) return;

   memset(arrival + (nStartOffset << ARRIVALS_PER_POSITION_SHIFT), 0, sizeof(lzsa_arrival) * ((nEndOffset - nStartOffset + 1) << ARRIVALS_PER_POSITION_SHIFT));

   for (i = (nStartOffset << ARRIVALS_PER_POSITION_SHIFT); i != ((nEndOffset + 1) << ARRIVALS_PER_POSITION_SHIFT); i++) {
      arrival[i].cost = 0x40000000;
   }

   arrival[nStartOffset << ARRIVALS_PER_POSITION_SHIFT].from_slot = -1;

   if (nInsertForwardReps) {
      memset(visited + nStartOffset, 0, (nEndOffset - nStartOffset) * sizeof(lzsa_match));
   }

   for (i = nStartOffset; i != nEndOffset; i++) {
      lzsa_arrival *cur_arrival = &arrival[i << ARRIVALS_PER_POSITION_SHIFT];
      int m;

      for (j = 0; j < nArrivalsPerPosition && cur_arrival[j].from_slot; j++) {
         const int nPrevCost = cur_arrival[j].cost & 0x3fffffff;
         int nCodingChoiceCost = nPrevCost + 8 /* literal */;
         int nScore = cur_arrival[j].score + 1;
         int nNumLiterals = cur_arrival[j].num_literals + 1;

         if (nNumLiterals == LITERALS_RUN_LEN_V2) {
            nCodingChoiceCost += 4;
         }
         else if (nNumLiterals == (LITERALS_RUN_LEN_V2 + 15)) {
            nCodingChoiceCost += 8;
         }
         else if (nNumLiterals == 256) {
            nCodingChoiceCost += 16;
         }

         if (nNumLiterals == 1)
            nCodingChoiceCost += nModeSwitchPenalty;

         lzsa_arrival *pDestSlots = &cur_arrival[1 << ARRIVALS_PER_POSITION_SHIFT];
         if (nCodingChoiceCost < pDestSlots[nArrivalsPerPosition - 1].cost ||
            (nCodingChoiceCost == pDestSlots[nArrivalsPerPosition - 1].cost && nScore < (pDestSlots[nArrivalsPerPosition - 1].score + nDisableScore))) {
            int nRepOffset = cur_arrival[j].rep_offset;
            int exists = 0;

            for (n = 0;
               n < nArrivalsPerPosition && pDestSlots[n].cost < nCodingChoiceCost;
               n++) {
               if (pDestSlots[n].rep_offset == nRepOffset) {
                  exists = 1;
                  break;
               }
            }

            if (!exists) {
               for (;
                  n < nArrivalsPerPosition && pDestSlots[n].cost == nCodingChoiceCost && nScore >= (pDestSlots[n].score + nDisableScore);
                  n++) {
                  if (pDestSlots[n].rep_offset == nRepOffset) {
                     exists = 1;
                     break;
                  }
               }

               if (!exists) {
                  if (n < nArrivalsPerPosition) {
                     int nn;

                     for (nn = n;
                        nn < nArrivalsPerPosition && pDestSlots[nn].cost == nCodingChoiceCost;
                        nn++) {
                        if (pDestSlots[nn].rep_offset == nRepOffset) {
                           exists = 1;
                           break;
                        }
                     }

                     if (!exists) {
                        int z;

                        for (z = n; z < nArrivalsPerPosition - 1 && pDestSlots[z].from_slot; z++) {
                           if (pDestSlots[z].rep_offset == nRepOffset)
                              break;
                        }

                        memmove(&pDestSlots[n + 1],
                           &pDestSlots[n],
                           sizeof(lzsa_arrival) * (z - n));

                        lzsa_arrival* pDestArrival = &pDestSlots[n];
                        pDestArrival->cost = nCodingChoiceCost;
                        pDestArrival->from_pos = i;
                        pDestArrival->from_slot = j + 1;
                        pDestArrival->match_len = 0;
                        pDestArrival->num_literals = nNumLiterals;
                        pDestArrival->score = nScore;
                        pDestArrival->rep_offset = nRepOffset;
                        pDestArrival->rep_pos = cur_arrival[j].rep_pos;
                        pDestArrival->rep_len = cur_arrival[j].rep_len;
                     }
                  }
               }
            }
         }
      }

      lzsa_match *match = pCompressor->match + ((i - nStartOffset) << MATCHES_PER_INDEX_SHIFT_V2);
      int nNumArrivalsForThisPos = j, nMinOverallRepLen = 0, nMaxOverallRepLen = 0;

      int nRepMatchArrivalIdxAndLen[(NARRIVALS_PER_POSITION_V2_BIG * 2) + 1];
      int nNumRepMatchArrivals = 0;

      int nMaxRepLenForPos = nEndOffset - i;
      if (nMaxRepLenForPos > LCP_MAX)
         nMaxRepLenForPos = LCP_MAX;
      const unsigned char* pInWindowStart = pInWindow + i;
      const unsigned char* pInWindowMax = pInWindowStart + nMaxRepLenForPos;

      for (j = 0; j < nNumArrivalsForThisPos && (i + MIN_MATCH_SIZE_V2) <= nEndOffset; j++) {
         int nRepOffset = cur_arrival[j].rep_offset;

         if (nRepOffset) {
            if (i > nRepOffset) {
               if (pInWindow[i] == pInWindow[i - nRepOffset]) {
                  const unsigned char* pInWindowAtPos;

                  int nLen0 = rle_len[i - nRepOffset];
                  int nLen1 = rle_len[i];
                  int nMinLen = (nLen0 < nLen1) ? nLen0 : nLen1;

                  if (nMinLen > nMaxRepLenForPos)
                     nMinLen = nMaxRepLenForPos;
                  pInWindowAtPos = pInWindowStart + nMinLen;

                  while ((pInWindowAtPos + 8) < pInWindowMax && !memcmp(pInWindowAtPos - nRepOffset, pInWindowAtPos, 8))
                     pInWindowAtPos += 8;
                  while ((pInWindowAtPos + 4) < pInWindowMax && !memcmp(pInWindowAtPos - nRepOffset, pInWindowAtPos, 4))
                     pInWindowAtPos += 4;
                  while (pInWindowAtPos < pInWindowMax && pInWindowAtPos[-nRepOffset] == pInWindowAtPos[0])
                     pInWindowAtPos++;
                  int nCurRepLen = (int)(pInWindowAtPos - pInWindowStart);

                  if (nCurRepLen >= MIN_MATCH_SIZE_V2) {
                     if (nMaxOverallRepLen < nCurRepLen)
                        nMaxOverallRepLen = nCurRepLen;
                     nRepMatchArrivalIdxAndLen[nNumRepMatchArrivals++] = j;
                     nRepMatchArrivalIdxAndLen[nNumRepMatchArrivals++] = nCurRepLen;
                  }
               }
            }
         }
      }
      nRepMatchArrivalIdxAndLen[nNumRepMatchArrivals] = -1;

      if (!nReduce) {
         memset(nRepSlotHandledMask, 0, nArrivalsPerPosition * ((LCP_MAX + 1) / 8) * sizeof(char));
      }
      memset(nRepLenHandledMask, 0, ((LCP_MAX + 1) / 8) * sizeof(char));

      for (m = 0; m < NMATCHES_PER_INDEX_V2 && match[m].length; m++) {
         int nMatchLen = match[m].length & 0x7fff;
         int nMatchOffset = match[m].offset;
         int nScorePenalty = 3 + ((match[m].length & 0x8000) >> 15);
         int nNoRepmatchOffsetCost = (nMatchOffset <= 32) ? 4 : ((nMatchOffset <= 512) ? 8 : ((nMatchOffset <= (8192 + 512)) ? 12 : 16));
         int nStartingMatchLen, k;

         if ((i + nMatchLen) > nEndOffset)
            nMatchLen = nEndOffset - i;

         if (nInsertForwardReps)
            lzsa_insert_forward_match_v2(pCompressor, pInWindow, i, nMatchOffset, nStartOffset, nEndOffset, 0);

         int nNonRepMatchArrivalIdx = -1;
         for (j = 0; j < nNumArrivalsForThisPos; j++) {
            int nRepOffset = cur_arrival[j].rep_offset;

            if (nMatchOffset != nRepOffset) {
               nNonRepMatchArrivalIdx = j;
               break;
            }
         }

         int nMatchLenCost;
         if (nMatchLen >= nLeaveAloneMatchSize) {
            nStartingMatchLen = nMatchLen;
            nMatchLenCost = 4 + 24 + 8 /* token */;
         }
         else {
            nStartingMatchLen = nMinMatchSize;
            nMatchLenCost = 0 + 8 /* token */;
         }

         for (k = nStartingMatchLen; k <= nMatchLen; k++) {
            if (k == (MATCH_RUN_LEN_V2 + MIN_MATCH_SIZE_V2)) {
               nMatchLenCost = 4 + 8 /* token */;
            }
            else {
               if (k == (MATCH_RUN_LEN_V2 + 15 + MIN_MATCH_SIZE_V2))
                  nMatchLenCost = 4 + 8 + 8 /* token */;
               else {
                  if (k == 256)
                     nMatchLenCost = 4 + 24 + 8 /* token */;
               }
            }

            lzsa_arrival *pDestSlots = &cur_arrival[k << ARRIVALS_PER_POSITION_SHIFT];

            /* Insert non-repmatch candidate */

            if (nNonRepMatchArrivalIdx >= 0) {
               const int nPrevCost = cur_arrival[nNonRepMatchArrivalIdx].cost & 0x3fffffff;
               int nCodingChoiceCost = nPrevCost /* the actual cost of the literals themselves accumulates up the chain */ + nMatchLenCost + nNoRepmatchOffsetCost;

               if (!cur_arrival[nNonRepMatchArrivalIdx].num_literals)
                  nCodingChoiceCost += nModeSwitchPenalty;

               int nScore = cur_arrival[nNonRepMatchArrivalIdx].score + nScorePenalty;
               if (nCodingChoiceCost < pDestSlots[nArrivalsPerPosition - 2].cost ||
                  (nCodingChoiceCost == pDestSlots[nArrivalsPerPosition - 2].cost && nScore < (pDestSlots[nArrivalsPerPosition - 2].score + nDisableScore))) {
                  int exists = 0;

                  for (n = 0;
                     n < nArrivalsPerPosition && pDestSlots[n].cost < nCodingChoiceCost;
                     n++) {
                     if (pDestSlots[n].rep_offset == nMatchOffset) {
                        exists = 1;
                        break;
                     }
                  }

                  if (!exists) {
                     for (;
                        n < nArrivalsPerPosition && pDestSlots[n].cost == nCodingChoiceCost && nScore >= (pDestSlots[n].score + nDisableScore);
                        n++) {
                        if (pDestSlots[n].rep_offset == nMatchOffset) {
                           exists = 1;
                           break;
                        }
                     }

                     if (!exists) {
                        if (n < nArrivalsPerPosition - 1) {
                           int nn;

                           for (nn = n;
                              nn < nArrivalsPerPosition && pDestSlots[nn].cost == nCodingChoiceCost;
                              nn++) {
                              if (pDestSlots[nn].rep_offset == nMatchOffset &&
                                 (!nInsertForwardReps || pDestSlots[nn].rep_pos >= i ||
                                    pDestSlots[nArrivalsPerPosition - 1].from_slot)) {
                                 exists = 1;
                                 break;
                              }
                           }

                           if (!exists) {
                              int z;

                              for (z = n; z < nArrivalsPerPosition - 1 && pDestSlots[z].from_slot; z++) {
                                 if (pDestSlots[z].rep_offset == nMatchOffset)
                                    break;
                              }

                              if (z == (nArrivalsPerPosition - 1) && pDestSlots[z].from_slot && pDestSlots[z].match_len < MIN_MATCH_SIZE_V2)
                                 z--;

                              memmove(&pDestSlots[n + 1],
                                 &pDestSlots[n],
                                 sizeof(lzsa_arrival) * (z - n));

                              lzsa_arrival* pDestArrival = &pDestSlots[n];
                              pDestArrival->cost = nCodingChoiceCost;
                              pDestArrival->from_pos = i;
                              pDestArrival->from_slot = nNonRepMatchArrivalIdx + 1;
                              pDestArrival->match_len = k;
                              pDestArrival->num_literals = 0;
                              pDestArrival->score = nScore;
                              pDestArrival->rep_offset = nMatchOffset;
                              pDestArrival->rep_pos = i;
                              pDestArrival->rep_len = k;
                              nRepLenHandledMask[k >> 3] &= ~(1 << (k & 7));
                           }
                        }
                     }
                  }
               }
            }

            /* Insert repmatch candidates */

            if (k > nMinOverallRepLen && k <= nMaxOverallRepLen && (nRepLenHandledMask[k >> 3] & (1 << (k & 7))) == 0) {
               int nCurRepMatchArrival;

               nRepLenHandledMask[k >> 3] |= 1 << (k & 7);

               for (nCurRepMatchArrival = 0; (j = nRepMatchArrivalIdxAndLen[nCurRepMatchArrival]) >= 0; nCurRepMatchArrival += 2) {
                  int nMaskOffset = (j << 7) + (k >> 3);
                  if (nRepMatchArrivalIdxAndLen[nCurRepMatchArrival + 1] >= k && (nReduce || !(nRepSlotHandledMask[nMaskOffset] & (1 << (k & 7))))) {
                     const int nPrevCost = cur_arrival[j].cost & 0x3fffffff;
                     int nRepCodingChoiceCost = nPrevCost /* the actual cost of the literals themselves accumulates up the chain */ + nMatchLenCost;
                     int nScore = cur_arrival[j].score + 2;

                     if (nRepCodingChoiceCost < pDestSlots[nArrivalsPerPosition - 1].cost ||
                        (nRepCodingChoiceCost == pDestSlots[nArrivalsPerPosition - 1].cost && nScore < (pDestSlots[nArrivalsPerPosition - 1].score + nDisableScore))) {
                        int nRepOffset = cur_arrival[j].rep_offset;
                        int exists = 0;

                        for (n = 0;
                           n < nArrivalsPerPosition && pDestSlots[n].cost < nRepCodingChoiceCost;
                           n++) {
                           if (pDestSlots[n].rep_offset == nRepOffset) {
                              exists = 1;
                              if (!nReduce)
                                 nRepSlotHandledMask[nMaskOffset] |= 1 << (k & 7);
                              break;
                           }
                        }

                        if (!exists) {
                           for (;
                              n < nArrivalsPerPosition && pDestSlots[n].cost == nRepCodingChoiceCost && nScore >= (pDestSlots[n].score + nDisableScore);
                              n++) {
                              if (pDestSlots[n].rep_offset == nRepOffset) {
                                 exists = 1;
                                 break;
                              }
                           }

                           if (!exists) {
                              if (n < nArrivalsPerPosition) {
                                 int nn;

                                 for (nn = n;
                                    nn < nArrivalsPerPosition && pDestSlots[nn].cost == nRepCodingChoiceCost;
                                    nn++) {
                                    if (pDestSlots[nn].rep_offset == nRepOffset) {
                                       exists = 1;
                                       break;
                                    }
                                 }

                                 if (!exists) {
                                    int z;

                                    for (z = n; z < nArrivalsPerPosition - 1 && pDestSlots[z].from_slot; z++) {
                                       if (pDestSlots[z].rep_offset == nRepOffset)
                                          break;
                                    }

                                    memmove(&pDestSlots[n + 1],
                                       &pDestSlots[n],
                                       sizeof(lzsa_arrival) * (z - n));

                                    lzsa_arrival* pDestArrival = &pDestSlots[n];
                                    pDestArrival->cost = nRepCodingChoiceCost;
                                    pDestArrival->from_pos = i;
                                    pDestArrival->from_slot = j + 1;
                                    pDestArrival->match_len = k;
                                    pDestArrival->num_literals = 0;
                                    pDestArrival->score = nScore;
                                    pDestArrival->rep_offset = nRepOffset;
                                    pDestArrival->rep_pos = i;
                                    pDestArrival->rep_len = k;
                                    nRepLenHandledMask[k >> 3] &= ~(1 << (k & 7));
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

               if (k < nMaxRepInsertedLen)
                  nMinOverallRepLen = k;
            }
         }

         if (nMatchLen >= LCP_MAX && ((m + 1) >= NMATCHES_PER_INDEX_V2 || match[m + 1].length < LCP_MAX))
            break;
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
         (i + 1) < nEndOffset &&
         pBestMatch[i + 1].length >= MIN_MATCH_SIZE_V2 &&
         pBestMatch[i + 1].length < MAX_VARLEN &&
         pBestMatch[i + 1].offset &&
         i >= pBestMatch[i + 1].offset &&
         (i + pBestMatch[i + 1].length + 1) <= nEndOffset &&
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
                     (i - nRepMatchOffset + pMatch->length) <= nEndOffset &&
                     !memcmp(pInWindow + i - nRepMatchOffset, pInWindow + i - pMatch->offset, pMatch->length)) {
                     pMatch->offset = nRepMatchOffset;
                     nDidReduce = 1;
                  }
               }

               if (pBestMatch[nNextIndex].offset && pMatch->offset != pBestMatch[nNextIndex].offset && nRepMatchOffset != pBestMatch[nNextIndex].offset) {
                  /* Otherwise, try to gain a match forward as well */
                  if (i > pBestMatch[nNextIndex].offset && (i - pBestMatch[nNextIndex].offset + pMatch->length) <= nEndOffset) {
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
                  int nNextCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNextLiterals) + /* (nNextLiterals << 3) + */ lzsa_get_match_varlen_size_v2(pBestMatch[nNextIndex].length - MIN_MATCH_SIZE_V2);
                  if (pBestMatch[nNextIndex].offset != pMatch->offset)
                     nNextCommandSize += (pBestMatch[nNextIndex].offset <= 32) ? 4 : ((pBestMatch[nNextIndex].offset <= 512) ? 8 : ((pBestMatch[nNextIndex].offset <= (8192 + 512)) ? 12 : 16));

                  int nOriginalCombinedCommandSize = nCurCommandSize + nNextCommandSize;

                  /* Calculate the cost of replacing this match command by literals + the next command with the cost of encoding these literals (excluding 'nNumLiterals' bytes) */
                  int nReducedCommandSize = (pMatch->length << 3) + 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNumLiterals + pMatch->length + nNextLiterals) + /* (nNextLiterals << 3) + */ lzsa_get_match_varlen_size_v2(pBestMatch[nNextIndex].length - MIN_MATCH_SIZE_V2);
                  if (pBestMatch[nNextIndex].offset != nRepMatchOffset)
                     nReducedCommandSize += (pBestMatch[nNextIndex].offset <= 32) ? 4 : ((pBestMatch[nNextIndex].offset <= 512) ? 8 : ((pBestMatch[nNextIndex].offset <= (8192 + 512)) ? 12 : 16));

                  int nReplaceRepOffset = 0;
                  if (nRepMatchOffset && nRepMatchOffset != nPrevRepMatchOffset && nRepMatchLen >= MIN_MATCH_SIZE_V2 && nRepMatchOffset != pBestMatch[nNextIndex].offset && nRepIndex > pBestMatch[nNextIndex].offset &&
                     (nRepIndex - pBestMatch[nNextIndex].offset + nRepMatchLen) <= nEndOffset &&
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

            while (nNextIndex < nEndOffset && pBestMatch[nNextIndex].length < MIN_MATCH_SIZE_V2) {
               nNextIndex++;
            }

            int nNextOffset;
            if (nNextIndex < nEndOffset)
               nNextOffset = pBestMatch[nNextIndex].offset;
            else
               nNextOffset = 0;

            int nCurPartialSize = lzsa_get_match_varlen_size_v2(pMatch->length - MIN_MATCH_SIZE_V2);

            nCurPartialSize += 8 /* token */ + /* lzsa_get_literals_varlen_size_v2(0) + */ lzsa_get_match_varlen_size_v2(pBestMatch[i + pMatch->length].length - MIN_MATCH_SIZE_V2);
            if (pBestMatch[i + pMatch->length].offset != pMatch->offset)
               nCurPartialSize += (pBestMatch[i + pMatch->length].offset <= 32) ? 4 : ((pBestMatch[i + pMatch->length].offset <= 512) ? 8 : ((pBestMatch[i + pMatch->length].offset <= (8192 + 512)) ? 12 : 16));

            if (nNextOffset != pBestMatch[i + pMatch->length].offset)
               nCurPartialSize += (nNextOffset <= 32) ? 4 : ((nNextOffset <= 512) ? 8 : ((nNextOffset <= (8192 + 512)) ? 12 : 16));

            int nReducedPartialSize = lzsa_get_match_varlen_size_v2(pMatch->length + pBestMatch[i + pMatch->length].length - MIN_MATCH_SIZE_V2);

            if (nNextOffset != pMatch->offset)
               nReducedPartialSize += (nNextOffset <= 32) ? 4 : ((nNextOffset <= 512) ? 8 : ((nNextOffset <= (8192 + 512)) ? 12 : 16));

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
      int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNumLiterals) + (nNumLiterals << 3);

      nCompressedSize += nCommandSize;
      nNumLiterals = 0;
   }

   if (pCompressor->flags & LZSA_FLAG_RAW_BLOCK) {
      nCompressedSize += (8 + 4);
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
   int nCurNibbleOffset = -1;
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
         nOutOffset = lzsa_write_literals_varlen_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, nNumLiterals);
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
            nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, ((-nMatchOffset) & 0x1e) >> 1);
            if (nOutOffset < 0) return -1;
         }
         else if (nTokenOffsetMode == 0x40 || nTokenOffsetMode == 0x60) {
            pOutData[nOutOffset++] = (-nMatchOffset) & 0xff;
         }
         else if (nTokenOffsetMode == 0x80 || nTokenOffsetMode == 0xa0) {
            nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, ((-(nMatchOffset - 512)) >> 9) & 0x0f);
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

         nOutOffset = lzsa_write_match_varlen_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, nEncodedMatchLen);
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
         pOutData[nOutOffset++] = (nTokenLiteralsLen << 3) | 0xe7;
      else
         pOutData[nOutOffset++] = (nTokenLiteralsLen << 3) | 0x00;
      nOutOffset = lzsa_write_literals_varlen_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, nNumLiterals);
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

      nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, 15);   /* Extended match length nibble */
      if (nOutOffset < 0) return -1;

      if ((nOutOffset + 1) > nMaxOutDataSize)
         return -1;

      pOutData[nOutOffset++] = 232;    /* EOD match length byte */
   }

   if (nCurNibbleOffset != -1) {
      nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, 0);
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
   int nCurNibbleOffset = -1;
   int nNumLiterals = nEndOffset - nStartOffset;
   int nTokenLiteralsLen = (nNumLiterals >= LITERALS_RUN_LEN_V2) ? LITERALS_RUN_LEN_V2 : nNumLiterals;
   int nOutOffset = 0;

   int nCommandSize = 8 /* token */ + lzsa_get_literals_varlen_size_v2(nNumLiterals) + (nNumLiterals << 3) + 4 + 8;
   if ((nOutOffset + ((nCommandSize + 7) >> 3)) > nMaxOutDataSize)
      return -1;

   pCompressor->num_commands = 0;
   pOutData[nOutOffset++] = (nTokenLiteralsLen << 3) | 0xe7;

   nOutOffset = lzsa_write_literals_varlen_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, nNumLiterals);
   if (nOutOffset < 0) return -1;

   if (nNumLiterals != 0) {
      memcpy(pOutData + nOutOffset, pInWindow + nStartOffset, nNumLiterals);
      nOutOffset += nNumLiterals;
      nNumLiterals = 0;
   }

   /* Emit EOD marker for raw block */

   nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, 15);   /* Extended match length nibble */
   if (nOutOffset < 0) return -1;

   if ((nOutOffset + 1) > nMaxOutDataSize)
      return -1;

   pOutData[nOutOffset++] = 232;    /* EOD match length byte */

   pCompressor->num_commands++;

   if (nCurNibbleOffset != -1) {
      nOutOffset = lzsa_write_nibble_v2(pOutData, nOutOffset, nMaxOutDataSize, &nCurNibbleOffset, 0);
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
   int nArrivalsPerPosition = (nInDataSize < 65536) ? NARRIVALS_PER_POSITION_V2_BIG : NARRIVALS_PER_POSITION_V2_SMALL;
   int *rle_len = (int*)pCompressor->intervals /* reuse */;
   int i;

   i = 0;
   while (i < (nPreviousBlockSize + nInDataSize)) {
      int nRangeStartIdx = i;
      unsigned char c = pInWindow[nRangeStartIdx];
      do {
         i++;
      } while (i < (nPreviousBlockSize + nInDataSize) && pInWindow[i] == c);
      while (nRangeStartIdx < i) {
         rle_len[nRangeStartIdx] = i - nRangeStartIdx;
         nRangeStartIdx++;
      }
   }

   /* Compress optimally without breaking ties in favor of less tokens */
   
   memset(pCompressor->best_match, 0, BLOCK_SIZE * sizeof(lzsa_match));
   lzsa_optimize_forward_v2(pCompressor, pInWindow, pCompressor->best_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, 0 /* reduce */, (nInDataSize < 65536) ? 1 : 0 /* insert forward reps */, nArrivalsPerPosition);

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
      lzsa_optimize_forward_v2(pCompressor, pInWindow, pCompressor->improved_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, 1 /* reduce */, 0 /* use forward reps */, nArrivalsPerPosition);

      nPasses = 0;
      do {
         nDidReduce = lzsa_optimize_command_count_v2(pCompressor, pInWindow, pCompressor->improved_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
         nPasses++;
      } while (nDidReduce && nPasses < 20);

      nReducedCompressedSize = lzsa_get_compressed_size_v2(pCompressor, pCompressor->improved_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
      if (nReducedCompressedSize > 0 && nReducedCompressedSize <= nBaseCompressedSize) {
         const int nEndOffset = nPreviousBlockSize + nInDataSize;
         int nSupplementedCompressedSize;

         /* Pick the parse with the reduced number of tokens as it didn't negatively affect the size */
         pBestMatch = pCompressor->improved_match - nPreviousBlockSize;

         int* first_offset_for_byte = pCompressor->first_offset_for_byte;
         int* next_offset_for_pos = pCompressor->next_offset_for_pos;
         int nPosition;

         /* Supplement small matches */

         memset(first_offset_for_byte, 0xff, sizeof(int) * 65536);
         memset(next_offset_for_pos, 0xff, sizeof(int) * nInDataSize);

         for (nPosition = nPreviousBlockSize; nPosition < nEndOffset - 1; nPosition++) {
            next_offset_for_pos[nPosition - nPreviousBlockSize] = first_offset_for_byte[((unsigned int)pInWindow[nPosition]) | (((unsigned int)pInWindow[nPosition + 1]) << 8)];
            first_offset_for_byte[((unsigned int)pInWindow[nPosition]) | (((unsigned int)pInWindow[nPosition + 1]) << 8)] = nPosition;
         }

         for (nPosition = nPreviousBlockSize + 1; nPosition < (nEndOffset - 1); nPosition++) {
            lzsa_match* match = pCompressor->match + ((nPosition - nPreviousBlockSize) << MATCHES_PER_INDEX_SHIFT_V2);
            int m = 0, nInserted = 0;
            int nMatchPos;

            while (m < 15 && match[m].length)
               m++;

            for (nMatchPos = next_offset_for_pos[nPosition - nPreviousBlockSize]; m < 15 && nMatchPos >= 0; nMatchPos = next_offset_for_pos[nMatchPos - nPreviousBlockSize]) {
               int nMatchOffset = nPosition - nMatchPos;
               int nExistingMatchIdx;
               int nAlreadyExists = 0;

               for (nExistingMatchIdx = 0; nExistingMatchIdx < m; nExistingMatchIdx++) {
                  if (match[nExistingMatchIdx].offset == nMatchOffset) {
                     nAlreadyExists = 1;
                     break;
                  }
               }

               if (!nAlreadyExists) {
                  int nMatchLen = 2;
                  while (nMatchLen < 16 && (nPosition + nMatchLen + 4) < nEndOffset && !memcmp(pInWindow + nMatchPos + nMatchLen, pInWindow + nPosition + nMatchLen, 4))
                     nMatchLen += 4;
                  while (nMatchLen < 16 && (nPosition + nMatchLen) < nEndOffset && pInWindow[nMatchPos + nMatchLen] == pInWindow[nPosition + nMatchLen])
                     nMatchLen++;
                  match[m].length = nMatchLen;
                  match[m].offset = nMatchOffset;
                  m++;
                  nInserted++;
                  if (nInserted >= 15)
                     break;
               }
            }
         }

         /* Compress optimally with the extra matches */
         memset(pCompressor->best_match, 0, BLOCK_SIZE * sizeof(lzsa_match));
         lzsa_optimize_forward_v2(pCompressor, pInWindow, pCompressor->best_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, 1 /* reduce */, 0 /* use forward reps */, nArrivalsPerPosition);

         nPasses = 0;
         do {
            nDidReduce = lzsa_optimize_command_count_v2(pCompressor, pInWindow, pCompressor->best_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
            nPasses++;
         } while (nDidReduce && nPasses < 20);

         nSupplementedCompressedSize = lzsa_get_compressed_size_v2(pCompressor, pCompressor->best_match - nPreviousBlockSize, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);
         if (nSupplementedCompressedSize > 0 && nSupplementedCompressedSize < nReducedCompressedSize) {
            /* Pick the parse with the extra matches as it didn't negatively affect the size */
            pBestMatch = pCompressor->best_match - nPreviousBlockSize;
         }
      }
   }

   nResult = lzsa_write_block_v2(pCompressor, pBestMatch, pInWindow, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, pOutData, nMaxOutDataSize);
   if (nResult < 0 && pCompressor->flags & LZSA_FLAG_RAW_BLOCK) {
      nResult = lzsa_write_raw_uncompressed_block_v2(pCompressor, pInWindow, nPreviousBlockSize, nPreviousBlockSize + nInDataSize, pOutData, nMaxOutDataSize);
   }

   return nResult;
}
