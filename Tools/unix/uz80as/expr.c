/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Expression parsing.
 * ===========================================================================
 */

#include "config.h"
#include "expr.h"
#include "utils.h"
#include "err.h"
#include "sym.h"

#ifndef ASSERT_H
#include <assert.h>
#endif

#ifndef CTYPE_H
#include <ctype.h>
#endif

#ifndef LIMITS_H
#include <limits.h>
#endif

#ifndef STDIO_H
#include <stdio.h>
#endif

#ifndef STDLIB_H
#include <stdlib.h>
#endif

/* Max nested expressions. */
#define ESTKSZ		16
#define ESTKSZ2		(ESTKSZ*2)

/* Return -1 on syntax error.
 * *p must be a digit already.
 * *q points to one past the end of the number without suffix.
 */
static int takenum(const char *p, const char *q, int radix)
{
	int k, n;

	n = 0;
	while (p != q) {
		k = hexval(*p);
	       	p++;
		if (k >= 0 && k < radix)
			n = n * radix + k;
		else
			return -1;
	}
	return n;
}

/* Go to the end of a number (advance all digits or letters). */
static const char *goendnum(const char *p)
{
	const char *q;

	for (q = p; isalnum(*q); q++)
		;
	return q;
}

/*
 * Returns NULL on error.
 * '*p' must be a digit already.
 */
static const char *getnum(const char *p, int *v)
{
	int n;
	char c;
	const char *q;

	assert(isdigit(*p));

	n = 0;
	q = goendnum(p) - 1;
	if (isalpha(*q)) {
		c = toupper(*q);
		if (c == 'H') {
			n = takenum(p, q, 16);
		} else if (c == 'D') {
			n = takenum(p, q, 10);
		} else if (c == 'O') {
			n = takenum(p, q, 8);
		} else if (c == 'B') {
			n = takenum(p, q, 2);
		} else {
			return NULL;
		}
	} else {
		n = takenum(p, q + 1, 10);
	}

	if (n < 0)
		return NULL;

	*v = n;
	return q + 1;
}

/* 
 * Gets a number that was prefixed.
 * Returns NULL on error.
 */
static const char *getpnum(const char *p, int radix, int *v)
{
	const char *q;
	int n;

	q = goendnum(p);
	n = takenum(p, q, radix);
	if (n < 0)
		return NULL;
	*v = n;
	return q;
}

/* Left shift */
static int shl(int r, int n)
{
	n &= int_precission();
	return r << n;
}


/* Portable arithmetic right shift. */
static int ashr(int r, int n)
{
	n &= int_precission();
	if (r & INT_MIN) {
		return ~(~r >> n);
	} else {
		return r >> n;
	}
}

/* Parses expression pointed by 'p'.
 * If success, returns pointer to the end of parsed expression, and
 * 'v' contains the calculated value of the expression.
 * Returns NULL if a syntactic error has occurred. 
 * Operators are evaluated left to right.
 * To allow precedence use parenthesis.
 * 'linepc' is the program counter to consider when we find the $ current
 * pointer location symbol ($).
 * 'allowfr' stands for 'allow forward references'. We will issue an error
 * if we find a label that is not defined.
 * 'ecode' will be valid if NULL is returned. NULL can be passed as ecode.
 * 'ep' is the pointer to the position where the error ocurred. NULL can be
 * passed as ep.
 */
const char *expr(const char *p, int *v, int linepc, int allowfr,
	enum expr_ecode *ecode, const char **ep)
{
	int si, usi, usl;
	const char *q;
	char last;
	int stack[ESTKSZ2];
	int uopstk[ESTKSZ];
	int r, n;
	struct sym *sym;
	int err;
	enum expr_ecode ec;

