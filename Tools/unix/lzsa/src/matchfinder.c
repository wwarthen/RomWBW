/*
 * matchfinder.c - LZ match finder implementation
 *
 * The following copying information applies to this specific source code file:
 *
 * Written in 2019 by Emmanuel Marty <marty.emmanuel@gmail.com>
 * Portions written in 2014-2015 by Eric Biggers <ebiggers3@gmail.com>
 *
 * To the extent possible under law, the author(s) have dedicated all copyright
 * and related and neighboring rights to this software to the public domain
 * worldwide via the Creative Commons Zero 1.0 Universal Public Domain
 * Dedication (the "CC0").
 *
 * This software is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the CC0 for more details.
 *
 * You should have received a copy of the CC0 along with this software; if not
 * see <http://creativecommons.org/publicdomain/zero/1.0/>.
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
#include "matchfinder.h"
#include "format.h"
#include "lib.h"

/**
 * Hash index into TAG_BITS
 *
 * @param nIndex index value
 *
 * @return hash
 */
static inline int lzsa_get_index_tag(unsigned int nIndex) {
   return (int)(((unsigned long long)nIndex * 11400714819323198485ULL) >> (64ULL - TAG_BITS));
}

/**
 * Parse input data, build suffix array and overlaid data structures to speed up match finding
 *
 * @param pCompressor compression context
 * @param pInWindow pointer to input data window (previously compressed bytes + bytes to compress)
 * @param nInWindowSize total input size in bytes (previously compressed bytes + bytes to compress)
 *
 * @return 0 for success, non-zero for failure
 */
int lzsa_build_suffix_array(lzsa_compressor *pCompressor, const unsigned char *pInWindow, const int nInWindowSize) {
   unsigned int *intervals = pCompressor->intervals;

   /* Build suffix array from input data */
   if (divsufsort_build_array(&pCompressor->divsufsort_context, pInWindow, (saidx_t*)intervals, nInWindowSize) != 0) {
      return 100;
   }

   int *PLCP = (int*)pCompressor->pos_data;  /* Use temporarily */
   int *Phi = PLCP;
   int nCurLen = 0;
   int i, r;

   /* Compute the permuted LCP first (Kärkkäinen method) */
   Phi[intervals[0]] = -1;
   for (i = 1; i < nInWindowSize; i++)
      Phi[intervals[i]] = intervals[i - 1];
   for (i = 0; i < nInWindowSize; i++) {
      if (Phi[i] == -1) {
         PLCP[i] = 0;
         continue;
      }
      int nMaxLen = (i > Phi[i]) ? (nInWindowSize - i) : (nInWindowSize - Phi[i]);
      while (nCurLen < nMaxLen && pInWindow[i + nCurLen] == pInWindow[Phi[i] + nCurLen]) nCurLen++;
      PLCP[i] = nCurLen;
      if (nCurLen > 0)
         nCurLen--;
   }

   /* Rotate permuted LCP into the LCP. This has better cache locality than the direct Kasai LCP method. This also
    * saves us from having to build the inverse suffix array index, as the LCP is calculated without it using this method,
    * and the interval builder below doesn't need it either. */
   intervals[0] &= POS_MASK;
   int nMinMatchSize = pCompressor->min_match_size;

   if (pCompressor->format_version >= 2) {
      for (i = 1; i < nInWindowSize; i++) {
         int nIndex = (int)(intervals[i] & POS_MASK);
         int nLen = PLCP[nIndex];
         if (nLen < nMinMatchSize)
            nLen = 0;
         if (nLen > LCP_MAX)
            nLen = LCP_MAX;
         int nTaggedLen = 0;
         if (nLen)
            nTaggedLen = (nLen << TAG_BITS) | (lzsa_get_index_tag((unsigned int)nIndex) & ((1 << TAG_BITS) - 1));
         intervals[i] = ((unsigned int)nIndex) | (((unsigned int)nTaggedLen) << LCP_SHIFT);
      }
   }
   else {
      for (i = 1; i < nInWindowSize; i++) {
         int nIndex = (int)(intervals[i] & POS_MASK);
         int nLen = PLCP[nIndex];
         if (nLen < nMinMatchSize)
            nLen = 0;
         if (nLen > LCP_AND_TAG_MAX)
            nLen = LCP_AND_TAG_MAX;
         intervals[i] = ((unsigned int)nIndex) | (((unsigned int)nLen) << LCP_SHIFT);
      }
   }

   /**
    * Build intervals for finding matches
    *
    * Methodology and code fragment taken from wimlib (CC0 license):
    * https://wimlib.net/git/?p=wimlib;a=blob_plain;f=src/lcpit_matchfinder.c;h=a2d6a1e0cd95200d1f3a5464d8359d5736b14cbe;hb=HEAD
    */
   unsigned int * const SA_and_LCP = intervals;
   unsigned int *pos_data = pCompressor->pos_data;
   unsigned int next_interval_idx;
   unsigned int *top = pCompressor->open_intervals;
   unsigned int prev_pos = SA_and_LCP[0] & POS_MASK;

   *top = 0;
   intervals[0] = 0;
   next_interval_idx = 1;

   for (r = 1; r < nInWindowSize; r++) {
      const unsigned int next_pos = SA_and_LCP[r] & POS_MASK;
      const unsigned int next_lcp = SA_and_LCP[r] & LCP_MASK;
      const unsigned int top_lcp = *top & LCP_MASK;

      if (next_lcp == top_lcp) {
         /* Continuing the deepest open interval  */
         pos_data[prev_pos] = *top;
      }
      else if (next_lcp > top_lcp) {
         /* Opening a new interval  */
         *++top = next_lcp | next_interval_idx++;
         pos_data[prev_pos] = *top;
      }
      else {
         /* Closing the deepest open interval  */
         pos_data[prev_pos] = *top;
         for (;;) {
            const unsigned int closed_interval_idx = *top-- & POS_MASK;
            const unsigned int superinterval_lcp = *top & LCP_MASK;

            if (next_lcp == superinterval_lcp) {
               /* Continuing the superinterval */
               intervals[closed_interval_idx] = *top;
               break;
            }
            else if (next_lcp > superinterval_lcp) {
               /* Creating a new interval that is a
                * superinterval of the one being
                * closed, but still a subinterval of
                * its superinterval  */
               *++top = next_lcp | next_interval_idx++;
               intervals[closed_interval_idx] = *top;
               break;
            }
            else {
               /* Also closing the superinterval  */
               intervals[closed_interval_idx] = *top;
            }
         }
      }
      prev_pos = next_pos;
   }

   /* Close any still-open intervals.  */
   pos_data[prev_pos] = *top;
   for (; top > pCompressor->open_intervals; top--)
      intervals[*top & POS_MASK] = *(top - 1);

   /* Success */
   return 0;
}

