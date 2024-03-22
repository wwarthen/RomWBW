/*
 * shrink_context.c - compression context implementation
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
#include "shrink_context.h"
#include "shrink_block_v1.h"
#include "shrink_block_v2.h"
#include "format.h"
#include "matchfinder.h"
#include "lib.h"

/**
 * Initialize compression context
 *
 * @param pCompressor compression context to initialize
 * @param nMaxWindowSize maximum size of input data window (previously compressed bytes + bytes to compress)
 * @param nMinMatchSize minimum match size (cannot be less than MIN_MATCH_SIZE)
 * @param nFlags compression flags
 *
 * @return 0 for success, non-zero for failure
 */
int lzsa_compressor_init(lzsa_compressor *pCompressor, const int nMaxWindowSize, const int nMinMatchSize, const int nFormatVersion, const int nFlags) {
   int nResult;
   int nMinMatchSizeForFormat = (nFormatVersion == 1) ? MIN_MATCH_SIZE_V1 : MIN_MATCH_SIZE_V2;
   int nMaxMinMatchForFormat = (nFormatVersion == 1) ? 5 : 3;

   nResult = divsufsort_init(&pCompressor->divsufsort_context);
   pCompressor->intervals = NULL;
   pCompressor->pos_data = NULL;
   pCompressor->open_intervals = NULL;
   pCompressor->match = NULL;
   pCompressor->best_match = NULL;
   pCompressor->improved_match = NULL;
   pCompressor->arrival = NULL;
   pCompressor->rep_slot_handled_mask = NULL;
   pCompressor->rep_len_handled_mask = NULL;
   pCompressor->first_offset_for_byte = NULL;
   pCompressor->next_offset_for_pos = NULL;
   pCompressor->min_match_size = nMinMatchSize;
   if (pCompressor->min_match_size < nMinMatchSizeForFormat)
      pCompressor->min_match_size = nMinMatchSizeForFormat;
   else if (pCompressor->min_match_size > nMaxMinMatchForFormat)
      pCompressor->min_match_size = nMaxMinMatchForFormat;
   pCompressor->format_version = nFormatVersion;
   pCompressor->flags = nFlags;
   pCompressor->safe_dist = 0;
   pCompressor->num_commands = 0;
   
   memset(&pCompressor->stats, 0, sizeof(pCompressor->stats));
   pCompressor->stats.min_literals = -1;
   pCompressor->stats.min_match_len = -1;
   pCompressor->stats.min_offset = -1;
   pCompressor->stats.min_rle1_len = -1;
   pCompressor->stats.min_rle2_len = -1;

   if (!nResult) {
      pCompressor->intervals = (unsigned int *)malloc(nMaxWindowSize * sizeof(unsigned int));

      if (pCompressor->intervals) {
         pCompressor->pos_data = (unsigned int *)malloc(nMaxWindowSize * sizeof(unsigned int));

         if (pCompressor->pos_data) {
            pCompressor->open_intervals = (unsigned int *)malloc((LCP_AND_TAG_MAX + 1) * sizeof(unsigned int));

            if (pCompressor->open_intervals) {
               pCompressor->arrival = (lzsa_arrival *)malloc(((BLOCK_SIZE + 1) << ARRIVALS_PER_POSITION_SHIFT) * sizeof(lzsa_arrival));
   
               if (pCompressor->arrival) {
                  pCompressor->best_match = (lzsa_match *)malloc(BLOCK_SIZE * sizeof(lzsa_match));

                  if (pCompressor->best_match) {
                     pCompressor->improved_match = (lzsa_match *)malloc(BLOCK_SIZE * sizeof(lzsa_match));

                     if (pCompressor->improved_match) {
                        if (pCompressor->format_version == 2)
                           pCompressor->match = (lzsa_match *)malloc(BLOCK_SIZE * NMATCHES_PER_INDEX_V2 * sizeof(lzsa_match));
                        else
                           pCompressor->match = (lzsa_match *)malloc(BLOCK_SIZE * NMATCHES_PER_INDEX_V1 * sizeof(lzsa_match));
                        if (pCompressor->match) {
                           if (pCompressor->format_version == 2) {
                              pCompressor->rep_slot_handled_mask = (char*)malloc(NARRIVALS_PER_POSITION_V2_BIG * ((LCP_MAX + 1) / 8) * sizeof(char));
                              if (pCompressor->rep_slot_handled_mask) {
                                 pCompressor->rep_len_handled_mask = (char*)malloc(((LCP_MAX + 1) / 8) * sizeof(char));
                                 if (pCompressor->rep_len_handled_mask) {
                                    pCompressor->first_offset_for_byte = (int*)malloc(65536 * sizeof(int));
                                    if (pCompressor->first_offset_for_byte) {
                                       pCompressor->next_offset_for_pos = (int*)malloc(BLOCK_SIZE * sizeof(int));
                                       if (pCompressor->next_offset_for_pos) {
                                          return 0;
                                       }
                                    }
                                 }
                              }
                           }
                           else {
                              return 0;
                           }
                        }
                     }
                  }
               }
            }
         }
      }
   }

   lzsa_compressor_destroy(pCompressor);
   return 100;
}

