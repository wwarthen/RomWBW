/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Assembler.
 * ===========================================================================
 */

#include "config.h"
#include "uz80as.h"
#include "options.h"
#include "utils.h"
#include "err.h"
#include "incl.h"
#include "sym.h"
#include "expr.h"
#include "exprint.h"
#include "pp.h"
#include "list.h"
#include "targets.h"

#ifndef ASSERT_H
#include <assert.h>
#endif

#ifndef CTYPE_H
#include <ctype.h>
#endif

#ifndef STDIO_H
#include <stdio.h>
#endif

#ifndef STDLIB_H
#include <stdlib.h>
#endif

#ifndef STRING_H
#include <string.h>
#endif

static void output();

static const char *d_align(const char *);
static const char *d_null(const char *);
static const char *d_block(const char *);
static const char *d_byte(const char *);
static const char *d_chk(const char *);
static const char *d_codes(const char *);
static const char *d_echo(const char *);
static const char *d_eject(const char *);
static const char *d_export(const char *);
static const char *d_end(const char *);
static const char *d_equ(const char *);
static const char *d_fill(const char *);
static const char *d_ds(const char *);
static const char *d_list(const char *);
static const char *d_lsfirst(const char *);
static const char *d_module(const char *);
static const char *d_msfirst(const char *);
static const char *d_nocodes(const char *);
static const char *d_nolist(const char *);
static const char *d_org(const char *);
static const char *d_set(const char *);
static const char *d_text(const char *);
static const char *d_title(const char *);
static const char *d_word(const char *);

/* 
 * Directives.
 * This table must be sorted, to allow for binary search.
 */ 
static struct direc {
	const char *name;
	const char *(*fun)(const char *);
} s_directab[] = { 
	{ "ALIGN", d_align },
	{ "BLOCK", d_block },
	{ "BYTE", d_byte },
	{ "CHK", d_chk },
	{ "CODES", d_codes },
	{ "DB", d_byte },
	{ "DS", d_ds },
	{ "DW", d_word },
	{ "ECHO", d_echo },
	{ "EJECT", d_eject },
	{ "END", d_end },
	{ "EQU", d_equ },
	{ "EXPORT", d_export },
	{ "FILL", d_fill },
	{ "GLOBAL", d_export },
	{ "LIST", d_list },
	{ "LSFIRST", d_lsfirst },
	{ "MODULE", d_module },
	{ "MSFIRST", d_msfirst },
	{ "NOCODES", d_nocodes },
	{ "NOLIST", d_nolist },
	{ "NOPAGE", d_null },
	{ "ORG", d_org },
	{ "PAGE", d_null },
	{ "SECTION", d_null },
	{ "SET", d_set },
	{ "TEXT", d_text },
	{ "TITLE", d_title },
	{ "WORD", d_word },
};

/* binary output file */
FILE *fout;

/* output in source order */
int b_flag = 1;

/* The target. */
const struct target *s_target;

/* The z80 addressable memory. The object code. */
static unsigned char s_mem[64 * 1024];

/* Program counter min and max ([s_minpc, s_maxpc[). */
static int s_minpc, s_maxpc;

/* Original input line. */
static char s_line[LINESZ];

/* Label defined on this line. */
static struct sym *s_lastsym;

/* Output words the most significant byte first */
static int s_msbword;

/* If we have seen the .END directive. */
static int s_end_seen;

/* We have issued the error of generating things after an .END. */
static int s_gen_after_end;

/* The empty line, to pass to listing, for compatibility with TASM. */
static const char *s_empty_line = "";

/* Pointer in s_pline for error reporting. */
const char *s_pline_ep;

/* We skip characters until endline or backslash or comment. */
static const char *sync(const char *p)
{
	while (*p != '\0' && *p != '\\' && *p != ';')
		p++;
	return p;
}

/* the written bitmap */
unsigned char membit[65536 / 8];

void
setbit(int pc)
{
	membit[pc / 8] |= (1 << (pc % 8));
}

int
isset(int pc)
{
	return membit[pc / 8] & (1 << (pc % 8));
}

void
open_output()
{
	fout = efopen(s_objfname, "wb");
}

void
close_output()
{
	if (fclose(fout) == EOF) {
		eprint(_("cannot close file %s\n"), s_objfname);
	}
}