/**
 * Find matches at the specified offset in the input window
 *
 * @param pCompressor compression context
 * @param nOffset offset to find matches at, in the input window
 * @param pMatches pointer to returned matches
 * @param nMaxMatches maximum number of matches to return (0 for none)
 * @param nInWindowSize total input size in bytes (previously compressed bytes + bytes to compress)
 *
 * @return number of matches
 */
int lzsa_find_matches_at(lzsa_compressor *pCompressor, const int nOffset, lzsa_match *pMatches, const int nMaxMatches, const int nInWindowSize) {
   unsigned int *intervals = pCompressor->intervals;
   unsigned int *pos_data = pCompressor->pos_data;
   unsigned int ref;
   unsigned int super_ref;
   unsigned int match_pos;
   lzsa_match *matchptr;
   int nPrevOffset = 0;

   /**
    * Find matches using intervals
    *
    * Taken from wimlib (CC0 license):
    * https://wimlib.net/git/?p=wimlib;a=blob_plain;f=src/lcpit_matchfinder.c;h=a2d6a1e0cd95200d1f3a5464d8359d5736b14cbe;hb=HEAD
    */

    /* Get the deepest lcp-interval containing the current suffix. */
   ref = pos_data[nOffset];

   pos_data[nOffset] = 0;

   /* Ascend until we reach a visited interval, the root, or a child of the
    * root.  Link unvisited intervals to the current suffix as we go.  */
   while ((super_ref = intervals[ref & POS_MASK]) & LCP_MASK) {
      intervals[ref & POS_MASK] = nOffset | VISITED_FLAG;
      ref = super_ref;
   }

   if (super_ref == 0) {
      /* In this case, the current interval may be any of:
       * (1) the root;
       * (2) an unvisited child of the root */

      if (ref != 0)  /* Not the root?  */
         intervals[ref & POS_MASK] = nOffset | VISITED_FLAG;
      return 0;
   }

   /* Ascend indirectly via pos_data[] links.  */
   match_pos = super_ref & EXCL_VISITED_MASK;
   matchptr = pMatches;

   if (pCompressor->format_version >= 2 && nInWindowSize < 65536) {
      if ((matchptr - pMatches) < nMaxMatches) {
         int nMatchOffset = (int)(nOffset - match_pos);

         if (nMatchOffset <= MAX_OFFSET) {
            matchptr->length = (unsigned short)(ref >> (LCP_SHIFT + TAG_BITS));
            matchptr->offset = (unsigned short)nMatchOffset;
            matchptr++;

            nPrevOffset = nMatchOffset;
         }
      }
   }

   for (;;) {
      if ((super_ref = pos_data[match_pos]) > ref) {
         match_pos = intervals[super_ref & POS_MASK] & EXCL_VISITED_MASK;

         if (pCompressor->format_version >= 2 && nInWindowSize < 65536) {
            if ((matchptr - pMatches) < nMaxMatches) {
               int nMatchOffset = (int)(nOffset - match_pos);

               if (nMatchOffset <= MAX_OFFSET && nMatchOffset != nPrevOffset) {
                  matchptr->length = ((unsigned short)(ref >> (LCP_SHIFT + TAG_BITS))) | 0x8000;
                  matchptr->offset = (unsigned short)nMatchOffset;
                  matchptr++;

                  nPrevOffset = nMatchOffset;
               }
            }
         }
      }

      while ((super_ref = pos_data[match_pos]) > ref)
         match_pos = intervals[super_ref & POS_MASK] & EXCL_VISITED_MASK;
      intervals[ref & POS_MASK] = nOffset | VISITED_FLAG;
      pos_data[match_pos] = ref;

      if ((matchptr - pMatches) < nMaxMatches) {
         int nMatchOffset = (int)(nOffset - match_pos);

         if (nMatchOffset <= MAX_OFFSET && nMatchOffset != nPrevOffset) {
            if (pCompressor->format_version >= 2) {
               matchptr->length = (unsigned short)(ref >> (LCP_SHIFT + TAG_BITS));
            }
            else {
               matchptr->length = (unsigned short)(ref >> LCP_SHIFT);
            }
            matchptr->offset = (unsigned short)nMatchOffset;
            matchptr++;
         }
      }

      if (super_ref == 0)
         break;
      ref = super_ref;
      match_pos = intervals[ref & POS_MASK] & EXCL_VISITED_MASK;

      if (pCompressor->format_version >= 2 && nInWindowSize < 65536) {
         if ((matchptr - pMatches) < nMaxMatches) {
            int nMatchOffset = (int)(nOffset - match_pos);

            if (nMatchOffset <= MAX_OFFSET && nMatchOffset != nPrevOffset) {
               matchptr->length = ((unsigned short)(ref >> (LCP_SHIFT + TAG_BITS))) | 0x8000;
               matchptr->offset = (unsigned short)nMatchOffset;

               if ((matchptr->length & 0x7fff) > 2) {
                  matchptr++;

                  nPrevOffset = nMatchOffset;
               }
            }
         }
      }
   }

   return (int)(matchptr - pMatches);
}

