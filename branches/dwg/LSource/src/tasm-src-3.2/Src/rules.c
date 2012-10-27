/****************************************************************************
 *  $Id: rules.c 1.9 2000/06/02 11:42:58 toma Exp $
 **************************************************************************** 
 *  File: rules.c
 *
 *  Description:
 *    Invoke specific rules for the current instruction and addressing mode. 
 *
 *    Copyright 1985-1995  Speech Technology Incorporated.
 *    Copyright 1997-2000  Squak Valley Software
 *    Restrictions apply to the duplication of this software.
 *    See the COPYRIGH.TXT file on this disk for restrictions.
 *
 *    Thomas N. Anderson
 *    Squak Valley Software
 *    837 Front Street South
 *    Issaquah, WA  98027
 *
 *    See rlog for file revision history.
 *    See relnotes.txt for general revision history.
 *
 */

//static char *id_rules_c = "$Id: rules.c 1.9 2000/06/02 11:42:58 toma Exp $";

/* INCLUDES */
#include        "tasm.h"

#ifdef T_MEMCHECK
#include        <memcheck.h>
#endif

/* DEFINES */

/* Constants for the encoding rules (MODOPS) used in the instruction definition table (first
 * two characters) and processed by the special_case() function.
 */
#define JMPANYPAGE       (('J' << 8) | 'M')
#define JMPTHISPAGE      (('J' << 8) | 'T')
#define ZEROPAGE         (('Z' << 8) | 'P')
#define Z80BIT           (('Z' << 8) | 'B')
#define Z80IDX           (('Z' << 8) | 'I')
#define REL1             (('R' << 8) | '1')
#define REL2             (('R' << 8) | '2')
#define REL3             (('R' << 8) | '3')
#define SWAP             (('S' << 8) | 'W')
#define COMBREL          (('C' << 8) | 'R')
#define COMB_SWAP        (('C' << 8) | 'S')
#define COMBINE          (('C' << 8) | 'O')
#define COMB_NIBBLE      (('C' << 8) | 'N')
#define COMB_NIBBLE_SWAP (('C' << 8) | '5')
#define ST7_ZEROPAGE     (('S' << 8) | 'Z')
#define ST7_BIT          (('S' << 8) | 'B')
#define MOTOR_ZEROPAGE   (('M' << 8) | 'Z')
#define MOTOR_BIT        (('M' << 8) | 'B')
#define THREE_ARG        (('3' << 8) | 'A')
#define THREE_REL        (('3' << 8) | 'R')
#define TMS1             (('T' << 8) | '1')
#define TMS2             (('T' << 8) | '2')
#define TMS3             (('T' << 8) | '3')
#define TMS4             (('T' << 8) | '4')
#define TMS5             (('T' << 8) | '5')
#define TMS6             (('T' << 8) | '6')
#define TDMA             (('T' << 8) | 'D')
#define TLK              (('T' << 8) | 'L')
#define TAR              (('T' << 8) | 'A')
#define I8096_1_COMB     (('I' << 8) | '1')
#define I8096_2_2FAR     (('I' << 8) | '2')
#define I8096_3_3FAR     (('I' << 8) | '3')
#define I8096_4_JBIT     (('I' << 8) | '4')
#define I8096_5_REL      (('I' << 8) | '5')
#define I8096_6_IND      (('I' << 8) | '6')
#define I8096_7_1FAR     (('I' << 8) | '7')
#define I8096_8_TIJMP    (('I' << 8) | '8')
#define SUB              (('S' << 8) | 'U')
#define Z8_WORKREG       (('Z' << 8) | 'W')
#define Z8_DJNZ          (('Z' << 8) | 'D')
#define Z8_LD            (('Z' << 8) | 'L')

/* Special opcodes for 6502 extended instructions. */
#define STZ_ABS         0x9c
#define STZ_ABSX        0x9e

#define LOW_NIBBLE     0x0FL


/* STATIC FUNCTIONS */
static ushort    shift_and  (char *parg, int shiftcnt, ulong andmask);
static ushort    arp_val    (char *parg);

static void      isargvalid      (long argval, ulong vmask, ushort sbit,
                                                       ushort width,
                                                       char   *argtext);
static void      isargrangevalid (long argval, long argmin, long argmax,
                                                       char   *argtext);


/* EXTERNALS */
extern  ushort  Debug;
extern  char    Errorbuf[LINESIZE];

/************************************************************************/
/* FUNCTIONS */


/* Function: rules()
 * Description:
 *     Apply specified encoding rule for all instructions that did
 *     not specify NOP/NOTOUCH.  
 *     
 */