/* 
 * Generates a byte to the output and updates s_pc, s_minpc and s_maxpc.
 * Will issue a fatal error if we write beyong 64k.
 */
void genb(int b, const char *ep)
{
	if (s_pass == 0 && s_end_seen && !s_gen_after_end) {
		s_gen_after_end = 1;
		eprint(_("generating code after .END\n"));
		eprcol(s_pline, ep);
		newerr();
	}
	if (s_minpc < 0)
		s_minpc = s_pc;
       	if (s_pc >= 65536) {
		eprint(_("generating code beyond address 65535\n"));
		eprcol(s_pline, ep);
		exit(EXIT_FAILURE);
	}
	s_mem[s_pc] = (unsigned char) b;
	setbit(s_pc);

	if (s_pass == 1) {
		list_genb(b);
		if (b_flag) {
			fwrite(&s_mem[s_pc], 1, 1, fout);
		}
	}

	if (s_pc < s_minpc)
		s_minpc = s_pc;
	s_pc++;
	if (s_pc > s_maxpc)
		s_maxpc = s_pc;
}

/* 
 * Generate 'n' as a 16 bit word, little endian or big endian depending on
 * s_msbword.
 */
static void genw(int n, const char *ep)
{
	if (s_msbword)
		genb(n >> 8, ep);
	genb(n, ep);
	if (!s_msbword)
		genb(n >> 8, ep);
}

/* 
 * We have matched an instruction in the table.
 * Generate the machine code for the instruction using the generation
 * pattern 'p. 'vs are the arguments generated during the matching process.
 */
static void gen(const char *p, const int *vs)
{
	// int w, b, i, savepc;
	int b, i, savepc;
	const char *p_orig;

	savepc = s_pc;
	p_orig = p;
	b = 0;
loop:
	i = hexvalu(*p);
	if (i >= 0) {
		p++;
		b = (i << 4) | hexval(*p);
	} else if (*p == '.') {
		genb(b, s_pline_ep);
		b = 0;
	} else if (*p == '\0') {
		return;
	} else {
		i = *(p + 1) - '0';
		switch (*p) {
		case 'b': b |= (vs[i] << 3); break;
		case 'c': b |= vs[i]; break;
		case 'd': b = vs[i]; break;
		case 'e': genb(vs[i] & 0xff, s_pline_ep);
			  genb(vs[i] >> 8, s_pline_ep);
			  break;
		default:
			if (s_target->genf(&b, *p, vs, i, savepc) == -1) { 
				eprogname();
				fprintf(stderr,
					_("fatal:  bad pattern %s ('%c')"),
					p_orig, *p);
				enl();
				exit(EXIT_FAILURE);
			}
		}
		p++;
	}
	p++;
	goto loop;
}

/*
 * Tries to match *p with any of the strings in list.
 * If matched, returns the index in list and r points to the position
 * in p past the matched string.
 */
int mreg(const char *p, const char *const list[], const char **r)
{
	const char *s;
	const char *q;
	int i;

	i = 0;
	while ((s = list[i++]) != NULL) {
		if (*s == '\0')
			continue;
		q = p;
		while (toupper(*q++) == *s++) {
			if (*s == '\0') {
				if (!isalnum(*q)) {
					*r = q;
					return i - 1;
				} else {
					break;
				}
			}
		}
	}
	return -1;
}

static int isoctal(int c)
{
	return c >= '0' && c <= '7';
}

/*
 * Read an octal of 3 digits, being the maximum value 377 (255 decimal);
 * Return -1 if there is an error in the syntax.
 */
static int readoctal(const char *p)
{
	int n;
	const char *q;

	if (*p >= '0' && *p <= '3' && isoctal(*(p + 1)) && isoctal(*(p + 2))) {
		n = 0;
		q = p + 3;
		while (p < q) {
			n *= 8;
			n += (*p - '0');
			p++;
		}
		return n;
	}

	return -1;
}

enum strmode {
	STRMODE_ECHO,
	STRMODE_NULL,
	STRMODE_BYTE,
	STRMODE_WORD
};

