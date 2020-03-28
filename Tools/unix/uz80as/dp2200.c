/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Datapoint 2200.
 * ===========================================================================
 */

/*
 * Datapoint 2200 Version I, 2K to 8K mem (program counter 13 bits).
 * Datapoint 2200 Version II, 2K to 16K mem (protram counter 14 bits).
 */

#include "pp.h"
#include "err.h"
#include "options.h"
#include "uz80as.h"
#include <stddef.h>

/* pat:
 *	a: expr
 *	b: ADA,ADB,ADC,ADD,ADH,ADL,ADM,
 *	   ACA,ACB,ACC,ACD,ACH,ACL,ACM,
 *	   SUA,SUB,SUC,SUD,SUH,SUL,SUM,
 *	   SBA,SBB,SBC,SBD,SBH,SBL,SBM,
 *	   NDA,NDB,NDC,NDD,NDH,NDL,NDM,
 *	   XRA,XRB,XRC,XRD,XRH,XRL,XRM,
 *	   ORA,ORB,ORC,ORD,ORH,ORL,ORM,
 *	   CPA,CPB,CPC,CPD,CPH,CPL,CPM
 *	c: NOP,LAB,LAC,LAD,LAE,LAH,LAL,LAM,
 *	   LBA,LBC,LBD,LBE,LBH,LBL,LBM,
 *	   LCA,LCB,LCD,LCE,LCH,LCL,LCM,
 *	   LDA,LDB,LDC,LDE,LDH,LDL,LDM,
 *	   LEA,LEB,LEC,LED,LEH,LEL,LEM,
 *	   LHA,LHB,LHC,LHD,LHE,LHL,LHM,
 *	   LLA,LLB,LLC,LLD,LLE,LLH,LLM,
 *	   LMA,LMB,LMC,LMD,LME,LMH,LML,HALT
 *	d: ADR,STATUS,DATA,WRITE,COM1,COM2,COM3,COM4
 *	   BEEP,CLICK,DECK1,DECK2,
 *	   RBK,WBK,BSP,SF,SB,REWND,TSTOP 
 *	e: RFC,RFS,RTC,RTS,RFZ,RFP,RTZ,RTP
 *	f: JFC,JFZ,JFS,JFP,JTC,JTZ,JTS,JTP
 *	g: AD,SU,ND,OR,AC,SB,XR,CP
 *	h: LA,LB,LC,LD,LE,LH,LL
 *	i: CFC,CFZ,CFS,CFP,CTC,CTZ,CTS,CTP
 *
 * gen:
 * 	.: output lastbyte
 * 	b: (op << 3) | lastbyte
 * 	c: op | lastbyte
 * 	d: lastbyte = op as 8 bit value
 * 	e: output op as word (no '.' should follow)
 * 	f: (op << 1) + lastbyte
 * 	g: (op << 4) | lastbyte
 */

const struct matchtab s_matchtab_dp2200[] = {
	{ "SLC", "02.", 3, 0 },
	{ "SRC", "0A.", 3, 0 },
	{ "RETURN", "07.", 3, 0 },
	{ "INPUT", "41.", 3, 0 },
	{ "b", "80c0.", 3, 0 },
	{ "c", "C0c0.", 3, 0 },
	{ "EX d", "51f0.", 3, 0 },
	{ "e", "03b0.", 3, 0 },
	{ "g a", "04b0.d1.", 3, 0, "e8" },
	{ "h a", "06b0.d1.", 3, 0, "e8"},
	{ "f a", "40b0.e1", 3, 0 },
	{ "i a", "42b0.e1", 3, 0 },
	{ "JMP a", "44.e0", 3, 0 },
	{ "CALL a", "46.e0", 3, 0 },
	/* version II */
	{ "BETA", "10.", 2, 0 },
	{ "DI", "20.", 2, 0 },
	{ "POP", "30.", 2, 0 },
	{ "ALPHA", "18.", 2, 0 },
	{ "EI", "28.", 2, 0 },
	{ "PUSH", "38.", 2, 0 },
	{ NULL, NULL },
};

