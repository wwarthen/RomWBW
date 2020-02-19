/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Intel 8051.
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
 * 	d: ADD,ADDC,ORL,ANL,XRL,SUBB,XCH,MOV
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
 * 	g: relative jump -2
 * 	h: relative jump -3
 * 	i: ouput op as big endian word
 * 	j: b + (op << 4)
 */

static const struct matchtab s_matchtab_i8051[] = {
	{ "ACALL a", "11f0", 1, 0, "e11" },
	{ "d A,b", "08j0c1.", 1, 0 },
	{ "d A,@c", "06j0c1.", 1, 0 },
	{ "ADD A,#a", "24.d0.", 1, 0, "e8" },
	{ "ADDC A,#a", "34.d0.", 1, 0, "e8" },
	{ "ORL A,#a", "44.d0.", 1, 0, "e8" },
	{ "ANL A,#a", "54.d0.", 1, 0, "e8" },
	{ "XRL A,#a", "64.d0.", 1, 0, "e8" },
	{ "SUBB A,#a", "94.d0.", 1, 0, "e8" },
	{ "MOV A,#a", "74.d0.", 1, 0, "e8" },
	{ "d A,a", "05j0.d1.", 1, 0, "e8" },
	// { "ADD A,b", "28c0.", 1, 0 },
	// { "ADD A,@c", "26c0.", 1, 0 },
	// { "ADD A,a", "25.d0.", 1, 0, "e8" },
	// { "ADDC A,b", "38c0.", 1, 0 },
	// { "ADDC A,@c", "36c0.", 1, 0 },
	// { "ADDC A,a", "35.d0.", 1, 0, "e8" },
	{ "AJMP a", "01f0", 1, 0, "e11" },
	// { "ANL A,b", "58c0.", 1, 0 },
	// { "ANL A,@c", "56c0.", 1, 0 },
	// { "ANL A,a", "55.d0.", 1, 0, "e8" },
	{ "ANL C,/a", "B0.d0.", 1, 0, "e8" },
	{ "ANL C,a", "82.d0.", 1, 0, "e8" },
	{ "ANL a,A", "52.d0.", 1, 0 },
	{ "ANL a,#a", "53.d0.d1.", 1, 0, "e8e8" },
	{ "CJNE A,#a,a", "B4.d0.h1.", 1, 0, "e8r8" },
	{ "CJNE b,#a,a", "B8c0.d1.h2.", 1, 0, "e8r8" },
	{ "CJNE @c,#a,a", "B6c0.d1.h2.", 1, 0, "e8r8" },
	{ "CJNE A,a,a", "B5.d0.h1.", 1, 0, "e8r8" },
	{ "CLR A", "E4.", 1, 0 },
	{ "CLR C", "C3.", 1, 0 },
	{ "CLR a", "C2.d0.", 1, 0, "e8" },
	{ "CPL A", "F4.", 1, 0 },
	{ "CPL C", "B3.", 1, 0 },
	{ "CPL a", "B2.d0.", 1, 0, "e8" },
	{ "DA A", "D4.", 1, 0 },
	{ "DEC A", "14.", 1, 0 },
	{ "DEC b", "18c0.", 1, 0 },
	{ "DEC @c", "16c0.", 1, 0 },
	{ "DEC a", "15.d0.", 1, 0, "e8" },
	{ "DIV AB", "84.", 1, 0 },
	{ "DJNZ b,a", "D8c0.g1.", 1, 0, "r8" },
	{ "DJNZ a,a", "D5.d0.h1.", 1, 0, "e8r8" },
	{ "INC DPTR", "A3.", 1, 0 },
	{ "INC A", "04.", 1, 0 },
	{ "INC b", "08c0.", 1, 0 },
	{ "INC @c", "06c0.", 1, 0 },
	{ "INC a", "05.d0.", 1, 0, "e8" },
	{ "JB a,a", "20.d0.h1.", 1, 0, "e8r8" },
	{ "JBC a,a", "10.d0.h1.", 1, 0, "e8r8" },
	{ "JC a", "40.g0.", 1, 0, "r8" },
	{ "JMP @A+DPTR", "73.", 1, 0 },
	{ "JNB a,a", "30.d0.h1.", 1, 0, "e8r8" },
	{ "JNC a", "50.g0.", 1, 0, "r8" },
	{ "JNZ a", "70.g0.", 1, 0, "r8" },
	{ "JZ a", "60.g0.", 1, 0, "r8" },
	{ "LCALL a", "12.i0", 1, 0 }, 
	{ "LJMP a", "02.i0", 1, 0 },
	// { "MOV A,b", "E8c0.", 1, 0 },
	// { "MOV A,@c", "E6c0.", 1, 0 },
	// { "MOV A,a", "E5.d0.", 1, 0, "e8" }, // MOV A,ACC not valid?
	{ "MOV b,A", "F8c0.", 1, 0 },
	{ "MOV b,#a", "78c0.d1.", 1, 0, "e8" },
	{ "MOV b,a", "A8c0.d1.", 1, 0, "e8" },
	{ "MOV @c,A", "F6c0.", 1, 0 },
	{ "MOV @c,#a", "76c0.d1.", 1, 0, "e8" },
	{ "MOV @c,a", "A6c0.d1.", 1, 0, "e8" },
	{ "MOV C,a", "A2.d0.", 1, 0, "e8" },
	{ "MOV DPTR,#a", "90.i0", 1, 0, "e8" },
	{ "MOV a,A", "F5.d0.", 1, 0, "e8" },
	{ "MOV a,C", "92.d0.", 1, 0, "e8" },
	{ "MOV a,b", "88c1.d0.", 1, 0, "e8" },
	{ "MOV a,@c", "86c1.d0.", 1, 0, "e8" },
	{ "MOV a,#a", "75.d0.d1.", 1, 0, "e8e8" },
	{ "MOV a,a", "85.d1.d0.", 1, 0, "e8e8" },
	{ "MOVC A,@A+DPTR", "93.", 1, 0 },
	{ "MOVC A,@A+PC", "83.", 1, 0 },
	{ "MOVX A,@c", "E2c0.", 1, 0 },
	{ "MOVX A,@DPTR", "E0.", 1, 0 },
	{ "MOVX @c,A", "F2c0.", 1, 0 },
	{ "MOVX @DPTR,A", "F0.", 1, 0 },
	{ "MUL AB", "A4.", 1, 0 },
	{ "NOP", "00.", 1, 0 },
	// { "ORL A,b", "48c0.", 1, 0 },
	// { "ORL A,@c", "46c0.", 1, 0 },
	// { "ORL A,a", "45.d0.", 1, 0, "e8" },
	{ "ORL C,/a", "A0.d0.", 1, 0, "e8" },
	{ "ORL C,a", "72.d0.", 1, 0, "e8" },
	{ "ORL a,A", "42.d0.", 1, 0, "e8" },
	{ "ORL a,#a", "43.d0.d1.", 1, 0, "e8e8" },
	{ "POP a", "D0.d0.", 1, 0, "e8" },
	{ "PUSH a", "C0.d0.", 1, 0, "e8" },
	{ "RET", "22.", 1, 0 },
	{ "RETI", "32.", 1, 0 },
	{ "RL A", "23.", 1, 0 },
	{ "RLC A", "33.", 1, 0 },
	{ "RR A", "03.", 1, 0 },
	{ "RRC A", "13.", 1, 0 },
	{ "SETB C", "D3.", 1, 0 },
	{ "SETB a", "D2.d0.", 1, 0, "e8" },
	{ "SJMP a", "80.g0.", 1, 0, "r8" },
	// { "SUBB A,b", "98c0.", 1, 0 },
	// { "SUBB A,@c", "96c0.", 1, 0 },
	// { "SUBB A,a", "95.d0.", 1, 0, "e8" },
	{ "SWAP A", "C4.", 1, 0 },
	// { "XCH A,b", "C8c0.", 1, 0 },
	// { "XCH A,@c", "C6c0.", 1, 0 },
	// { "XCH A,a", "C5.d0.", 1, 0, "e8" },
	{ "XCHD A,@c", "D6c0.", 1, 0 },
	// { "XRL A,b", "68c0.", 1, 0 },
	// { "XRL A,@c", "66c0.", 1, 0 },
	// { "XRL A,a", "65.d0.", 1, 0, "e8" },
	{ "XRL a,A", "62.d0.", 1, 0, "e8" },
	{ "XRL a,#a", "63.d0.d1.", 1, 0, "e8e8" },
	{ NULL, NULL },
};