/**
 * Skip previously compressed bytes
 *
 * @param pCompressor compression context
 * @param nStartOffset current offset in input window (typically 0)
 * @param nEndOffset offset to skip to in input window (typically the number of previously compressed bytes)
 */
void lzsa_skip_matches(lzsa_compressor *pCompressor, const int nStartOffset, const int nEndOffset) {
   lzsa_match match;
   int i;

   /* Skipping still requires scanning for matches, as this also performs a lazy update of the intervals. However,
    * we don't store the matches. */
   for (i = nStartOffset; i < nEndOffset; i++) {
      lzsa_find_matches_at(pCompressor, i, &match, 0, 0);
   }
}

/**
 * Find all matches for the data to be compressed
 *
 * @param pCompressor compression context
 * @param nMatchesPerOffset maximum number of matches to store for each offset
 * @param nStartOffset current offset in input window (typically the number of previously compressed bytes)
 * @param nEndOffset offset to end finding matches at (typically the size of the total input window in bytes
 */
void lzsa_find_all_matches(lzsa_compressor *pCompressor, const int nMatchesPerOffset, const int nStartOffset, const int nEndOffset) {
   lzsa_match *pMatch = pCompressor->match;
   int i;

   for (i = nStartOffset; i < nEndOffset; i++) {
      int nMatches = lzsa_find_matches_at(pCompressor, i, pMatch, nMatchesPerOffset, nEndOffset - nStartOffset);

      while (nMatches < nMatchesPerOffset) {
         pMatch[nMatches].length = 0;
         pMatch[nMatches].offset = 0;
         nMatches++;
      }

      pMatch += nMatchesPerOffset;
   }
}