static const char *const bval[] = {
"ADA", "ADB", "ADC", "ADD", "ADE", "ADH", "ADL", "ADM",
"ACA", "ACB", "ACC", "ACD", "ACE", "ACH", "ACL", "ACM",
"SUA", "SUB", "SUC", "SUD", "SUE", "SUH", "SUL", "SUM",
"SBA", "SBB", "SBC", "SBD", "SBE", "SBH", "SBL", "SBM",
"NDA", "NDB", "NDC", "NDD", "NDE", "NDH", "NDL", "NDM",
"XRA", "XRB", "XRC", "XRD", "XRE", "XRH", "XRL", "XRM",
"ORA", "ORB", "ORC", "ORD", "ORE", "ORH", "ORL", "ORM",
"CPA", "CPB", "CPC", "CPD", "CPE", "CPH", "CPL", "CPM",
NULL };

static const char *const cval[] = {
"NOP", "LAB", "LAC", "LAD", "LAE", "LAH", "LAL", "LAM",
"LBA", "",    "LBC", "LBD", "LBE", "LBH", "LBL", "LBM",
"LCA", "LCB", "",    "LCD", "LCE", "LCH", "LCL", "LCM",
"LDA", "LDB", "LDC", "",    "LDE", "LDH", "LDL", "LDM",
"LEA", "LEB", "LEC", "LED", "",    "LEH", "LEL", "LEM",
"LHA", "LHB", "LHC", "LHD", "LHE", "",    "LHL", "LHM",
"LLA", "LLB", "LLC", "LLD", "LLE", "LLH", "",    "LLM",
"LMA", "LMB", "LMC", "LMD", "LME", "LMH", "LML", "HALT",
NULL };

static const char *const dval[] = {
"ADR", "STATUS", "DATA", "WRITE", "COM1", "COM2",  "COM3",  "COM4",
"",    "",       "",     "",      "BEEP", "CLICK", "DECK1", "DECK2", 
"RBK", "WBK",    "",     "BSP",   "SF",   "SB",    "REWND", "TSTOP", 
NULL };

static const char *const eval[] = { "RFC", "RFZ", "RFS", "RFP",
				    "RTC", "RTZ", "RTS", "RTP",
				    NULL };

static const char *const fval[] = { "JFC", "JFZ", "JFS", "JFP",
				    "JTC", "JTZ", "JTS", "JTP",
				    NULL };

static const char *const gval[] = { "AD", "AC", "SU", "SB",
				    "ND", "XR", "OR", "CP",
				    NULL };

static const char *const hval[] = { "LA", "LB", "LC", "LD",
				    "LE", "LH", "LL",
				    NULL };

static const char *const ival[] = { "CFC", "CFZ", "CFS", "CFP",
				    "CTC", "CTZ", "CTS", "CTP",
				    NULL };

static const char *const *const valtab[] = { 
	bval, cval, dval, eval, fval,
       	gval, hval, ival
};

static int match_dp2200(char c, const char *p, const char **q)
{
	int v;

	if (c <= 'i') {
		v = mreg(p, valtab[(int) (c - 'b')], q);
	} else {
		v = -1;
	}

	return v;
}

static int gen_dp2200(int *eb, char p, const int *vs, int i, int savepc)
{
	int b;
       
	b = *eb;
	switch (p) {
	case 'f': b += (vs[i] << 1); break;
	case 'g': b |= (vs[i] << 4); break;
	default:
		  return -1;
	}

	*eb = b;
	return 0;
}

static int s_pat_char = 'b';
static int s_pat_index;

static void pat_char_rewind_dp2200(int c)
{
	s_pat_char = c;
	s_pat_index = 0;
};

static const char *pat_next_str_dp2200(void)
{
	const char *s;

	if (s_pat_char >= 'b' && s_pat_char <= 'n') {
		s = valtab[(int) (s_pat_char - 'b')][s_pat_index];
		if (s != NULL) {
			s_pat_index++;
		}
	} else {
		s = NULL;
	}

	return s;
};

const struct target s_target_dp2200 = {
	.id = "dp2200",
	.descr = "Datapoint 2200 Version I",
	.matcht = s_matchtab_dp2200,
	.matchf = match_dp2200,
	.genf = gen_dp2200,
	.pat_char_rewind = pat_char_rewind_dp2200,
	.pat_next_str = pat_next_str_dp2200,
	.mask = 1
};

const struct target s_target_dp2200ii = {
	.id = "dp2200ii",
	.descr = "Datapoint 2200 Version II",
	.matcht = s_matchtab_dp2200,
	.matchf = match_dp2200,
	.genf = gen_dp2200,
	.pat_char_rewind = pat_char_rewind_dp2200,
	.pat_next_str = pat_next_str_dp2200,
	.mask = 2
};
