/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Expression error reporting.
 * ===========================================================================
 */

#ifndef EXPRINT_H
#define EXPRINT_H

#ifndef EXPR_H
#include "expr.h"
#endif

void exprint(enum expr_ecode ecode, const char *pline, const char *ep);

#endif
