/*
 * Functions for manipulating variable sized memory buffers.
 * These buffers can grow and shrink as the program progresses.
 *
 * Written by Eric R. Smith
 * Copyright (c) 2012 Total Spectrum Software Inc.
 * See terms of use in flexbuf.c
 */

#ifndef FLEXBUF_H_
#define FLEXBUF_H_
#include <string.h>

struct flexbuf {
    char * data;  /* current data */
    size_t len;   /* current length of valid data */
    size_t space; /* total space available (must be >= len) */
    size_t growsize; /* how much we should grow */
};

/* initialize a buffer */
void flexbuf_init(struct flexbuf *fb, size_t growsize);

/* add a single character to a buffer */
/* returns a pointer to the start of the buffer, or NULL on failure */
char *flexbuf_addchar(struct flexbuf *fb, int c);

/* add N characters to a buffer */
char *flexbuf_addmem(struct flexbuf *fb, const char *buf, size_t N);

/* add a string to a buffer */
char *flexbuf_addstr(struct flexbuf *fb, const char *str);

/* reset the buffer to empty */
void flexbuf_clear(struct flexbuf *fb);

/* harvest the flexible buffer pointer for use elsewhere */
char *flexbuf_get(struct flexbuf *fb);

/* like get, but does not release the buffer */
char *flexbuf_peek(struct flexbuf *fb);

/* free the space associated with a buffer */
void flexbuf_delete(struct flexbuf *fb);

/* find current length of a buffer */
size_t flexbuf_curlen(struct flexbuf *fb);

#endif
