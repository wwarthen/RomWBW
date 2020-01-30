/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * MOS Technology 6502.
 * Rockwell R6501.
 * California Micro Devices G65SC02.
 * Rockwell R65C02.
 * Rockwell R65C29.
 * Western Design Center W65C02S.
 * ===========================================================================
 */

/* mos6502, the original
 *
 *     g65sc02 California Micro Devices, adds to mos6502:
 *         - zp ADC,AND,CMP,EOR,LDA,ORA,SBC,STA
 *         - DEC A, INC A
 *         - JMP (abs,X)
 *         - BRA
 *         - PHX,PHY,PLX,PLY
 *         - STZ
 *         - TRB
 *         - TSB
 *         - More addressing modes for BIT, etc
 *
 *     r6501 Rockwell, adds to mos6502:
 *         - BBR, BBS
 *         - RMB, SMB
 *
 *     r65c02 Rockwell, adds the instructions of the g65sc02 and r6501
 * 	
 *     r65c29 Rockwell, adds to r65c02:
 *        - MUL
 *
 *     w65c02s Western Design Center, adds to r65c02:
 *        - STP,WAI
 */

#include "pp.h"
#include "err.h"
#include "options.h"
#include "uz80as.h"
#include <stddef.h>

/* pat:
 *	a: expr
 *	b: ORA,AND,EOR,ADC,STA,LDA,CMP,SBC
 *	c: ORA,AND,EOR,ADC,LDA,CMP,SBC
 *	d: PHP,CLC,PLP,SEC,PHA,CLI,PLA,SEI,
 *	   DEY,TYA,TAY,CLV,INY,CLD,INX,SED
 *	e: ASL,ROL,LSR,ROR
 *	f: DEC, INC
 *	g: BPL,BMI,BVC,BVS,BCC,BCS,BNE,BEQ
 *	h: TXA,TXS,TAX,TSX,DEX,NOP
 *	i: CPY,CPX
 *	j: TSB,TRB
 *	k: BBR0,BBR1,BBR2,BBR3,BBR4,BBR5,BBR6,BBR6,
 *	   BBS0,BBS1,BBS2,BBS3,BBS4,BBS5,BBS6,BBS7
 *	l: RMB0,RMB1,RMB2,RMB3,RMB4,RMB5,EMB6,RMB7,
 *	   SMB0,SMB1,SMB2,SMB3,SMB4,SMB5,SMB6,SMB7
 *	m: PHY,PLY
 *	n: PHX,PLX
 *	o: INC, DEC
 *
 * gen:
 * 	.: output lastbyte
 * 	b: (op << 3) | lastbyte
 * 	c: op | lastbyte
 * 	d: lastbyte = op as 8 bit value
 * 	e: output op as word (no '.' should follow)
 * 	f: (op << 5) | lastbyte
 * 	g: if op <= $FF output last byte and then op as 8 bit value;
 * 	   else output (lastbyte | 0x08) and output op as word
 * 	   (no '.' should follow)
 * 	h: (op << 4) | lastbyte
 * 	i: relative jump to op (-2)
 * 	j: if op <= $FF output $64 and op as 8 bit
 * 	   else output $9C and op as word
 * 	   (no '.' should follow)
 * 	k: if op <= $FF ouput $74 and op as 8 bit
 * 	   else output $9E and op as word
 * 	   (no '.' should follow)
 * 	l: relative jump to op (-3)
 */

