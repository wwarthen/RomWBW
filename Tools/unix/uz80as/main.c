/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * main(), handling of command line options.
 * ===========================================================================
 */

#include "config.h"
#include "ngetopt.h"
#include "options.h"
#include "utils.h"
#include "err.h"
#include "uz80as.h"
#include "prtable.h"
#include "targets.h"

#ifndef STDIO_H
#include <stdio.h>
#endif

#ifndef STDLIB_H
#include <stdlib.h>
#endif

#ifndef STRING_H
#include <string.h>
#endif

#ifndef CTYPE_H
#include <ctype.h>
#endif

void print_copyright(FILE *f)
{
	static const char *copyright =
"Copyright (C) " COPYRIGHT_YEARS " Jorge Giner Cordero.\n";

	fputs(copyright, f);
}

static void print_license(FILE *f)
{
	static const char *license[] = {
"Permission is hereby granted, free of charge, to any person obtaining",
"a copy of this software and associated documentation files (the",
"\"Software\"), to deal in the Software without restriction, including",
"without limitation the rights to use, copy, modify, merge, publish,",
"distribute, sublicense, and/or sell copies of the Software, and to",
"permit persons to whom the Software is furnished to do so, subject to",
"the following conditions:",
"",
"The above copyright notice and this permission notice shall be included",
"in all copies or substantial portions of the Software.",
"",
"THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,",
"EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF",
"MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.",
"IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY",
"CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,",
"TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE",
"SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
       	};

	int i;

	for (i = 0; i < NELEMS(license); i++) {
		fprintf(f, "%s\n", license[i]);
	}
}

static void print_version(FILE *f)
{
	const struct target *p;

	fputs(PACKAGE_STRING, f);
	fputs("\n", f);
	fputs("Targets:", f);
	for (p = first_target(); p != NULL; p = next_target()) {
		fprintf(f, " %s", p->id);
	}
	fputs("\n", f);
}

static void print_help(const char *argv0)
{
	static const char *help =
"Usage: %s [OPTION]... ASM_FILE [OBJ_FILE [LST_FILE]]\n"
"\n"
"Assemble ASM_FILE into OBJ_FILE and generate the listing LST_FILE.\n"
"If not specified, OBJ_FILE is ASM_FILE with the extension changed to .obj.\n"
"If not specified, LST_FILE is ASM_FILE with the extension changed to .lst.\n"
"\n"
"Options:\n"
"  -h, --help           Display this help and exit.\n"
"  -V, --verbose        be chatty.\n"
"  -v, --version        Output version information and exit.\n"
"  -l, --license        Display the license text and exit.\n"
"  -d, --define=MACRO   Define a macro.\n"
"  -f, --fill=n         Fill memory with value n.\n"
"  -q, --quiet          Do not generate the listing file.\n"
"  -x, --extended       Enable extended instruction syntax.\n"
"  -u, --undocumented   Enable undocumented instructions.\n"
"  -t, --target=NAME    Select the target micro. z80 is the default.\n" 
"  -e, --list-targets   List the targets supported.\n" 
"\n"
"Examples:\n"
"  " PACKAGE " p.asm                     Assemble p.asm into p.obj\n"
"  " PACKAGE " p.asm p.bin               Assemble p.asm into p.bin\n"
"  " PACKAGE " -d\"MUL(a,b) (a*b)\" p.asm  Define the macro MUL and assemble p.asm\n"
"\n"
"Report bugs to: <" PACKAGE_BUGREPORT ">.\n"
"Home page: <" PACKAGE_URL ">.\n";

	printf(help, argv0);
}

/*
 * Get the filename part of fname (that is, for ../../fname.abc, get
 * fname.abc).
 * Then substitute the extension .abd by .ext or append .ext.
 */
static char *mkfname(const char *fname, const char *ext)
{
	size_t alen, elen;
	const char *p, *q;
	char *s;

	alen = strlen(fname);
	elen = strlen(ext);

	/* Find start of filename in path string */
	p = fname + alen;
	while (p > fname && *p != '/' && *p != '\\')
		p--;

	if (*p == '/' || *p == '\\')
		p++;
	
	/* Find the extension */
	q = fname + alen;
	while (q > p && *q != '.')
		q--;

	if (*q != '.')
		q = fname + alen;

	s = emalloc((q - p) + 1 + elen + 1);
	if (q > p)
		memmove(s, p, (q - p));
	s[q - p] = '\0';
	strcat(s, ".");
	strcat(s, ext);
	return s;
}

