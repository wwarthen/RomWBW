/*
 * lib.h - LZSA library definitions
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

#ifndef _LIB_H
#define _LIB_H

#include "stream.h"
#include "dictionary.h"
#include "frame.h"
#include "format.h"
#include "shrink_context.h"
#include "shrink_streaming.h"
#include "shrink_inmem.h"
#include "expand_context.h"
#include "expand_streaming.h"
#include "expand_inmem.h"

#ifdef __cplusplus
extern "C" {
#endif

/** High level status for compression and decompression */
typedef enum _lzsa_status_t {
   LZSA_OK = 0,                           /**< Success */
   LZSA_ERROR_SRC,                        /**< Error reading input */
   LZSA_ERROR_DST,                        /**< Error reading output */
   LZSA_ERROR_DICTIONARY,                 /**< Error reading dictionary */
   LZSA_ERROR_MEMORY,                     /**< Out of memory */

   /* Compression-specific status codes */
   LZSA_ERROR_COMPRESSION,                /**< Internal compression error */
   LZSA_ERROR_RAW_TOOLARGE,               /**< Input is too large to be compressed to a raw block */
   LZSA_ERROR_RAW_UNCOMPRESSED,           /**< Input is incompressible and raw blocks don't support uncompressed data */

   /* Decompression-specific status codes */
   LZSA_ERROR_FORMAT,                     /**< Invalid input format or magic number when decompressing */
   LZSA_ERROR_DECOMPRESSION               /**< Internal decompression error */
} lzsa_status_t;

/* Compression flags */
#define LZSA_FLAG_FAVOR_RATIO    (1<<0)      /**< 1 to compress with the best ratio, 0 to trade some compression ratio for extra decompression speed */
#define LZSA_FLAG_RAW_BLOCK      (1<<1)      /**< 1 to emit raw block */
#define LZSA_FLAG_RAW_BACKWARD   (1<<2)      /**< 1 to compress or decompress raw block backward */

/**
 * Reverse bytes in the specified buffer
 *
 * @param pBuffer pointer to buffer whose contents are to be reversed
 * @param nBufferSize size of buffer in bytes
 */
static inline void lzsa_reverse_buffer(unsigned char *pBuffer, const int nBufferSize) {
   int nMidPoint = nBufferSize / 2;
   int i, j;

   for (i = 0, j = nBufferSize - 1; i < nMidPoint; i++, j--) {
      unsigned char c = pBuffer[i];
      pBuffer[i] = pBuffer[j];
      pBuffer[j] = c;
   }
}

#ifdef __cplusplus
}
#endif

#endif /* _LIB_H */
