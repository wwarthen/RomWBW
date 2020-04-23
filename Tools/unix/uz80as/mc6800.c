/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Motorola 6800, 6801.
 * ===========================================================================
 */

#include "pp.h"
#include "err.h"
#include "options.h"
#include "uz80as.h"
#include <stddef.h>

/* pat:
 *	a: expr
 * 	b: NEGA,COMA,LSRA,RORA,ASRA,
 *	   ROLA,DECA,INCA,TSTA,CLRA
 * 	c: NEGB,COMB,LSRB,RORB,ASRB,
 *	   ROLB,DECB,INCB,TSTB,CLRB
 * 	d: NEG,COM,LSR,ROR,ASR,
 *	   ROL,DEC,INC,TST,JMP,CLR
 *	e: SUBA,CMPA,SBCA,ANDA,BITA,LDAA,
 * 	   EORA,ADCA,ORAA,ADDA
 *	f: SUBB,CMPB,SBCB,ANDB,BITB,LDAB,
 * 	   EORB,ADCB,ORAB,ADDB
 * 	g: INX,DEX,CLV,SEV,CLC,SEC,CLI,SEI
 *      h: BRA,BHI,BLS,BCC,BCS,BNE,BEQ,
 *	   BVC,BVS,BPL,BMI,BGE,BLT,BGT,BLE
 *	i: TSX,INS,PULA,PULB,DES,TXS,PSHA,
 *	   PSHB,RTS,RTI,WAI,SWI
 *
 * gen:
 * 	.: output lastbyte
 * 	b: (op << 3) | lastbyte
 * 	c: op | lastbyte
 * 	d: lastbyte = op as 8 bit value
 * 	e: output op as word (no '.' should follow)
 * 	f: ouput op as big endian word (no '.' should follow)
 * 	g: if op<=$ff output lastbyte and output op as byte
 * 	   else output (lastbyte | 0x20) and output op as big endian word
 * 	   (no '.' should follow)
 * 	h: relative - 2
 * 	i: relative - 4
 * 	i: relative - 5
 */