/**
 * Clean up compression context and free up any associated resources
 *
 * @param pCompressor compression context to clean up
 */
void lzsa_compressor_destroy(lzsa_compressor *pCompressor) {
   divsufsort_destroy(&pCompressor->divsufsort_context);

   if (pCompressor->next_offset_for_pos) {
      free(pCompressor->next_offset_for_pos);
      pCompressor->next_offset_for_pos = NULL;
   }

   if (pCompressor->first_offset_for_byte) {
      free(pCompressor->first_offset_for_byte);
      pCompressor->first_offset_for_byte = NULL;
   }

   if (pCompressor->rep_len_handled_mask) {
      free(pCompressor->rep_len_handled_mask);
      pCompressor->rep_len_handled_mask = NULL;
   }

   if (pCompressor->rep_slot_handled_mask) {
      free(pCompressor->rep_slot_handled_mask);
      pCompressor->rep_slot_handled_mask = NULL;
   }

   if (pCompressor->match) {
      free(pCompressor->match);
      pCompressor->match = NULL;
   }

   if (pCompressor->improved_match) {
      free(pCompressor->improved_match);
      pCompressor->improved_match = NULL;
   }

   if (pCompressor->arrival) {
      free(pCompressor->arrival);
      pCompressor->arrival = NULL;
   }

   if (pCompressor->best_match) {
      free(pCompressor->best_match);
      pCompressor->best_match = NULL;
   }

   if (pCompressor->open_intervals) {
      free(pCompressor->open_intervals);
      pCompressor->open_intervals = NULL;
   }

   if (pCompressor->pos_data) {
      free(pCompressor->pos_data);
      pCompressor->pos_data = NULL;
   }

   if (pCompressor->intervals) {
      free(pCompressor->intervals);
      pCompressor->intervals = NULL;
   }
}

/**
 * Compress one block of data
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
int lzsa_compressor_shrink_block(lzsa_compressor *pCompressor, unsigned char *pInWindow, const int nPreviousBlockSize, const int nInDataSize, unsigned char *pOutData, const int nMaxOutDataSize) {
   int nCompressedSize;

   if (pCompressor->flags & LZSA_FLAG_RAW_BACKWARD) {
      lzsa_reverse_buffer(pInWindow + nPreviousBlockSize, nInDataSize);
   }

   if (lzsa_build_suffix_array(pCompressor, pInWindow, nPreviousBlockSize + nInDataSize))
      nCompressedSize = -1;
   else {
      if (nPreviousBlockSize) {
         lzsa_skip_matches(pCompressor, 0, nPreviousBlockSize);
      }
      lzsa_find_all_matches(pCompressor, (pCompressor->format_version == 2) ? NMATCHES_PER_INDEX_V2 : NMATCHES_PER_INDEX_V1, nPreviousBlockSize, nPreviousBlockSize + nInDataSize);

      if (pCompressor->format_version == 1) {
         nCompressedSize = lzsa_optimize_and_write_block_v1(pCompressor, pInWindow, nPreviousBlockSize, nInDataSize, pOutData, nMaxOutDataSize);
         if (nCompressedSize != -1 && (pCompressor->flags & LZSA_FLAG_RAW_BACKWARD)) {
            lzsa_reverse_buffer(pOutData, nCompressedSize);
         }
      }
      else if (pCompressor->format_version == 2) {
         nCompressedSize = lzsa_optimize_and_write_block_v2(pCompressor, pInWindow, nPreviousBlockSize, nInDataSize, pOutData, nMaxOutDataSize);
         if (nCompressedSize != -1 && (pCompressor->flags & LZSA_FLAG_RAW_BACKWARD)) {
            lzsa_reverse_buffer(pOutData, nCompressedSize);
         }
      }
      else {
         nCompressedSize = -1;
      }
   }

   if (pCompressor->flags & LZSA_FLAG_RAW_BACKWARD) {
      lzsa_reverse_buffer(pInWindow + nPreviousBlockSize, nInDataSize);
   }

   return nCompressedSize;
}

/**
 * Get the number of compression commands issued in compressed data blocks
 *
 * @return number of commands
 */
int lzsa_compressor_get_command_count(lzsa_compressor *pCompressor) {
   return pCompressor->num_commands;
}
