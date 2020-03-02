#include "prtable.h"
#include "err.h"
#include "targets.h"
#include "uz80as.h"

#ifndef STDLIB_H
#include <stdlib.h>
#endif

#ifndef CTYPE_H
#include <ctype.h>
#endif

#ifndef STRING_H
#include <string.h>
#endif

enum { STRSZ = 32 };

struct itext {
	struct itext *next;
	int undoc;
	char str[STRSZ];
};

struct ilist {
	struct itext *head;
	int nelems;
};

struct itable {
	struct itext **table;
	int nelems;
};

static char s_buf[STRSZ];

static void nomem(const char *str)
{
	eprogname();
	fprintf(stderr, _("not enough memory (%s)\n"), str);
	exit(EXIT_FAILURE);
}

static int compare(const void *pa, const void *pb)
{
	const struct itext * const *ia;
	const struct itext * const *ib;

	ia = (const struct itext * const *) pa;
	ib = (const struct itext * const *) pb;
	return strcmp((*ia)->str, (*ib)->str);
}

/* 
 * Returns a new allocated itable of pointers that point to each element in the
 * list ilist, alphabetically sorted.
 */
static struct itable *sort_list(struct ilist *ilist)
{
	int n;
	struct itable *itable;
	struct itext *p;

	if ((itable = calloc(1, sizeof(*itable))) == NULL) {
		return NULL;
	}
	itable->nelems = 0;

	if (ilist->nelems == 0) {
		return itable;
	}

	itable->table = malloc(ilist->nelems * sizeof(*itable->table));
	if (itable->table == NULL) {
		free(itable);
		return NULL;
	}

	for (n = 0, p = ilist->head;
	     p != NULL && n < ilist->nelems;
	     p = p->next, n++)
       	{
		itable->table[n] = p;
	}
	itable->nelems = n;

	qsort(itable->table, itable->nelems, sizeof(*itable->table), compare);
	return itable;
}

static void print_itable(struct itable *itable, FILE *f)
{
	int i, col;
	struct itext *p;

	if (itable == NULL) {
		return;
	}

	fputs("@multitable @columnfractions .25 .25 .25 .25\n", f);
	col = 0;
	for (i = 0; i < itable->nelems; i++) {
		p = itable->table[i];
		if (col == 0) {
			fputs("@item ", f);
		} else {
			fputs("@tab ", f);
		}
		if (p->undoc) {
			fputs("* ", f);
		}
		fprintf(f, "%s\n", p->str);
		col++;
		if (col >= 4) {
			col = 0;
		}
	}
	fputs("@end multitable\n", f);
}

#if 0
static void print_ilist(struct ilist *ilist, FILE *f)
{
	int col;
	struct itext *p;

	if (ilist == NULL) {
		return;
	}

	fputs("@multitable @columnfractions .25 .25 .25 .25\n", f);
	col = 0;
	for (p = ilist->head; p != NULL; p = p->next) {
		if (col == 0) {
			fputs("@item ", f);
		} else {
			fputs("@tab ", f);
		}
		if (p->undoc) {
			fputs("* ", f);
		}
		fprintf(f, "%s\n", p->str);
		col++;
		if (col >= 4) {
			col = 0;
		}
	}
	fputs("@end multitable\n", f);
}
#endif

static void bufset(int i, char c)
{
	if (i >= STRSZ) {
		eprogname();
		fputs(_("prtable: please, increase s_buf size\n"), stderr);
		exit(EXIT_FAILURE);
	} else {
		s_buf[i] = c;
	}
}

static void gen_inst2(struct ilist *ilist, char *instr, int undoc)
{
	struct itext *p;

	if ((p = malloc(sizeof(*p))) == NULL) {
		nomem("gen_inst2");
	}

	snprintf(p->str, STRSZ, "%s", instr);
	p->undoc = undoc;
	p->next = ilist->head;
	ilist->head = p;
	ilist->nelems++;
}