/* 
 * Generate the string bytes until double quote or null char.
 * Return a pointer to the ending double quote character or '\0'.
 * 'p must point to the starting double quote.
 * If mode:
 * 	STRMODE_ECHO only echo to stderr the characters.
 * 	STRMODE_NULL only parses the string.
 * 	STRMODE_BYTE generate the characters in the binary file as bytes.
 * 	STRMODE_WORD generate the characters in the binary file as words.
 */
static const char *genstr(const char *p, enum strmode mode)
{
	int c;

	for (p = p + 1; *p != '\0' && *p != '\"'; p++) {
		c = *p;
		if (c == '\\') {
			p++;
			switch (*p) {
			case 'n': c = '\n'; break;
			case 'r': c = '\r'; break;
			case 'b': c = '\b'; break;
			case 't': c = '\t'; break;
			case 'f': c = '\f'; break;
			case '\\': c = '\\'; break;
			case '\"': c = '\"'; break;
			default:
				c = readoctal(p);
				if (c < 0) {
					eprint(_("bad character escape "
						 "sequence\n"));
					eprcol(s_pline, p - 1);
					newerr();
					p--;
				} else {
					p += 2;
				}
			}
		}
		switch (mode) {
		case STRMODE_ECHO: fputc(c, stderr); break;
		case STRMODE_NULL: break;
		case STRMODE_BYTE: genb(c, p); break;
		case STRMODE_WORD: genw(c, p); break;
		}
	}

	return p;
}

/* Match an instruction.
 * If no match returns NULL; else returns one past end of match.
 * p should point to no whitespace.
 */
static const char *match(const char *p)
{
	const struct matchtab *mtab;
	const char *s, *pp, *q;
	int v, n, vi, linepc;
	int vs[4];

	assert(!isspace(*p));

	mtab = s_target->matcht;
	linepc = s_pc;
	pp = p;
	n = -1;
next:
	n++;
	s = mtab[n].pat;
	if (s == NULL) {
		return NULL;
	} else if ((s_target->mask & mtab[n].mask) == 0) {
		goto next;
	} else if (!s_undocumented_op && (s_target->mask & mtab[n].undoc)) {
		goto next;
	}
	p = pp;
	vi = 0;
loop:
	if (*s == '\0') {
		p = skipws(p);
		if (*p != ';' && *p != '\0' && *p != '\\')
			goto next;
		else
			goto found;
	} else if (*s == ' ') {
		if (!isspace(*p))
			goto next;
		p = skipws(p);
	} else if ((*s == ',' || *s == '(' || *s == ')') && isspace(*p)) {
		p = skipws(p);
		if (*s != *p)
			goto next;
		p = skipws(p + 1);
	} else if (*s == 'a') {
		p = expr(p, &v, linepc, s_pass == 0, NULL, NULL);
		if (p == NULL)
			return NULL;
		vs[vi++] = v;
	} else if (*s >= 'b' && *s <= 'z') {
		v = s_target->matchf(*s, p, &q);
		goto reg;
	} else if (*p == *s && *p == ',') {
		p = skipws(p + 1);
	} else if (toupper(*p) == *s) {
		p++;
	} else {
		goto next;
	}
freg:
	s++;
	goto loop;
reg:
	if (v < 0) {
		goto next;
	} else {
		assert(vi < sizeof(vs));
		vs[vi++] = v;
		p = q;
	}
	goto freg;
found:
	// printf("%s\n", s_matchtab[n].pat);
	gen(mtab[n].gen, vs);
	return p;
}

static const char *
d_null(const char *p)
{
	p = sync(p);
	while (*p != '\0' && *p != '\\') {
		if (!isspace(*p)) {
			wprint(_("invalid characters after directive\n"));
			eprcol(s_pline, p);
			return sync(p);
		} else {
			p++;
		}
	}
	return p;
}

static const char *d_end(const char *p)
{
	enum expr_ecode ecode;
	const char *q;
	const char *ep;

	if (s_pass == 0) {
		if (s_end_seen) {
			eprint(_("duplicate .END\n"));
			eprcol(s_pline, s_pline_ep);
			newerr();
		} else {
			s_end_seen = 1;
		}
	}
		
	q = expr(p, NULL, s_pc, s_pass == 0, &ecode, &ep);
	if (q == NULL && ecode == EXPR_E_NO_EXPR) {
		return p;
	} else if (q == NULL) {
		exprint(ecode, s_pline, ep);
		newerr();
		return NULL;
	} else {
		return q;
	}
}