static const struct matchtab s_matchtab_mc6800[] = {
	{ "NOP", "01.", 1, 0 },
	{ "TAP", "06.", 1, 0 },
	{ "TPA", "07.", 1, 0 },
	{ "g", "08c0.", 1, 0 },
	{ "SBA", "10.", 1, 0 },
	{ "CBA", "11.", 1, 0 },
	{ "TAB", "16.", 1, 0 },
	{ "TBA", "17.", 1, 0 },
	{ "DAA", "19.", 1, 0 },
	{ "ABA", "1B.", 1, 0 },
	{ "i", "30c0.", 1, 0 }, 
	{ "h a", "20c0.h1.", 1, 0, "r8" },
	{ "b", "40c0.", 1, 0 },
	{ "c", "50c0.", 1, 0 },
	{ "d a,X", "60c0.d1.", 1, 0, "e8" },
	{ "d a,Y", "18.60c0.d1.", 8, 0, "e8" },
	{ "d a", "70c0.f1", 1, 0, "e16" },
	{ "e #a", "80c0.d1.", 1, 0, "e8" },
	{ "f #a", "C0c0.d1.", 1, 0, "e8" },
	{ "e >a", "B0c0.f1", 1, 0, "e16" },
	{ "f >a", "F0c0.f1", 1, 0, "e16" },
	{ "e a,X", "A0c0.d1.", 1, 0, "e8" },
	{ "f a,X", "E0c0.d1.", 1, 0, "e8" },
	{ "e a,Y", "18.A0c0.d1.", 8, 0, "e8" },
	{ "f a,Y", "18.E0c0.d1.", 8, 0, "e8" },
	{ "e a", "90c0g1", 1, 0 },
	{ "f a", "D0c0g1", 1, 0 },
	{ "STAA >a", "B7.f0", 1, 0, "e16" },
	{ "STAA a,X", "A7.d0.", 1, 0, "e8" },
	{ "STAA a,Y", "18.A7.d0.", 8, 0, "e8" },
	{ "STAA a", "97g0", 1, 0 },
	{ "STAB >a", "F7.f0", 1, 0, "e16" },
	{ "STAB a,X", "E7.d0.", 1, 0, "e8" },
	{ "STAB a,Y", "18.E7.d0.", 8, 0, "e8" },
	{ "STAB a", "D7g0", 1, 0 },
	{ "CPX #a", "8C.f0", 1, 0, "e16" },
	{ "CPX >a", "BC.f0", 1, 0, "e16" },
	{ "CPX a,X", "AC.d0.", 1, 0, "e8" },
	{ "CPX a,Y", "CD.AC.d0.", 8, 0, "e8" },
	{ "CPX a", "9Cg0", 1, 0 },
	{ "LDS #a", "8E.f0", 1, 0, "e16" },
	{ "LDS >a", "BE.f0", 1, 0, "e16" },
	{ "LDS a,X", "AE.d0.", 1, 0, "e8" },
	{ "LDS a,Y", "18.AE.d0.", 8, 0, "e8" },
	{ "LDS a", "9Eg0", 1, 0 },
	{ "STS >a", "BF.f0", 1, 0, "e16" },
	{ "STS a,X", "AF.d0.", 1, 0, "e8" },
	{ "STS a,Y", "18.AF.d0.", 8, 0, "e8" },
	{ "STS a", "9Fg0", 1, 0 },
	{ "LDX #a", "CE.f0", 1, 0, "e16" },
	{ "LDX >a", "FE.f0", 1, 0, "e16" },
	{ "LDX a,X", "EE.d0.", 1, 0, "e8" },
	{ "LDX a,Y", "CD.EE.d0.", 8, 0, "e8" },
	{ "LDX a", "DEg0", 1, 0 },
	{ "STX >a", "FF.f0", 1, 0, "e16" },
	{ "STX a,X", "EF.d0.", 1, 0, "e8" },
	{ "STX a,Y", "CD.EF.d0.", 8, 0, "e8" },
	{ "STX a", "DFg0", 1, 0 },
	{ "BSR a", "8D.h0.", 1, 0, "r8" },
	{ "JSR >a", "BD.f0", 4, 0, "e16" },
	{ "JSR a,X", "AD.d0.", 1, 0, "e8" },
	{ "JSR a,Y", "18.AD.d0.", 8, 0, "e8" },
	{ "JSR a", "BD.f0", 2, 0, "e16" },
	{ "JSR a", "9Dg0", 4, 0 },
	{ "ABX", "3A.", 4, 0 },
	{ "ADDD #a", "C3.f0", 4, 0, "e16" },
	{ "ADDD >a", "F3.f0", 4, 0, "e16" },
	{ "ADDD a,X", "E3.d0.", 4, 0, "e8" },
	{ "ADDD a,Y", "18.E3.d0.", 8, 0, "e8" },
	{ "ADDD a", "D3g0", 4, 0 },
	{ "ASLD", "05.", 4, 0 },
	{ "LSLD", "05.", 4, 0 },
	{ "BHS a", "24.h0.", 4, 0, "r8" },
	{ "BLO a", "25.h0.", 4, 0, "r8" },
	{ "BRN a", "21.h0.", 4, 0, "r8" },
	{ "LDD #a", "CC.f0", 4, 0, "e16" },
	{ "LDD >a", "FC.f0", 4, 0, "e16" },
	{ "LDD a,X", "EC.d0.", 4, 0, "e8" },
	{ "LDD a,Y", "18.EC.d0.", 8, 0, "e8" },
	{ "LDD a", "DCg0", 4, 0 },
	{ "LSL a,X", "68.d0.", 4, 0, "e8" },
	{ "LSL a,Y", "18.68.d0.", 8, 0, "e8" },
	{ "LSL a", "78.f0", 4, 0, "e16" },
	{ "LSRD", "04.", 4, 0 },
	{ "MUL", "3D.", 4, 0 },
	{ "PSHX", "3C.", 4, 0 },
	{ "PSHY", "18.3C.", 8, 0 },
	{ "PULX", "38.", 4, 0 },
	{ "PULY", "18.38.", 8, 0 },
	{ "STD >a", "FD.f0", 4, 0, "e16" },
	{ "STD a,X", "ED.d0.", 4, 0, "e8" },
	{ "STD a,Y", "18.ED.d0.", 8, 0, "e8" },
	{ "STD a", "DDg0", 4, 0 },
	{ "SUBD #a", "83.f0", 4, 0, "e16" },
	{ "SUBD >a", "B3.f0", 4, 0, "e16" },
	{ "SUBD a,X", "A3.d0.", 4, 0, "e8" },
	{ "SUBD a,Y", "18.A3.d0.", 8, 0, "e8" },
	{ "SUBD a", "93g0", 4, 0 },
	{ "TEST", "00.", 8, 0 },
	{ "IDIV", "02.", 8, 0 },
	{ "FDIV", "03.", 8, 0 },
	{ "BRSET a,X,a,a", "1E.d0.d1.i2.", 8, 0, "e8e8r8" },
	{ "BRSET a,Y,a,a", "18.1E.d0.d1.j2.", 8, 0, "e8e8r8" },
	{ "BRSET a,a,a", "12.d0.d1.i2.", 8, 0, "e8e8r8" },
	{ "BRCLR a,X,a,a", "1F.d0.d1.i2.", 8, 0, "e8e8r8" },
	{ "BRCLR a,Y,a,a", "18.1F.d0.d1.j2.", 8, 0, "e8e8r8" },
	{ "BRCLR a,a,a", "13.d0.d1.i2.", 8, 0, "e8e8r8" },
	{ "BSET a,X,a", "1C.d0.d1.", 8, 0, "e8e8" }, 
	{ "BSET a,Y,a", "18.1C.d0.d1.", 8, 0, "e8e8" }, 
	{ "BSET a,a", "14.d0.d1.", 8, 0, "e8e8" },
	{ "BCLR a,X,a", "1D.d0.d1.", 8, 0, "e8e8" }, 
	{ "BCLR a,Y,a", "18.1D.d0.d1.", 8, 0, "e8e8" }, 
	{ "BCLR a,a", "15.d0.d1.", 8, 0, "e8e8" },
	{ "LSLA", "48.", 8, 0 },
	{ "LSLB", "58.", 8, 0 },
	{ "XGDX", "8F.", 8, 0 },
	{ "STOP", "CF.", 8, 0 },
	{ "ABY", "18.3A.", 8, 0 },
	{ "CPY #a", "18.8C.f0", 8, 0, "e16" },
	{ "CPY >a", "18.BC.f0", 8, 0, "e16" },
	{ "CPY a,X", "1A.AC.d0.", 8, 0, "e8" },
	{ "CPY a,Y", "18.AC.d0.", 8, 0, "e8" },
	{ "CPY a", "18.9Cg0", 8, 0 },
	{ "DEY", "18.09.", 8, 0 },
	{ "INY", "18.08.", 8, 0 },
	{ "LDY #a", "18.CE.f0", 8, 0, "e16" },
	{ "LDY >a", "18.FE.f0", 8, 0, "e16" },
	{ "LDY a,X", "1A.EE.d0.", 8, 0, "e8" },
	{ "LDY a,Y", "18.EE.d0.", 8, 0, "e8" },
	{ "LDY a", "18.DEg0", 8, 0 },
	{ "STY >a", "18.FF.f0", 8, 0, "e16" },
	{ "STY a,X", "1A.EF.d0.", 8, 0, "e8" },
	{ "STY a,Y", "18.EF.d0.", 8, 0, "e8" },
	{ "STY a", "18.DFg0", 8, 0 },
	{ "TSY", "18.30.", 8, 0 },
	{ "TYS", "18.35.", 8, 0 },
	{ "XGDY", "18.8F.", 8, 0 },
	{ "CPD #a", "1A.83.f0", 8, 0, "e16" },
	{ "CPD >a", "1A.B3.f0", 8, 0, "e16" },
	{ "CPD a,X", "1A.A3.d0.", 8, 0, "e8" },
	{ "CPD a,Y", "CD.A3.d0.", 8, 0, "e8" },
	{ "CPD a", "1A.93g0", 8, 0 },
	{ NULL, NULL },
};