	ec = EXPR_E_NO_EXPR;
	err = 0;
	usi = 0;
	si = 0;
	r = 0;
	last = 'V';	/* first void */
	usl = 0;
loop:
	p = skipws(p);
	if (*p == '(') {
		if (last == 'n') {
			goto end;
		} else {
			if (si >= ESTKSZ2) {
				eprint(_("expression too complex\n"));
				exit(EXIT_FAILURE);
			}
			stack[si++] = last;
			stack[si++] = r;
			stack[si++] = usl;
			usl = usi;
			p++;
			r = 0;
			last = 'v';	/* void */
		}
	} else if (*p == ')') {
		if (last != 'n') {
			ec = EXPR_E_CPAR;
			goto esyntax;
		} else if (si == 0) {
			goto end;
		} else {
			p++;
			n = r;
			usl = stack[--si];
			r = stack[--si];
			last = (char) stack[--si];	
			goto oper;
		}
	} else if (*p == '+') {
		p++;
		if (last == 'n')
			last = '+';
	} else if (*p == '-') {
		if (last == 'n') {
			p++;
			last = '-';
		} else {
			goto uoper;
		}
	} else if (*p == '~') {
		goto uoper;
	} else if (*p == '!') {
		if (*(p + 1) == '=') {
			if (last != 'n') {
				ec = EXPR_E_OPER;
				goto esyntax;
			} else {
				p += 2;
				last = 'N';
			}
		} else {
			goto uoper;
		}
	} else if (*p == '*') {
		if (last == 'n') {
			last = *p++;
		} else {
			p++;
			n = linepc;
			goto oper;
		}
	} else if (*p == '/' || *p == '&' || *p == '|'
		|| *p == '^')
       	{
		if (last != 'n') {
			ec = EXPR_E_OPER;
			goto esyntax;
		} else {
			last = *p++;
		}
	} else if (*p == '>') {
		if (last != 'n') {
			ec = EXPR_E_OPER;
			goto esyntax;
		}
		p++;
	       	if (*p == '=') {
			last = 'G';
			p++;
		} else if (*p == '>') {
			last = 'R';
			p++;
		} else {
			last = '>';
		}
	} else if (*p == '<') {
		if (last != 'n') {
			ec = EXPR_E_OPER;
			goto esyntax;
		}
		p++;
	       	if (*p == '=') {
			last = 'S';
			p++;
		} else if (*p == '<') {
			last = 'L';
			p++;
		} else {
			last = '<';
		}
	} else if (*p == '=') {
		if (last != 'n') {
			ec = EXPR_E_OPER;
			goto esyntax;
		}
		p++;
		if (*p == '=')
			p++;
		last = '=';
	} else if (*p == '\'') {
		if (last == 'n')
			goto end;		
		p++;
		n = *p++;
		if (*p != '\'') {
			ec = EXPR_E_CHAR;
			goto esyntax;
		}
		p++;
		goto oper;
	} else if (*p == '$') {
		if (last == 'n')
			goto end;
		p++;
		if (hexval(*p) < 0) {
			n = linepc;
			goto oper;
		}
		q = getpnum(p, 16, &n);
		if (q == NULL) {
			p--;
			ec = EXPR_E_HEX;
			goto esyntax;
		}
		p = q;
		goto oper;
	} else if (*p == '@') {
		if (last == 'n')
			goto end;
		p++;
		q = getpnum(p, 8, &n);
		if (q == NULL) {
			p--;
			ec = EXPR_E_OCTAL;
			goto esyntax;
		}
		p = q;
		goto oper;
	} else if (*p == '%') {
		if (last == 'n') {
			last = *p;
			p++;
		} else {
			p++;
			q = getpnum(p, 2, &n);
			if (q == NULL) {
				ec = EXPR_E_BIN;
				goto esyntax;
			}
			p = q;
			goto oper;
		}
	} else if ((p[0] == '0') && (p[1] == 'x')) {
		p+=2;
		q = getpnum(p, 16, &n);
		if (q == NULL) {
			p--;
			ec = EXPR_E_HEX;
			goto esyntax;
		}
		p = q;
		goto oper;
	} else if (isdigit(*p)) {
		if (last == 'n')
			goto end;
		q = getnum(p, &n);
		if (q == NULL) {
			ec = EXPR_E_DEC;
			goto esyntax;
		}
		p = q;
		goto oper;
	} else if (isidc0(*p)) {
		if (last == 'n')
			goto end;
		q = p;
		while (isidc(*p))
			p++;
		sym = lookup(q, p, 0, 0);
		if (sym == NULL) {
			n = 0;
			if (!allowfr) {
				err = 1;
				eprint(_("undefined label"));
				epchars(q, p);
				enl();
				newerr();
			}
		} else {
			n = sym->val;
		}
		goto oper;
	} else if (last == 'V') {
		goto esyntax;
	} else if (last != 'n') {
		ec = EXPR_E_SYNTAX;
		goto esyntax;
	} else {
end:		if (v != NULL)
			*v = r;
		return p;
	}
	goto loop;
uoper:
	if (last == 'n')
		goto end;
	if (usi >= ESTKSZ) {
		eprint(_("expression too complex\n"));
		exit(EXIT_FAILURE);
	}
	uopstk[usi++] = *p++;
	goto loop;
oper:
	while (usi > usl) {
		usi--;
		switch (uopstk[usi]) {
		case '~': n = ~n; break;
		case '-': n = -n; break;
		case '!': n = !n; break;
		}
	}
	switch (last) {
	case 'V': r = n; break;
	case 'v': r = n; break;
	case '+': r += n; break;
	case '-': r -= n; break;
	case '*': r *= n; break;
	case '&': r &= n; break;
	case '|': r |= n; break;
	case '^': r ^= n; break;
	case '=': r = r == n; break;
	case '<': r = r < n; break;
	case '>': r = r > n ; break;
	case 'G': r = r >= n; break;
	case 'S': r = r <= n; break;
	case 'N': r = r != n; break;
	/* This would be logical right shift:
	 * case 'R': r = (unsigned int) r >> n; break;
	 */
	case 'R': r = ashr(r, n); break;
	case 'L': r = shl(r, n); break;
	case '~': r = ~n; break;
	case '%':
		if (n != 0) {
			r %= n;
	       	} else if (!err && !allowfr) {
			err = 1;
			eprint(_("modulo by zero\n"));
			exit(EXIT_FAILURE);
		}
		break;
	case '/':
	       	if (n != 0) {
			r /= n;
		} else if (!err && !allowfr) {
			err = 1;
			eprint(_("division by zero\n"));
			exit(EXIT_FAILURE);
		}
		break;
	}
	last = 'n';
	goto loop;
esyntax:
	if (ecode != NULL)
		*ecode = ec;
	if (ep != NULL)
		*ep = p;
	return NULL;
}
