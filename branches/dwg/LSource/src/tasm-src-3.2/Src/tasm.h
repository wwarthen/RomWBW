/****************************************************************************
 * $Id: tasm.h 1.8 2001/10/23 01:39:39 toma Exp $
 ****************************************************************************
 * File:         tasm.h       
 * Description:  TASM Constants.  
 *
 *       Thomas N. Anderson
 *       Copyright 1989-2001, Squak Valley Software
 */

/* Local TASM types */
typedef          long           expr_t;    /* Expression value */
typedef unsigned long           uexpr_t;   /* Unsigned Expression values */
typedef unsigned long           pc_t;      /* Program Counter */
typedef unsigned char          *opbuf_t;   /* Pointer to op code buffer */
typedef unsigned char           ubyte;

#include        <stdio.h>
#include        <fcntl.h>
#include        <string.h>
#include        <ctype.h>
#include        <stdlib.h>
#include        <time.h>
#include        <sys/types.h>
#include        <sys/stat.h>

/* define unsigned data types */

/*********************************************/
/* Here is the non-portable stuff.  Use the right include
 * files (etc.) for the appropriate environment.
 * (All ifdefs are right here).
 */

/* If we detect LINUX set the UNIX define and the unsigned types which
 * are not always provided
 */
#define UNIX
#ifdef __linux__
#define UNIX
#define HUGE
#else
typedef unsigned short          ushort;
typedef unsigned long           ulong;
//#define HUGE huge
#define HUGE
#endif

#ifdef  UNIX

/* The MSDOS environments typically have io.h to handle the low level IO stuff.
 * The "extern C" is appropriate only if CC is being used to build in the 
 * UNIX environment.
 */
#ifdef __cplusplus
extern "C" {
#endif
int	close(int fd);
int	read(int fd, char *buf, int nbytes);
/* int	open(char * file, int flags, ...); */
#ifdef __cplusplus
}
#endif

//#include        "sys/file.h"
//#define O_BINARY   0

#else

/* MSDOS - Borland C */
#include <io.h>
#include <alloc.h>

#endif
/*********************************************/

#define O_MODE      (S_IREAD | S_IWRITE)


#define TRUE        1
#define FALSE       0
#define SAME        0
#define FAILURE     -1
#define SUCCESS     0
#define FILL_DEFAULT 0xff       /* default value to fill memory          */ 
                                /* with when the FILL directive is used. */

/* Bit masks for the label attribute flags */
#define         F_EXPORT        0x01
#define         F_SEG           0x0e
#define         F_LOCAL         0x10
#define         UNDEF_LABVAL    0x20000L

/* Segment constants */
#define         NULL_SEG        (0 << 1)
#define         CODE_SEG        (1 << 1)
#define         BIT_SEG         (2 << 1)
#define         EXTD_SEG        (3 << 1)
#define         DATA_SEG        (4 << 1)

/* TASM exit codes */
#define         EXIT_NORMAL             0
#define         EXIT_ASMERRORS          1
#define         EXIT_MALLOC             2
#define         EXIT_FILEACCESS         3
#define         EXIT_FATALERROR         4

/* Top of Form string (for EJECT directive) */
#define TOF         "\014"

/* delimiter for multiple instruction line */
#define DELIM       '\\'

/* size of source input line buffer ( and other misc buffers )*/
#define LINESIZE    512

/* size of file names */
#define PATHSIZE    80

/* File name pointers */
#define SRC_FN          Filenames[0]
#define OBJ_FN          Filenames[1]
#define LST_FN          Filenames[2]
#define EXP_FN          Filenames[3]
#define SYM_FN          Filenames[4]

/* Access macro for the label table */
#define GETLABTAB(index) (Labtab[index])

/* Maximum number of files open at one time. */
#define MAXFILES        20

#define USAGE  \
"tasm -<nn> [-options] src_file [obj_file [lst_file [exp_file [sym_file]]]]\n"

#define LOTS_OF_LABELS  /* don't bother with a small version        */

#ifdef LOTS_OF_LABELS
#define MAXLAB  15000   /* maximum number of labels in symbol table */
#define MAXINSTR 1200    /* maximum number of instructions           */
#else
#define MAXLAB  2000    /* maximum number of labels in symbol table */
#define MAXINSTR 600    /* maximum number of instructions           */
#endif

#define MAXARGS 128     /* maximum number of args for inst or directive */
#define LABLEN  32      /* maximum number of characters in label +1 */
#define MAXREG  32      /* maximum number of register set entries   */ 
#define MAXMEM  0xffff  /* maximum number of bytes in ROM (opbuf)   */
#define PAGESIZE 63     /* lines per page on listing file           */
#define MAX_CONDITIONAL_LEVELS  32
#define MAXIHASH 1024   /* maximum size of instruction hash table.  
                                Actually, just one element per letter
                                of the alphabet is used.*/
