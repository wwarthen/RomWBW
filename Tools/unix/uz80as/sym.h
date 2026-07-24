/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Symbol table for labels.
 * ===========================================================================
 */

#ifndef SYM_H
#define SYM_H

/* Max symbol length + '\0'. */
#define SYMLEN		32

enum {
	SYM_FLAG_EQU = 1,
	SYM_FLAG_EXPORT = 2
};

struct sym {
	char name[SYMLEN];		/* null terminated string */
	int val;			/* value of symbol */
	unsigned short next;		/* index into symlist; 0 is no next */
	unsigned short flags;		/* SYM_FLAG_X */
};

struct sym *lookup(const char *p, const char *q, int insert, int pc);
int anything_to_export(void);
void write_export_file(const char *fname);

#endif
