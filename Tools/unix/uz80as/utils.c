/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Generic functions.
 * ===========================================================================
 */

#include "config.h"
#include "utils.h"

#ifndef CTYPE_H
#include <ctype.h>
#endif

#ifndef LIMITS_H
#include <limits.h>
#endif

/*
 * Copy [p, q[ to dst and null terminate dst.
 */
void copychars(char *dst, const char *p, const char *q)
{
//	int i = 0;
//	printf("copychars %x->%x to %x \'", p, q, dst);
	while (p != q) {
//		printf("%c", *p);
		*dst++ = *p++;
//		i++;
	}
	*dst = '\0';
//	printf("\' %d %x %d\n", *dst, dst, i);
}

/* Skip space. */
const char *skipws(const char *p)
{
	while (isspace(*p))
		p++;
	return p;
}

/* Return 1 if *p is a valid start character for an identifier. */
int isidc0(char c)
{
	return (c == '_') || isalpha(c);
}

/* 
 * Return 1 if *p is a valid character for an identifier.
 * Don't use for the first character.
 */
int isidc(char c)
{
	return (c == '_') || (c == '.') || isalnum(c);
}

/* Hash the string in [p, q[ to give a bucket in symtab. */
int hash(const char *p, const char *q, unsigned int tabsz)
{
	unsigned int h;

	h = 0;
	while (p != q) {
		h = 31 * h + (unsigned char) *p;
		p++;
	}

	return h % tabsz;
}

/* 
 * Compare the string in [p, q[ with the null-terminated string s.
 * Return 0 if equal.
 */
int scmp(const char *p, const char *q, const char *s)
{
	while (p < q) {
		if (*p == *s) {
			p++;
			s++;
		} else if (*s == '\0') {
			return 1;
		} else if (*p < *s) {
			return -1;
		} else {
			return 1;
		}
	}

	if (*s == '\0')
		return 0;
	else
		return -1;
}
/*
 * Given a hexadecimal character (in upper case), returns its integer value.
 * Returns -1 if c is not a hexadecimal character.
 */
int hexvalu(char c)
{
	if (c >= '0' && c <= '9')
		return c - '0';
	else if (c >= 'A' && c <= 'F')
		return (c - 'A') + 10;
	else
		return -1;
}

/*
 * Given a hexadecimal character, returns its integer value.
 * Returns -1 if c is not a hexadecimal character.
 */
int hexval(char c)
{
	if (c >= 'a' && c <= 'f')
		return (c - 'a') + 10;
	else
		return hexvalu(c);
}

int int_precission(void)
{
	static int bits = 0;
	unsigned int i;

	if (bits > 0)
		return bits;

	i = INT_MAX;
	bits = 0;
	while (i) {
		bits++;
		i >>= 1;
	}
	return bits;
}
