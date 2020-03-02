/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Generic functions.
 * ===========================================================================
 */

#ifndef UTILS_H
#define UTILS_H

#define NELEMS(a)	(sizeof(a)/sizeof(a[0]))

#define XSTR(n) STR(n)
#define STR(n) #n

void copychars(char *dst, const char *p, const char *q);
int hash(const char *p, const char *q, unsigned int tabsz);
int isidc0(char c);
int isidc(char c);
int scmp(const char *p, const char *q, const char *s);
const char *skipws(const char *p);
int hexvalu(char c);
int hexval(char c);
int int_precission(void);

#endif