#define MAXLHASH 64     /* Maximum size of label hash table.
                         * One element per letter (upper and lower case). 
                         */

#define HASHKEY(p)  (((*p & 0x1f) << 5) | (*(p+1)&0x1f))

/* The macros min and max (in stdlib.h) are not defined in the 
 * c++ case (because of the desire to minimize the side effects
 * associated with macros).  Here are the preferred definintions:
 */
#ifdef __cplusplus
inline int min(int i, int j)
        {
        return i < j ? i:j;
        }

inline int max(int i, int j)
        {
        return i > j ? i:j;
        }
#else

#ifndef max
#define max(a,b)    (((a) > (b)) ? (a) : (b))
#define min(a,b)    (((a) < (b)) ? (a) : (b))
#endif

#endif

/* Structure for storing instruction set definition */
typedef struct{
        char    *instruction;   /* pointer to instruction mnemonic */
        char    *args;          /* pointer to argument description */
        ulong   opcode;         /* Opcode                          */
        ubyte   obytes;         /* Number of bytes of opcode            */
        ubyte   abytes;         /* Number of bytes of args              */
        ushort  modop;          /* Modifier operation (for special cases)*/
        ubyte   iclass;         /* Instruction set class (for extended instr)*/
        ubyte   shift;          /* bits to shift first argval */
        ulong   bor;            /* mask to OR first argval with */
        ubyte   same_inst;      /* Set to TRUE if instruction matches previous */
}OPTAB;

/* Structure for storing register set definitions */
typedef struct{
        char    *reg;           /* pointer to instruction mnemonic */
        ulong   opcode;         /* Opcode mask (ORd into instruction) */
        ubyte   iclass;         /* Instruction set class (for extended instr)*/
}REGTAB;

/* Structure for storing label data */
typedef struct{
        expr_t  val;            /* Label value */
        ushort  flags;          /* Label flags */
        char    lab[2];         /* Label string (min size; 
                                   malloc may extend buffer area */
}LABTAB;

#define FLUSHE  fflush(stderr)

#define DEBUG(f,d)          {if(Debug){fprintf(stderr,f,d);        FLUSHE;}}
#define DEBUG2(f,d,e)       {if(Debug){fprintf(stderr,f,d,e);      FLUSHE;}}
#define DEBUG3(f,d,e,g)     {if(Debug){fprintf(stderr,f,d,e,g);    FLUSHE;}}
#define DEBUG4(f,d,e,g,h)   {if(Debug){fprintf(stderr,f,d,e,g,h);  FLUSHE;}}
#define DEBUG5(f,d,e,g,h,i) {if(Debug){fprintf(stderr,f,d,e,g,h,i);FLUSHE;}}

/* Directive constants */
/* Note that NDIR must be the last enumerated item (indicating 
 * total number of items in the list).
 */
typedef enum   {NOTDIR=-1,
                BYTE,   ORG,    EQU,    END, 
                TEXT,   EJECT,  WORD,   LIST, 
                NOLIST, INCLUDE,PAGE,   NOPAGE, 
                TITLE,  IFDEF,  ENDIF,  IFNDEF, 
                ELSE,   DEFINE, IF,     EQU2, 
                ORG2,   ORG3,   ADDINSTR,BLOCK,  
                DS,     DB,     DW,     DEFCONT, 
                CODES,  NOCODES,SET,    EXPORT, 
                LSFIRST,MSFIRST,NSEG,   CSEG,
                BSEG,   XSEG,   DSEG,   SYM, 
                AVSYM,  UNDEF,  MODULE, COMMENTCHAR,
                LOCALLABELCHAR, CHK, FILL, ECHO, NDIR} dir_t;

/* Error codes */
typedef enum{
      ER_NOERR = 0,        /* No error                    */
      ER_BADDIR = 1,       /* Bad directive               */
      ER_BADINST,          /* Bad instruction             */
      ER_BADARG,           /* Bad argument                */
      ER_MISALLIGN,        /* Label misallign             */
      ER_TAB_OVERFLOW,     /* label table overflow        */
      ER_HEAP_OVERFLOW,    /* heap overflow               */
      ER_NO_LABEL}error_t; /* No such label yet defined   */