static const char *d_codes(const char *p)
{
	s_codes = 1;
	return p;
}

static const char *d_module(const char *p)
{
	p = sync(p);
	while (*p != '\0' && *p != '\\') {
		if (!isspace(*p)) {
			wprint(_("invalid characters after directive\n"));
			eprcol(s_pline, p);
			return sync(p);
		} else {
			p++;
		}
	}
	return p;
}

static const char *d_nocodes(const char *p)
{
	s_codes = 0;
	return p;
}

static const char *d_list(const char *p)
{
	s_list_on = 1;
	return p;
}

static const char *d_nolist(const char *p)
{
	s_list_on = 0;
	return p;
}

static const char *d_eject(const char *p)
{
	list_eject();
	return p;
}

static const char *d_echo(const char *p)
{
	int n;
	int mode;
	enum expr_ecode ecode;
	const char *ep;

	mode = (s_pass == 0) ? STRMODE_NULL : STRMODE_ECHO;
	if (*p == '\"') {
		p = genstr(p, mode);
		if (*p == '\"') {
			p++;
		} else if (s_pass == 0) {
			wprint(_("no terminating quote\n"));
			eprcol(s_pline, p);
		}
	} else if (*p != '\0') {
		p = expr(p, &n, s_pc, s_pass == 0, &ecode, &ep);
		if (p == NULL) {
			exprint(ecode, s_pline, ep);
			newerr();
			return NULL;
		}
		if (mode == STRMODE_ECHO) {
			fprintf(stderr, "%d", n);
		}
	}
	return p;
}

static const char *d_equ(const char *p)
{
	int n;
	enum expr_ecode ecode;
	const char *ep;

	p = expr(p, &n, s_pc, 0, &ecode, &ep);
	if (p == NULL) {
		exprint(ecode, s_pline, ep);
		newerr();
		return NULL;
	}

	if (s_lastsym == NULL) {
		eprint(_(".EQU without label\n"));
		eprcol(s_pline, s_pline_ep);
		newerr();
	} else {
		/* TODO: check label misalign? */
		s_lastsym->val = n;
		s_lastsym->isequ = 1;
	}
	return p;
}

static const char *d_set(const char *p)
{
	int n;
	enum expr_ecode ecode;
	const char *ep;

	p = expr(p, &n, s_pc, 0, &ecode, &ep);
	if (p == NULL) {
		exprint(ecode, s_pline, ep);
		newerr();
		return NULL;
	}

	if (s_lastsym == NULL) {
		eprint(_(".EQU without label\n"));
		eprcol(s_pline, s_pline_ep);
		newerr();
	} else {
		/* TODO: check label misalign? */
		s_lastsym->val = n;
		s_lastsym->isequ = 1;
	}
	return p;
}

static const char *d_export(const char *p)
{
	/* TODO */
	return NULL;
}

static const char *d_fill(const char *p)
{
	int n, v, er;
	const char *q;
	enum expr_ecode ecode;
	const char *ep, *eps;

	eps = p;
	er = 0;
	p = expr(p, &n, s_pc, 0, &ecode, &ep); 
	if (p == NULL) {
		exprint(ecode, s_pline, ep);
		newerr();
		return NULL;
	}

	if (n < 0) {
		eprint(_("number of positions to fill is negative (%d)\n"), n);
		eprcol(s_pline, eps);
		exit(EXIT_FAILURE);
	}

	v = 255;
	p = skipws(p);
	if (*p == ',') {
		p = skipws(p + 1);
		q = expr(p, &v, s_pc, s_pass == 0, &ecode, &ep);
		if (q == NULL) {
			er = 1;
			exprint(ecode, s_pline, ep);
			newerr();
		} else {
			p = q;
		}
	}

	while (n--)
		genb(v, eps);

	if (er)
		return NULL;
	else
		return p;
}