static const char *const bval[] = {
"NEGA", "", "", "COMA", "LSRA", "", "RORA", "ASRA",
"ASLA", "ROLA", "DECA", "", "INCA", "TSTA", "", "CLRA",
NULL };

static const char *const cval[] = {
"NEGB", "", "", "COMB", "LSRB", "", "RORB", "ASRB",
"ASLB", "ROLB", "DECB", "", "INCB", "TSTB", "", "CLRB",
NULL };

static const char *const dval[] = {
"NEG", "", "", "COM", "LSR", "", "ROR", "ASR",
"ASL", "ROL", "DEC", "", "INC", "TST", "JMP", "CLR",
NULL };

static const char *const eval[] = {
"SUBA", "CMPA", "SBCA", "", "ANDA", "BITA", "LDAA", "",
"EORA", "ADCA", "ORAA", "ADDA",
NULL };

static const char *const fval[] = {
"SUBB", "CMPB", "SBCB", "", "ANDB", "BITB", "LDAB", "",
"EORB", "ADCB", "ORAB", "ADDB",
NULL };

static const char *const gval[] = {
"INX", "DEX", "CLV", "SEV", "CLC", "SEC", "CLI", "SEI",
NULL };

static const char *const hval[] = {
"BRA", "", "BHI", "BLS", "BCC", "BCS", "BNE", "BEQ",
"BVC", "BVS", "BPL", "BMI", "BGE", "BLT", "BGT", "BLE",
NULL };