static void parse_fill_byte(const char *optarg)
{
	int hi, lo;

	if (strlen(optarg) != 2)
		goto error;

	if ((hi = hexval(optarg[0])) < 0)
		goto error;
	if ((lo = hexval(optarg[1])) < 0)
		goto error;

	s_mem_fillval = hi * 16 + lo;
	return;

error:	eprogname();
	fprintf(stderr, _("invalid command line fill value (%s)\n"), optarg);
	eprogname();
	fprintf(stderr, " ");
	fprintf(stderr, _("Please, use two hexadecimal digits.\n"));
	exit(EXIT_FAILURE);
}

static void parse_target_id(const char *optarg)
{
	const struct target *p;

	p = find_target(optarg);
	if (p == NULL) {
		eprogname();
		fprintf(stderr, _("invalid target '%s'\n"), optarg);
		exit(EXIT_FAILURE);
	} else {
		s_target_id = p->id;
	}
}

static void list_targets(FILE *f)
{	
	const struct target *p;

	for (p = first_target(); p != NULL; p = next_target()) {
		fprintf(f, "%-14s%s\n", p->id, p->descr);
	}
}

int main(int argc, char *argv[])
{
	int c;
	struct ngetopt ngo;

	static struct ngetopt_opt ops[] = {
		{ "define", 1, 'd' },
		{ "extended", 0, 'x' },
		{ "list-targets", 0, 'e' },
		{ "fill", 1, 'f' },
		{ "help", 0, 'h' },
		{ "license", 0, 'l' },
		{ "quiet", 0, 'q' },
		{ "target", 1, 't' },
		{ "undocumented", 0, 'u' },
		{ "version", 0, 'v' },
		{ "print-table", 1, 0 },
		{ "print-delta", 1, 0 },
		{ "verbose", 0, 'V' },
		{ NULL, 0, 0 },
	};

	ngetopt_init(&ngo, argc, argv, ops);
	do {
		c = ngetopt_next(&ngo);
		switch (c) {
		case 'V':
			verbose++;
			break;
		case 'v':
			print_version(stdout);
			exit(EXIT_SUCCESS);
		case 'h':
			print_help(argv[0]);
			exit(EXIT_SUCCESS);
		case 'l':
			print_copyright(stdout);
			fputs("\n", stdout);
			print_license(stdout);
			exit(EXIT_SUCCESS);
		case 't':
			parse_target_id(ngo.optarg);
			break;
		case 'e':
			list_targets(stdout);
			exit(EXIT_SUCCESS);
			break;
		case 'd':
			predefine(ngo.optarg);
			break;
		case 'f':
			parse_fill_byte(ngo.optarg);
			break;
		case 'q':
			s_listing = 0;
			break;
		case 'x':
			s_extended_op = 1;
			break;
		case 'u':
			s_undocumented_op = 1;
			break;
		case '?':
			eprint(_("unrecognized option %s\n"),
				ngo.optarg);
			exit(EXIT_FAILURE);
		case ':':
			eprint(_("%s needs an argument\n"),
				ngo.optarg);
			exit(EXIT_FAILURE);
		case ';':
			eprint(_("%s does not allow for arguments\n"),
				ngo.optarg);
			exit(EXIT_FAILURE);
		case 0:
			if (strcmp(ngo.optstr, "print-table") == 0) {
				print_table(stdout, ngo.optarg);
				exit(EXIT_SUCCESS);
			}
		}
	} while (c != -1);

	if (argc == ngo.optind) {
		eprint(_("wrong number of arguments\n"));
		exit(EXIT_FAILURE);
	}

	s_asmfname = argv[ngo.optind];

	if (argc - ngo.optind > 1)
		s_objfname = argv[ngo.optind + 1];
	else
		s_objfname = mkfname(s_asmfname, "obj");

	if (argc - ngo.optind > 2)
		s_lstfname = argv[ngo.optind + 2];
	else
		s_lstfname = mkfname(s_asmfname, "lst");

	uz80as();
	return 0;
}