static const char *d_ds(const char *p)
{
	int n, v, er;
	const char *q;
	enum expr_ecode ecode;
	const char *ep, *eps;

	eps = p;
	er = 0;
	p = expr(p, &n, s_pc, 0, &ecode, &ep); 
	if (p == NULL) {
		exprint(ecode, s_pline, ep);
		newerr();
		return NULL;
	}

	if (n < 0) {
		eprint(_("number of positions to space over is negative (%d)\n"), n);
		eprcol(s_pline, eps);
		exit(EXIT_FAILURE);
	}

	v = 255;
	p = skipws(p);
	if (*p == ',') {
		p = skipws(p + 1);
		q = expr(p, &v, s_pc, s_pass == 0, &ecode, &ep);
		if (q == NULL) {
			er = 1;
			exprint(ecode, s_pline, ep);
			newerr();
		} else {
			p = q;
		}
	}

	s_pc += n;

	if (er)
		return NULL;
	else
		return p;
}

static const char *d_lsfirst(const char *p)
{
	s_msbword = 0;
	return p;
}

static const char *d_msfirst(const char *p)
{
	s_msbword = 1;
	return p;
}

static const char *d_org(const char *p)
{
	int n;
	enum expr_ecode ecode;
	const char *ep, *eps;

	eps = p;
	p = expr(p, &n, s_pc, 0, &ecode, &ep);
	if (p == NULL) {
		exprint(ecode, s_pline, ep);
		newerr();
		return NULL;
	}

	if (n < 0 || n > 65536) {
		eprint(_(".ORG address (%d) is not in range [0, 65536]\n"), n);
		eprcol(s_pline, eps);
		exit(EXIT_FAILURE);
	}

	s_pc = n;

	/* Change the listing PC so in orgs we print the changed PC. */
	if (s_pass > 0)
		list_setpc(s_pc);

	if (s_lastsym != NULL) {
		/* TODO: check label misalign? */
		s_lastsym->val = s_pc;
		s_lastsym->isequ = 1;
	}

	return p;
}

static const char *d_lst(const char *p, int w)
{
	enum strmode mode;
	int n, linepc;
	enum expr_ecode ecode;
	const char *ep, *eps;

	if (w)
		mode = STRMODE_WORD;
	else
		mode = STRMODE_BYTE;

	linepc = s_pc;
dnlst: 
	if (*p == '\"') {
		p = genstr(p, mode);
		if (*p == '\"') {
			p++;
		} else {
			wprint(_("no terminating quote\n"));
			eprcol(s_pline, p);
		}
	} else {
		eps = p;
		p = expr(p, &n, linepc, s_pass == 0, &ecode, &ep);
		if (p == NULL) {
			exprint(ecode, s_pline, ep);
			newerr();
			return NULL;
		}
		if (w)
			genw(n, eps);
		else
			genb(n, eps);
	}
	p = skipws(p);
	if (*p == ',') {
		p++;
		p = skipws(p);
		goto dnlst;
	}
	return p;
}

static const char *d_align(const char *p)
{
	int n, v, er;
	const char *q;
	enum expr_ecode ecode;
	const char *ep, *eps;

	eps = p;
	er = 0;
	p = expr(p, &n, s_pc, 0, &ecode, &ep); 
	if (p == NULL) {
		exprint(ecode, s_pline, ep);
		newerr();
		return NULL;
	}

	if (n < 0) {
		eprint(_("align is negative (%d)\n"), n);
		eprcol(s_pline, eps);
		exit(EXIT_FAILURE);
	}

	while (s_pc % n) {
		genb(0, eps);
	}

	if (er)
		return NULL;
	else
		return p;
}

static const char *d_byte(const char *p)
{
	return d_lst(p, 0);
}

static const char *d_word(const char *p)
{
	return d_lst(p, 1);
}

static const char *d_text(const char *p)
{
	if (*p == '\"') {
		p = genstr(p, STRMODE_BYTE);
		if (*p == '\"') {
			p++;
		} else {
			wprint(_("no terminating quote\n"));
			eprcol(s_pline, p);
		}
		return p;
	} else {
		eprint(_(".TEXT directive needs a quoted string argument\n"));
		eprcol(s_pline, p);
		newerr();
		return NULL;
	}
}

static const char *d_title(const char *p)
{
	return NULL;
}

static const char *d_block(const char *p)
{
	int n;
	enum expr_ecode ecode;
	const char *ep, *eps;

	eps = p;
	p = expr(p, &n, s_pc, 0, &ecode, &ep);
	if (p == NULL) {
		exprint(ecode, s_pline, ep);
		newerr();
		return NULL;
	}

	s_pc += n;
	if (s_pc < 0 || s_pc > 65536) {
		eprint(_("address (%d) set by .BLOCK is not in range "
			 "[0, 65536]\n"), s_pc);
		eprcol(s_pline, eps);
		exit(EXIT_FAILURE);
	}

	return p;
}

