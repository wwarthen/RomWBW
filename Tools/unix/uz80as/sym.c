/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Symbol table for labels.
 * ===========================================================================
 */

#include "config.h"
#include "sym.h"
#include "utils.h"
#include "err.h"

#ifndef STDIO_H
#include <stdio.h>
#endif

#ifndef STDLIB_H
#include <stdlib.h>
#endif

/*
 * Maximum number of symbols (labels) allowed.
 * Must not be more than 64K.
 */
#define NSYMS		15000

/* Closest prime to NSYMS / 4. */
#define SYMTABSZ	3739

/*
 * Nodes for the s_symtab hash table.
 * The symbol at index 0 is never used.
 */
static struct sym s_symlist[NSYMS];

/*
 * Hash table of indexes into s_symlist.
 * 0 means that the bucket is empty.
 */
static unsigned short s_symtab[SYMTABSZ];

/* Next free symbol in s_symlist. Note: 0 not used. */
static int s_nsyms = 1;

/*
 * Lookups the string in [p, q[ in s_symtab.
 * If !insert, returns the symbol or NULL if it is not in the table.
 * If insert, inserts the symbol in the table if it is not there, and
 * sets its .val to 'pc'.
 */
struct sym *lookup(const char *p, const char *q, int insert, int pc)
{
	int h, k;
	struct sym *nod;

	if (q - p > SYMLEN - 1) {
		/* Label too long, don't add. */
		eprint(_("label too long"));
		epchars(p, q);
		enl();
		newerr();
		/*
		 * This would truncate:
		 * q = p + (SYMLEN - 1);
		 */
		return NULL;
	}

	h = hash(p, q, SYMTABSZ);
	for (k = s_symtab[h]; k != 0; k = s_symlist[k].next) {
		if (scmp(p, q, s_symlist[k].name) == 0) {
			if (insert) {
				if (!s_symlist[k].isequ) {
					wprint("duplicate label (%s)\n",
						s_symlist[k].name);
				}
			}
			return &s_symlist[k];
		}
	}

	if (insert) {
		if (s_nsyms == NSYMS) {
			eprint(_("maximum number of labels exceeded (%d)\n"),
				NSYMS);
			exit(EXIT_FAILURE);
		}

		nod = &s_symlist[s_nsyms];
		nod->next = s_symtab[h];
		s_symtab[h] = (unsigned short) s_nsyms;
		s_nsyms++;

		k = 0;
		while (p != q && k < SYMLEN - 1)
			nod->name[k++] = *p++;
		nod->name[k] = '\0';
		nod->val = pc;
		return nod;
	}

	return NULL;
}
