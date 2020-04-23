/*
 * expand_block_v1.c - LZSA1 block decompressor implementation
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
#include "format.h"
#include "expand_block_v1.h"

#ifdef _MSC_VER
#define FORCE_INLINE __forceinline
#else /* _MSC_VER */
#define FORCE_INLINE __attribute__((always_inline))
#endif /* _MSC_VER */

static inline FORCE_INLINE int lzsa_build_literals_len_v1(const unsigned char **ppInBlock, const unsigned char *pInBlockEnd, unsigned int *nLiterals) {
   unsigned int nByte;
   const unsigned char *pInBlock = *ppInBlock;

   if (pInBlock < pInBlockEnd) {
      nByte = *pInBlock++;
      (*nLiterals) += nByte;

      if (nByte == 250) {
         if (pInBlock < pInBlockEnd) {
            (*nLiterals) = 256 + ((unsigned int)*pInBlock++);
         }
         else {
            return -1;
         }
      }
      else if (nByte == 249) {
         if ((pInBlock + 1) < pInBlockEnd) {
            (*nLiterals) = ((unsigned int)*pInBlock++);
            (*nLiterals) |= (((unsigned int)*pInBlock++) << 8);
         }
         else {
            return -1;
         }
      }

      *ppInBlock = pInBlock;
      return 0;
   }
   else {
      return -1;
   }
}

static inline FORCE_INLINE int lzsa_build_match_len_v1(const unsigned char **ppInBlock, const unsigned char *pInBlockEnd, unsigned int *nMatchLen) {
   unsigned int nByte;
   const unsigned char *pInBlock = *ppInBlock;

   if (pInBlock < pInBlockEnd) {
      nByte = *pInBlock++;
      (*nMatchLen) += nByte;

      if (nByte == 239) {
         if (pInBlock < pInBlockEnd) {
            (*nMatchLen) = 256 + ((unsigned int)*pInBlock++);
         }
         else {
            return -1;
         }
      }
      else if (nByte == 238) {
         if ((pInBlock + 1) < pInBlockEnd) {
            (*nMatchLen) = ((unsigned int)*pInBlock++);
            (*nMatchLen) |= (((unsigned int)*pInBlock++) << 8);
         }
         else {
            return -1;
         }
      }

      *ppInBlock = pInBlock;
      return 0;
   }
   else {
      return -1;
   }
}

/**
 * Decompress one LZSA1 data block
 *
 * @param pInBlock pointer to compressed data
 * @param nBlockSize size of compressed data, in bytes
 * @param pOutData pointer to output decompression buffer (previously decompressed bytes + room for decompressing this block)
 * @param nOutDataOffset starting index of where to store decompressed bytes in output buffer (and size of previously decompressed bytes)
 * @param nBlockMaxSize total size of output decompression buffer, in bytes
 *
 * @return size of decompressed data in bytes, or -1 for error
 */
int lzsa_decompressor_expand_block_v1(const unsigned char *pInBlock, int nBlockSize, unsigned char *pOutData, int nOutDataOffset, int nBlockMaxSize) {
   const unsigned char *pInBlockEnd = pInBlock + nBlockSize;
   unsigned char *pCurOutData = pOutData + nOutDataOffset;
   const unsigned char *pOutDataEnd = pCurOutData + nBlockMaxSize;
   const unsigned char *pOutDataFastEnd = pOutDataEnd - 18;

   while (pInBlock < pInBlockEnd) {
      const unsigned char token = *pInBlock++;
      unsigned int nLiterals = (unsigned int)((token & 0x70) >> 4);

      if (nLiterals != LITERALS_RUN_LEN_V1 && (pInBlock + 8) <= pInBlockEnd && pCurOutData < pOutDataFastEnd) {
         memcpy(pCurOutData, pInBlock, 8);
         pInBlock += nLiterals;
         pCurOutData += nLiterals;
      }
      else {
         if (nLiterals == LITERALS_RUN_LEN_V1) {
            if (lzsa_build_literals_len_v1(&pInBlock, pInBlockEnd, &nLiterals))
               return -1;
         }

         if (nLiterals != 0) {
            if ((pInBlock + nLiterals) <= pInBlockEnd &&
               (pCurOutData + nLiterals) <= pOutDataEnd) {
               memcpy(pCurOutData, pInBlock, nLiterals);
               pInBlock += nLiterals;
               pCurOutData += nLiterals;
            }
            else {
               return -1;
            }
         }
      }

      if ((pInBlock + 1) < pInBlockEnd) { /* The last token in the block does not include match information */
         unsigned int nMatchOffset;

         nMatchOffset = ((unsigned int)(*pInBlock++)) ^ 0xff;
         if (token & 0x80) {
            nMatchOffset |= (((unsigned int)(*pInBlock++)) << 8) ^ 0xff00;
         }
         nMatchOffset++;

         const unsigned char *pSrc = pCurOutData - nMatchOffset;
         if (pSrc >= pOutData) {
            unsigned int nMatchLen = (unsigned int)(token & 0x0f);
            if (nMatchLen != MATCH_RUN_LEN_V1 && nMatchOffset >= 8 && pCurOutData < pOutDataFastEnd && (pSrc + 18) <= pOutDataEnd) {
               memcpy(pCurOutData, pSrc, 8);
               memcpy(pCurOutData + 8, pSrc + 8, 8);
               memcpy(pCurOutData + 16, pSrc + 16, 2);
               pCurOutData += (MIN_MATCH_SIZE_V1 + nMatchLen);
            }
            else {
               nMatchLen += MIN_MATCH_SIZE_V1;
               if (nMatchLen == (MATCH_RUN_LEN_V1 + MIN_MATCH_SIZE_V1)) {
                  if (lzsa_build_match_len_v1(&pInBlock, pInBlockEnd, &nMatchLen))
                     return -1;
                  if (nMatchLen == 0)
                     break;
               }

               if ((pSrc + nMatchLen) <= pOutDataEnd) {
                  if ((pCurOutData + nMatchLen) <= pOutDataEnd) {
                     /* Do a deterministic, left to right byte copy instead of memcpy() so as to handle overlaps */

                     if (nMatchOffset >= 16 && (pCurOutData + nMatchLen) < (pOutDataFastEnd - 15)) {
                        const unsigned char *pCopySrc = pSrc;
                        unsigned char *pCopyDst = pCurOutData;
                        const unsigned char *pCopyEndDst = pCurOutData + nMatchLen;

                        do {
                           memcpy(pCopyDst, pCopySrc, 16);
                           pCopySrc += 16;
                           pCopyDst += 16;
                        } while (pCopyDst < pCopyEndDst);

                        pCurOutData += nMatchLen;
                     }
                     else {
                        while (nMatchLen) {
                           *pCurOutData++ = *pSrc++;
                           nMatchLen--;
                        }
                     }
                  }
                  else {
                     return -1;
                  }
               }
               else {
                  return -1;
               }
            }
         }
         else {
            return -1;
         }
      }
   }

   return (int)(pCurOutData - (pOutData + nOutDataOffset));
}
