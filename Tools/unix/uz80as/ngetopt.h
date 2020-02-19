/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Handling of command line options, similar to getopt.
 * ===========================================================================
 */

#ifndef NGETOPT_H
#define NGETOPT_H

/*
 * Changelog:
 *
 * - Jul 21 2018: long options without short option character recognized.
 *
 */

struct ngetopt_opt {
	const char *name;
	int has_arg;
	int val;
};

struct ngetopt {
	char *optstr;
	char *optarg;
	/* private */
	int optind;
	int argc;
	char *const *argv;
	struct ngetopt_opt *ops;
	int subind;
	char str[3];
};

void ngetopt_init(struct ngetopt *p, int argc, char *const *argv,
	struct ngetopt_opt *ops);
int ngetopt_next(struct ngetopt *p);

#endif
