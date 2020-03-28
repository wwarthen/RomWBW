/* ===========================================================================
 * uz80as, an assembler for the Zilog Z80 and several other microprocessors.
 *
 * Sharp LR35902 (Nintendo Gameboy CPU).
 * ===========================================================================
 */

#include "pp.h"
#include "err.h"
#include "options.h"
#include "uz80as.h"
#include <stddef.h>

#if 0
Opcode  Z80             GMB
 ---------------------------------------
 08      EX   AF,AF      LD   (nn),SP
 10      DJNZ PC+dd      STOP
 22      LD   (nn),HL    LDI  (HL),A
 2A      LD   HL,(nn)    LDI  A,(HL)
 32      LD   (nn),A     LDD  (HL),A
 3A      LD   A,(nn)     LDD  A,(HL)
 D3      OUT  (n),A      -
 D9      EXX             RETI
 DB      IN   A,(n)      -
 DD      <IX>            -
 E0      RET  PO         LD   (FF00+n),A
 E2      JP   PO,nn      LD   (FF00+C),A
 E3      EX   (SP),HL    -
 E4      CALL PO,nn      -
 E8      RET  PE         ADD  SP,dd
 EA      JP   PE,nn      LD   (nn),A
 EB      EX   DE,HL      -
 EC      CALL PE,nn      -
 ED      <pref>          -
 F0      RET  P          LD   A,(FF00+n)
 F2      JP   P,nn       LD   A,(FF00+C)
 F4      CALL P,nn       -
 F8      RET  M          LD   HL,SP+dd
 FA      JP   M,nn       LD   A,(nn)
 FC      CALL M,nn       -
 FD      <IY>            -
 CB3X    SLL  r/(HL)     SWAP r/(HL) 
#endif

/* pat:
 * 	a: expr
 * 	b: B,C,D,E,H,L,A
 * 	c: *
 * 	d: BC,DE,HL,SP
 * 	e: *
 * 	f: BC,DE,HL,AF
 * 	g: ADD,ADC,SUB,SBC,AND,XOR,OR,CP
 * 	h: INC,DEC
 * 	i: *
 * 	j: *
 * 	k: *
 * 	l: BIT,RES,SET
 * 	m: *
 * 	n: NZ,Z,NC,C
 * 	o: RLC,RRC,RL,RR,SLA,SRA,SWAP,SRL
 *
 * gen:
 * 	.: output lastbyte
 * 	b: (op << 3) | lastbyte
 * 	c: op | lastbyte
 * 	d: lastbyte = op as 8 bit value
 * 	e: output op as word (no '.' should follow)
 * 	f: (op << 4) | lastbyte
 * 	g: (op << 6) | lastbyte
 * 	h: if op >= FF00 output last byte and then op as 8 bit value;
 * 	   else output (lastbyte | 0x0A) and output op as word
 * 	   (no '.' should follow)
 * 	i: relative jump to op
 * 	j: possible value to RST
 * 	k: possible value to IM
 * 	l: *
 * 	m: check arithmetic used with A register
 * 	n: check arithmetic used without A register
 */