static const struct matchtab s_matchtab_mos6502[] = {
	{ "BRK", "00.", 1, 0 },
	{ "JSR a", "20.e0", 1, 0 },
	{ "RTI", "40.", 1, 0 },
	{ "RTS", "60.", 1, 0 },
	{ "h", "8Ah0.", 1, 0 },
	{ "d", "08h0.", 1, 0 },
	{ "c #a", "09f0.d1.", 1, 0, "e8" },
	{ "b (a,X)", "01f0.d1.", 1, 0, "e8" },
	{ "b (a),Y", "11f0.d1.", 1, 0, "e8" },
	{ "b (a)", "12f0.d1.", 2, 0, "e8" },
	{ "b a", "05f0g1", 1, 0 },
	{ "b a,X", "15f0g1", 1, 0 },
	{ "b a,Y", "19f0.e1", 1, 0 },
	{ "e A", "0Af0.", 1, 0 },
	{ "e a", "06f0g1", 1, 0 },
	{ "e a,X", "16f0g1", 1, 0 },
	{ "STX a", "86g0", 1, 0 },
	{ "STX a,Y", "96.d0.", 1, 0, "e8" },
	{ "LDX #a", "A2.d0.", 1, 0, "e8" },
	{ "LDX a", "A6g0", 1, 0 },
	{ "LDX a,Y", "B6g0", 1, 0 },
	{ "o A", "1Af0.", 2, 0 },
	{ "f a", "C6f0g1", 1, 0 },
	{ "f a,X", "D6f0g1", 1, 0 },
	{ "g a", "10f0.i1.", 1, 0, "r8" },
	{ "BIT #a", "89.d0.", 2, 0, "e8" },
	{ "BIT a", "24g0", 1, 0 },
	{ "BIT a,X", "34g0", 2, 0 },
	{ "JMP (a)", "6C.e0", 1, 0 },
	{ "JMP (a,X)", "7C.e0", 2, 0 },
	{ "JMP a", "4C.e0", 1, 0 },
	{ "STY a", "84g0", 1, 0 },
	{ "STY a,X", "94.d0.", 1, 0, "e8" },
	{ "LDY #a", "A0.d0.", 1, 0, "e8" },
	{ "LDY a", "A4g0", 1, 0 },
	{ "LDY a,X", "B4g0", 1, 0 },
	{ "i #a", "C0f0.d1.", 1, 0, "e8" },
	{ "i a", "C4f0g1", 1, 0 },
	{ "j a", "04h0g1", 2, 0 },
	{ "k a,a", "0Fh0.d1.l2.", 4, 0, "e8r8" },
	{ "l a", "07h0.d1.", 4, 0, "e8" },
	{ "m", "5Af0.", 2, 0 },
	{ "n", "DAf0.", 2, 0 },
	{ "BRA a", "80.i0.", 2, 0, "r8" },
	{ "STZ a,X", "k1", 2, 0 },
	{ "STZ a", "j1", 2, 0 },
	{ "MUL", "02.", 8, 0 },
	{ "WAI", "CB.", 16, 0 },
	{ "STP", "DB.", 16, 0 },
	{ NULL, NULL },
};

static const char *const bval[] = {
	"ORA", "AND", "EOR", "ADC",
	"STA", "LDA", "CMP", "SBC",
       	NULL
};

static const char *const cval[] = {
	"ORA", "AND", "EOR", "ADC",
	"", "LDA", "CMP", "SBC", NULL
};

static const char *const dval[] = {
       	"PHP", "CLC", "PLP", "SEC",
	"PHA", "CLI", "PLA", "SEI",
	"DEY", "TYA", "TAY", "CLV",
	"INY", "CLD", "INX", "SED",
	NULL
};


static const char *const eval[] = {
	"ASL", "ROL", "LSR", "ROR",
	NULL
};

static const char *const fval[] = {
	"DEC", "INC",
	NULL
};

static const char *const gval[] = {
	"BPL", "BMI", "BVC", "BVS",
	"BCC", "BCS", "BNE", "BEQ",
	NULL
};

static const char *const hval[] = {
	"TXA", "TXS", "TAX", "TSX",
	"DEX", "", "NOP",
	NULL
};

static const char *const ival[] = {
	"CPY", "CPX",
	NULL
};

static const char *const jval[] = {
	"TSB", "TRB",
	NULL
};

static const char *const kval[] = {
	"BBR0", "BBR1", "BBR2", "BBR3",
       	"BBR4", "BBR5", "BBR6", "BBR7",
	"BBS0", "BBS1", "BBS2", "BBS3",
       	"BBS4", "BBS5", "BBS6", "BBS7",
	NULL
};

static const char *const lval[] = {
	"RMB0", "RMB1", "RMB2", "RMB3",
       	"RMB4", "RMB5", "RMB6", "RMB7",
	"SMB0", "SMB1", "SMB2", "SMB3",
       	"SMB4", "SMB5", "SMB6", "SMB7",
	NULL
};

static const char *const mval[] = {
	"PHY", "PLY",
	NULL
};

static const char *const nval[] = {
	"PHX", "PLX",
	NULL
};

static const char *const oval[] = {
	"INC", "DEC",
	NULL
};

static const char *const *const valtab[] = { 
	bval, cval, dval, eval, fval,
	gval, hval, ival, jval, kval,
	lval, mval, nval, oval
};

static int match_mos6502(char c, const char *p, const char **q)
{
	int v;

	if (c <= 'o') {
		v = mreg(p, valtab[(int) (c - 'b')], q);
	} else {
		v = -1;
	}

	return v;
}

