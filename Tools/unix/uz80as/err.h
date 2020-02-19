/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Error reporting.
 * ===========================================================================
 */

#ifndef ERR_H
#define ERR_H

#ifndef STDIO_H
#define STDIO_H
#include <stdio.h>
#endif

#define _(str)	(str)

extern int s_nerrors;

void newerr(void);
void eprogname(void);
void echars(const char *p, const char *q);
void epchars(const char *p, const char *q);
void eprint(const char *ecode, ...);
void wprint(const char *ecode, ...);
void eprcol(const char *line, const char *q);
void enl(void);
void *emalloc(size_t n);
void *erealloc(void *p, size_t n);
FILE *efopen(const char *fname, const char *ops);

#endif