void
rules(
    ushort  modop,
    ulong   *opcode,
    ushort  *obytes,
    ushort  *abytes,
    ulong   *argval,
    pc_t    pcx,
    ushort  argc,
    char    **argv,
    ubyte   shift,
    ulong   bor)
{

    short   delta;
    ushort  aval;
    ulong   arg0;     
    ulong   arg1;
    ulong   arg2;
    ulong   arg3;
    long    sarg0;
    long    sarg1;
    ushort  reg;
    ushort  regsrc;
    ushort  regdst;
    ulong   dir_mem_add;
    ulong   arp;
    ushort  bit;
    long    idx;

    extern  int   Use_argvalv;
    extern  ubyte Argvalv[];

    strcpy(Errorbuf,"");
    Use_argvalv = FALSE;

    /* get a short version of argval since that is all that
     *  is needed for most of the things in the function. */
    arg0 = (ulong) *argval;
    aval = (ushort)*argval;

    switch(modop){

    case 0:
    case NOTOUCH:
        /* Don't do anything to this instruction */
        break;

    case 1:
    case JMPANYPAGE:
        /* 8048 and 8051 Page Jump or Call instructions.
         * Only enable this check for the 8051.  The 8048 JMP/CALL
         * instructions use the SEL MB instruction to select the high
         * bits of PC.  
         * The 8051 AJMP/ACALL instructions use the high bits of the 
         * PC after it is incremented beyond the current instruction.
         * Use the bor field to to control the out-of-range check.   
         * For 8048 set bor=0000, for 8051 set bor=F800
         */
        if(((pcx + 2) & bor) != (aval & bor)){
            strcpy(Errorbuf,"");
            errlog("Branch off of current 2K page.",   PASS2_ONLY); 
        }

        *opcode |= ((aval & 0x700) >> 3);

        /* Clear out upper bits of arg so we don't complain about
         * unused data.
         */
        *argval = aval & 0xff;
        break;

    case JMPTHISPAGE:
        /* Jump to any location on current page.  Complain if upper byte
         * is not on the current page.
         * Note that for the 8048, if the instruction starts on location
         * XXFF the branch must be on the following page.  Thus, the
         * (pcx+1) below.
         */
        if((aval & 0xff00) != (ushort)((pcx+1) & 0xff00)){
            strcpy(Errorbuf,"");
            errlog("Branch off of current page.",   PASS2_ONLY); 
        }
        *argval = aval & 0xff;
        break;

    case ZEROPAGE:
        /* 6502 zero page mode */
        if((*argval < 0x10000L) && (aval < 0x100)){
            /* test for the two special cases in the
               extended instruction set STZ */
            switch((int)(*opcode)){
            case STZ_ABS:
               *opcode = 0x64;
               break;
            case STZ_ABSX:
               *opcode = 0x74;
               break;
            default:
               *opcode = *opcode & 0xf7;
            }   
            *abytes = 1;
        }
        break;

    case MOTOR_ZEROPAGE:
        /* Motorola 6800, 6805 zero page mode */
        if((*argval < 0x10000L) && (aval <= 0xff)){
            switch((int)(*opcode) & 0xf0){
            case 0xc0:      /* 6805 Extended/direct */
                *opcode = (*opcode & 0x0f) | 0xb0;
                break;

            case 0xd0:      /* 6805 Indexed 2 byte/Indexed 1 byte*/
                *opcode = (*opcode & 0x0f) | 0xe0;
                break;

            default:
                /* 6800-6804,68HC11 zero page */
                *opcode = *opcode & 0xffdf;
                break;
            }   
            *abytes = 1;
        }
        else{
            /* Not zero page so swap bytes */
            *argval = ((aval >> 8) & 0x00ff) | ((aval << 8) & 0xff00);
        }
        break;

    case ST7_ZEROPAGE:
        /* ST7 zero page mode */
        if((*argval < 0x10000L) && (aval <= 0xff)){
            /* Yes, the arg is on the zero page.         */
            /* Adjust the opcode for 1 and 2 byte cases  */
            /*   CX ->   BX                              */
            /*   DX ->   EX                              */
            /* XXCX -> XXBX                              */
            /* XXDX -> XXEX                              */
            if      ((*opcode & 0xf0)  ==      0xc0)
                *opcode = (*opcode & 0xff0f) | 0xb0;
            else if ((*opcode & 0xf0)  ==      0xd0)
                *opcode = (*opcode & 0xff0f) | 0xe0;

            *abytes = 1;
        }
        else{
            /* Not zero page so swap bytes of arg since this is a BigEndian MCU */
            *argval = ((aval >> 8) & 0x00ff) | ((aval << 8) & 0xff00);
        }
        break;

    case Z80BIT:
        /* Z80 BIT instructions */
        bit = (ushort)val(argv[0]);
        if(argc == 1){

            isargrangevalid ((long)bit, 0L, 7L, argv[0] );
            *opcode = *opcode | ((bit & 0x7) << 11);
            *argval = 0;
        }
        else{
            /* Index displacement is a signed byte quantity */
            sarg1 = val(argv[1]);     /* DISP */
            isargrangevalid ((long)bit,   0L,   7L, argv[0] );
            isargrangevalid (sarg1,    -128L, 127L, argv[1] );

            *argval =  ((bit & 0x7) << 11) | (sarg1 & 0xff);
        }
        break;

    case Z80IDX:
        /* Z80 Indexed instructions.  e.g. SRL (IX+DISP) */
        /* Truncate arg to a single byte even though it is
         * returned as a two byte.  The high byte is ORd with
         * the mask to get the fourth byte of some instructions
         * and if DISP is negative a conflict occurs.
         */

        if (argc == 1) {
            /* Index displacement is a signed byte quantity */
            sarg0 = val(argv[0]);   /* DISP */
            isargrangevalid (sarg0, -128L, 127L, argv[0] );

            *argval = ((ushort)sarg0 & 0xff);
        }
        else {
            sarg0 = val(argv[0]);   /* DISP */
            sarg1 = val(argv[1]);   /* DATA */
            isargrangevalid (sarg1,     -128L, 255L, argv[1] );
            isargrangevalid (sarg0,     -128L, 127L, argv[0] );

            *argval = (sarg0 & 0xff) | ((sarg1 & 0xff) << 8);

        }

        break;

    case MOTOR_BIT:
        /* MOTOROLA 6805 BIT instructions */
        if(argc == 2){
            /* BSET and BCLR instructions  */
            /* OR the bit into the opcode, followed by Zpage address */
            *opcode = *opcode | (((ushort)val(argv[0]) & 0x7) << 1);
            *argval = (ushort)val(argv[1]) & 0xff;
        }
        if(argc == 3){
            /* (BRSET and BRCLR instuctions (two args: bit and label) */
            *opcode = *opcode | (((ushort)val(argv[0]) & 0x7) << 1);
            delta   = (short)((ushort)val(argv[2]) - pcx - 3);
            if((delta > 127) || (delta < -128)){
                *argval = 0;
                strcpy(Errorbuf,"");
                errlog("Range of relative branch exceeded.",   PASS2_ONLY); 
            }else{
                *argval = (int)((delta & 0xff) << 8) | 
                               ((ushort)val(argv[1]) & 0xff);
            }
        }
        break;

    case ST7_BIT:
        /* ST7 BRES, BSET, and BTJF instructions */
        if(argc == 2){
            /* BSET addr,#bit              */
            /* BRES addr,#bit              */
            /* BSET [addr],#bit            */
            /* BRES [addr],#bit            */
            /* OR the bit into the opcode, followed by Zpage address */
            *opcode = *opcode | (((ushort)val(argv[1]) & 0x7) << 1);
            *argval = (ushort)val(argv[0]) & 0xff;
        }
        if(argc == 3){
            /* BTJF addr,#bit,rel  */
            /* BTJT addr,#bit,rel  */
            *opcode = *opcode | (((ushort)val(argv[1]) & 0x7) << 1);
            delta   = (short)((ushort)val(argv[2]) - pcx - (*obytes+2));
            if((delta > 127) || (delta < -128)){
                *argval = 0;
                strcpy(Errorbuf,"");
                errlog("Range of relative branch exceeded.",   PASS2_ONLY); 
            }else{
                *argval = (int)((delta & 0xff) << 8) | 
                               ((ushort)val(argv[0]) & 0xff);
            }
        }
        break;

    case REL1:
    /* arg is relative to PC and should be reduced to a single byte */
        delta   = (short)((long)aval - (long)pcx - ((long)(*obytes) + *abytes));
        if((delta > 127) || (delta < -128)){
            *argval = 0;
            strcpy(Errorbuf,"");
            errlog("Range of relative branch exceeded.",   PASS2_ONLY);
        }else
            *argval = delta & 0xff;
        break;

    case REL2:
    /* arg is relative to PC and is double byte */
        delta   = (short)(*argval - pcx - ((long)(*obytes) + *abytes));
        *argval = delta;
        break;

    case REL3:
    /* arg is relative to PC and is to be OR'd into opcode */
    /* uPD75000 relative branch instruction                */
    /* Note that the sign extension of the delta in the backwards  branch */
    /* case is desired.  The upper nibble is all 0's for the forward case */
    /* and all 1's for the backwards case.                                */
        delta   = (short)(val(argv[0]) - (long)pcx) - (short)(*obytes + *abytes);
        if ((delta > 15) || (delta < -16)){
            errlog("Range of relative branch exceeded.",   PASS2_ONLY);
        }

        *opcode = *opcode | (ushort)delta;
        break;

    case COMBREL:
    /* two arguments, second is relative */
        delta  = (short)(val(argv[1]) - (long)pcx) - (short)(*obytes + *abytes);
        if((delta > 127) || (delta < -128)){
            *argval = 0;
            errlog("Range of relative branch exceeded.",   PASS2_ONLY);
        }else
            *argval = (*argval & 0xff) | (ushort)((delta & 0xff) << 8);
        break;

    case COMBINE:
    /* two arguments, combine into argval  */
	/* If three bytes expected then assume first arg provides two */
        if (*abytes == 2){
			*argval = (aval & 0xff) | (((ushort)val(argv[1]) & 0xff) << 8);
		}
		else{
            /* two bytes from second arg. */
            arg1    = val(argv[1]);
            *argval = ((arg1        & 0xff)   << 16) |
                      ((ulong)aval & 0xffff);
        }
        break;

    case COMB_SWAP:
    /* Two arguments, combine into argval but swap bytes.
     * If three bytes expected then assume first arg provides two.
     */ 

        if(*abytes == 2){
            /* just low bytes from each */
            *argval = (val(argv[1]) & 0xff) | ((aval & 0xff) << 8);
        }
        else{
            /* two bytes from second arg. */
            arg1    = val(argv[1]);
            *argval = ((arg1        & 0xff)   << 16) |
                      (((ulong)aval & 0xff)   <<  8) |  
                      (((ulong)aval & 0xff00) >>  8);
        }

        if ((bor) && (*argval != (*argval & bor))){
            sprintf(Errorbuf, "%s or %s", argv[0], argv[1]);
            errlog("range of argument exceeded.",   PASS2_ONLY);
        }
        break;

    case COMB_NIBBLE:
    /* two arguments, combine into one byte of argval  */
        *argval = (aval & 0xf) | (((ushort)val(argv[1]) & 0xf) << 4);
        /* If a mask is provided (bor) then use it to verify the 
         * correctness of the args.  This can be used to check
         * for even register use for some Z8 instructions.
         */
        if ((bor) && (*argval != (*argval & bor))){
            sprintf(Errorbuf, "%s or %s", argv[0], argv[1]);
            errlog("range of argument exceeded.",   PASS2_ONLY);
        }
        
        break;

    case COMB_NIBBLE_SWAP:
    /* two arguments, combine into one byte of argval, swap nibbles  */
        *argval = ((aval & 0xf) << 4) | (((ushort)val(argv[1]) & 0xf));
        /* If a mask is provided (bor) then use it to verify the 
         * correctness of the args.  This can be used to check
         * for even register use for some Z8 instructions.
         */
        if ((bor) && (*argval != (*argval & bor))){
            sprintf(Errorbuf, "%s or %s", argv[0], argv[1]);
            errlog("range of argument exceeded.",   PASS2_ONLY);
        }
        break;

    case THREE_REL:
    /* three arguments, last is relative */
        delta = (short)((ushort)val(argv[2]) - (long)pcx) - (short)(*obytes + *abytes);
        if((delta > 127) || (delta < -128)){
            *argval = 0;
            errlog("range of relative branch exceeded.",   PASS2_ONLY);
        }else
            *argval = (aval & 0xff) | ((ulong)(val(argv[1]) & 0xff) << 8)
                                    | ((ulong)(delta        & 0xff) << 16);
            break;

    case THREE_ARG:
    /* three arguments, combine into argval  */
        *argval = (aval & 0xff) | ((ulong)(val(argv[1]) & 0xff) << 8)
                                | ((ulong)(val(argv[2]) & 0xff) << 16);
        break;

    case I8096_1_COMB:
    /* Two or three arguments, combine into argval but swap bytes.
     * If three bytes expected then assume first arg provides two.
      *
     *   abytes    argc          op1      op2      op3      op4
     *   ---------------------------------------------------
     *   2         2           arg1    arg0
     *   3         2           arg1_lo arg1_hi   arg0
     *   3         3           arg2    arg1      arg0
     *   4         3
     */ 

        if (argc == 1){
            /* No need to do anything here, but validate */
            isargvalid (arg0, bor, 0, 8, argv[0]);
        }
        else if ((argc == 2) && (*abytes == 2)){
            /* just low bytes from each */
            arg1    = val(argv[1]);
            *argval = (arg1 & 0xff) | ((arg0 & 0xff) << 8);

            isargvalid (arg0, bor, 8, 8, argv[0]);
            isargvalid (arg1, bor, 0, 8, argv[1]);

        }
        else if ((argc == 2) && (*abytes == 3)){
            /* two bytes from second arg. */
            arg1    = val(argv[1]);
            *argval = (((ulong)aval & 0xff)   << 16) |
                      (((ulong)arg1 & 0xff)        ) |  
                      (((ulong)arg1 & 0xff00)      );

            isargvalid (arg0, bor, 16,  8, argv[0]);
            isargvalid (arg1, bor,  0, 16, argv[1]);

        }
        else if((argc == 3) && (*abytes == 3)){
            /* just low bytes from each */
            arg1    = val(argv[1]);
            arg2    = val(argv[2]);
            *argval = (arg2 & 0xff)       | 
                     ((arg1 & 0xff) << 8) |
                     ((arg0 & 0xff) <<16);

            isargvalid (arg0, bor, 16,  8, argv[0]);
            isargvalid (arg1, bor,  8,  8, argv[1]);
            isargvalid (arg2, bor,  0,  8, argv[2]);

        }
        else if((argc == 3) && (*abytes == 4)){
            /* low bytes from each */
            arg1    = val(argv[1]);
            arg2    = val(argv[2]);
            *argval = (arg2 & 0xffff)      | 
                     ((arg1 & 0xff) << 16) |
                     ((arg0 & 0xff) << 24);

            isargvalid (arg0, bor, 24,  8, argv[0]);
            isargvalid (arg1, bor, 16,  8, argv[1]);
            isargvalid (arg2, bor,  0, 16, argv[2]);

        }
        else if((argc == 4)){
            arg1    = val(argv[1]);
            arg2    = val(argv[2]);
            arg3    = val(argv[3]);

            /* just low bytes from each */
            *argval = (arg3 & 0xff)        | 
                     ((arg2 & 0xff) <<  8) | 
                     ((arg1 & 0xff) << 16) |
                     ((arg0 & 0xff) << 24);

            isargvalid (arg0, bor, 24,  8, argv[0]);
            isargvalid (arg1, bor, 16,  8, argv[1]);
            isargvalid (arg2, bor,  8,  8, argv[2]);
            isargvalid (arg3, bor,  0,  8, argv[3]);

        }




        /* OR the argval with the shift field (which is really used
         * as general purpose data;  use defined by the rule).  Here,
         * we use it to turn on the LSB of the first arg bytes for 
         * the auto-increment modes of the 8096.
         */
        *argval = *argval | (ulong) shift;

        break;

    case I8096_8_TIJMP:
    /* TIJMP Rule.
     * Three args combined as in the I8096_1_COMB, except arg2 & arg1 are 
     * swapped.
     *
     */ 

        if((argc == 3) && (*abytes == 3))
        {
            /* just low bytes from each */
            arg1    = val(argv[1]);
            arg2    = val(argv[2]);
            *argval = (arg1 & 0xff)       | 
                     ((arg2 & 0xff) << 8) |
                     ((arg0 & 0xff) <<16);

            isargvalid (arg0, bor, 16,  8, argv[0]);
            isargvalid (arg1, bor,  8,  8, argv[1]);
            isargvalid (arg2, bor,  0,  8, argv[2]);

        }

        break;


    case I8096_2_2FAR:
        /* I8096;  2 args, second might be far. */

        arg1= val(argv[1]);
        if( arg1 < 256) {
            *argval = (val(argv[1]) & 0xff) | ((aval & 0xff) << 8);
                                        /* Discard the LS byte and           */
                                        /* turn off the low two bits         */
                                        /* of the new LS byte.               */
                                        /* Note:  the XOR with shift is      */
                                        /* specifically here for the XCH/XCHB*/
                                        /* instructions which do not follow  */
                                        /* the general pattern of the other  */
                                        /* instructions.  Shift should be 00 */
                                        /* for all other instructions.       */
                                        /* Shift=0C converts the X8 to X4    */
                                        /* as needed for XCH/XCHB.           */
            *opcode = ((*opcode >> 8) & 0xfffc) ^ shift;
            *obytes = *obytes - 1;
            *abytes = 2;
        }
        else {
            *argval = (((ulong)aval & 0xff)   << 16) |
                      (((ulong)arg1 & 0xff)        ) |  
                      (((ulong)arg1 & 0xff00)      );
        }

        isargvalid (arg0, bor,  0,  8, argv[0]);

        break;

    case I8096_7_1FAR:
        /* I8096;  1 arg, might be far. */

        if( arg0 < 256) {
            *argval = (aval & 0xff);
                                        /* Discard the LS byte and    */
                                        /* turn off the low two bits */
                                        /* of the new LS byte.       */
            *opcode = (*opcode >> 8) & 0xfffc;
            *obytes = *obytes - 1;
            *abytes = 1;
        }
        else {
            *argval = (((ulong)arg0 & 0xff)        ) |  
                      (((ulong)arg0 & 0xff00)      );
        }

        isargvalid (arg0, bor,  0, 16, argv[0]);

        break;

    case I8096_3_3FAR:
        arg1= val(argv[1]);
        arg2= val(argv[2]);
        if( arg2 < 256) {
            /* just low bytes from each */
            *argval = (arg2 & 0xff)       | 
                     ((arg1 & 0xff) << 8) |
                     ((arg0 & 0xff) <<16);
                                    /* Discard the LS byte and    */
                                    /* turn off the low two bits */
                                    /* of the new LS byte.       */
            *opcode = (*opcode >> 8) & 0xfffc;
            *obytes = *obytes - 1;
            *abytes = 3;
        }
        else {
            *argval = (arg2 & 0xffff)     | 
                     ((arg1 & 0xff) << 16) |
                     ((arg0 & 0xff) << 24);

        }

        isargvalid (arg0, bor,  8,  8, argv[0]);
        isargvalid (arg1, bor,  0,  8, argv[1]);

        break;

    case I8096_4_JBIT:
        /* I8096 JBC and JBS instructions */
        /* three arguments, 2nd is bit, last is relative */
        delta  = (short)(val(argv[2]) - (long)pcx) - (short)(*obytes + *abytes);
        bit    = (short)val(argv[1]);

        if((delta > 127) || (delta < -128))
        {
            *argval = 0;
            errlog("range of relative branch exceeded.",   PASS2_ONLY);
        }
        else if(bit > 7) 
        {
            *argval = 0;
            sprintf(Errorbuf, "%s", argv[1]);
            errlog("range of argument exceeded.",   PASS2_ONLY);
        }
        else
        {
            *argval = (aval & 0xff) | ((ulong)(delta & 0xff) << 8);
            *opcode = *opcode | bit;
        }

        break;


    case I8096_5_REL:
        /* I8096 SJMP and SCALL */
        delta   = (short)(val(argv[0]) - (long)pcx) - (short)(*obytes + *abytes);

        if((delta > 1023) || (delta < -1024))
        {
            sprintf(Errorbuf, "offset=%d", delta);
            errlog("range of relative branch exceeded.",   PASS2_ONLY);
        }
        else
        {
            *opcode = *opcode | (ulong)(delta & 0x07ff);
        }

        break;

     case I8096_6_IND:
        /* Short and long indexed modes. */
        /*   XXX  idx[sreg]           where idx may be short or long */
        /*   XXX  dreg,idx[sreg]      where idx may be short or long */
        /*   XXX  dreg,reg,idx[sreg]      where idx may be short or long */

        if( argc == 3) {                /*  dreg,idx[sreg] form */
            idx =         val( argv[1] );
            if ((idx < 0) && (idx >= -128)) idx = 256 + idx;
            
            arg2= (ushort)val( argv[2] );

            if (idx < 256 ){
            /* short index */
                *argval = (       arg2 & 0xff)        | 
                         ((ulong)(idx  & 0xff) << 8)  |
                         ((ulong)(arg0 & 0xff) << 16);
                *abytes = *abytes - 1;
            }
            else
            {
                /* long index */
                *argval = (       val(argv[2]) & 0xff)          | 
                         ((ulong)(idx          & 0xffff) << 8)  |
                         ((ulong)(aval         & 0xff) << 24);
                     *argval = *argval | 0x01; /* force first byte odd */
            }

            /* No validation for the idx */
            isargvalid (arg0, bor,  8,  8, argv[0]);
            isargvalid (arg2, bor,  0,  8, argv[2]);

        }
        else if (argc == 4)
        {
            /*  XXX dreg, sreg1, idx[sreg2] */
            Use_argvalv = TRUE;
            idx =         val( argv[2] );
            if ((idx < 0) && (idx >= -128)) idx = 256 + idx;
            arg1= (ushort)val( argv[1] );
            arg3= (ushort)val( argv[3] );

            if (idx < 256 ){
                /* short index */
                Argvalv[0] = (ubyte)(arg3 & 0xff); 
                Argvalv[1] =         idx  & 0xff;
                Argvalv[2] = (ubyte)(arg1 & 0xff);
                Argvalv[3] = (ubyte)(aval & 0xff);

                             
                *abytes = *abytes - 1;
            }
            else{
                /* long index */
                Argvalv[0] = (ubyte)((arg3 & 0xff)   | 0x01); 
                Argvalv[1] = idx  & 0xff;
                Argvalv[2] = (idx >> 8 ) & 0xff;
                Argvalv[3] = (ubyte)(arg1 & 0xff);
                Argvalv[4] = aval & 0xff;

            }

            isargvalid (arg0, bor, 16,  8, argv[0]);
            isargvalid (arg1, bor,  8,  8, argv[1]);
            isargvalid (arg3, bor,  0,  8, argv[3]);

        }
        else{ /* argc == 2 */

            idx =         val( argv[0] );
            if ((idx < 0) && (idx >= -128)) idx = 256 + idx;
            
            arg1= (ushort)val( argv[1] );

            if (idx < 256 ){
            /* short index */
                *argval = (       arg1 & 0xff)        | 
                         ((ulong)(idx  & 0xff) << 8);
                *abytes = *abytes - 1;
            }
            else{
                /* long index */
                *argval = (       arg1         & 0xff)          | 
                         ((ulong)(idx          & 0xffff) << 8);
                     *argval = *argval | 0x01; /* force first byte odd */
            }

            /* validate reg */
            isargvalid (arg1, bor,  0,  8, argv[1]);
            /* No validation for the idx */
        }           
        break;

    case Z8_DJNZ:
    /* Z8 DJNZ instruction.  Two args; first is the working register;
     * the second is the address of the jump point (which should be 
     * converted to a relative byte count)
     */
        delta   = (short)((long)val(argv[1]) - (long)pcx - ((long)(*obytes) + *abytes));
        if((delta > 127) || (delta < -128)){
            *argval = 0;
            strcpy(Errorbuf,"");
            errlog("Range of relative branch exceeded.",   PASS2_ONLY);
        }else
            *argval = delta & 0xff;

        /* OR the first arg into the upper nibble of the opcode. */
        *opcode = *opcode | ((arg0 & 0xf) << 4);
        break;


    case Z8_WORKREG:
    /* Z8.  Two arguments.  If both are working registers (in the range
     * E0 to EF)  then combine into one byte
     * and adjust the byte count and opcode for the working register mode.
     * If not, then swap bytes.
     */ 
        Use_argvalv = TRUE;
        arg1 = val(argv[1]);

        if(((arg0 >= 0xe0) && (arg0 < 0xf0)) &&
           ((arg1 >= 0xe0) && (arg1 < 0xf0))  ){
            Argvalv[0] = (ubyte)(((arg0 & 0xf) << 4) | (arg1 & 0xf)); 
            *abytes = 1;
            /* turn bit 2 off and bit 1 on*/
            *opcode = (*opcode & 0xfb) | 0x02;
        }
        else
        {
            /* two bytes from second arg. */
            Argvalv[0] = (ubyte)arg1;
            Argvalv[1] = (ubyte)arg0;

        }

        if ( arg0 > 255)
        {
            sprintf(Errorbuf, "%s", argv[0]);
            errlog("range of argument exceeded.",   PASS2_ONLY);
        }

        if ( arg1 > 255)
        {
            sprintf(Errorbuf, "%s", argv[1]);
            errlog("range of argument exceeded.",   PASS2_ONLY);
        }

        break;
                                 
    case Z8_LD:
    /*  Z8 LD immed[r1],r2 
     *     Where r1 is handled literally in the table.  Thus, r2 is the 
     *     second arg.
     *     Let the first arg (immed) get the default handling.
     */
        arg1 = val(argv[1]);

        /* arg1 should be a working register (not including the R) */
        if( arg1 < 16 ) 
        {
            *opcode = *opcode | (arg1 << 4);
        }
        else
        {
            sprintf(Errorbuf, "%s", argv[1]);
            errlog("range of argument exceeded.",   PASS2_ONLY);
        }
        break;


    

    case SWAP:
        /* swap low and high bytes of argval (one argument) */
        *argval = ((aval >> 8) & 0x00ff) | ((aval << 8) & 0xff00);
        break;

    case TMS1:
        /* TMS320, shift, mask, and or first arg into opcode.
         *   If there is a second arg assume it is an ARP designation.
         */
        arg0 = shift_and(argv[0], shift, bor);
        
        if (argc > 1) arp = arp_val(argv[1]);
        else          arp = 0;

        *opcode = *opcode | arp | arg0;
        break;

    case TMS2:
        /* TMS9900, first arg is OR'd to opcode (register num).  Second
         *   If there is a second arg it is a 16 bit constant.
         */
        
        if (argc > 1){
            /* Two args (e.g. SWPB @$1234(R7)  ) */
            arg0    = ((ushort)val(argv[0]));
            *argval = ((arg0 >> 8) & 0x00ff) | ((arg0 << 8) & 0xff00);
            reg     = shift_and(argv[1], 0, LOW_NIBBLE);
        }
        else{
            /* single arg ( e.g. SWPB R7  ) */
            reg = shift_and(argv[0], 0, LOW_NIBBLE);
        }

        *opcode = *opcode | reg;
        break;

    case TMS3:
        /* TMS9900, two args, first is Reg, second is constant (16bit).
         */
        
        /* Two args (e.g. LI R7,$1234  ) */
        arg0    = ((ushort)val(argv[1]));
        *argval = ((arg0 >> 8) & 0x00ff) | ((arg0 << 8) & 0xff00);
        reg     = shift_and(argv[0], 0, LOW_NIBBLE);
        *opcode = *opcode | reg;
        break;

    case TMS4:
        /* TMS9900, two args, both Reg. (e.g. MOV R1,R2    ) */
        
        regsrc = shift_and(argv[0], 0, LOW_NIBBLE);
        regdst = shift_and(argv[1], 0, LOW_NIBBLE);
        *opcode = *opcode | regsrc | (int)(regdst << 6);
        break;

    case TDMA:
        /* TMS320, first arg is a DMA (direct memory address).
         *   Second arg gets the shift, mask and or treatment.
         */
        dir_mem_add         = shift_and(argv[0],     0, 0x7fL);
        if (argc > 1)  arg1 = shift_and(argv[1], shift, bor);
        else           arg1 = 0;

        *opcode = *opcode | dir_mem_add | arg1;
        break;

    case TLK:
        /* TMS320, first arg is a Long Constant (16 bit)      
         *   Second arg (if present) gets the shift, mask and or treatment.
         */
        arg0    = ((ushort)val(argv[0]));
        *argval = ((arg0 >> 8) & 0x00ff) | ((arg0 << 8) & 0xff00);
        if (argc > 1)  arg1 = shift_and(argv[1], shift, bor);
        else           arg1 = 0;

        *opcode = *opcode | arg1;
        break;

    case TMS5:
        /* Same as TLK, but swap args
         * TMS320, second arg is a Long Constant (16 bit)      
         *   First arg gets the shift, mask and or treatment.
         */
        arg1    = ((ushort)val(argv[1]));
        *argval = ((arg1 >> 8) & 0x00ff) | ((arg1 << 8) & 0xff00);
        arg0 = shift_and(argv[0], shift, bor);

        *opcode = *opcode | arg0;
        break;


    case TMS6:
        /* uPD75xxx and TMS320
         *   First arg is 8 bits and is right justified in the opcode
         *   Second arg gets the shift, mask and or treatment.
         */
        dir_mem_add         = shift_and(argv[0],     0, LOW_NIBBLE);
        if (argc > 1)  arg1 = shift_and(argv[1], shift, bor);
        else           arg1 = 0;

        *opcode = *opcode | dir_mem_add | arg1;
        break;

    case TAR:
        /* TMS320, first arg is a AR (auxilliary register).
         *   Second arg gets the shift, mask and or treatment.
         */
        arp = (ushort)(arp_val(argv[0]) << 8);
        if (argc > 1)  arg1 = shift_and(argv[1], shift, bor);
        else           arg1 = 0;

        *opcode = *opcode | arp | arg1;
        break;

    case SUB:
        /* Subtract first arg from opcode.  TMS7000 TRAP instruction.
         * Cant use aval or argval here since abytes == 0
         */
        arg1 = val(argv[0]);
        *opcode = *opcode - arg1;

        /* Check for out of range */
        if(arg1 > 23){
            strcpy(Errorbuf,argv[0]);
            errlog("Range of argument exceeded.",   PASS2_ONLY);
        }
        break;

    default:
        sprintf(Errorbuf,"%04X", modop);
        errlog("Invalid MODOP.",   PASS2_ONLY);
        break;

    } /* end of switch */

}