static int gen_mos6502(int *eb, char p, const int *vs, int i, int savepc)
{
	int b, w;
       
	b = *eb;
	switch (p) {
	case 'f': b |= (vs[i] << 5); break;
	case 'g': w = vs[i] & 0xffff;
		  if (w <= 0xff) {
			genb(b, s_pline_ep);
			b = 0;
			genb(w, s_pline_ep);
		  } else {
			b |= 0x08; 
			genb(b, s_pline_ep);
			b = 0;
			genb(w, s_pline_ep);
			genb(w >> 8, s_pline_ep);
		  }
		  break;
	case 'h': b |= (vs[i] << 4); break;
	case 'i': b = (vs[i] - savepc - 2); break;
	case 'j': w = vs[i] & 0xffff;
		  if (w <= 0xff) {
			genb(0x64, s_pline_ep);
			b = 0;
			genb(w, s_pline_ep);
		  } else {
			genb(0x9C, s_pline_ep);
			b = 0;
			genb(w, s_pline_ep);
			genb(w >> 8, s_pline_ep);
		  }
		  break;
	case 'k': w = vs[i] & 0xffff;
		  if (w <= 0xff) {
			genb(0x74, s_pline_ep);
			b = 0;
			genb(w, s_pline_ep);
		  } else {
			genb(0x9E, s_pline_ep);
			b = 0;
			genb(w, s_pline_ep);
			genb(w >> 8, s_pline_ep);
		  }
		  break;
	case 'l': b = (vs[i] - savepc - 3); break;
	default:
		  return -1;
	}

	*eb = b;
	return 0;
}

static int s_pat_char = 'b';
static int s_pat_index;

static void pat_char_rewind_mos6502(int c)
{
	s_pat_char = c;
	s_pat_index = 0;
};

static const char *pat_next_str_mos6502(void)
{
	const char *s;

	if (s_pat_char >= 'b' && s_pat_char <= 'o') {
		s = valtab[(int) (s_pat_char - 'b')][s_pat_index];
		if (s != NULL) {
			s_pat_index++;
		}
	} else {
		s = NULL;
	}

	return s;
};

const struct target s_target_mos6502 = {
	.id = "mos6502",
	.descr = "MOS Technology 6502",
	.matcht = s_matchtab_mos6502,
	.matchf = match_mos6502,
	.genf = gen_mos6502,
	.pat_char_rewind = pat_char_rewind_mos6502,
	.pat_next_str = pat_next_str_mos6502,
	.mask = 1
};

const struct target s_target_r6501 = {
	.id = "r6501",
	.descr = "Rockwell R6501",
	.matcht = s_matchtab_mos6502,
	.matchf = match_mos6502,
	.genf = gen_mos6502,
	.pat_char_rewind = pat_char_rewind_mos6502,
	.pat_next_str = pat_next_str_mos6502,
	.mask = 5
};

const struct target s_target_g65sc02 = {
	.id = "g65sc02",
	.descr = "California Micro Devices G65SC02",
	.matcht = s_matchtab_mos6502,
	.matchf = match_mos6502,
	.genf = gen_mos6502,
	.pat_char_rewind = pat_char_rewind_mos6502,
	.pat_next_str = pat_next_str_mos6502,
	.mask = 3
};

const struct target s_target_r65c02 = {
	.id = "r65c02",
	.descr = "Rockwell R65C02",
	.matcht = s_matchtab_mos6502,
	.matchf = match_mos6502,
	.genf = gen_mos6502,
	.pat_char_rewind = pat_char_rewind_mos6502,
	.pat_next_str = pat_next_str_mos6502,
	.mask = 7
};

const struct target s_target_r65c29 = {
	.id = "r65c29",
	.descr = "Rockwell R65C29, R65C00/21",
	.matcht = s_matchtab_mos6502,
	.matchf = match_mos6502,
	.genf = gen_mos6502,
	.pat_char_rewind = pat_char_rewind_mos6502,
	.pat_next_str = pat_next_str_mos6502,
	.mask = 15
};

const struct target s_target_w65c02s = {
	.id = "w65c02s",
	.descr = "Western Design Center W65C02S",
	.matcht = s_matchtab_mos6502,
	.matchf = match_mos6502,
	.genf = gen_mos6502,
	.pat_char_rewind = pat_char_rewind_mos6502,
	.pat_next_str = pat_next_str_mos6502,
	.mask = 027
};