/* Line type constants */
typedef enum    {
        UNKNOWN = 0,    /* Unknown line type        */
        COMMENT,        /* Comment line             */
        DIRECTIVE,      /* Assembler directive line */
        INSTRUCT,       /* Instruction line         */
        BLANK} line_t;  /* Blank line               */

/* assembler pass */
typedef enum{
        FIRST = 1,
        SECOND} pass_t;

/* Output control modes for errlog() */
typedef enum    {ALWAYS, PASS2_ONLY} errout_t;

/* Token Types */
typedef enum    {
                TOK_VOID,
                TOK_BINOP,
                TOK_UNOP,
                TOK_VAL,
                TOK_RPAREN,      
                TOK_LPAREN} tok_t;

typedef enum {
                 UNDEFTOKEN=-1,
                 EOL,
                 PLUS,
                 MINUS,
                 MULTIPLY,
                 DIVIDE,
                 LABEL,
                 LITERAL,
                 LPAREN,
                 RPAREN,
                 PC,
                 MODULO,
                 TILDE,
                 EQUAL,
                 LESSTHAN,
                 GREATERTHAN,
                 GEQUAL,
                 LEQUAL,
                 SHIFTR,
                 SHIFTL,
                 BINOR,
                 BINEOR,
                 BINAND,
                 CHAR,
                 SPACE,
                 NOTEQUAL,
                 LOGICALNOT} ptok_t;

/* Error checking bit masks */
#define         EC_OUTER_PAREN          0x01
#define         EC_UNUSED_ARGBYTES      0x02
#define         EC_DUP_LABELS           0x04
#define         EC_NON_UNARY            0x08

/* Object file types */
typedef enum    {INTEL_OBJ=0, 
                 MOSTECH_OBJ, 
                 MOTOROLA_OBJ, 
                 BINARY_OBJ,
                 INTELWORD_OBJ} obj_t;


/* Define just the NOP rule here (since it is needed by modules other than 
 * rules.c).  The rest are local to rules.c.                           
 */
#define NOTOUCH          (('N' << 8) | 'O')



/* Prototypes */

/* tasmmain.c */
int	  main       (int argc, char **argv );
void      tasmexit   (int exit_code );

/* tasm.c */
int     tasm         ( int argc, char **argv );
void    errprt       ( char *err_mess );
void    listprt      ( char *buf );
int     isequate     ( void );
void    free_all     ( void );
ubyte   getop        ( pc_t pcx);

/* str.c */
int     search       ( char *p , char *s );
void    replace      ( char *target , char *psearch , char *preplace );
void    stoupper     ( char *s );
void    crush        ( char *s );
int     remquotes    ( char *s );
int     strget       ( char *ptarget , char *psource );
ulong   lhex_to_bin  ( char *hex_string );
ushort  hex_to_bin   ( char *hex_string );
ushort  hex_val      ( char hex_digit );
void    sort_labels  ( void );
int     find_comment ( char s []);
int     inquotes     ( char *s , int pos );

/* parse.c */
int     parse ( char   *buf, 
                char   *label, 
                char   *inst, 
                dir_t  *directive,
                ulong  *op_code, 
                ushort *obytes, 
                ushort *abytes, 
                ushort *argc, 
                char   **argv ,
                ulong  *argval );

/* macro.c */
void    macro_expand    ( char *src , char *target );
int     macro_get_index ( char *macro_name);
void    macro_save      ( char *macro_name );
void    macro_append    ( char *s );
void    macro_free      ( int freeAll );

expr_t  val             ( char *expr_buf );
void    read_table      ( char *pn );
void    add_instruction ( char *s );
void    errlog          ( char *err_mess , errout_t output_mode );

/* rules.c */
void    rules(
             ushort           modop,
             ulong            *opcode,
             ushort           *obytes,
             ushort           *abytes,
             ulong            *argval,
             pc_t             pcx,
             ushort           argc,
             char             **argv,
             ubyte            shift,
             ulong            bor);

/* lookup.c */
dir_t   dir_lookup  ( char *directive );
error_t inst_lookup(char    *inst, 
                    char    *args,  
                    ulong   *op_code, 
                    ushort  *obytes,
                    ushort  *abytes,
                    ushort  *modop,
                    ubyte   *shift,
                    ulong   *bor,
                    ushort  *argc,
                    char    **argv);
void    save_label ( char *label , expr_t val );
int     find_label ( char *label );

/* wrtobj.c */
void    wrtobj     ( pc_t  firstpc, pc_t  lastpc, ushort bytes_per_rec);
void    wrtlastobj ( obj_t obj_type );

/* fname.c */
void    fname_push  ( char * fname );
void    fname_pop   ( void );
char   *fname_get   ( void );


/* That's all folks */

