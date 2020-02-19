/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Intel 8021.
 * Intel 8022.
 * Intel 8041.
 * Intel 8048.
 * ===========================================================================
 */

#include "pp.h"
#include "err.h"
#include "options.h"
#include "uz80as.h"
#include <stddef.h>

/* pat:
 *	a: expr
 *	b: R0,R1,R2,R3,R4,R5,R6,R7
 *	c: R0,R1
 *	d: P1,P2
 *	e: P4,P5,P6,P7
 *	f: JB0,JB1,JB2,JB3,JB4,JB5,JB6,JB7
 *
 * gen:
 * 	.: output lastbyte
 * 	b: (op << 3) | lastbyte
 * 	c: op | lastbyte
 * 	d: lastbyte = op as 8 bit value
 * 	e: output op as word (no '.' should follow)
 * 	f: output lastbyte | ((op & 0x700) >> 3)
 * 	   output op as 8 bit value
 * 	   (no '.' should follow)
 * 	g: (op << 5) | lastbyte
 */

static const struct matchtab s_matchtab_i8048[] = {
	{ "NOP", "00.", 1, 0 },
	{ "ADD A,b", "68c0.", 1, 0 },
	{ "ADD A,@c", "60c0.", 1, 0 },
	{ "ADD A,#a", "03.d0.", 1, 0, "e8" },
	{ "ADDC A,b", "78c0.", 1, 0 },
	{ "ADDC A,@c", "70c0.", 1, 0 },
	{ "ADDC A,#a", "13.d0.", 1, 0, "e8" },
	{ "ANL A,b", "58c0.", 1, 0 },
	{ "ANL A,@c", "50c0.", 1, 0 },
	{ "ANL A,#a", "53.d0.", 1, 0, "e8" },
	{ "ANL BUS,#a", "98.d0.", 32, 0, "e8" },
	{ "ANL d,#a", "98c0.d1.", 4, 0, "e8" },
	{ "ANLD e,A", "9Cc0.", 1, 0 },
	{ "CALL a", "14f0", 1, 0 },
	{ "CLR A", "27.", 1, 0 },
	{ "CLR C", "97.", 1, 0 },
	{ "CLR F1", "A5.", 4, 0 },
	{ "CLR F0", "85.", 4, 0 },
	{ "CPL A", "37.", 1, 0 },
	{ "CPL C", "A7.", 1, 0 },
	{ "CPL F0", "95.", 4, 0 },
	{ "CPL F1", "B5.", 4, 0 },
	{ "DA A", "57.", 1, 0 },
	{ "DEC A", "07.", 1, 0 },
	{ "DEC b", "C8c0.", 4, 0 },
	{ "DIS I", "15.", 2, 0 },
	{ "DIS TCNTI", "35.", 2, 0 },
	{ "DJNZ b,a", "E8c0.d1.", 1, 0, "e8" },
	{ "EN DMA", "E5.", 64, 0 },
	{ "EN FLAGS", "F5.", 64, 0 },
	{ "EN I", "05.", 2, 0 },
	{ "EN TCNTI", "25.", 2, 0 },
	{ "ENT0 CLK", "75.", 32, 0 },
	{ "IN A,DBB", "22.", 64, 0 },
	{ "IN A,P0", "08.", 8, 0 },
	{ "IN A,d", "08c0.", 1, 0 },
	{ "INC A", "17.", 1, 0 },
	{ "INC b", "18c0.", 1, 0 },
	{ "INC @c", "10c0.", 1, 0 },
	{ "INS A,BUS", "08.", 32, 0 },
	{ "f a", "12g0.d1.", 4, 0, "e8" },
	{ "JC a", "F6.d0.", 1, 0, "e8" },
	{ "JF0 a", "B6.d0.", 4, 0, "e8" },
	{ "JF1 a", "76.d0.", 4, 0, "e8" },
	{ "JMP a", "04f0", 1, 0, "e11" },
	{ "JMPP @A", "B3.", 1, 0 },
	{ "JNC a", "E6.d0.", 1, 0, "e8" },
	{ "JNI a", "86.d0.", 32, 0, "e8" },
	{ "JNIBF a", "D6.d0.", 64, 0, "e8" },
	{ "JNT0 a", "26.d0.", 2, 0, "e8" },
	{ "JNT1 a", "46.d0.", 1, 0, "e8" },
	{ "JNZ a", "96.d0.", 1, 0, "e8" },
	{ "JOBF a", "86.d0.", 64, 0, "e8" },
	{ "JTF a", "16.d0.", 1, 0, "e8" },
	{ "JT0 a", "36.d0.", 2, 0, "e8" },
	{ "JT1 a", "56.d0.", 1, 0, "e8" },
	{ "JZ a", "C6.d0.", 1, 0, "e8" },
	{ "MOV A,#a", "23.d0.", 1, 0, "e8" },
	{ "MOV A,PSW", "C7.", 4, 0 },
	{ "MOV A,b", "F8c0.", 1, 0 },
	{ "MOV A,@c", "F0c0.", 1, 0 },
	{ "MOV A,T", "42.", 1, 0 },
	{ "MOV PSW,A", "D7.", 4, 0 },
	{ "MOV b,A", "A8c0.", 1, 0 },
	{ "MOV b,#a", "B8c0.d1.", 1, 0, "e8" },
	{ "MOV @c,A", "A0c0.", 1, 0 },
	{ "MOV @c,#a", "B0c0.d1.", 1, 0, "e8" },
	{ "MOV STS,A", "90.", 64, 0 },
	{ "MOV T,A", "62.", 1, 0 },
	{ "MOVD A,e", "0Cc0.", 1, 0 },
	{ "MOVD e,A", "3Cc0.", 1, 0 },
	{ "MOVP A,@A", "A3.", 1, 0 },
	{ "MOVP3 A,@A", "E3.", 4, 0 },
	{ "MOVX A,@c", "80c0.", 32, 0 },
	{ "MOVX @c,A", "90c0.", 32, 0 },
	{ "NOP", "00.", 1, 0 },
	{ "ORL A,b", "48c0.", 1, 0 },
	{ "ORL A,@c", "40c0.", 1, 0 },
	{ "ORL A,#a", "43.d0.", 1, 0, "e8" },
	{ "ORL BUS,#a", "88.d0.", 32, 0, "e8" },
	{ "ORL d,#a", "88c0.d1.", 4, 0, "e8" },
	{ "ORLD e,A", "8Cc0.", 1, 0 },
	{ "OUT DBB,A", "02.", 64, 0 },
	{ "OUTL BUS,A", "02.", 32, 0 },
	{ "OUTL P0,A", "90.", 8, 0 },
	{ "OUTL d,A", "38c0.", 1, 0 },
	{ "RAD", "80.", 16, 0 },
	{ "RET", "83.", 1, 0 },
	{ "RETR", "93.", 4, 0 },
	{ "RETI", "93.", 16, 0 },
	{ "RL A", "E7.", 1, 0 },
	{ "RLC A", "F7.", 1, 0 },
	{ "RR A", "77.", 1, 0 },
	{ "RRC A", "67.", 1, 0 },
	{ "SEL AN0", "85.", 16, 0 },
	{ "SEL AN1", "95.", 16, 0 },
	{ "SEL MB0", "E5.", 32, 0 },
	{ "SEL MB1", "F5.", 32, 0 },
	{ "SEL RB0", "C5.", 4, 0 },
	{ "SEL RB1", "D5.", 4, 0 },
	{ "STOP TCNT", "65.", 1, 0 },
	{ "STRT CNT", "45.", 1, 0 },
	{ "STRT T", "55.", 1, 0 },
	{ "SWAP A", "47.", 1, 0 },
	{ "XCH A,b", "28c0.", 1, 0 },
	{ "XCH A,@c", "20c0.", 1, 0 },
	{ "XCHD A,@c", "30c0.", 1, 0 },
	{ "XRL A,b", "D8c0.", 1, 0 },
	{ "XRL A,@c", "D0c0.", 1, 0 },
	{ "XRL A,#a", "D3.d0.", 1, 0, "e8" },
	{ NULL, NULL },
};