/*
 * Function: isargvalid()
 *
 * Description:
 *
 */

static void
isargvalid(
  long  argval,
  ulong vmask,
  ushort sbit,
  ushort width,
  char   *argtext)

{
     ulong valmask;
     static ulong widthmask[]  = { 0x0000,
                                    0x0001,
                                    0x0003,
                                    0x0007,
                                    0x000F,
                                    0x001F,
                                    0x003F,
                                    0x007F,
                                    0x00FF,
                                    0x01FF,
                                    0x03FF,
                                    0x07FF,
                                    0x0FFF,
                                    0x1FFF,
                                    0x3FFF,
                                    0x7FFF,
                                    0xFFFF};

    if ( vmask ) 
        valmask = (widthmask[width] & (vmask >> sbit));
    else
        valmask = widthmask[width];

    if ( argval < 0 ) {
        /* Ignore overflow due to sign extension */
        argval = argval & widthmask[width];
    }

    if ((ulong)argval != (argval & valmask)){
        sprintf(Errorbuf, "%s", argtext);
        errlog("range of argument exceeded.",   PASS2_ONLY);
    }

}
static void
isargrangevalid(
  long   argval,
  long   argmin,
  long   argmax,
  char   *argtext)

{

    if ((argval < argmin) || (argval > argmax)){
        sprintf(Errorbuf, "%s", argtext);
        errlog("Range of argument exceeded.",   PASS2_ONLY);
    }

    DEBUG4("isargrangevalid: %ld %ld %ld %s\n", argval, argmin, argmax, 
                                                argtext);

}

