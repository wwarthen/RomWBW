/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Expression error reporting.
 * ===========================================================================
 */

#include "config.h"
#include "exprint.h"
#include "err.h"

static const char *expr_get_error_str(enum expr_ecode ecode)
{
	switch (ecode) {
	case EXPR_E_NO_EXPR: return _("expression expected\n");
	case EXPR_E_SYNTAX: return _("syntax error in expression\n");
	case EXPR_E_CPAR: return _("unexpected ')'\n");
	case EXPR_E_OPER: return _("misplaced operator\n");
	case EXPR_E_CHAR: return _("invalid character code\n");
	case EXPR_E_HEX: return _("invalid hexadecimal constant\n");
	case EXPR_E_OCTAL: return _("invalid octal constant\n");
	case EXPR_E_BIN: return _("invalid binary constant\n");
	case EXPR_E_DEC: return _("invalid decimal constant\n");
	default: return "\n";
	}
}

void exprint(enum expr_ecode ecode, const char *pline, const char *ep)
{
	eprint(expr_get_error_str(ecode));
	eprcol(pline, ep);
}
