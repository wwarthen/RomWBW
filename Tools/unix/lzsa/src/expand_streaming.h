/*
 * expand_streaming.h - streaming decompression definitions
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

#ifndef _EXPAND_STREAMING_H
#define _EXPAND_STREAMING_H

#include "stream.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Forward declaration */
typedef enum _lzsa_status_t lzsa_status_t;

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
   long long *pOriginalSize, long long *pCompressedSize);

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
   long long *pOriginalSize, long long *pCompressedSize);

#ifdef __cplusplus
}
#endif

#endif /* _EXPAND_STREAMING_H */