/*
 * Function: shift_and()
 *
 * Description:
 *      Determine the value of the indicated expression then shift
 *      left and AND.  Generate an error message if data is out of 
 *      range.
 *
 */

static ushort
shift_and(
char    *parg,
int     shiftcnt,
ulong   andmask)
{
    ushort              argt;
    ushort              arg;
    int                 aoperator;
    /* Extract the shift count from the low nibble, the optional operator
     * from the upper nibble.  If the operator is non-zero then invert the
     * arg.  Perhaps more operators in the future.  
     * The operator should get its own argument; this is a bit of a 
     * kludge to meet the need for TMS320C25 BIT instruction (for the moment).
     */
    aoperator = shiftcnt & 0xf0;
    shiftcnt  = shiftcnt & 0x0f;

    argt = (ushort)val(parg) << shiftcnt;
    arg  = argt & (ushort)andmask;

    if(arg != argt) {
        strcpy(Errorbuf,parg);
        errlog("Range of argument exceeded.",   PASS2_ONLY);
    }

    /* If operator detected, then invert the bit field. */
    if (aoperator) arg = (~argt) & (ushort)andmask;

    return(arg);
}

/*
 * Function: arp_val()
 *
 * Description:
 *    This applicable to TMS320 modops.
 *    Mask the value provided for an auxilary reg (ARP) 
 *      
 *
 */

static ushort
arp_val(char *parg)
{
    ushort          argt;
    ushort          arg;
    extern  char Part_num[];

    argt = (ushort)val(parg);

    if(strcmp (Part_num, "3225" ) == SAME)     arg = argt & 7;
    else                                       arg = argt & 1;

    if(arg != argt) {
        strcpy(Errorbuf,parg);
        errlog("Range of ARP argument exceeded.",   PASS2_ONLY);
    }

    return(arg);
}

/* that's all folks */

