/*
 * shrink_context.h - compression context definitions
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

#ifndef _SHRINK_CONTEXT_H
#define _SHRINK_CONTEXT_H

#include "divsufsort.h"

#ifdef __cplusplus
extern "C" {
#endif

#define LCP_BITS 14
#define TAG_BITS 4
#define LCP_MAX ((1U<<(LCP_BITS - TAG_BITS)) - 1)
#define LCP_AND_TAG_MAX (1U<<(LCP_BITS - 1))
#define LCP_SHIFT (31-LCP_BITS)
#define LCP_MASK (((1U<<LCP_BITS) - 1) << LCP_SHIFT)
#define POS_MASK ((1U<<LCP_SHIFT) - 1)
#define VISITED_FLAG 0x80000000
#define EXCL_VISITED_MASK  0x7fffffff

#define NARRIVALS_PER_POSITION_V1 8
#define NARRIVALS_PER_POSITION_V2_SMALL 9
#define NARRIVALS_PER_POSITION_V2_BIG 32
#define ARRIVALS_PER_POSITION_SHIFT 5

#define NMATCHES_PER_INDEX_V1 8
#define MATCHES_PER_INDEX_SHIFT_V1 3

#define NMATCHES_PER_INDEX_V2 64
#define MATCHES_PER_INDEX_SHIFT_V2 6

#define LEAVE_ALONE_MATCH_SIZE 300
#define LEAVE_ALONE_MATCH_SIZE_SMALL 1000

#define MODESWITCH_PENALTY 3

/** One match */
typedef struct _lzsa_match {
   unsigned short length;
   unsigned short offset;
} lzsa_match;

/** Forward arrival slot */
typedef struct {
   int cost;
   unsigned short rep_offset;
   short from_slot;

   int from_pos;
   unsigned short rep_len;
   unsigned short match_len;
   int rep_pos;
   int num_literals;
   int score;
} lzsa_arrival;

/** Compression statistics */
typedef struct _lzsa_stats {
   int min_literals;
   int max_literals;
   int total_literals;

   int min_offset;
   int max_offset;
   int num_rep_offsets;
   int total_offsets;

   int min_match_len;
   int max_match_len;
   int total_match_lens;

   int min_rle1_len;
   int max_rle1_len;
   int total_rle1_lens;

   int min_rle2_len;
   int max_rle2_len;
   int total_rle2_lens;

   int literals_divisor;
   int match_divisor;
   int rle1_divisor;
   int rle2_divisor;
} lzsa_stats;

/** Compression context */
typedef struct _lzsa_compressor {
   divsufsort_ctx_t divsufsort_context;
   unsigned int *intervals;
   unsigned int *pos_data;
   unsigned int *open_intervals;
   lzsa_match *match;
   lzsa_match *best_match;
   lzsa_match *improved_match;
   lzsa_arrival *arrival;
   char *rep_slot_handled_mask;
   char *rep_len_handled_mask;
   int *first_offset_for_byte;
   int *next_offset_for_pos;
   int min_match_size;
   int format_version;
   int flags;
   int safe_dist;
   int num_commands;
   lzsa_stats stats;
} lzsa_compressor;

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
int lzsa_compressor_init(lzsa_compressor *pCompressor, const int nMaxWindowSize, const int nMinMatchSize, const int nFormatVersion, const int nFlags);

/**
 * Clean up compression context and free up any associated resources
 *
 * @param pCompressor compression context to clean up
 */
void lzsa_compressor_destroy(lzsa_compressor *pCompressor);

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
int lzsa_compressor_shrink_block(lzsa_compressor *pCompressor, unsigned char *pInWindow, const int nPreviousBlockSize, const int nInDataSize, unsigned char *pOutData, const int nMaxOutDataSize);

/**
 * Get the number of compression commands issued in compressed data blocks
 *
 * @return number of commands
 */
int lzsa_compressor_get_command_count(lzsa_compressor *pCompressor);

#ifdef __cplusplus
}
#endif

#endif /* _SHRINK_CONTEXT_H */