const struct matchtab s_matchtab_gbcpu[] = {
	{ "LD b,b", "40b0c1.", 1, 0 },
	{ "LD b,(HL)", "46b0.", 1, 0 },
	{ "LD A,(C)", "F2.", 1, 0 }, // * LD A,(FF00+C)
	{ "LD A,(BC)", "0A.", 1, 0 },
	{ "LD A,(DE)", "1A.", 1, 0 },
	{ "LD A,(HLI)", "2A.", 1, 0 }, // *
	{ "LD A,(HLD)", "3A.", 1, 0 }, // *
	{ "LD A,(a)", "F0h0", 1, 0 }, // * LD A,(nn) & LD A,(FF00+n)
	{ "LD b,a", "06b0.d1.", 1, 0, "e8" },
	{ "LD SP,HL", "F9.", 1, 0 },
	{ "LDHL SP,a", "F8.d0.", 1, 0, "e8" }, // * LD HL,SP+n
	{ "LD d,a", "01f0.e1", 1, 0 },
	{ "LD (C),A", "E2.", 1, 0 }, // * LD (FF00+C),A
	{ "LD (HL),b", "70c0.", 1, 0 },
	{ "LD (HL),a", "36.d0.", 1, 0, "e8" },
	{ "LD (HLI),A", "22.", 1, 0 }, // *
	{ "LD (HLD),A", "32.", 1, 0 }, // *
	{ "LD (BC),A", "02.", 1, 0 },
	{ "LD (DE),A", "12.", 1, 0 },
	{ "LD (a),A", "E0h0", 1, 0 }, // * LD (nn),A & LD (FF00+n),A
	{ "LD (a),SP", "08.e0", 1, 0 }, // *
	{ "LDH A,(a)", "F0.d0.", 1, 0, "e8" }, // * LD A,(FF00+n)
	{ "LDH (a),A", "E0.d0.", 1, 0, "e8" }, // * LD (FF00+n),A
	{ "PUSH f", "C5f0.", 1, 0 },
	{ "POP f", "C1f0.", 1, 0 },
	{ "ADD HL,d", "09f0.", 1, 0 },
	{ "ADD SP,a", "E8.d0.", 1, 0, "e8" }, // * 
	{ "g A,b", "m080b0c1.", 1, 0 },
	{ "g A,(HL)", "m086b0.", 1, 0 },
	{ "g A,a", "m0C6b0.d1.", 1, 0, "e8" },
	{ "g b", "n080b0c1.", 1, 0 },
	{ "g (HL)", "n086b0.", 1, 0 },
	{ "g a", "n0C6b0.d1.", 1, 0, "e8" },
	{ "h b", "04b1c0.", 1, 0 },
	{ "h (HL)", "34c0.", 1, 0 },
	{ "INC d", "03f0.", 1, 0 },
	{ "DEC d", "0Bf0.", 1, 0 },
	{ "DAA", "27.", 1, 0 },
	{ "CPL", "2F.", 1, 0 },
	{ "CCF", "3F.", 1, 0 },
	{ "SCF", "37.", 1, 0 },
	{ "NOP", "00.", 1, 0 },
	{ "HALT", "76.", 1, 0 },
	{ "DI", "F3.", 1, 0 },
	{ "EI", "FB.", 1, 0 },
	{ "RLCA", "07.", 1, 0 },
	{ "RLA", "17.", 1, 0 },
	{ "RRCA", "0F.", 1, 0 },
	{ "RRA", "1F.", 1, 0 },
	{ "o b", "CB.00b0c1.", 1, 0 },
	{ "o (HL)", "CB.06b0.", 1, 0 },
	{ "l a,b", "CB.00g0b1c2.", 1, 0, "b3" },
	{ "l a,(HL)", "CB.06g0b1.", 1, 0, "b3" },
	{ "JP (HL)", "E9.", 1, 0 },
	{ "JP n,a", "C2b0.e1", 1, 0 }, // *
	{ "JP a", "C3.e0", 1, 0 },
	{ "JR n,a", "20b0.i1.", 1, 0, "r8" },
	{ "JR a", "18.i0.", 1, 0, "r8" },
	{ "STOP", "10.00.", 1, 0 }, // *
	{ "CALL n,a", "C4b0.e1", 1, 0 }, // *
	{ "CALL a", "CD.e0", 1, 0 },
	{ "RETI", "D9.", 1, 0 }, // *
	{ "RET n", "C0b0.", 1, 0 },
	{ "RET", "C9.", 1, 0 },
	{ "RST a", "C7j0.", 1, 0, "ss" },
	{ NULL, NULL },
};

static const char *const bval[] = { "B", "C", "D", "E",
				    "H", "L", "", "A", NULL };
static const char *const dval[] = { "BC", "DE", "HL", "SP", NULL };
static const char *const fval[] = { "BC", "DE", "HL", "AF", NULL };
static const char *const gval[] = { "ADD", "ADC", "SUB", "SBC",
				    "AND", "XOR", "OR", "CP", NULL };
