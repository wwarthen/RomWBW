/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Global options, normally coming from the command line.
 * ===========================================================================
 */

#include "config.h"
#include "options.h"
#include "err.h"

const char *s_asmfname;	/* Name of source file. */
const char *s_objfname;	/* Name of generated binary file. */
const char *s_lstfname;	/* Name of listing file. */
const char *s_target_id = "z80"; /* ID of target */
int s_listing = 1;	/* If we generate the listing file or not. */
int s_extended_op = 0;	/* Allow extended instruction syntax. */
int s_undocumented_op = 0;  /* Allow undocumented instructions. */
int s_mem_fillval = 0;	/* Default value to fill the 64K memory. */

/* Command line macro definitions. */
struct predef *s_predefs;

/* Predefine a macro in the command line that must persist between passes. */
void predefine(const char *text)
{
	struct predef *pdef;

	pdef = emalloc(sizeof(*pdef));
	pdef->name = text;
	pdef->next = s_predefs;
	s_predefs = pdef;
}
