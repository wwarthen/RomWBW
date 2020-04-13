/*
 * frame.h - frame definitions
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

#ifndef _FRAME_H
#define _FRAME_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Get compressed file header size
 *
 * @return file header size
 */
int lzsa_get_header_size(void);

/**
 * Get compressed frame header size
 *
 * @return frame header size
 */
int lzsa_get_frame_size(void);

/**
 * Encode file header
 *
 * @param pFrameData encoding buffer
 * @param nMaxFrameDataSize max encoding buffer size, in bytes
 *
 * @return number of encoded bytes, or -1 for failure
 */
int lzsa_encode_header(unsigned char *pFrameData, const int nMaxFrameDataSize, int nFormatVersion);

/**
 * Encode compressed block frame header
 *
 * @param pFrameData encoding buffer
 * @param nMaxFrameDataSize max encoding buffer size, in bytes
 * @param nBlockDataSize compressed block's data size, in bytes
 *
 * @return number of encoded bytes, or -1 for failure
 */
int lzsa_encode_compressed_block_frame(unsigned char *pFrameData, const int nMaxFrameDataSize, const int nBlockDataSize);

/**
 * Encode uncompressed block frame header
 *
 * @param pFrameData encoding buffer
 * @param nMaxFrameDataSize max encoding buffer size, in bytes
 * @param nBlockDataSize uncompressed block's data size, in bytes
 *
 * @return number of encoded bytes, or -1 for failure
 */
int lzsa_encode_uncompressed_block_frame(unsigned char *pFrameData, const int nMaxFrameDataSize, const int nBlockDataSize);

/**
 * Encode terminal frame header
 *
 * @param pFrameData encoding buffer
 * @param nMaxFrameDataSize max encoding buffer size, in bytes
 *
 * @return number of encoded bytes, or -1 for failure
 */
int lzsa_encode_footer_frame(unsigned char *pFrameData, const int nMaxFrameDataSize);

/**
 * Decode file header
 *
 * @param pFrameData data bytes
 * @param nFrameDataSize number of bytes to decode
 *
 * @return 0 for success, or -1 for failure
 */
int lzsa_decode_header(const unsigned char *pFrameData, const int nFrameDataSize, int *nFormatVersion);

/**
 * Decode frame header
 *
 * @param pFrameData data bytes
 * @param nFrameDataSize number of bytes to decode
 * @param nBlockSize pointer to block size, updated if this function succeeds (set to 0 if this is the terminal frame)
 * @param nIsUncompressed pointer to compressed block flag, updated if this function succeeds
 *
 * @return 0 for success, or -1 for failure
 */
int lzsa_decode_frame(const unsigned char *pFrameData, const int nFrameDataSize, unsigned int *nBlockSize, int *nIsUncompressed);

#ifdef __cplusplus
}
#endif

#endif /* _FRAME_H */
