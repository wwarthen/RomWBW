/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Expression parsing.
 * ===========================================================================
 */

#ifndef EXPR_H
#define EXPR_H

enum expr_ecode {
	EXPR_E_NO_EXPR,	/* There was no expression parsed. */
	EXPR_E_SYNTAX,	/* Syntax error. */
	EXPR_E_CPAR,
	EXPR_E_OPER,
	EXPR_E_CHAR,
	EXPR_E_HEX,
	EXPR_E_OCTAL,
	EXPR_E_BIN,
	EXPR_E_DEC,
};

const char *expr(const char *p, int *v, int linepc, int allowfr,
		 enum expr_ecode *ecode, const char **ep);

#endif
