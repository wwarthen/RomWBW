/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Global options, normally coming from the command line.
 * ===========================================================================
 */

#ifndef OPTIONS_H
#define OPTIONS_H

/* Predefined macro at the command line. */
struct predef {
	struct predef *next;
	const char *name;
};

extern const char *s_asmfname;
extern const char *s_objfname;
extern const char *s_lstfname;
extern const char *s_target_id;
extern int s_listing;
extern int s_extended_op;
extern int s_undocumented_op;
extern int s_mem_fillval;
extern struct predef *s_predefs;

void predefine(const char *name);

#endif