/* a must be < b. */
static int checksum(int a, int b)
{
	int n;

	assert(a < b);

	n = 0;
	while (a < b)
		n += s_mem[a++];

	return n;
}

static const char *d_chk(const char *p)
{
	int n;
	enum expr_ecode ecode;
	const char *ep, *eps;

	eps = p;
	p = expr(p, &n, s_pc, s_pass == 0, &ecode, &ep);
	if (p == NULL) {
		exprint(ecode, s_pline, ep);
		newerr();
		genb(0, eps);
		return NULL;
	}

	if (s_pass == 0) {
		genb(0, s_pline_ep);
	} else if (n < 0 || n >= s_pc) {
		eprint(_(".CHK address (%d) is not in range [0, %d[\n"), n,
			s_pc);
		eprcol(s_pline, eps);
		newerr();
		genb(0, eps);
	} else {
		genb(checksum(n, s_pc), eps);
	}

	return p;
}

/* Parses an internal directive (those that start with '.').
 * Returns NULL on error;
 * If no error returns position past the parsed directive and arguments. */
static const char *parse_direc(const char *cp)
{
	const char *cq, *p;
	int a, b, m = 0;

	a = 0;
	b = NELEMS(s_directab) - 1;
	while (a <= b) {
		m = (a + b) / 2;
		cq = cp;
		p = s_directab[m].name;
		while (*p != '\0' && toupper(*cq) == *p) {
			p++;
			cq++;
		}
		if (*p == '\0' && (*cq == '\0' || isspace(*cq)))
			break;
		else if (toupper(*cq) < *p)
			b = m - 1;
		else
			a = m + 1;
	}

	if (a <= b) {
		cq = skipws(cq);
		return s_directab[m].fun(cq);
	} else {
		eprint(_("unrecognized directive\n"));
		eprcol(s_pline, s_pline_ep);
		newerr();
		return NULL;
	}
}

static void parselin(const char *cp)
{
	int col0, alloweq;
	const char *q;

	s_pline_ep = cp;
start:	s_lastsym = NULL;
	alloweq = 0;
	col0 = 1;	
loop:
	if (*cp == '\0' || *cp == ';') {
		return;
	} else if (*cp == '\\') {
		if (s_pass == 1) {
			list_endln();
			list_startln(s_empty_line, curfile()->linenum, s_pc,
				nfiles());
		}
		cp++;
		goto start;
	} else if (*cp == '.') {
		s_pline_ep = cp;
		cp++;
		q = parse_direc(cp);
		if (q == NULL) {
			cp = sync(cp);
		} else {
			cp = d_null(q);
		}
	} else if ((*cp == '$' || *cp == '*') && cp[1] == '=') {
		/* Alternative form of .ORG: *= or $= */
		cp += 2;
		q = d_org(cp);
		if (q == NULL) {
			cp = sync(cp);
		} else {
			cp = d_null(q);
		}
	} else if (*cp == '=' && alloweq) {
		/* equ */
		s_pline_ep = cp;
		cp++;
		q = d_equ(cp);
		if (q == NULL) {
			cp = sync(cp);
		} else {
			cp = d_null(q);
		}
	} else if (isidc0(*cp)) {
		if (col0 && *cp != '.') {
			/* take label */
			s_pline_ep = cp;
			q = cp;
			col0 = 0;
			while (isidc(*cp))
				cp++;
			s_lastsym = lookup(q, cp, s_pass == 0, s_pc);
			if (*cp == ':' || isspace(*cp)) {
				alloweq = 1;
				cp++;
			} else if (*cp == '=') {
				alloweq = 1;
			}
			if (s_pass == 1 && !s_lastsym->isequ &&
				s_lastsym->val != s_pc)
			{
				eprint(_("misaligned label %s\n"),
					s_lastsym->name);
				fprintf(stderr, _(" Previous value was %XH, "
					"new value %XH."), s_lastsym->val,
					s_pc);
				eprcol(s_pline, s_pline_ep);
				newerr();
			}
		} else {
			cp = skipws(cp);
			s_pline_ep = cp;
			q = match(cp);
			if (q == NULL) {
				eprint(_("syntax error\n"));
				newerr();
				cp = sync(cp);
			} else {
				cp = d_null(q);
			}
		}
	} else if (isspace(*cp)) {
		col0 = 0;
		while (isspace(*cp))
			cp++;
	} else {
		eprint(_("unexpected character (%c)\n"), *cp);
		eprcol(s_pline, cp);
		newerr();
		cp = sync(cp + 1);
	}
	goto loop;
}

