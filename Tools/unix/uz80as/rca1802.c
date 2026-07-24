/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * RCA 1802.
 * ===========================================================================
 */

#include "pp.h"
#include "err.h"
#include "options.h"
#include "uz80as.h"
#include <stddef.h>

/* pat:
 *	a: expr
 *
 * gen:
 * 	.: output lastbyte
 * 	b: (op << 3) | lastbyte
 * 	c: op | lastbyte
 * 	d: lastbyte = op as 8 bit value
 * 	e: output op as word (no '.' should follow)
 * 	f: op | lastbyte (op in [0-15])
 * 	g: op | lastbyte (op in [1-7])
 * 	h: op | lastbyte (op in [1-15])
 * 	i: *
 * 	j: output op as big endian word (no '.' should follow)
 */

static const struct matchtab s_matchtab_rca1802[] = {
	{ "IDL", "00.", 1, 0 },
	{ "LDN a", "00h0.", 1, 0, "mm" },
	{ "INC a", "10f0.", 1, 0, "b4" },
	{ "DEC a", "20f0.", 1, 0, "b4" },
	{ "BR a", "30.d0.", 1, 0, "e8" },
	{ "BQ a", "31.d0.", 1, 0, "e8" },
	{ "BZ a", "32.d0.", 1, 0, "e8" },
	{ "BDF a", "33.d0.", 1, 0, "e8" },
	{ "BGE a", "33.d0.", 1, 0, "e8" },
	{ "BPZ a", "33.d0.", 1, 0, "e8" },
	{ "B1 a", "34.d0.", 1, 0, "e8" },
	{ "B2 a", "35.d0.", 1, 0, "e8" },
	{ "B3 a", "36.d0.", 1, 0, "e8" },
	{ "B4 a", "37.d0.", 1, 0, "e8" },
	{ "NBR a", "38.d0.", 1, 0, "e8" },
	{ "SKP", "38.", 1, 0 },
	{ "BNQ a", "39.d0.", 1, 0, "e8" },
	{ "BNZ a", "3A.d0.", 1, 0, "e8" },
	{ "BL a", "3B.d0.", 1, 0, "e8" },
	{ "BM a", "3B.d0.", 1, 0, "e8" },
	{ "BNF a", "3B.d0.", 1, 0, "e8" },
	{ "BN1 a", "3C.d0.", 1, 0, "e8" },
	{ "BN2 a", "3D.d0.", 1, 0, "e8" },
	{ "BN3 a", "3E.d0.", 1, 0, "e8" },
	{ "BN4 a", "3F.d0.", 1, 0, "e8" },
	{ "LDA a", "40f0.", 1, 0, "b4" },
	{ "STR a", "50f0.", 1, 0, "b4" },
	{ "IRX", "60.", 1, 0 },
	{ "OUT a", "60g0.", 1, 0, "pp" },
	{ "INP a", "68g0.", 1, 0, "pp" },
	{ "RET", "70.", 1, 0 },
	{ "DIS", "71.", 1, 0 },
	{ "LDXA", "72.", 1, 0 },
	{ "STXD", "73.", 1, 0 },
	{ "ADC", "74.", 1, 0 },
	{ "SDB", "75.", 1, 0 },
	{ "RSHR", "76.", 1, 0 },
	{ "SHRC", "76.", 1, 0 },
	{ "SMB", "77.", 1, 0 },
	{ "SAV", "78.", 1, 0 },
	{ "MARK", "79.", 1, 0 },
	{ "REQ", "7A.", 1, 0 },
	{ "SEQ", "7B.", 1, 0 },
	{ "ADCI a", "7C.d0.", 1, 0, "e8" },
	{ "SDBI a", "7D.d0.", 1, 0, "e8" },
	{ "RSHL", "7E.", 1, 0 },
	{ "SHLC", "7E.", 1, 0 },
	{ "SMBI a", "7F.d0.", 1, 0, "e8" },
	{ "GLO a", "80f0.", 1, 0, "b4" },
	{ "GHI a", "90f0.", 1, 0, "b4" },
	{ "PLO a", "A0f0.", 1, 0, "b4" },
	{ "PHI a", "B0f0.", 1, 0, "b4" },
	{ "LBR a", "C0.j0", 1, 0 },
	{ "LBQ a", "C1.j0", 1, 0 },
	{ "LBZ a", "C2.j0", 1, 0 },
	{ "LBDF a", "C3.j0", 1, 0 },
	{ "NOP", "C4.", 1, 0 },
	{ "LSNQ", "C5.", 1, 0 },
	{ "LSNZ", "C6.", 1, 0 },
	{ "LSNF", "C7.", 1, 0 },
	{ "LSKP", "C8.", 1, 0 },
	{ "NLBR a", "C8.j0", 1, 0 },
	{ "LBNQ a", "C9.j0", 1, 0 },
	{ "LBNZ a", "CA.j0", 1, 0 },
	{ "LBNF a", "CB.j0", 1, 0 },
	{ "LSIE", "CC.", 1, 0 },
	{ "LSQ", "CD.", 1, 0 },
	{ "LSZ", "CE.", 1, 0 },
	{ "LSDF", "CF.", 1, 0 },
	{ "SEP a", "D0f0.", 1, 0, "b4" },
	{ "SEX a", "E0f0.", 1, 0, "b4" },
	{ "LDX", "F0.", 1, 0 },
	{ "OR", "F1.", 1, 0 },
	{ "AND", "F2.", 1, 0 },
	{ "XOR", "F3.", 1, 0 },
	{ "ADD", "F4.", 1, 0 },
	{ "SD", "F5.", 1, 0 },
	{ "SHR", "F6.", 1, 0 },
	{ "SM", "F7.", 1, 0 },
	{ "LDI a", "F8.d0.", 1, 0, "e8" },
	{ "ORI a", "F9.d0.", 1, 0, "e8" },
	{ "ANI a", "FA.d0.", 1, 0, "e8" },
	{ "XRI a", "FB.d0.", 1, 0, "e8" },
	{ "ADI a", "FC.d0.", 1, 0, "e8" },
	{ "SDI a", "FD.d0.", 1, 0, "e8" },
	{ "SHL", "FE.", 1, 0 },
	{ "SMI a", "FF.d0.", 1, 0, "e8" },
	{ NULL, NULL },
};

