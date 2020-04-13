/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Assembly listing generation.
 * ===========================================================================
 */

#include "config.h"
#include "list.h"
#include "err.h"

#ifndef STDIO_H
#include <stdio.h>
#endif

#ifndef STLIB_H
#include <stdlib.h>
#endif

#ifndef STRING_H
#include <string.h>
#endif

static FILE *s_list_file;

/* N characters in current line. */
static int s_nchars;

/* Generated data bytes in this line. */
static int s_nbytes;

/* Line text. */
static const char *s_line;

/* Line number. */
static int s_linenum;

/* Program counter. */
static int s_pc;

/* Number of current nested files. */
static int s_nfiles;

/* If listing line number, etc are generated or just the line. */
int s_codes = 1;

/* If listing is enabled or not. */
int s_list_on = 1;

/* If we are skipping lines. */
static int s_skip_on = 0;

void list_open(const char *fname)
{
	s_list_file = fopen(fname, "w");
	if (s_list_file == NULL) {
		eprint(_("cannot open file %s\n"), fname);
	}
}

void list_close(void)
{
	if (s_list_file != NULL)
		fclose(s_list_file);
}

static void prhead(void)
{
	int i, j, n;

	s_nchars = fprintf(s_list_file, "%-.4d", s_linenum);

	n = 7 - s_nchars;
	if (n <= 0)
		n = 1;
	j = 0;
	if (s_nfiles > 0)
		j = s_nfiles - 1;
	if (j > n)
		j = n;
	for (i = 0; i < j; i++)
		fputc('+', s_list_file);
	j = n - j;
	while (j--)
		fputc(' ', s_list_file);
	s_nchars += n;

	s_nchars += fprintf(s_list_file, "%.4X", s_pc);
	if (s_skip_on)
		fputc('~', s_list_file);
	else
		fputc(' ', s_list_file);
	s_nchars += 1;
}

static void prline(void)
{
	if (s_line == NULL) {
		fputs("\n", s_list_file);
	} else {
		if (s_codes) {
			while (s_nchars < 24) {
				s_nchars++;
				fputc(' ', s_list_file);
			}
		}
		fprintf(s_list_file, "%s\n", s_line);
		s_line = NULL;
	}
	s_nchars = 0;
	s_nbytes = 0;
}

void list_startln(const char *line, int linenum, int pc, int nested_files)
{
	if (s_list_file == NULL)
		return;
	s_linenum = linenum;
	s_pc = pc;
	s_line = line;
	s_nchars = 0;
	s_nbytes = 0;
	s_nfiles = nested_files;
}

void list_setpc(int pc)
{
	s_pc = pc;
}

void list_skip(int on)
{
	s_skip_on = on;
}

void list_eject(void)
{
	if (s_list_file == NULL || !s_list_on)
		return;
}

void list_genb(int b)
{
	if (s_list_file == NULL || !s_codes || !s_list_on)
		return;
	if (s_nchars == 0)
		prhead();
	if (s_nbytes >= 4) {
		prline();
		prhead();
	}
	s_nchars += fprintf(s_list_file, "%2.2X ", (b & 0xff));
	s_nbytes++;
	s_pc++;
}

void list_endln(void)
{
	if (s_list_file == NULL || !s_list_on)
		return;
	if (s_codes && s_nchars == 0)
		prhead();
	prline();
}