/*
 * Gets a new line into 's_line from 'fin.
 * Terminates the line with '\0'.
 * Does not read more than LINESZ - 1 characters.
 * Does not add a '\n' character, thus a line of length 0 it's possible.
 * Always advances to the next line.
 * Returns -1 for EOF or the line length.
 */
static int getlin(FILE *fin)
{
	int i, c;

	c = EOF;
	i = 0;
	while (i < LINESZ - 1) {
		c = getc(fin);
		if (c == EOF || c == '\n')
			break;
		s_line[i++] = (char) c;
	}
	if (c != EOF && c != '\n') {
		wprint(_("line too long, truncated to %d characters\n"),
			LINESZ);
	}
	while (c != EOF && c != '\n')
		c = getc(fin);
	if (i == 0 && c == EOF)
		return -1;
	s_line[i] = '\0';
	return i;
}

/* Preinstall the macros defined in the command line. */
static void install_predefs(void)
{
	struct predef *pdef;

	for (pdef = s_predefs; pdef != NULL; pdef = pdef->next)
		pp_define(pdef->name);
}

/* Do a pass through the source. */
static void dopass(const char *fname)
{
	/* Fill memory with default value. */
	if ((s_pass == 0 && s_mem_fillval != 0) || s_pass > 0) {
		memset(s_mem, s_mem_fillval, sizeof(s_mem));
	}

	if (s_pass > 0) {
		pp_reset();
		list_open(s_lstfname);
		s_codes = 1;
		s_list_on = 1;
	}


	install_predefs();
	s_minpc = -1;
	s_maxpc = -1;
	s_pc = 0;
	s_lastsym = NULL;
	s_msbword = 0;

	pushfile(fname, fname + strlen(fname));
	while (nfiles() > 0) {
		curfile()->linenum++;
		if (getlin(curfile()->fin) >= 0) {
			if (s_pass == 1) {
				list_startln(s_line, curfile()->linenum, s_pc,
					nfiles());
			}
			pp_line(s_line);
			if (s_pass == 1)
				list_skip(s_skipon);
			parselin(s_pline);
			if (s_pass == 1)
				list_endln();
		} else {
			popfile();
		}
	}

	if (s_pass > 0) {
		list_close();
	}
}

/*
 * Write the object file in memory order
 */
static void output()
{
	int i;

	// fprintf(stderr, "output: min: %x max: %x\n", s_minpc, s_maxpc);

	if (s_minpc < 0)
		s_minpc = 0;
	if (s_maxpc < 0)
		s_maxpc = 0;

	for (i = s_minpc; i < s_maxpc; i++) {
		if (isset(i)) {
			fwrite(&s_mem[i], 1, 1, fout);
		}
	}
	if (ferror(fout)) {
		eprint(_("cannot write to file %s\n"), s_objfname);
		clearerr(fout);
	}
}

/* Start the assembly using the config in options.c. */
void uz80as(void)
{
	s_target = find_target(s_target_id);
	if (s_target == NULL) {
		eprint(_("target '%s' not supported\n"), s_target_id);
		exit(EXIT_FAILURE);
	}

	for (s_pass = 0; s_nerrors == 0 && s_pass < 2; s_pass++) {
		if ((s_pass > 0) && (s_nerrors == 0)) {
			open_output();
		}
		dopass(s_asmfname);
		if (s_pass == 0 && !s_end_seen) {
			wprint(_("no .END statement in the source\n"));
		}
		if (s_nerrors == 0) {
			if (verbose) printf("Pass %d completed.\n", s_pass + 1);
		}
	}

	if (s_nerrors > 0) {
		exit(EXIT_FAILURE);
	}

	if (!b_flag) {
		output();
	}
	close_output();
}
