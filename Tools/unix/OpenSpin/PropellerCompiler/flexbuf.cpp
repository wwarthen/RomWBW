/*
 * Functions for manipulating variable sized memory buffers.
 * These buffers can grow and shrink as the program progresses.
 *
 * Written by Eric R. Smith
 * Copyright (c) 2012 Total Spectrum Software Inc.
 * MIT Licensed; see terms at the end of this file.
 */

#include "flexbuf.h"
#include <stdlib.h>
#include <stdio.h>

#define DEFAULT_GROWSIZE BUFSIZ

void flexbuf_init(struct flexbuf *fb, size_t growsize)
{
    fb->data = NULL;
    fb->len = 0;
    fb->space = 0;
    fb->growsize = growsize ? growsize : DEFAULT_GROWSIZE;
}

size_t flexbuf_curlen(struct flexbuf *fb)
{
    return fb->len;
}

/* add a single character to a buffer */
char *flexbuf_addchar(struct flexbuf *fb, int c)
{
    size_t newlen = fb->len + 1;

    if (newlen > fb->space) {
        char *newdata;
        newdata = (char *)realloc(fb->data, fb->space + fb->growsize);
        if (!newdata) return newdata;
        fb->space += fb->growsize;
        fb->data = newdata;
    }
    fb->data[fb->len] = (char)c;
    fb->len = newlen;
    return fb->data;
}

/* add N characters to a buffer */
char *flexbuf_addmem(struct flexbuf *fb, const char *buf, size_t N)
{
    size_t newlen = fb->len + N;

    if (newlen > fb->space) {
        char *newdata;
        size_t newspace;
        newspace = fb->space + fb->growsize;
        if (newspace < newlen) {
            newspace = newlen + fb->growsize;
        }
        newdata = (char *)realloc(fb->data, newspace);
        if (!newdata) return newdata;
        fb->space = newspace;
        fb->data = newdata;
    }
    memcpy(fb->data + fb->len, buf, N);
    fb->len = newlen;
    return fb->data;
}

/* add a string to a buffer */
char *flexbuf_addstr(struct flexbuf *fb, const char *str)
{
    return flexbuf_addmem(fb, str, strlen(str));
}

/* retrieve the pointer for a flexbuf */
/* "peek" gets it but keeps it reserved;
 * "get" gets it and releases it from the flexbuf
 */
char *flexbuf_peek(struct flexbuf *fb)
{
    char *r = fb->data;
    return r;
}

char *flexbuf_get(struct flexbuf *fb)
{
    char *r = fb->data;
    flexbuf_init(fb, fb->growsize);
    return r;
}

/* reset the buffer to empty (but do not free space) */
void flexbuf_clear(struct flexbuf *fb)
{
    fb->len = 0;
}

/* free the memory associated with a buffer */
void flexbuf_delete(struct flexbuf *fb)
{
    if (fb->data)
        free(fb->data);
    flexbuf_init(fb, 1);
}

/*
 * +--------------------------------------------------------------------
 * ¦  TERMS OF USE: MIT License
 * +--------------------------------------------------------------------
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files
 * (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * +--------------------------------------------------------------------
 */
