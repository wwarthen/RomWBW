/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Handling of command line options, similar to getopt.
 * ===========================================================================
 */

/*
 * Changes:
 *
 * - Jul 22 2018: long options without short option character recognized.
 *
 */

#include "ngetopt.h"

#ifndef STRING_H
#include <string.h>
#endif

static int find_short_opt(int val, struct ngetopt_opt *ops)
{
	int i;

	i = 0;
	while (ops[i].name != NULL) {
		if (ops[i].val > 0 && ops[i].val == val)
			return i;
		i++;
	}

	return -1;
}

static int find_long_opt(char *str, struct ngetopt_opt *ops)
{
	int i;
	const char *p, *q;

	i = 0;
	while (ops[i].name != NULL) {
		p = ops[i].name;
		q = str;
		while (*p != '\0' && *p == *q) {
			p++;
			q++;
		}
		if (*p == '\0' && (*q == '\0' || *q == '=')) {
			return i;
		}
		i++;
	}

	return -1;
}

void ngetopt_init(struct ngetopt *p, int argc, char *const *argv,
	struct ngetopt_opt *ops)
{
	p->argc = argc;
	p->argv = argv;
	p->ops = ops;
	p->optind = 1;
	p->subind = 0;
	strcpy(p->str, "-X");
}

static int get_short_opt(struct ngetopt *p)
{
	int i;
	char *opt;

	opt = p->argv[p->optind];
	i = find_short_opt(opt[p->subind], p->ops);
	if (i < 0) {
		/* unrecognized option */
		p->str[1] = (char) opt[p->subind];
		p->optarg = p->str;
		p->subind++;
		return '?';
	}

	if (!p->ops[i].has_arg) {
		/* it's ok */
		p->subind++;
		return p->ops[i].val;
	}

	/* needs an argument */
	if (opt[p->subind + 1] != '\0') {
		/* the argument is the suffix */
		p->optarg = &opt[p->subind + 1];
		p->subind = 0;
		p->optind++;
		return p->ops[i].val;
	}

	/* the argument is the next token */
	p->optind++;
	p->subind = 0;
	if (p->optind < p->argc) {
		p->optarg = p->argv[p->optind];
		p->optind++;
		return p->ops[i].val;
	}

	/* ups, argument missing */
	p->str[1] = (char) p->ops[i].val;
	p->optarg = p->str;
	return ':';
}

static int get_opt(struct ngetopt *p)
{
	int i;
	char *opt, *optnext;

	/* all arguments consumed */
	if (p->optind >= p->argc)
		return -1;

	opt = p->argv[p->optind];
	if (opt[0] != '-') {
		/* non option */
		return -1;
	}

	/* - */
	if (opt[1] == '\0') {
		/* stdin */
		return -1;
	}

	if (opt[1] != '-') {
		/* -xxxxx */
		p->subind = 1;
		return get_short_opt(p);
	}
	
	/* -- */
	if (opt[2] == '\0') {
		/* found "--" */
		p->optind++;
		return -1;
	}

	/* long option */
	i = find_long_opt(&opt[2], p->ops);
	if (i < 0) {
		/* not found */
		p->optind++;
		p->optarg = opt;
		while (*opt != '\0' && *opt != '=') {
			opt++;
		}
		*opt = '\0';
		return '?';
	}

	/* found, go to end of option */
	optnext = opt + 2 + strlen(p->ops[i].name);

	if (*optnext == '\0' && !p->ops[i].has_arg) {
		/* doesn't need arguments */
		p->optind++;
		p->optstr = opt + 2;
		return p->ops[i].val;
	}

	if (*optnext == '=' && !p->ops[i].has_arg) {
		/* does not need arguments but argument supplied */
		*optnext = '\0';
		p->optarg = opt;
		return ';';
	}

	/* the argument is the next token */
	if (*optnext == '\0') {
		p->optind++;
		if (p->optind < p->argc) {
			p->optstr = opt + 2;
			p->optarg = p->argv[p->optind];
			p->optind++;
			return p->ops[i].val;
		}

		/* ups, argument missing */
		p->optarg = opt;
		p->optind++;
		return ':';
	}

	/* *optnext == '=' */
	*optnext = '\0';
	p->optstr = opt + 2;
	p->optarg = optnext + 1;
	p->optind++;
	return p->ops[i].val;
}

/*
 * If ok:
 *
 * 	- For a long option with a zero value single character option, 0 is
 * 	returned, optstr is the string of the long option (without '-' or '--')
 * 	and optarg is the option argument or NULL.
 *
 * 	- For anything else the single option character is returned and optarg
 * 	is the option argument or NULL.
 *
 * If the option is not recognized, '?' is returned, and optarg is the
 * literal string of the option not recognized (already with '-' or '--'
 * prefixed).
 *
 * If the option is recognized but the argument is missing, ':' is
 * returned and optarg is the option as supplied (with '-' or '--' prefixed).
 *
 * If the option is recognized and it is a long option followed by '=', but the
 * option does not take arguments, ';' is returned and optarg is the option
 * (with '-' or '--' prefixed).
 *
 * -1 is returned if no more options.
 */
int ngetopt_next(struct ngetopt *p)
{
	if (p->subind == 0)
		return get_opt(p);

	/* p->subind > 0 */
	if (p->argv[p->optind][p->subind] != '\0')
		return get_short_opt(p);

	/* no more options in this list of short options */
	p->subind = 0;
	p->optind++;
	return get_opt(p);
}