static const char *const ival[] = {
"TSX", "INS", "PULA", "PULB", "DES", "TXS", "PSHA",
"PSHB", "", "RTS", "", "RTI", "", "", "WAI", "SWI",
NULL };

static const char *const *const valtab[] = { 
	bval, cval, dval, eval, fval,
       	gval, hval, ival
};

static int match_mc6800(char c, const char *p, const char **q)
{
	int v;

	if (c <= 'i') {
		v = mreg(p, valtab[(int) (c - 'b')], q);
	} else {
		v = -1;
	}

	return v;
}

static int gen_mc6800(int *eb, char p, const int *vs, int i, int savepc)
{
	int b;
       
	b = *eb;
	switch (p) {
	case 'f': genb(vs[i] >> 8, s_pline_ep);
		  genb(vs[i], s_pline_ep);
		  break;
	case 'g': if (vs[i] <= 255) {
			  genb(b, s_pline_ep);
			  genb(vs[i], s_pline_ep);
		  } else {
			  genb(b | 0x20, s_pline_ep);
			  genb(vs[i] >> 8, s_pline_ep);
			  genb(vs[i], s_pline_ep);
		  }
		  break;
	case 'h': b = (vs[i] - savepc - 2);
		  break;
	case 'i': b = (vs[i] - savepc - 4);
		  break;
	case 'j': b = (vs[i] - savepc - 5);
		  break;
	default:
		  return -1;
	}

	*eb = b;
	return 0;
}

static int s_pat_char = 'b';
static int s_pat_index;

static void pat_char_rewind_mc6800(int c)
{
	s_pat_char = c;
	s_pat_index = 0;
};

static const char *pat_next_str_mc6800(void)
{
	const char *s;

	if (s_pat_char >= 'b' && s_pat_char <= 'i') {
		s = valtab[(int) (s_pat_char - 'b')][s_pat_index];
		if (s != NULL) {
			s_pat_index++;
		}
	} else {
		s = NULL;
	}

	return s;
};

const struct target s_target_mc6800 = {
	.id = "mc6800",
	.descr = "Motorola 6800",
	.matcht = s_matchtab_mc6800,
	.matchf = match_mc6800,
	.genf = gen_mc6800,
	.pat_char_rewind = pat_char_rewind_mc6800,
	.pat_next_str = pat_next_str_mc6800,
	.mask = 3
};

const struct target s_target_mc6801 = {
	.id = "mc6801",
	.descr = "Motorola 6801",
	.matcht = s_matchtab_mc6800,
	.matchf = match_mc6800,
	.genf = gen_mc6800,
	.pat_char_rewind = pat_char_rewind_mc6800,
	.pat_next_str = pat_next_str_mc6800,
	.mask = 5
};

const struct target s_target_m68hc11 = {
	.id = "m68hc11",
	.descr = "Motorola 68HC11",
	.matcht = s_matchtab_mc6800,
	.matchf = match_mc6800,
	.genf = gen_mc6800,
	.pat_char_rewind = pat_char_rewind_mc6800,
	.pat_next_str = pat_next_str_mc6800,
	.mask = 13
};
