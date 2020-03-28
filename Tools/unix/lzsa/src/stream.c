/*
 * stream.c - streaming I/O  implementation
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
#include <string.h>
#include "stream.h"

/**
 * Close file stream
 *
 * @param stream stream
 */
static void lzsa_filestream_close(lzsa_stream_t *stream) {
   if (stream->obj) {
      fclose((FILE*)stream->obj);
      stream->obj = NULL;
      stream->read = NULL;
      stream->write = NULL;
      stream->eof = NULL;
      stream->close = NULL;
   }
}

/**
 * Read from file stream
 *
 * @param stream stream
 * @param ptr buffer to read into
 * @param size number of bytes to read
 *
 * @return number of bytes read
 */
static size_t lzsa_filestream_read(lzsa_stream_t *stream, void *ptr, size_t size) {
   return fread(ptr, 1, size, (FILE*)stream->obj);
}

/**
 * Write to file stream
 *
 * @param stream stream
 * @param ptr buffer to write from
 * @param size number of bytes to write
 *
 * @return number of bytes written
 */
static size_t lzsa_filestream_write(lzsa_stream_t *stream, void *ptr, size_t size) {
   return fwrite(ptr, 1, size, (FILE*)stream->obj);
}

/**
 * Check if file stream has reached the end of the data
 *
 * @param stream stream
 *
 * @return nonzero if the end of the data has been reached, 0 if there is more data
 */
static int lzsa_filestream_eof(lzsa_stream_t *stream) {
   return feof((FILE*)stream->obj);
}

/**
 * Open file and create an I/O stream from it
 *
 * @param stream stream to fill out
 * @param pszInFilename filename
 * @param pszMode open mode, as with fopen()
 *
 * @return 0 for success, nonzero for failure
 */
int lzsa_filestream_open(lzsa_stream_t *stream, const char *pszInFilename, const char *pszMode) {
   stream->obj = (void*)fopen(pszInFilename, pszMode);
   if (stream->obj) {
      stream->read = lzsa_filestream_read;
      stream->write = lzsa_filestream_write;
      stream->eof = lzsa_filestream_eof;
      stream->close = lzsa_filestream_close;
      return 0;
   }
   else
      return -1;
}