static const char *const bval[] = {
"R0", "R1", "R2", "R3", "R4", "R5", "R6", "R7",
NULL };

static const char *const cval[] = {
"R0", "R1",
NULL };

static const char *const dval[] = {
"", "P1", "P2",
NULL };

static const char *const eval[] = {
"P4", "P5", "P6", "P7",
NULL };

static const char *const fval[] = {
"JB0", "JB1", "JB2", "JB3", "JB4", "JB5", "JB6", "JB7",
NULL };

static const char *const *const valtab[] = { 
	bval, cval, dval, eval, fval
};

static int match_i8048(char c, const char *p, const char **q)
{
	int v;

	if (c <= 'f') {
		v = mreg(p, valtab[(int) (c - 'b')], q);
	} else {
		v = -1;
	}

	return v;
}

static int gen_i8048(int *eb, char p, const int *vs, int i, int savepc)
{
	int b;
       
	b = *eb;
	switch (p) {
	case 'f': b |= ((vs[i] & 0x700) >> 3);
		  genb(b, s_pline_ep);
		  genb(vs[i], s_pline_ep);
		  break;
	case 'g': b |= (vs[i] << 5);
		  break;
	default:
		  return -1;
	}

	*eb = b;
	return 0;
}

static int s_pat_char = 'b';
static int s_pat_index;

static void pat_char_rewind_i8048(int c)
{
	s_pat_char = c;
	s_pat_index = 0;
};

static const char *pat_next_str_i8048(void)
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

const struct target s_target_i8041 = {
	.id = "i8041",
	.descr = "Intel 8041",
	.matcht = s_matchtab_i8048,
	.matchf = match_i8048,
	.genf = gen_i8048,
	.pat_char_rewind = pat_char_rewind_i8048,
	.pat_next_str = pat_next_str_i8048,
	.mask = 71
};

const struct target s_target_i8048 = {
	.id = "i8048",
	.descr = "Intel 8048",
	.matcht = s_matchtab_i8048,
	.matchf = match_i8048,
	.genf = gen_i8048,
	.pat_char_rewind = pat_char_rewind_i8048,
	.pat_next_str = pat_next_str_i8048,
	.mask = 39
};

const struct target s_target_i8021 = {
	.id = "i8021",
	.descr = "Intel 8021",
	.matcht = s_matchtab_i8048,
	.matchf = match_i8048,
	.genf = gen_i8048,
	.pat_char_rewind = pat_char_rewind_i8048,
	.pat_next_str = pat_next_str_i8048,
	.mask = 9
};

const struct target s_target_i8022 = {
	.id = "i8022",
	.descr = "Intel 8022",
	.matcht = s_matchtab_i8048,
	.matchf = match_i8048,
	.genf = gen_i8048,
	.pat_char_rewind = pat_char_rewind_i8048,
	.pat_next_str = pat_next_str_i8048,
	.mask = 27
};