static int match_rca1802(char c, const char *p, const char **q)
{
	return -1;
}

static int gen_rca1802(int *eb, char p, const int *vs, int i, int savepc)
{
	int b;
       
	b = *eb;
	switch (p) {
	case 'f': if (s_pass > 0 && (vs[i] & ~15) != 0) {
			  eprint(_("argument (%d) must be in range [0-15]\n"),
				vs[i]);
			  eprcol(s_pline, s_pline_ep);
			  newerr();
		  }
		  b |= vs[i];
		  break;
	case 'g': if (s_pass > 0 && (vs[i] < 1 || vs[i] > 7)) {
			  eprint(_("argument (%d) must be in range [1-7]\n"),
				vs[i]);
			  eprcol(s_pline, s_pline_ep);
			  newerr();
		  }
		  b |= vs[i];
		  break;
	case 'h': if (s_pass > 0 && (vs[i] < 1 || vs[i] > 15)) {
			  eprint(_("argument (%d) must be in range [1-15]\n"),
				vs[i]);
			  eprcol(s_pline, s_pline_ep);
			  newerr();
		  }
		  b |= vs[i];
		  break;
	case 'j': genb(vs[i] >> 8, s_pline_ep);
		  genb(vs[i], s_pline_ep);
		  break;
	default:
		  return -1;
	}

	*eb = b;
	return 0;
}

static int s_pat_char = 'b';
static int s_pat_index;

static void pat_char_rewind_rca1802(int c)
{
	s_pat_char = c;
	s_pat_index = 0;
};

static const char *pat_next_str_rca1802(void)
{
	return NULL;
};

const struct target s_target_rca1802 = {
	.id = "rca1802",
	.descr = "RCA 1802",
	.matcht = s_matchtab_rca1802,
	.matchf = match_rca1802,
	.genf = gen_rca1802,
	.pat_char_rewind = pat_char_rewind_rca1802,
	.pat_next_str = pat_next_str_rca1802,
	.mask = 1
};
