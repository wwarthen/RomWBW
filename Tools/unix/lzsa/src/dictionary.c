/*
 * dictionary.c - dictionary implementation
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

#include <stdio.h>
#include <stdlib.h>
#include "format.h"
#include "lib.h"

/**
 * Load dictionary contents
 *
 * @param pszDictionaryFilename name of dictionary file, or NULL for none
 * @param ppDictionaryData pointer to returned dictionary contents, or NULL for none
 * @param pDictionaryDataSize pointer to returned size of dictionary contents, or 0
 *
 * @return LZSA_OK for success, or an error value from lzsa_status_t
 */
int lzsa_dictionary_load(const char *pszDictionaryFilename, void **ppDictionaryData, int *pDictionaryDataSize) {
   unsigned char *pDictionaryData = NULL;
   int nDictionaryDataSize = 0;

   if (pszDictionaryFilename) {
      pDictionaryData = (unsigned char *)malloc(BLOCK_SIZE);
      if (!pDictionaryData) {
         return LZSA_ERROR_MEMORY;
      }

      FILE *pDictionaryFile = fopen(pszDictionaryFilename, "rb");
      if (!pDictionaryFile) {
         free(pDictionaryData);
         pDictionaryData = NULL;
         return LZSA_ERROR_DICTIONARY;
      }

      fseek(pDictionaryFile, 0, SEEK_END);
#ifdef _WIN32
      __int64 nDictionaryFileSize = _ftelli64(pDictionaryFile);
#else
      off_t nDictionaryFileSize = ftello(pDictionaryFile);
#endif
      if (nDictionaryFileSize > BLOCK_SIZE) {
         /* Use the last BLOCK_SIZE bytes of the dictionary */
         fseek(pDictionaryFile, -BLOCK_SIZE, SEEK_END);
      }
      else {
         fseek(pDictionaryFile, 0, SEEK_SET);
      }

      nDictionaryDataSize = (int)fread(pDictionaryData, 1, BLOCK_SIZE, pDictionaryFile);
      if (nDictionaryDataSize < 0)
         nDictionaryDataSize = 0;

      fclose(pDictionaryFile);
      pDictionaryFile = NULL;
   }

   *ppDictionaryData = pDictionaryData;
   *pDictionaryDataSize = nDictionaryDataSize;
   return LZSA_OK;
}

/**
 * Free dictionary contents
 *
 * @param ppDictionaryData pointer to pointer to dictionary contents
 */
void lzsa_dictionary_free(void **ppDictionaryData) {
   if (*ppDictionaryData) {
      free(*ppDictionaryData);
      *ppDictionaryData = NULL;
   }
}
