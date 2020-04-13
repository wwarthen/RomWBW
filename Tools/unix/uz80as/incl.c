/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Include file stack.
 * ===========================================================================
 */

#include "config.h"
#include "incl.h"
#include "utils.h"
#include "err.h"

#ifndef ASSERT_H
#include <assert.h>
#endif

#ifndef STDIO_H
#include <stdio.h>
#endif

#ifndef STDLIB_H
#include <stdlib.h>
#endif

/* Max number of nested included files. */
#define NFILES		128

/* Number of nested files. */
static int s_nfiles;

/* Current file. */
static struct incfile *s_curfile;

/* Get the current file. Never returns NULL. */
struct incfile *curfile(void)
{
	assert(s_curfile != NULL);
	return s_curfile;
}

/* The number of nested files. 0 means no file loaded. */
int nfiles(void)
{
	return s_nfiles;
}

/* Leave the current included file. */
void popfile(void)
{
	struct incfile *ifile;

	assert(s_curfile != NULL);
	fclose(s_curfile->fin);
	ifile = s_curfile;
	s_curfile = ifile->prev;
	free(ifile);
	s_nfiles--;
}

/* Include a file whose name is [p, q[. */
void pushfile(const char *p, const char *q)
{
	struct incfile *ifile;

	if (s_nfiles == NFILES) {
		eprint(_("maximum number of nested includes exceeded (%d)\n"),
			NFILES);
		exit(EXIT_FAILURE);
	}

	// printf("pushfile: %s\n", p);
	ifile = emalloc((sizeof *ifile) + (q - p) + 1);
	ifile->name = (char *) ((unsigned char *) ifile + sizeof *ifile);
	copychars(ifile->name, p, q);

	ifile->fin = efopen(ifile->name, "r");
	ifile->linenum = 0;
	ifile->prev = s_curfile;
	s_curfile = ifile;
	s_nfiles++;
}