static const char *const bval[] = {
"R0", "R1", "R2", "R3", "R4", "R5", "R6", "R7",
NULL };

static const char *const cval[] = {
"R0", "R1",
NULL };

static const char *const dval[] = {
"", "", "ADD", "ADDC", "ORL", "ANL", "XRL", "",
"", "SUBB", "", "", "XCH", "", "MOV",
NULL };

static const char *const *const valtab[] = { 
	bval, cval, dval
};

static int match_i8051(char c, const char *p, const char **q)
{
	int v;

	if (c <= 'd') {
		v = mreg(p, valtab[(int) (c - 'b')], q);
	} else {
		v = -1;
	}

	return v;
}

static int gen_i8051(int *eb, char p, const int *vs, int i, int savepc)
{
	int b;
       
	b = *eb;
	switch (p) {
	case 'f': b |= ((vs[i] & 0x700) >> 3);
		  genb(b, s_pline_ep);
		  genb(vs[i], s_pline_ep);
		  break;
	case 'g': b = (vs[i] - savepc - 2); break;
		  break;
	case 'h': b = (vs[i] - savepc - 3); break;
		  break;
	case 'i': genb(vs[i] >> 8, s_pline_ep);
		  genb(vs[i], s_pline_ep);
		  break;
	case 'j': b += (vs[i] << 4); break;
	default:
		  return -1;
	}

	*eb = b;
	return 0;
}

static int s_pat_char = 'b';
static int s_pat_index;

static void pat_char_rewind_i8051(int c)
{
	s_pat_char = c;
	s_pat_index = 0;
};

static const char *pat_next_str_i8051(void)
{
	const char *s;

	if (s_pat_char >= 'b' && s_pat_char <= 'd') {
		s = valtab[(int) (s_pat_char - 'b')][s_pat_index];
		if (s != NULL) {
			s_pat_index++;
		}
	} else {
		s = NULL;
	}

	return s;
};

const struct target s_target_i8051 = {
	.id = "i8051",
	.descr = "Intel 8051",
	.matcht = s_matchtab_i8051,
	.matchf = match_i8051,
	.genf = gen_i8051,
	.pat_char_rewind = pat_char_rewind_i8051,
	.pat_next_str = pat_next_str_i8051,
	.mask = 1
};

