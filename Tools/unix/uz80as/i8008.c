/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Intel 8008.
 * ===========================================================================
 */

/* Max. memory 16K (14 bits addresses). */

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
 *	   LBA,LBB,LBC,LBD,LBE,LBH,LBL,LBM,
 *	   LCA,LCB,LCC,LCD,LCE,LCH,LCL,LCM,
 *	   LDA,LDB,LDC,LDD,LDE,LDH,LDL,LDM,
 *	   LEA,LEB,LEC,LED,LEE,LEH,LEL,LEM,
 *	   LHA,LHB,LHC,LHD,LHE,LHH,LHL,LHM,
 *	   LLA,LLB,LLC,LLD,LLE,LLH,LLL,LLM,
 *	   LMA,LMB,LMC,LMD,LME,LMH,LML,HLT
 *	d: JFC,CFC,JMP,CAL,JFZ,CFZ,
 *	   JFS,CFS,JFP,CFP,
 *	   JTC,CTC,JTZ,CTZ,
 *	   JTS,CTS,JTP,CTP
 *	e: INB,INC,IND,INE,INH,INL
 *	f: DCB,DCC,DCD,DCE,DCH,DCL
 *	g: ADI,ACI,SUI,SBI,NDI,XRI,ORI,CPI
 *	h: LAI,LBI,LCI,LDI,LEI,LHI,LLI,LMI
 *	i: RFC,RFS,RTC,RTS,RFZ,RFP,RTZ,RTP
 *	j: RLC,RRC,RAL,RAR
 *
 * gen:
 * 	.: output lastbyte
 * 	b: (op << 3) | lastbyte
 * 	c: op | lastbyte
 * 	d: lastbyte = op as 8 bit value
 * 	e: output op as word (no '.' should follow)
 * 	f: (op << 1) | lastbyte, op in [0-7]
 * 	g: (op << 1) | lastbyte, op in [8-31]
 * 	h: (op << 4) | lastbyte
 * 	i: (op << 1) | lastbyte
 * 	j: (op << 3) | lastbyte, op in [0-7]
 */

static const struct matchtab s_matchtab_i8008[] = {
	{ "RET", "07.", 1, 0 },
	{ "j", "02b0.", 1, 0 },
	{ "i", "03b0.", 1, 0 },
	{ "h a", "06b0.d1.", 1, 0, "e8" },
	{ "g a", "04b0.d1.", 1, 0, "e8" },
	{ "e", "00b0.", 1, 0 },
	{ "f", "01b0.", 1, 0 },
	{ "RST a", "05j0.", 1, 0, "b3" },
	{ "d a", "40i0.e1", 1, 0 },
	{ "INP a", "41f0.", 1, 0, "b3" },
	{ "OUT a", "41g0.", 1, 0, "kk" },
	{ "b", "80c0.", 1, 0 },
	{ "c", "C0c0.", 1, 0 },
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
"LBA", "LBB", "LBC", "LBD", "LBE", "LBH", "LBL", "LBM",
"LCA", "LCB", "LCC", "LCD", "LCE", "LCH", "LCL", "LCM",
"LDA", "LDB", "LDC", "LDD", "LDE", "LDH", "LDL", "LDM",
"LEA", "LEB", "LEC", "LED", "LEE", "LEH", "LEL", "LEM",
"LHA", "LHB", "LHC", "LHD", "LHE", "LHH", "LHL", "LHM",
"LLA", "LLB", "LLC", "LLD", "LLE", "LLH", "LLL", "LLM",
"LMA", "LMB", "LMC", "LMD", "LME", "LMH", "LML", "HLT",
NULL };

static const char *const dval[] = {
"JFC", "CFC", "JMP", "CAL", "JFZ", "CFZ", "", "",
"JFS", "CFS", "",    "",    "JFP", "CFP", "", "",
"JTC", "CTC", "",    "",    "JTZ", "CTZ", "", "",
"JTS", "CTS", "",    "",    "JTP", "CTP",
NULL };

static const char *const eval[] = { "",    "INB", "INC", "IND",
				    "INE", "INH", "INL",
				    NULL };

static const char *const fval[] = { "",    "DCB", "DCC", "DCD",
				    "DCE", "DCH", "DCL",
				    NULL };

static const char *const gval[] = { "ADI", "ACI", "SUI", "SBI",
				    "NDI", "XRI", "ORI", "CPI",
				    NULL };

static const char *const hval[] = { "LAI", "LBI", "LCI", "LDI",
				    "LEI", "LHI", "LLI", "LMI",
				    NULL };

static const char *const ival[] = { "RFC", "RFZ", "RFS", "RFP",
				    "RTC", "RTZ", "RTS", "RTP",
				    NULL };

static const char *const jval[] = { "RLC", "RRC", "RAL", "RAR",
				    NULL };

static const char *const *const valtab[] = { 
	bval, cval, dval, eval, fval,
       	gval, hval, ival, jval
};

static int match_i8008(char c, const char *p, const char **q)
{
	int v;

	if (c <= 'j') {
		v = mreg(p, valtab[(int) (c - 'b')], q);
	} else {
		v = -1;
	}

	return v;
}

static int gen_i8008(int *eb, char p, const int *vs, int i, int savepc)
{
	int b;
       
	b = *eb;
	switch (p) {
	case 'f': if (s_pass > 0 && (vs[i] < 0 || vs[i] > 7)) {
			  eprint(_("argument (%d) must be in range [0-7]\n"),
				vs[i]);
			  eprcol(s_pline, s_pline_ep);
			  newerr();
		  }
	          b |= (vs[i] << 1);
		  break;
	case 'g': if (s_pass > 0 && (vs[i] < 8 || vs[i] > 31)) {
			  eprint(_("argument (%d) must be in range [8-31]\n"),
				vs[i]);
			  eprcol(s_pline, s_pline_ep);
			  newerr();
		  }
	          b |= (vs[i] << 1);
		  break;
	case 'h': b |= (vs[i] << 4); break;
	case 'i': b |= (vs[i] << 1); break;
	case 'j': if (s_pass > 0 && (vs[i] < 0 || vs[i] > 7)) {
			  eprint(_("argument (%d) must be in range [0-7]\n"),
				vs[i]);
			  eprcol(s_pline, s_pline_ep);
			  newerr();
		  }
	          b |= (vs[i] << 3);
		  break;
	default:
		  return -1;
	}

	*eb = b;
	return 0;
}

static int s_pat_char = 'b';
static int s_pat_index;

static void pat_char_rewind_i8008(int c)
{
	s_pat_char = c;
	s_pat_index = 0;
};

static const char *pat_next_str_i8008(void)
{
	const char *s;

	if (s_pat_char >= 'b' && s_pat_char <= 'j') {
		s = valtab[(int) (s_pat_char - 'b')][s_pat_index];
		if (s != NULL) {
			s_pat_index++;
		}
	} else {
		s = NULL;
	}

	return s;
};

const struct target s_target_i8008 = {
	.id = "i8008",
	.descr = "Intel 8008",
	.matcht = s_matchtab_i8008,
	.matchf = match_i8008,
	.genf = gen_i8008,
	.pat_char_rewind = pat_char_rewind_i8008,
	.pat_next_str = pat_next_str_i8008,
	.mask = 1
};

