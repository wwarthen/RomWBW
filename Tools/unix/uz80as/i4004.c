/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Intel 4004.
 * Intel 4040.
 * ===========================================================================
 */

/* Intel 4004. Max. memory 4K (12 bit addresses).
 * Intel 4040. Max. memory 8K (13 bit addresses).
 */

#include "pp.h"
#include "err.h"
#include "options.h"
#include "uz80as.h"
#include <stddef.h>

/* pat:
 *	a: expr
 *	b: ADD,SUB,LD,XCH,BBL,LDM 
 *	c: WRM,WMP,WRR,WPM,WR0,WR1,WR2,WR3
 *	   SBM,RDM,RDR,ADM,RD0,RD1,RD2,RD3
 * 	d: CLB,CLC,IAC,CMC,CMA,RAL,RAR,TCC,
 * 	   DAC,TCS,STC,DAA,KBP,DCL,
 *	e: HLT,BBS,LCR,OR4,OR5,AN6,AN7
 *	   DB0,DB1,SB0,SB1,EIN,DIN,RPM
 *	f: 0P,1P,2P,3P,4P,5P,6P,7P
 *
 * gen:
 * 	.: output lastbyte
 * 	b: (op << 3) | lastbyte
 * 	c: op | lastbyte
 * 	d: lastbyte = op as 8 bit value
 * 	e: output op as word (no '.' should follow)
 * 	f: op | lastbyte, op in [0-15]
 * 	g: op | lastbyte, op in [0,2,4,6,8,10,12,14]
 * 	h: output (op & 0xff0000 >> 8) | lastbyte;
 * 	   then ouput op as 8 bit value
 * 	i: (op << 4) | lastbyte
 * 	j: (op << 1) | lastbyte
 */

static const struct matchtab s_matchtab_i4004[] = {
	{ "NOP", "00.", 1, 0 },
	{ "JCN a,a", "10f0.d1.", 1, 0, "b4e8" },
	{ "FIM f,a", "20j0.d1.", 1, 0, "e8" },
	{ "FIM a,a", "20g0.d1.", 1, 0, "ppe8" },
	{ "SRC f", "21j0.", 1, 0 },
	{ "SRC a", "21g0.", 1, 0, "pp" },
	{ "FIN f", "30j0.", 1, 0 },
	{ "FIN a", "30g0.", 1, 0, "pp" },
	{ "JIN f", "31j0.", 1, 0 },
	{ "JIN a", "31g0.", 1, 0, "pp" },
	{ "JUN a", "40h0", 1, 0 },
	{ "JMS a", "50h0", 1, 0 },
	{ "INC a", "60f0.", 1, 0, "b4" },
	{ "ISZ a,a", "70f0.d1.", 1, 0, "b4e8" },
	{ "b a", "80i0f1.", 1, 0, "b4" },
	{ "c", "E0c0.", 1, 0 },
	{ "d", "F0c0.", 1, 0 },
	{ "e", "00c0.", 2, 0 },
	{ NULL, NULL },
};

static const char *const bval[] = {
"ADD", "SUB", "LD", "XCH", "BBL", "LDM",
NULL };

static const char *const cval[] = {
"WRM", "WMP", "WRR", "WPM", "WR0", "WR1", "WR2", "WR3",
"SBM", "RDM", "RDR", "ADM", "RD0", "RD1", "RD2", "RD3",
NULL };

static const char *const dval[] = {
"CLB", "CLC", "IAC", "CMC", "CMA", "RAL", "RAR", "TCC",
"DAC", "TCS", "STC", "DAA", "KBP", "DCL",
NULL };

static const char *const eval[] = {
"", "HLT", "BBS", "LCR", "OR4", "OR5", "AN6", "AN7",
"DB0", "DB1", "SB0", "SB1", "EIN", "DIN", "RPM",
NULL };

static const char *const fval[] = {
"0P", "1P", "2P", "3P", "4P", "5P", "6P", "7P",
NULL };

static const char *const *const valtab[] = { 
	bval, cval, dval, eval, fval
};

static int match_i4004(char c, const char *p, const char **q)
{
	int v;

	if (c <= 'f') {
		v = mreg(p, valtab[(int) (c - 'b')], q);
	} else {
		v = -1;
	}

	return v;
}

static int gen_i4004(int *eb, char p, const int *vs, int i, int savepc)
{
	int b;
       
	b = *eb;
	switch (p) {
	case 'f': if (s_pass > 0 && (vs[i] < 0 || vs[i] > 15)) {
			  eprint(_("argument (%d) must be in range [0-15]\n"),
				vs[i]);
			  eprcol(s_pline, s_pline_ep);
			  newerr();
		  }
	          b |= vs[i];
		  break;
	case 'g': if (s_pass > 0 && (vs[i] < 0 || vs[i] > 14 || (vs[i] & 1))) {
			  eprint(
		  _("argument (%d) must be an even number in range [0-14]\n"),
				vs[i]);
			  eprcol(s_pline, s_pline_ep);
			  newerr();
		  }
	          b |= vs[i];
		  break;
	case 'h': b |= ((vs[i] >> 8) & 0x0f);
		  genb(b, s_pline_ep);
		  genb(vs[i], s_pline_ep);
		  break;
	case 'i': b |= (vs[i] << 4); break;
	case 'j': b |= (vs[i] << 1); break;
	default:
		  return -1;
	}

	*eb = b;
	return 0;
}

static int s_pat_char = 'b';
static int s_pat_index;

static void pat_char_rewind_i4004(int c)
{
	s_pat_char = c;
	s_pat_index = 0;
};

static const char *pat_next_str_i4004(void)
{
	const char *s;

	if (s_pat_char >= 'b' && s_pat_char <= 'f') {
		s = valtab[(int) (s_pat_char - 'b')][s_pat_index];
		if (s != NULL) {
			s_pat_index++;
		}
	} else {
		s = NULL;
	}

	return s;
};

const struct target s_target_i4004 = {
	.id = "i4004",
	.descr = "Intel 4004",
	.matcht = s_matchtab_i4004,
	.matchf = match_i4004,
	.genf = gen_i4004,
	.pat_char_rewind = pat_char_rewind_i4004,
	.pat_next_str = pat_next_str_i4004,
	.mask = 1
};

const struct target s_target_i4040 = {
	.id = "i4040",
	.descr = "Intel 4040",
	.matcht = s_matchtab_i4004,
	.matchf = match_i4004,
	.genf = gen_i4004,
	.pat_char_rewind = pat_char_rewind_i4004,
	.pat_next_str = pat_next_str_i4004,
	.mask = 3
};