static void gen_inst(struct ilist *ilist, const struct target *t,
		     unsigned char undoc, const char *p, size_t bufi,
		     const char *pr)
{
	size_t bufk;
	const char *s;

	while (*p) {
		if (!islower(*p)) {
			if (*p == '@') {
				bufset(bufi++, '@');
			}
			bufset(bufi++, *p);
			p++;
		} else if (*p == 'a') {
			if (pr == NULL) {
				bufset(bufi++, 'e');
			} else if (pr[0] && pr[1]) {
				if (pr[0] == pr[1]) {
					bufset(bufi++, pr[0]);
					pr += 2;
				} else if (isdigit(pr[1])) {
					bufset(bufi++, *pr);
					pr++;
					while (isdigit(*pr)) {
						bufset(bufi++, *pr);
						pr++;
					}
				} else {
					bufset(bufi++, pr[0]);
					bufset(bufi++, pr[1]);
					pr += 2;
				}
			} else {
				bufset(bufi++, 'e');
			}
			p++;
		} else {
			break;
		}
	}

	if (*p == '\0') {
		bufset(bufi, '\0');
		gen_inst2(ilist, s_buf, t->mask & undoc);
	} else {
		t->pat_char_rewind(*p);
		while ((s = t->pat_next_str()) != NULL) {
			if (s[0] != '\0') {
				bufset(bufi, '\0');
				bufk = bufi;
				while (*s != '\0') {
					bufset(bufk++, *s);
					s++;
				}
				bufset(bufk, '\0');
				gen_inst(ilist, t, undoc, p + 1, bufk, pr);
			}
		}
	}
}

/* Generate a list of instructions. */
static struct ilist *gen_list(const struct target *t, unsigned char mask2,
                              int delta)
{
	int i, pr;
	const struct matchtab *mt;
	struct ilist *ilist;

	if ((ilist = calloc(1, sizeof(*ilist))) == NULL) {
		return NULL;
	}

	i = 0;
	mt = t->matcht;
	while (mt[i].pat != NULL) {
		pr = 0;
		if (t->mask == 1 && (mt[i].mask & 1)) {
			pr = 1;
		} else if (delta) {
			if ((mt[i].mask & t->mask) &&
				!(mt[i].mask & mask2))
			{
				pr = 1;
			}
		} else if (t->mask & mt[i].mask) {
			pr = 1;
		}
		if (pr) { 
			gen_inst(ilist, t, mt[i].undoc, mt[i].pat,
				 0, mt[i].pr);
		}
		i++;
	}

	return ilist;
}

/* 
 * Prints the instruction set of a target or if target_id is "target2,target1"
 * prints the instructions in target2 not in target1.
 */
void print_table(FILE *f, const char *target_id)
{
	struct ilist *ilist;
	struct itable *itable;
	const struct target *t, *t2;
	char target1[STRSZ];
	const char *target2;
	unsigned char mask2;
	int delta;

	/* check if we have "target" or "target,target" as arguments */
	if ((target2 = strchr(target_id, ',')) != NULL) {
		delta = 1;
		snprintf(target1, sizeof(target1), "%s", target_id);
		target1[target2 - target_id] = '\0';
		target2++;
	} else {
		delta = 0;
		snprintf(target1, sizeof(target1), "%s", target_id);
		target2 = NULL;
	}

	t = find_target(target1);
	if (t == NULL) {
		eprogname();
		fprintf(stderr, _("invalid target '%s'\n"), target1);
		exit(EXIT_FAILURE);
	}

	if (target2) {
		t2 = find_target(target2);
		if (t2 == NULL) {
			eprogname();
			fprintf(stderr, _("invalid target '%s'\n"), target2);
			exit(EXIT_FAILURE);
		}
		if (t->matcht != t2->matcht) {
			eprogname();
			fprintf(stderr, _("unrelated targets %s,%s\n"),
				target1, target2);
			exit(EXIT_FAILURE);
		}
		mask2 = t2->mask;
	} else {
		mask2 = 1;
	}

	if ((ilist = gen_list(t, mask2, delta)) == NULL) {
		nomem("gen_list");
	}

	if ((itable = sort_list(ilist)) == NULL) {
		nomem("sort_list");
	}

	print_itable(itable, f);

	/* We don't free ilist nor itable for now, since this is called
	 * from main and then the program terminated.
	 */
}