static const char *const hval[] = { "INC", "DEC", NULL };
static const char *const lval[] = { "", "BIT", "RES", "SET", NULL };
static const char *const nval[] = { "NZ", "Z", "NC", "C", NULL };
static const char *const oval[] = { "RLC", "RRC", "RL", "RR",
				    "SLA", "SRA", "SWAP", "SRL", NULL };
static const char *const nullv[] = { NULL };

static const char *const *const valtab[] = { 
	bval, nullv, dval, nullv, fval,
       	gval, hval, nullv, nullv, nullv,
       	lval, nullv, nval, oval
};

static int match_gbcpu(char c, const char *p, const char **q)
{
	int v;

	switch (c) {
	case 'b':
	case 'd':
	case 'f':
	case 'g':
	case 'h':
	case 'l':
	case 'n':
	case 'o':
		v = mreg(p, valtab[(int) (c - 'b')], q);
		break;
	default:
		v = -1;
	}

	return v;
}

static int gen_gbcpu(int *eb, char p, const int *vs, int i, int savepc)
{
	int w, b;
       
	b = *eb;
	switch (p) {
	case 'f': b |= (vs[i] << 4); break;
	case 'g': b |= (vs[i] << 6); break;
	case 'h': w = vs[i] & 0xffff;
		  if (w >= 0xff00) {
			genb(b, s_pline_ep);
			b = 0;
			genb(w & 0xff, s_pline_ep);
		  } else {
			b |= 0x0A; 
			genb(b, s_pline_ep);
			b = 0;
			genb(w & 0xff, s_pline_ep);
			genb(w >> 8, s_pline_ep);
		  }
		  break;
	case 'i': b = (vs[i] - savepc - 2); break;
	case 'j': if (s_pass > 0 && (vs[i] & ~56) != 0) {
			  eprint(_("invalid RST argument (%d)\n"),
				vs[i]);
			  eprcol(s_pline, s_pline_ep);
			  newerr();
		  }
		  b |= vs[i];
		  break;
	case 'k': if (s_pass > 0 && (vs[i] < 0 || vs[i] > 2)) {
			  eprint(_("invalid IM argument (%d)\n"),
				vs[i]);
			  eprcol(s_pline, s_pline_ep);
			  newerr();
		  }
		  b = 0x46;
		  if (vs[i] == 1)
			  b = 0x56;
		  else if (vs[i] == 2)
			  b = 0x5E;
		  break;
	case 'm': if (s_pass == 0 && !s_extended_op) {
			  if (vs[i] != 0 && vs[i] != 1 && vs[i] != 3) {
				eprint(_("unofficial syntax\n"));
				eprcol(s_pline, s_pline_ep);
				newerr();
			  }
		  }
		  break;
	case 'n': if (s_pass == 0 && !s_extended_op) {
			  if (vs[i] == 0 || vs[i] == 1 || vs[i] == 3) {
				eprint(_("unofficial syntax\n"));
				eprcol(s_pline, s_pline_ep);
				newerr();
			  }
		  }
		  break;
	default:
		  return -1;
	}

	*eb = b;
	return 0;
}

static int s_pat_char = 'b';
static int s_pat_index;

static void pat_char_rewind_gbcpu(int c)
{
	s_pat_char = c;
	s_pat_index = 0;
};

static const char *pat_next_str_gbcpu(void)
{
	const char *s;

	switch (s_pat_char) {
	case 'b':
	case 'd':
	case 'f':
	case 'g':
	case 'h':
	case 'l':
	case 'n':
	case 'o':
		s = valtab[(int) (s_pat_char - 'b')][s_pat_index];
		if (s != NULL) {
			s_pat_index++;
		}
		break;
	default:
		s = NULL;
	}

	return s;
};

const struct target s_target_gbcpu = {
	.id = "gbcpu",
	.descr = "Sharp LR35902 (Nintendo Gameboy CPU)",
	.matcht = s_matchtab_gbcpu,
	.matchf = match_gbcpu,
	.genf = gen_gbcpu,
	.pat_char_rewind = pat_char_rewind_gbcpu,
	.pat_next_str = pat_next_str_gbcpu,
	.mask = 1
};
