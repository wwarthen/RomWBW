/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Assembler.
 * ===========================================================================
 */

#ifndef UZ80AS_H
#define UZ80AS_H

int verbose;

/* matchtab.flags */
enum {
	MATCH_F_UNDOC = 1,
	MATCH_F_EXTEN = 2,
};

/* pat:
 * 	a: expr
 * 	b - z: used by target
 *
 * gen:
 * 	.: output lastbyte
 * 	b: (op << 3) | lastbyte
 * 	c: op | lastbyte
 * 	d: lastbyte = op as 8 bit value
 * 	e: output op as word (no '.' should follow)
 * 	f - z: used by target
 *
 * pr:
 * 	8: e8
 *	f: e16
 *	r: relative jump
 */

struct matchtab {
	const char *pat;
	const char *gen;
	unsigned char mask;
	unsigned char undoc;
	const char *pr;
};

struct target {
	const char *id;
	const char *descr;
	const struct matchtab *matcht;
	int (*matchf)(char c, const char *p, const char **q);
	int (*genf)(int *eb, char p, const int *vs, int i, int savepc);
	void (*pat_char_rewind)(int c);
	const char * (*pat_next_str)(void);
	unsigned char mask;
};

extern const char *s_pline_ep;

void genb(int b, const char *ep);
int mreg(const char *p, const char *const list[], const char **r);

void uz80as(void);

#endif
