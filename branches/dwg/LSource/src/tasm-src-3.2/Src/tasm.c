/****************************************************************************
 *  $Id: tasm.c 1.17 2001/10/23 01:43:20 toma Exp $
 ****************************************************************************
 *
 * Table Driven Absolute Assembler.
 *
 * Copyright 1985-1995 Speech Technology Incorporated.
 * Copyright 1997-2001 Squak Valley Software
 * Restrictions apply to the duplication of this software.
 * See the COPYRIGH.TXT file on this disk for restrictions.
 *
 *  Thomas N. Anderson
 *  Squak Valley Software
 *  837 Front Street South
 *  Issaquah, WA  98027
 *
 *      10/01/85 Version 2.0    First version with external table def files.
 *
 *      01/01/86 Version 2.1    Added '*=' and '=' directives as
 *                              alternatives to .ORG and .EQU (for
 *                              more complete MOS Technology compatibility).
 *
 *                              Also enhanced parsing algorithm so it can
 *                              deal with more than one variable expression.
 *
 *      02/02/86                Added -d option
 *
 *      02/14/86 Version 2.2    Modified so instruction set definition
 *                              tables don't need to be compiled in.
 *                              Added 8051 tables.
 *                              Increased the number of labels allowed.
 *
 *      03/31/87 Version 2.3    Fixed bug that prevented location 0xffff
 *                              from being used and written to object file.
 *                              Most changes in wrtobj() and pr_hextab().
 *
 *      05/01/87 Version 2.4    Added multiple byte opcode support.
 *                              Added shift/or operation capability to
 *                              args from instruction set definition table.
 *                              Converted to MS C version 3.0
 *                              Added hashing to instruction set table
 *                              lookups to speed up.
 *
 *      11/01/87 Version 2.5    Added DB and DW directives.
 *                              Added escape capability in TEXT strings.
 *                              Fixed inst_lookup function to treat the
 *                              multiple wild card case a little better
 *                              ( non-terminal wildcards can end in '),'
 *                              to support some of the Z80 syntax
 *                              requirements.
 *                              Added 8080/8085 and Z80 tables.
 *                              Added sorting on label table.
 *                              Increased size of read buffer.
 *                              Speed up.
 *                              Added DEFCONT (macro continuation) directive.
 *
 *      1/1/88 Version 2.6      Converted to Microsoft C 5.0 compiler.
 *                              Added 6805 table (and related modops).
 *                              Added Z80 bit modop.
 *                              Minor speed up.
 *                              Fixed bug that enters infinite loop
 *                              when a macro invocation has no closing
 *                              paren.
 *                              Added some three arg MODOPs.
 *
 *      8/15/88 Version 2.6.1   Added CODES/NOCODES directives
 *                              Fixed bug preventing directives in multiple
 *                              statement lines.
 *                      2.6.2   Added COMB_NIBBLE and COMB_NIBBLE_SWAP MODOPS
 *
 *      2/1/89  Version 2.7
 *                              Removed ad hoc heap and now use malloc()
 *                              Added MSFIRST and LSFIRST directives.
 *                              Added EXPORT directive.
 *                              Added symbol table file (-s flag).
 *                              Added NSEG/CSEG/BSEG/DSEG/XSEG directives
 *                                and the SYM/AVSYM directives to support
 *                                the Avocet avsim51 simulator.
 *                              Added support for TMS320.
 *                              Added -r flag to set read buffer size.
 *                              Converted expression evaluation from 
 *                              signed 16 bit to signed 32 bit (enabling
 *                              apparent ability to use signed or unsigned
 *                              16 bit values).
 *      
 *      4/20/89  Version 2.7.1  Return 0x20000 for undefined labels so that
 *                                (label+x) type stuff won't confuse zero
 *                                page addressing.
 *                              Added duplicate label error message on pass 1.
 *      6/20/89  Version 2.7.2  Improved macro expansion capability.
 *                                No expansion in comments.
 *                                Context sensitive identifiers.
 *                                Revised exit codes.
 *      6/27/89  Version 2.7.3  Added -a flag for strict error checking:
 *                                (1) No outer parens around expressions.
 *                                (2) Error message if unused argbytes remain 
 *                                (3) Duplicate labels
 *                              Fixed so ']' can terminate expressions.
 *                              Removed parse() from tasm.c
 *
 *      8/19/89  Version 2.7.4  Added Motorola hex object format
 *                              Fixed bug that complained when \ immediately
 *                                followed a opcode with no args.
 *                              Slightly improved error reporting (Errorbuf).
 *
 *      10/31/89 Version 2.7.5  Added TMS7000 support.
 *                              Fixed argv[] bug (only dimensioned to 10 in 
 *                              pass1.
 *
 *      12/23/89 Version 2.7.6  Improved handling of % (modulo vs 
 *                              binary prefix ambiguity)
 *                              Fixed list so lines with more than  
 *                              6 bytes go on second line
 *
 *      03/04/90 Version 2.7.7  Fixed bug that left off 2 bytes if ORG
 *                              went backwards and all 64K was used.
 *                              Added a command line option to ignore
 *                              case on labels.
 *                              Added a couple MODOP rules for TMS9900.
 *                              Allow double quoted text strings for BYTE.
 *
 *      04/15/90 Version 2.7.8  Fixed expression evaluator bug (paren popping)
 *                              and changed expression evaluator to a more
 *                              conventional left to right evaluation 
 *                              order.
 *                              Added TURBOC ifdef's (from Lance Jump).
 *
 *      08/20/90 Version 2.8    Primarily a documentation update.
 *                              Added error check for AJMP/ACALL off of
 *                              current 2K block (8051).
 *
 *      10/15/90 Version 2.8.1  Minor speed up in label searching.
 *                              Fixed word addressing for TMS320 
 *
 *               Version 2.8.2  Local labels.
 *                              More label table format options (long form
 *                              suppress local labels).
 *
 *      11/30/90 Version 2.8.3  Turbo C conversion
 *                              DS directive added.
 *
 *      12/27/90 Version 2.8.4  Added COMMENTCHAR directive to change the
 *                              comment indicator in the first column.
 *                              This was done to support the assembly
 *                              files from the small C compiler (sc11)
 *                              for the 68CH11.
 *
 *      02/14/91 Version 2.8.5  Added LOCALLABELCHAR directive to 
 *                              override the default "_" as the 
 *                              prefix for local labels.
 *
 *      03/18/91 Version 2.8.6  Added some MODOPs in support of TMS320C25
 *
 *      04/20/91 Version 2.8.7  Fixed sign extend bug in CSWAP modop.
 *                              Increased MAXLABS to 10000 for big version.
 *
 *      05/05/91 Version 2.8.8  Fixed pointer bug in debug output in 
 *                              sort_labels().
 *
 *      05/20/91 Version 2.9    TMS320C25 table along with some MODOP
 *                              enhancements for it.
 *                              TASMTABS.DOC updated (but not TASM.DOC)
 *
 *      08/09/91 Version 2.9.1  Nested conditionals.
 *
 *      04/01/92 Version 2.9.2  Fixed long label clobber problem in
 *                              find_label() and save_label.  Syntax
 *                              errors could result in a comment line
 *                              after an instruction being lumped together
 *                              with a label resulting in a long label.
 *                              The label functions were not testing for 
 *                              labels that exceed the specified size.
 *                              Added CHK directive.
 *                              Added REL3 MODOD to support uPD75xxx.
 *                              Delinting and more ANSIfication.
 *                              Modifications due to feedback from B Provo:
 *                                Added FILL directive.
 *                                Allow multiple labels for EXPORT directive.
 *                                Allow address with END directive.
 *                              TASM.DOC update
 *
 *      11/25/92 Version 2.9.3  Improved error reporting for mismatched quotes.
 *                              Disallow the single quote character constants.
 *                              Convert to BCC++ 3.1
 *                              Provide filename,linenum on all error messages.
 *                              Modify format of error messages for 
 *                                  compatibility with BRIEF.       
 *                              Added ECHO directive to send output to console
 *                              Performance improvements in macro processing.
 *                              "Type Safe" conversion (compatible with C++)
 *                              Improved error reporting for imbalanced ifdefs.
 *
 *                                     
 *      01/29/93 Version 2.9.4  Windows support.
 *                              Added rules for 8096 (I1,I2,I3,I4,I5,I6).
 *                              Generate error message on forward reference 
 *                                  in EQUate statements.
 *                              Eliminated -a option for enabling the detection
 *                                  of branches of 2K page for 8051.  This 
 *                                  is now built into the table.
 *                              Allow white space in double quotes for BYTE
 *                              directive.  This previously worked for TEXT,
 *                              but not BYTE.
 *                              Fixed defect with Z80 4 byte indexed instructions
 *                              Fixed macro defect.  If the macro definition has
 *                              args but the invocation does not some garbage
 *                              gets expanded into the source line.
 *                              Z80 OTDR opcode was incorrect.
 *                              Z80 IN0/OUT0/INA instructions did not require
 *                              the parens around the args.       
 *
 *      10/24/93 Version 3.0    Update the DOCs. TASM.EXE is functionally
 *                              unchanged.
 *
 *      02/20/94 Version 3.0.1  Multiple macros on the same line
 *                                -c with >8000h bytes used goes bonkers
 *                              waddr correction for BLOCK/DS 
 *                              Allow escaped quotes in TEXT.
 *
 *      04/20/97 version 3.1    8048 conditional jump off page warning
 *                              Define macros on both passes so ifdef
 *                                processing will work correctly for
 *                                both passes.
 *                              Fixed -y (timing flag) to use total
 *                                lines and not just lines of the 
 *                                first file.
 *                              Allow white space before # directives.
 *                              LINUX support.
 *                              Provide protected mode version with 
 *                                increased maximums for most things.
 *                              Provide logical NOT unary operator.
 *                              Fix problems with (inwork) 8096 rules
 *                                and make the 8096 table part of the 
 *                                official distribution.
 *                              Fix Min_pc calc (fails if .org is missing).
 *                              Eliminate non-ANSI I/O. 
 *                              Object format: intel hex w/ word addresses.
 *              
 *      02/20/99 version 3.1.1  Added rules for ST7 MCU.
 *                              Added support for TASMERRFORMAT env variable.
 *
 *      02/01/00 version 3.2    Increased LINESIZ to 512 to enable use of
 *                              longer macros.
 *                              Eliminated -r command line option (to set 
 *                              read buffer size).  Obsolete.
 *                              Improved list() function to put a max of 
 *                              six bytes per line to avoid problems with
 *                              directives that generate large blocks of 
 *                              object code (i.e. .FILL).
 *                              Built as a 32 bit version using MS C++ 6.0
 *
 *  Invoked as:
 *
 *  tasm [-flags] source_file [object_file [list_file [exp_file [sym_file]]]]
 *
 *  Where 'flags' can be:
 *
 *  -<nn>   Specify version  -48 for 8048
 *                           -65 for 6502
 *                           -51 for 8051
 *                           -85 for 8080/8085
 *                           -80 for Z80
 *                           -05 for 6805
 *                           -3210 for TMS32010
 *                           -3225 for TMS320C25
 *                           -68 for 6800/6801
 *                           -70 for TMS7000
 *                           -96 for 8096
 *
 *  -t<tab> Alternate form of above.
 *  -a      Assembly control (error checking)
 *  -c      Cause object file to be written as a contigous block
 *                  of code
 *  -d      Define macro label
 *  -e      Show source lines after macro expansion in listing.
 *  -f<xx>  Fill entire memory space with 'xx' (in hex)
 *  -g<x>   Obj type (0=intel, 1=mostech, 2=motorola, 3=bin, 4=intel word)
 *  -h      Produce a hex table of the assembled code in the listing
 *  -i      Ignore case for labels.
 *  -l[al]  Produce a label table in the listing
 *  -m      Produce object in MOS Technology hex format
 *  -b      Produce object in binary (.COM) format
 *  -p      Page the listing file
 *  -q      Quiet, disable the listing file
 *  -s      Symbol table
 *  -o<bb>  Set number of bytes per object record
 *  -x      Enable extended instruction set (if any)
 *  -y      Enable timing.
 *  -z      Turn debugging on (enables DEBUG statements).
 *
 */

#include        "tasm.h"
#include        <stdarg.h>

#ifdef T_MEMCHECK
#include        <memcheck.h>
#endif

#define         DEFAULT_MODULE  "noname"
				 /* Maximum number of file names on the command line */
#define         MAX_NAMED_FILES  5

//static char *id_tasm_c = "$Id: tasm.c 1.17 2001/10/23 01:43:20 toma Exp $";

/* define all legal directives */

char    *Dirtab[NDIR]   = {
	"BYTE",
	"ORG",
	"EQU",
	"END",
	"TEXT",
	"EJECT",
	"WORD",
	"LIST",
	"NOLIST",
	"INCLUDE",
	"PAGE",
	"NOPAGE",
	"TITLE",
	"IFDEF",
	"ENDIF",
	"IFNDEF",
	"ELSE",
	"DEFINE",
	"IF",
	"=",            /* same as EQU */
	"*=",           /* same as ORG */
	"$=",           /* same as ORG */
	"ADDINSTR",
	"BLOCK",        /* Reserve bytes                    */
	"DS",           /* same as BLOCK                    */
	"DB",           /* same as BYTE                     */
	"DW",           /* same as WORD                     */
	"DEFCONT",      /* DEFINE CONTINUATION              */
	"CODES",        /* Turn on op codes in listing      */
	"NOCODES",      /* Turn off op codes in listing     */
	"SET",          /* redefine value of label          */
	"EXPORT",       /* Export this label and value to file */
	"LSFIRST",      /* LS byte first                    */
	"MSFIRST",      /* MS byte first                    */
	"NSEG",         /* Null Segment                     */
	"CSEG",         /* Code Segment                     */
	"BSEG",         /* Bit  Segment                     */
	"XSEG",         /* Extern Segment                   */
	"DSEG",         /* Data Segment                     */
	"SYM",          /* Write symbol file                */
	"AVSYM",        /* Write symbol file in AVOCET format */
	"UNDEF",        /* Undefine a macro                 */  
	"MODULE",       /* New module starts here           */
	"COMMENTCHAR",  /* Character to indicate start of comment */
	"LOCALLABELCHAR",/* Character prefix for local labels */
	"CHK",          /* Compute checksum and deposit here */
	"FILL",         /* Fill memory                       */
	"ECHO"          /* Echo string to console (stderr)   */
		};

/* Label tables */
ushort   Nlab;                   /* number of labels in table    */
LABTAB  *Labtab[MAXLAB];        /* Pointers to Label data       */

ushort  Lhash[MAXLHASH];        /* label hash table             */

OPTAB   *Optab[MAXINSTR];
REGTAB  *Regtab[MAXREG];

ushort  Ihash[MAXIHASH];        /* instruction hash table */

ushort  Num_instr = 0;
ushort  Num_reg   = 0;
int     Seg       = NULL_SEG;

/* last record to write into obj file.  Indexed by obj format */
/* no such record if binary format selected */
obj_t   Obj_format        = INTEL_OBJ;

static  int     Avsim51           = FALSE;
static  int     Blockobj          = FALSE;
static  int     Conditional_level = 0;
static  dir_t   Directive         = NOTDIR;
static  char    *Filenames[MAX_NAMED_FILES];
static  int     Include_level     = 0;
static  int     Listflag          = TRUE;
static  int     Long_label_list   = FALSE;
static  int     Nocodes           = FALSE;
static  int     No_end            = TRUE;
static  ushort  Nobj_bytes_per_rec= 0x18;
static  int     Nexport           = 0;
static  int     Page_linenumber   = 0;
static  int     Pagesize          = PAGESIZE;
static  int     Page_num          = 0;
static  int     Pageflag          = FALSE;
static  int     Show_expanded     = FALSE;
static  int     Total_lines       = 0;
static  char    Title[LINESIZE]   = {"Speech Technology Incorporated.   "};
static  int     Write_symtab;
static  FILE    *Fp_list;
static  int     Ls_first          = TRUE;       /* Arg LS first                     */

int     AutoLabelID       = 7;
int     Skip              = FALSE;
int     Wordsize          = 1;          /* one byte per word default        */
int     No_arg_shift      = FALSE;      /* Disable the shift/or on arg values */
int     Ols_first         = TRUE;       /* Opcodes LS first                 */
int     Err_check         = EC_UNUSED_ARGBYTES | EC_DUP_LABELS;
char    Wild_char         = '*';        /* Wild character in opcode tables  */
char    Local_char        = '_';        /* Default first char for local labels */
char    Reg_char          = '!';        /* Wild for reg set entry in table  */
char    Comment_char1     = ';';        /* First char for comments          */
char    Comment_char2     = ';';        /* First char for embedded comments */
int     Ignore_case       = FALSE;      /* Ignore case of labels            */
int     Use_argvalv       = FALSE;      /* Use the Argvalv vector for args  */
ushort  Debug             = 0;
ushort  Class_mask        = 1;  /* Default instruction class mask.
								 * Bit 0 on enables basic instruction set.
								 * Other bits enable extended instructions,
								 *  if any */


char    Module_name[LABLEN]  = {DEFAULT_MODULE};



char    Banner[LINESIZE]  = {"TASM Assembler.         "};

char    Part_num[8];

char    *Expr;

ubyte   Argvalv[8];

		pc_t    Pc;
		pc_t    First_pc;
static  pc_t    Last_pc;
static  pc_t    Max_pc;
static  pc_t    Min_pc;
		pc_t    END_Pc;         /* Option addr provided with END directive */

int     Line_number;
line_t  Linetype;
pass_t  Pass;
error_t Errorno;
int     Codegen;

char    Errorbuf[LINESIZE];

/* file descriptors */
//static  int     Fd_object;
int		Fd_object;

FILE           *Fp_object;

/* File names */

int     Errcnt;
static char    *Errmess[] =    {"",
						 "unrecognized directive.           ",
						 "unrecognized instruction.         ",
						 "unrecognized argument.            ",
						 "label value misalligned.          ",
						 "label table overflow              ",
						 "heap overflow on label definition ",
						 "no such label yet defined.        " };


/* Declare pointer to the object code buffer  */
static unsigned char HUGE  Opbuffer[MAXMEM+1L];
static opbuf_t             Opbuf = (opbuf_t) Opbuffer;     /*lint !e643 */

/* Static Functions */
static  pc_t    baddr ( pc_t pc );
static  void    close_files ( void );
static  ubyte   compute_checksum ( pc_t start_addr, pc_t end_addr );
static  void    eject ( void );
static  void    export ( void );
static  void    list ( int linenumber , pc_t pc , ushort nbytes , char *buf );
static  int     open_files ( char *files [], int filecnt );
static  void    pass1 ( char *source_file );
static  void    pass2 ( char *source_file );
static  void    pr_hextab ( pc_t pc_lo , pc_t pc_hi );
static  void    pr_labels ( int show_no_locals );
static  int     process_conditional(dir_t directive, char * arg);
static  pc_t    waddr ( pc_t pc );
static  void    write_symbols ( void );
static  void    putop ( pc_t pc, ubyte op ); 

//	extern unsigned _stklen = 60000U;

int
tasm(int argc,char *margv[])
{
	int     jj;
	int     filecnt;
	int     arg;
	char    *files[MAX_NAMED_FILES];
	char    errbuf[LINESIZE];
	char    option_buf[LINESIZE];
	char    *p;
	char    *s;
	clock_t start_time;
	int     time_flag;
	char    *argv[MAXARGS];
	int     objformat;
	int     printhextab;
	int     printlabels;
	int     show_no_locals    = TRUE;       /* Don't list local labels */

	extern int Num_macros_predefined;
	extern int Num_macros;



	start_time = clock();

	/* Initialize the file pointer array */
	filecnt = 0;
	for (jj = 0; jj < MAX_NAMED_FILES; jj++ ) files[jj] = NULL;

	/* Set defaults for options */
	printlabels = FALSE;
	printhextab = FALSE;
	Blockobj    = FALSE;
	
	Codegen           = FALSE;
	Show_expanded     = FALSE;
	Nocodes           = FALSE;
	time_flag         = FALSE;
	Write_symtab      = FALSE;
	Skip              = FALSE;
	Conditional_level = 0;

	/* Copy args received from command line (in margv) to argv since
	 * we need to add to the end of the list and it is not
	 * safe to add to the end of the vector received from the startup
	 * routines.
	 */
	argv[0] = 0;          /* Just to keep lint quiet */
	for(jj = 0; jj < argc; jj++)
	{
		argv[jj] = margv[jj];
	}

	/* Add options from TASMOPTS environment variable if it is defined */
	if((p = getenv("TASMOPTS")) != NULL)
	{
		s = option_buf;
		while(*p)
		{
			argv[argc++] = s;
			while((!isspace(*p)) && (*p != '\0'))*s++ = *p++;
			*s++ = '\0';
			while(isspace(*p))p++;
		}
	}

	/* Get option flags and file names */
	for(arg = 1; arg < argc; arg++)
	{

		/* if 1st character of arg is '-' then it is an option flag*/
		if (*argv[arg] == '-'){

			switch (*(argv[arg]+1)){
			case 'z':       /* Debug */
			case 'Z':
				Debug = TRUE;
				break;

			case 'e':       /* print a label table */
			case 'E':
				Show_expanded = TRUE;
				break;

			case 's':       /* write a symbol table */
			case 'S':
				Write_symtab = TRUE;
				break;

			case 'l':       /* print a label table */
			case 'L':
				printlabels = TRUE;
				/* examine following characters for more selections */
				p = argv[arg]+2;
				while(*p){
					if(*p == 'l') Long_label_list = TRUE;
					if(*p == 'a') show_no_locals  = FALSE; 
					p++;
				}
				break;

			case 'h':       /* print a hex table of the code */
			case 'H':
				printhextab = TRUE;
				break;

			case 'i':       /* print a hex table of the code */
			case 'I':
				Ignore_case = TRUE;
				break;

			case 'f':       /* Set the memory fill byte */
			case 'F':
				/* fill opcode array with specified byte */
				{
					ubyte fillbyte;
					pc_t  pc;

					/* Use the hex value, if provided */
					if((*(argv[arg]+2)) != '\0')
						fillbyte = (ubyte)hex_to_bin(argv[arg]+2);
					else
						fillbyte = 0;

					for(pc = 0; pc <= MAXMEM; pc++) putop(pc,fillbyte);
				}
				break;

			case 'o':       /* Set the number of object bytes per */
			case 'O':       /*    object record */
				if((*(argv[arg]+2)) != '\0')
				   Nobj_bytes_per_rec = hex_to_bin(argv[arg]+2);
				break;

			case 'c':
			case 'C':
				/* set Blockobj flag so obj file is written
						as a contiguous block */
				Blockobj = TRUE;
				break;

			case 'g':
			case 'G':
				/* set obj output to indicated format */
				if((*(argv[arg]+2)) != '\0')
				{
						objformat = atoi((argv[arg]+2));
						if((objformat < 0) || (objformat > 4))
							Obj_format = INTEL_OBJ;
						else
							Obj_format = (obj_t)objformat;

				}
				break;

			case 'm':
			case 'M':
				/* set obj output to MOS Tech format */
				Obj_format = MOSTECH_OBJ;
				break;

			case 'b':
			case 'B':
				/* set obj output to binary format */
				Obj_format = BINARY_OBJ;
				/* implies contiguous output */
				Blockobj = TRUE;

				break;

			case 'p':
			case 'P':
				/* set listing file paging on */
				Pageflag = TRUE;
				if((*(argv[arg]+2)) != '\0')
				{
					Pagesize = atoi((argv[arg]+2));
					if((Pagesize < 5) || (Pagesize > 256))
							Pagesize = PAGESIZE;
				}
				break;

			case 'q':
			case 'Q':
				/* Quite, turn listing file off */
				Listflag = FALSE;
				break;

			case 'x':
			case 'X':
				/* Enable extended instruction set (if any).
				 * If there is a hex digit after the flag then
				 *      use it to set the Class_mask.
				 *      Bits in the class mask enable classes
				 *      of instructions that have the same bit
				 *      set in their class field.
				 */
				if((*(argv[arg]+2)) != '\0')
						Class_mask = hex_val(*(argv[arg]+2));
				else
						Class_mask = 0xff;
				break;

			case 'a':
			case 'A':
				/* Turn on selected strict error checking   
				 */
				if((*(argv[arg]+2)) != '\0'){
					Err_check  = hex_to_bin(argv[arg]+2);
				}
				else
					Err_check  = 0xff;
				break;

			case 'd':
			case 'D':
				/* define a macro */
				macro_save(argv[arg]+2);
				break;

			case '0':
			case '1':
			case '2':
			case '3':
			case '4':
			case '5':
			case '6':
			case '7':
			case '8':
			case '9':
				/* read instruction set definition table */
				strcpy(Part_num, argv[arg]+1);
				read_table(argv[arg]+1);
				break;

			case 't':
			case 'T':
				/* read instruction set definition table.  This is
				 * an alternate form of the above case where the table
				 * option is always indicated by a numeric string.
				 * If a table for the F8 existed and was in TASMF8.TAB
				 * then 'tasm -tf8'    could be used to invoke it.
				 */
				strcpy(Part_num, argv[arg]+2);
				read_table(argv[arg]+2);
				break;

			case 'y':
				time_flag = TRUE;
				break;

			default:
				sprintf(errbuf,
				"tasm: unknown option flag = %s\n",argv[arg]);
				errprt(errbuf);

				break;
			}
		}
		else{
			/* No '-' so take arg as a file name.
			 * Reject if it is shorter then 3 bytes.  This is to
			 * protect against mistakes in the options like "- b"
			 * which would result in "b" being interpreted as the 
			 * source file and then the real source file would be
			 * taken as the list file which would be opened and truncated.
			 */
			if(strlen(argv[arg]) > 2){
				files[filecnt++] = argv[arg];
			}
			else{
				sprintf(errbuf, 
			   "tasm: file name too short (possibly garbled option flag): %s\n",
						argv[arg]);
				errprt(errbuf);
			}
		}
	}

	/* Show the version of the source file */
//	DEBUG("%s\n", id_tasm_c );

	errprt(Banner);
	errprt("  Version 3.2 September, 2001.\n");
	errprt(
	  " Copyright (C) 2001 Squak Valley Software\n");

	/* open files */
	if (open_files(files,filecnt) != SUCCESS)
	{
		free_all ();
		tasmexit(EXIT_FILEACCESS);
	}


	/* initialize things */
	Pc              = 0;
	Max_pc          = 0;
	Min_pc          = MAXMEM;
	Nlab            = 0;
	Errcnt          = 0;
	No_end          = TRUE;
	Num_macros_predefined = Num_macros;

	strcpy(Module_name, DEFAULT_MODULE);      /* set to default */

	/* Write header to list file */
	if(Pageflag)eject();

	/* Do the first pass.  Build the symbol table.*/
	Pass = FIRST;
	pass1(SRC_FN);

	sort_labels();

	errprt("tasm: pass 1 complete.\n");


	/* pass 2.  Generate code. */
	Pc                = 0;
	First_pc          = Pc;
	Pass              = SECOND;
	Conditional_level = 0;
	Skip              = FALSE;   /* Always start with skip off.  
								  * This protects from an imbalanced
								  * conditional leaving skip
								  * on at the end of pass 1.
								  */
	/* Set the number of macros back to just the ones 
	 * defined at invocation. */
	macro_free (FALSE);

	strcpy(Module_name, DEFAULT_MODULE);      /* Reset to default */
	pass2(SRC_FN);

	/* assembly complete.  Now take care of any final things like
	 *   generating symbol table, writing last of obj file, etc. 
	 */

	/* If we get to this point and are still skipping or if we
	 * are still at a non-zero conditional level then we have a 
	 * problem.
	 */
	if ((Skip == TRUE) || (Conditional_level > 0))
	{
		Skip = FALSE;
		strcpy(Errorbuf,"");
		errlog("Imbalanced conditional.", ALWAYS);

	}


	/* if Blockobj flag was set then write the entire obj file now
	 *   as one big block.
	 */
	if(Blockobj) wrtobj( Min_pc, Max_pc+1, Nobj_bytes_per_rec);

	/* write last object record */
	wrtlastobj(Obj_format);

	/* generate label table if enabled*/
	if(printlabels) pr_labels(show_no_locals);

	/* generate hex opcode table if enabled */
	if(printhextab) pr_hextab( Min_pc, Max_pc+1);

	/* If some labels have been designated for export, then write them
	 * to the export file */
	if(Nexport) export();

	/* Write a symbol table to file */
	if(Write_symtab) write_symbols();


	if(No_end){
		strcpy(Errorbuf,"");
		errlog("No END directive before EOF.      ", ALWAYS);
	}

	errprt("tasm: pass 2 complete.\n");

	sprintf(errbuf,"tasm: Number of errors = %d\n",Errcnt);
	errprt(errbuf);
	listprt(errbuf);

	close_files();

#ifdef NEVER
	if(time_flag)
	{
		const clock_t ticksPerSec=(clock_t)CLK_TCK;
		clock_t et_ticks;
		clock_t et_secs;
		clock_t et_hunds;

		/* Compute Elapsed time in seconds and hundredths of seconds.
		 * Avoid using floating point so we don't bloat TASM.
		 */
		et_ticks = (clock() - start_time);
		et_secs  =   et_ticks / ticksPerSec;
		et_hunds = ((et_ticks % ticksPerSec) * 100)/ticksPerSec;

		if ( et_ticks > 0 )
		{
			sprintf(errbuf,"Elapsed time = %ld.%02ld secs  lines = %d   lines/sec = %ld\n",
			   et_secs, et_hunds, Total_lines,(Total_lines*ticksPerSec)/(et_ticks));
		}
		else
		{
			sprintf(errbuf,"Elapsed time = 0 secs  lines = %d\n",  Total_lines);
		}
		errprt(errbuf);
	}
#endif

	/* Free all the malloc'd memory */
	free_all();

	if(Errcnt){
		return (EXIT_ASMERRORS);
	}

	return(EXIT_NORMAL);

	
}


/**********************************************************************/
/*
 * Function: free_all()
 *
 * Description:
 *    Free all memory allocated for any purpose.
 */
/**********************************************************************/

void
free_all()
{
	unsigned int i;
	extern char Emptystring[];

	/* Free all the macros */
	macro_free (TRUE);

	/* Free all the labels */
	for(i=0; i< Nlab; i++)
	{
		free (GETLABTAB(i));
	}

	/* Free the instruction set table */
	for(i=0; i< Num_instr; i++)
	{
		free(Optab[i]->instruction);
		if(Optab[i]->args != Emptystring) free(Optab[i]->args);
		free(Optab[i]);
	}

	for(i=0; i< Num_reg; i++)
	{
		if (Regtab[i] != NULL) free(Regtab[i]);
	}

	/* Free the file names */
	for(i = 0; i < MAX_NAMED_FILES; i++)
	{
		if(Filenames[i] != NULL) free (Filenames[i]);
	}
}

/**********************************************************************/
/*
 * Function: pass1()
 *
 * Description:
 *     Do the first pass of assembly.
 *     Just build the label table.
 */
/**********************************************************************/

static void
pass1(char *source_file)
{
	ushort  nbytes;         /* total number of bytes */
	ushort  obytes;         /* number of opcode bytes */
	ushort  abytes;         /* number of argument bytes */

	char    label[LABLEN];
	char    inst[LABLEN];
	ulong   op_code;
	ulong   argval;
	ushort  argc;
	char    *argv[MAXARGS];
	char    errbuf[LINESIZE];

	char    buf[LINESIZE];
	char    sbuf[LINESIZE];
	char    *pbuf;
	int     local_line_number;
	int     i;
	dir_t   directive;
	char    include_filename[PATHSIZE];
	int     starting_conditional_level;
	FILE    *fp_source;

	extern  int     Num_macros;

	DEBUG ("pass1: open %s\n ",source_file);

	starting_conditional_level = Conditional_level;

	fp_source = fopen( source_file, "r");
	if(fp_source == NULL)
	{
		sprintf(errbuf,"tasm: source file open error on %s\n",source_file);
		errprt(errbuf);
		tasmexit(EXIT_FILEACCESS);
	}

	fname_push( source_file );    /* Save the filename for errlog */

	Include_level++;
	Line_number = local_line_number = 0;

	while(fgets( sbuf, LINESIZE-1, fp_source) != NULL)
	{
		Line_number = (++local_line_number);
		Total_lines++;

		if(Num_macros > 0){
			macro_expand(sbuf,buf);
			pbuf = buf;
		}
		else{
			pbuf = sbuf;
		}

		do{
			/* Parse each line to keep the PC up to date so the label
				table can be built with proper values for each label */
			pbuf += parse(pbuf,label,inst,&directive,&op_code,&obytes,
						  &abytes,&argc,argv,&argval);
			Directive = directive;     /* Save global for EQU detection */
			nbytes = obytes + abytes;

			if(Errorno == ER_NOERR){

				/* first check for 'ifdef', ifndef, else or 'endif'
				and set skip flag accordingly */
				if(Linetype == DIRECTIVE){
					Skip = process_conditional(directive, argv[0]);
				}

				if(Skip == FALSE){

					/* If this line is an org directive then set
					 * the PC accordingly
					 */
					if(Linetype == DIRECTIVE){
						switch(directive){
						case ORG:
							Pc = (pc_t)val(argv[0]);
							break;
						case TITLE:
							strcpy(Title,argv[0]);
							break;
						case DEFINE:
							macro_save(argv[0]);
							break;
						case DEFCONT:
							macro_append(argv[0]);
							break;
						case ADDINSTR:
							add_instruction(argv[0]);
							break;


						case BLOCK:
						case DS:
						case FILL:       /* data assigned on pass 2 */
							break;

						case NSEG:  Seg = NULL_SEG; break;
						case CSEG:  Seg = CODE_SEG; break;
						case BSEG:  Seg = BIT_SEG ; break;
						case XSEG:  Seg = EXTD_SEG; break;
						case DSEG:  Seg = DATA_SEG; break;

						case SYM:
							Write_symtab = TRUE;
							if(argc > 0)strcpy(SYM_FN,argv[0]);
							break;
						case AVSYM:
							Write_symtab = TRUE;
							Avsim51      = TRUE;
							if(argc > 0)strcpy(SYM_FN,argv[0]);
							break;

						case MODULE:
							strcpy(Module_name, argv[0]);
							(void)remquotes(Module_name);
							break;

						case COMMENTCHAR:
							/* Override default comment character.
							 * Assume first char of arg is a quote.
							 */
							Comment_char1 = argv[0][1];
							break;

						case LOCALLABELCHAR:
							/* Override default local label prefix character.
							 * Assume first char of arg is a quote.
							 */
							Local_char = argv[0][1];
							break;

						default:
							/* This is OK */
							break;
						}
					}
					/* if there is a label on this line then put
					 * it in the table along with its value */
					if(label[0] != '\0'){
						if(Nlab < MAXLAB){
							switch(Linetype){
							case BLANK:
							case INSTRUCT:
								save_label(label, (expr_t)Pc);
								break;

							case DIRECTIVE:
								switch(directive){
								case EQU:
									/* if this is an EQU directive then
									 *  assign label value.
									 */
									save_label(label, val(argv[0]));
									break;

								case SET:
									if((i = find_label(label)) != FAILURE)
										GETLABTAB(i)->val = val(argv[0]);
									else{
										sprintf(errbuf,
										  "label must pre-exist for SET.  %s", 
											label);
										errlog(errbuf, ALWAYS);
									}
									break;

								default:
									save_label(label, (expr_t)Pc);
									break;

								}
								break;

							default:
								/* OK */
								break;
							}
						}
						else{
							sprintf(Errorbuf,"MaxLab=%d",MAXLAB);
							errlog(Errmess[(int)ER_TAB_OVERFLOW], ALWAYS);
						}
					} /* end if(label) */

					/* increment the program counter */
					if((Linetype == DIRECTIVE) && 
						((directive == BLOCK) || (directive == DS)))
						Pc += waddr((pc_t)val(argv[0]));
					else
						Pc += waddr((pc_t)nbytes);

					/* if this is an INCLUDE directive, then switch files */
					if((Linetype == DIRECTIVE) && (directive == INCLUDE)){
						strcpy(include_filename, argv[0]);
						pass1(include_filename);
						DEBUG("Return from pass1 (include) %s\n",include_filename);
					}
				} /* end if (skip) */

			}
		}while(*pbuf);

	}
	fclose(fp_source);
	fname_pop();
	Include_level--;

	if ( Conditional_level != starting_conditional_level){
		strcpy( Errorbuf, "");
		errlog("Imbalanced conditional.", ALWAYS);

	}

}

/**********************************************************************/
/*
 * Function: pass2()
 *
 * Description:
 *     Do the second pass of assembly.
 *       1.  Generate code (object file).
 *       2.  Generate list file.
 *       3.  Generate label export file (if any labels indicated for export).
 */
/**********************************************************************/

static void
pass2(char *source_file)
{
	int     i;

	ushort  nbytes;         /* total number of bytes        */
	ushort  obytes;         /* number of opcode bytes       */
	ushort  abytes;         /* number of argument bytes     */

	char    label[LABLEN];
	char    inst[LABLEN];
	ulong   op_code;
	ulong   ultmp;
	ulong   argval;
	ushort  argc;
	char    *argv[MAXARGS];
	char    errbuf[LINESIZE];
	char    buf[LINESIZE];
	char    sbuf[LINESIZE];
	char    *pbuf;
	int     nchar;
	ubyte   fill_value; 
	int     local_line_number;
	pc_t    ipc;
	pc_t    iipc;
	ushort  jj;
	FILE    *fp_source;
	dir_t   directive;
	pc_t    start_addr;
	pc_t    end_addr;
	char    include_filename[PATHSIZE];

	extern  int     Num_macros;
	extern  int     Err_check;

	fp_source = fopen(source_file,"r");
	if(fp_source == NULL){
		sprintf(errbuf,"tasm: source file open error on %s\n",source_file);
		errprt(errbuf);
		tasmexit(EXIT_FILEACCESS);
	}

	fname_push( source_file );    /* Save the filename for errlog */


	/* increment the include level counter so we know how deep we are*/
	Include_level++;

	/* zero the line_number each time pass2 is called so the line
	 * number will accurately show the line in each file.
	 */
	Line_number = local_line_number = 0;

	while(fgets( sbuf, LINESIZE-1, fp_source) != NULL)
	{
		Line_number = (++local_line_number);

		if(Num_macros > 0){
			macro_expand(sbuf,buf);
			pbuf = buf;
		}
		else{
			pbuf = sbuf;
		}

		do{
			nchar = parse(pbuf,label,inst,&directive, &op_code,
						  &obytes,&abytes,&argc,argv,&argval);

			Directive = directive;       /* Save global for EQU detection. */
			nbytes    = obytes + abytes;
			Last_pc   = Pc;
			if(nbytes > 0) Codegen =  TRUE;

			/* first check for 'ifdef', ifndef, else or 'endif' and
			 *   set skip flag accordingly.
			 */
			if(Linetype == DIRECTIVE){
				Skip = process_conditional(directive, argv[0]);
			}

			if(Skip == FALSE){
				/* Process line according to the line type */
				switch(Linetype){

				case COMMENT:
				case BLANK:
					break;

				case DIRECTIVE:

					switch(directive){
					case ORG:
						Pc = (pc_t)val(argv[0]);
						break;
					case BLOCK:
					case DS:
						break;

					/* Define macros as they are encountered on Pass2 as well 
					 * as pass1 (with a flush inbetween) so ifdef's will
					 * work correctly for things defined in mid stream.
					 */
					case DEFINE:
						macro_save(argv[0]);
						break;
					case DEFCONT:
						macro_append(argv[0]);
						break;
 
					case FILL:
						/* abytes is set by parse for FILL */
						if (argc == 2) fill_value = (ubyte)val(argv[1]);
						else           fill_value = FILL_DEFAULT;
						for (jj = 0; jj < nbytes; jj++)
						   putop(baddr(Pc)+jj, fill_value);

						break;

					case BYTE:
						for(jj = 0; jj < argc; jj++)
						{
							putop(baddr(Pc)+jj,(ubyte)val(argv[jj]));
						}
						break;
					case WORD:
						for(jj = 0; jj < argc; jj++)
						{
							/* Funny (int) casting here to get lint to not
							 * worry about the truncation of i on shift left.
							 */
							if(Ls_first)
							{
								putop(baddr(Pc)+((ulong)jj<<1)  ,
										 (ubyte)((ulong)val(argv[jj]) & 0xff));
								putop(baddr(Pc)+((ulong)jj<<1)+1,
										 (ubyte)((ulong)val(argv[jj]) >> 8));
							}
							else
							{
								putop(baddr(Pc)+((ulong)jj<<1)  ,
										 (ubyte)((ulong)val(argv[jj]) >> 8));
								putop(baddr(Pc)+((ulong)jj<<1)+1,
										 (ubyte)((ulong)val(argv[jj]) & 0xff));
							}
						}
						break;
			 
					case CHK:
						start_addr = baddr(val(argv[0]));
						end_addr   = baddr(Pc) - 1;
						putop(baddr(Pc), 
							  compute_checksum(start_addr, end_addr));
						break;

					case ECHO:
						for (jj = 0; jj < argc; jj++)
							errprt( argv[jj] );
						break;
			 
					case TEXT:
						for(jj = 0; jj < abytes; jj++)
							putop(baddr(Pc)+jj,argv[0][jj]);
						break;

					case EQU:
					case SET:
						if((i = find_label(label)) != FAILURE)
							GETLABTAB(i)->val = val(argv[0]);
						else
						{
							strcpy(Errorbuf, label);
							errlog("Label must pre-exist for SET:", ALWAYS);

						}
						break;

					case EXPORT:
						for(jj = 0; jj < argc; jj++) {
							if((i = find_label(argv[jj])) != FAILURE){
								Nexport++;
								GETLABTAB(i)->flags |= F_EXPORT;
							}
							else{
								strcpy(Errorbuf, argv[jj]);
								errlog("No such label:", ALWAYS);
							}
						}
						break;

					case MODULE:
						strcpy(Module_name, argv[0]);
						(void)remquotes(Module_name);
						break;


					case TITLE:   strcpy(Title,argv[0]); break;
					case EJECT:   eject();              break;
					case LIST:    Listflag = TRUE;      break;
					case NOLIST:  Listflag = FALSE;     break;
					case PAGE:    Pageflag = TRUE;      break;
					case NOPAGE:  Pageflag = FALSE;     break;
					case NOCODES: Nocodes  = TRUE;      break;
					case CODES:   Nocodes  = FALSE;     break;
					case LSFIRST: Ls_first = TRUE;      break;
					case MSFIRST: Ls_first = FALSE;     break;

					case END:
						No_end   = FALSE;     
												/* Save the address provided */
												/* with the END directive    */
												/* to be included in last obj*/
												/* record.                   */
						if (argc > 0) END_Pc = (pc_t)val(argv[0]);
						break;
					
					default:
						/* OK */
						break;
					}

					break;


				case INSTRUCT:
					/* instruction */

					/* insert opcode bytes */
					ipc = baddr(Pc);
					if(Ols_first)
					{
						while((short)(obytes--) > 0)
						{
							putop(ipc++,(ubyte)(op_code & 0xff));
							ultmp = op_code >> 8;
							op_code = ultmp;
						}
					}
					else{
						iipc = baddr(Pc) + obytes;
						while((short)(obytes--) > 0)
						{
							putop(--iipc,(ubyte)(op_code & 0xff));
							ultmp = op_code >> 8;
							op_code = ultmp;
							ipc++;
						}
					}

					/* Insert arg bytes.  Some (most) rules deposit the 
					 *  the args in argval (even multiple arg instructions).
					 *  The newer (preferred) approach is to deposit the
					 *  arg bytes in the vector Argvalv.
					 */

					if ( Use_argvalv == TRUE )
					{
						jj = 0;
						argval = 0;
						while((short)(abytes--) > 0)
						{
							putop(ipc++, Argvalv[jj++]);
						}
					}
					else 
					{
						while((short)(abytes--) > 0)
						{
							putop(ipc++,(ubyte)(argval & 0xff));
							ultmp = argval >> 8;
							argval = ultmp;
						}
					}

					/* If strict error checking enabled, then complain
					 * if there is unused data left in argval.
					 */
					if(Err_check & EC_UNUSED_ARGBYTES)
					{
						if((argval > 0) && (argval < 0xffff))
						{
							sprintf(Errorbuf,"%lx",argval);
							errlog("Unused data in MS byte of argument.",
								PASS2_ONLY);
						}
					}

					break;

				default:
					break;
				}

				/* Send line to list file */
				if((pbuf == buf) || (pbuf == sbuf))
				{
					/* First line of this statement */
					if(Show_expanded)
						list(Line_number,Pc,nbytes,pbuf);
					else
						list(Line_number,Pc,nbytes,sbuf);
				}
				else
				{
					list(Line_number,Pc,nbytes,"\n");
				}

				/* Make sure label (if any) is matched to this pc
				 * location unless it is an EQU or SET directive
				 */
				if(!((Linetype == DIRECTIVE) &&
					 ((directive == EQU) || (directive == SET)))){

					if((label[0] != '\0') && (Pc != (pc_t)val(label)))
					{
						strcpy(Errorbuf, label);
						errlog(Errmess[(int)ER_MISALLIGN], ALWAYS);
					}
				}
				/* generate error message if any error pending */
				if(Errorno != ER_NOERR)
					errlog(Errmess[(int)Errorno], ALWAYS);

				if((Linetype == DIRECTIVE) && 
					((directive == BLOCK) || (directive == DS)))
					Pc += waddr((pc_t)val(argv[0]));
				else
					Pc += waddr((pc_t)nbytes);


				/* if the Blockobj flag is set then suppress output
				 * of the object records until the end, otherwise
				 * output if either:
				 *     1. a jump in the Pc has occured (e.g. .ORG)
				 *     2. or an .END directive is encountered
				 */

				if((Blockobj == FALSE) &&
				  ((Last_pc  != (Pc - waddr((pc_t)nbytes))) ||
				  ((Linetype == DIRECTIVE) && (directive == END))))
				{
					wrtobj( baddr(First_pc), baddr(Last_pc),Nobj_bytes_per_rec);
					First_pc = Pc;
				}

				/* If an include statement, then call pass2() recursively */
				if((Linetype == DIRECTIVE) && (directive == INCLUDE))
				{
					/* Copy the filename into a different variable, because
					 * the contents of the buffer pointed to by argv[0] may
					 * change during the execution of pass2.
					 */
					strcpy(include_filename, argv[0]);
					pass2(include_filename);
				}
			} /* end if (skip) */

			/* Send line to list file here if skip was TRUE, but
			 * show no code assembled.
			 */
			if(Skip)list(Line_number,Pc,0,sbuf);

		}while(*(pbuf +=nchar));/*keep parsing line until null is reached */

	}
	fclose(fp_source);
	fname_pop();
	Include_level--;

}

/**********************************************************************/
/*
 * Function: process_conditional()
 *
 * Description: 
 *      Check this directive for a conditional (IF,IFDEF,IFNDEF,ELSE,ENDIF)
 *      and set the skip state accordingly.
 *
 */
/**********************************************************************/

static int
process_conditional(dir_t   directive, char    *arg0)
{

/* Define a macro to set the skip variable.  A skip at any
 * level should cause a skip.
 */
#define SETSKIPSTATE  {skip=FALSE;\
						for(i=1;i<=Conditional_level;i++)\
						  if(skip_state[i]==TRUE) skip=TRUE;}

	int         i;
	static  int    skip_state[MAX_CONDITIONAL_LEVELS];
	static  int    skip = FALSE;

	switch(directive){
	case ENDIF:
		skip_state[Conditional_level] = FALSE;
		Conditional_level--;
		SETSKIPSTATE;
		break;

	case ELSE:
		if (skip_state[Conditional_level] == FALSE)
			skip_state[Conditional_level] = TRUE;
		else
			skip_state[Conditional_level] = FALSE;

		SETSKIPSTATE;
		break;

	case IFDEF:
		Conditional_level++;
		skip_state[Conditional_level] = TRUE;
		crush(arg0);
		if(macro_get_index(arg0) >= 0) skip_state[Conditional_level] = FALSE;
		SETSKIPSTATE;
		break;
	case IF:
		Conditional_level++;
		skip_state[Conditional_level] = TRUE;
		crush(arg0);
		if(val(arg0))skip_state[Conditional_level] = FALSE;
		SETSKIPSTATE;
		break;
	case IFNDEF:
		Conditional_level++;
		skip_state[Conditional_level] = FALSE;
		crush(arg0);
		if(macro_get_index(arg0) >= 0) skip_state[Conditional_level] = TRUE;
		SETSKIPSTATE;
		break;
	default:
		/* Set skip appropriately for non-conditionals, too. */
		SETSKIPSTATE;
		break;

	}

	if (Conditional_level >= MAX_CONDITIONAL_LEVELS)
	{
		sprintf(Errorbuf,"levels=%d",Conditional_level);
		errlog("Max number of nested conditionals exceeded.",
			PASS2_ONLY);

	}

	return(skip);
}


/**********************************************************************/
/*
 * Function: open_files()
 *
 * Description:
 *     Open the object and list files.
 *     Build file names if they were not all provided on the command
 *     line.
 */
/**********************************************************************/

static int 
open_files(
char    *files[],       /* pointers to file names */
int     filecnt)        /* Number of files given */
{

	char    errbuf[LINESIZE];
	char    basename[PATHSIZE];
	char    *p;
	char    *q;
	int     i;

	/* If not all the files are specified then use the source file
	 *  name with a new extension (.obj for object and .lst for
	 *  listing).
	 */

	if(filecnt <= 0){
		errprt("tasm: No files specified.\n");
		errprt(USAGE);
		errprt("Option Flags defined as follows:\n");
		errprt("  -<nn>    Table (48=8048 65=6502 51=8051 85=8085 80=z80)\n"); 
		errprt("                 (68=6800 05=6805 70=TMS7000      96=8096)\n");
		errprt("                 (3210=TMS32010 3225=TMS32025)\n");
		errprt("  -t<tab>    Table (alternate form of above)\n");
		errprt("  -a         Assembly control (strict error checking)\n");
		errprt("  -b         Produce object in binary format\n");
		errprt("  -c         Object file written as a contigous block\n");
		errprt("  -d<macro>  Define macro\n");
		errprt("  -e         Show source lines with macros expanded\n");
		errprt("  -f<xx>     Fill entire memory space with 'xx' (hex)\n");
		errprt("  -g<x>      Obj format (0=Intel,1=MOSTech,2=Motorola,3=bin,4=IntelWord)\n");
		errprt("  -h         Produce hex table of the assembled code\n");
		errprt("  -i         Ignore case in labels\n");
		errprt("  -l[al]     Produce a label table in the listing[l=long,a=all]\n");
		errprt("  -m         Produce object in MOS Technology format\n");
		errprt("  -o<xx>     Define number of bytes per obj record = <xx>\n");
		errprt("  -p<lines>  Page the listing file\n");
		errprt("  -q         Quiet, disable the listing file\n");
		errprt("  -s         Write a symbol table file\n");
		errprt("  -x<xx>     Enable extended instruction set (if any)\n");

		return(FAILURE);
	}

	/* extract the base filename from the first file name provided */
	p = files[0];
	q = basename;
	while((*p != '.') && (*p != '\0'))*q++ = *p++;
	*q++ = '\0';

	for(i = 0; i < MAX_NAMED_FILES; i++)
	{
		if((files[i] != NULL) && (i < filecnt))
		{
			Filenames[i] = (char *)malloc(strlen(files[i]) + 1);
			strcpy(Filenames[i], files[i]);
		}
		else
		{
			Filenames[i] = (char *)malloc(strlen(basename) + 5);
			strcpy(Filenames[i], basename);
			switch(i){
			case 1:  strcat(Filenames[i],".obj"); break;
			case 2:  strcat(Filenames[i],".lst"); break;
			case 3:  strcat(Filenames[i],".exp"); break;
			case 4:  strcat(Filenames[i],".sym"); break;
			default: errprt("tasm: invalid file count\n"); break;
			}
		}

	}
	/* don't open the source file here since it is opened for each pass */

#if 0
	/* open object file.  O_MODE ignored in MSDOS (here for UNIX) */
	if(Obj_format == BINARY_OBJ)
		Fd_object =open(OBJ_FN,(int)(O_WRONLY|O_CREAT|O_TRUNC|O_BINARY),O_MODE);
	else
		Fd_object =open(OBJ_FN,(O_WRONLY|O_CREAT|O_TRUNC),O_MODE);

	if(Fd_object < 0)
	{
		sprintf(errbuf,"tasm: object file open error on %s\n",OBJ_FN);
		errprt(errbuf);
		return(FAILURE);
	}
#endif

	/* open the object file (in TEXT or BINARY mode, as appropriate) */
	if(Obj_format == BINARY_OBJ)
		Fp_object = fopen(OBJ_FN,"wb");
	else
		Fp_object = fopen(OBJ_FN,"wt");

	if(Fp_object == NULL)
	{
		sprintf(errbuf,"tasm: object file open error on %s\n",OBJ_FN);
		errprt(errbuf);
		return(FAILURE);
	}


	/* open list file */
	Fp_list = fopen(LST_FN,"w");
	if(Fp_list == NULL)
	{
		sprintf(errbuf,"tasm: list   file open error on %s\n",LST_FN);
		errprt(errbuf);
		return(FAILURE);
	}

	/* Increase buffer size for list file */
	if(setvbuf(Fp_list, NULL, _IOFBF, 2048))
	{
		errprt("tasm: Cannot increase list file buffer");
		/* not fatal, so just continue. */
	}

	return (SUCCESS);
}

/**********************************************************************/
/*
 * Function: close_files
 * 
 * Description:
 *    Close all open files except for the source file(s).
 *    The source file is closed as needed in pass1/pass2 since
 *     there may be multiple source files open due to recursive 
 *     includes.
 */
/**********************************************************************/
static void
close_files()
{
	fclose(Fp_object);
	fclose(Fp_list);
}

/**********************************************************************/
/*
 * Function: list
 * 
 * Description:
 *    Format a line for the listing and send to the listing file.
 *    General format is:
 *
 *    9999 FFFF~ 01 02 03 04   SourceLine
 *
 *  Where:
 *    9999       = Line number in current source file
 *    FFFF       = PC at the start of the line
 *    ~          = Shown only if the source line is skipped due to ifdef, etc.
 *    01,02, etc = Opcodes in hex
 *    SourceLine = Source code line as read from the input file.
 */
/**********************************************************************/

#define OBJBYTESPERLINE (4)

void
list(
int     linenumber,    /* Line number in current source file           */
pc_t    pc,            /* PC at start of the line (word address fmt)   */
ushort  nbytes,        /* Total number of object code bytes to format  */
char    *srcbuf)       /* Source line                                  */
{

	char    obuf[LINESIZE];
	char    tbuf[4];
	char    *p;
	char    skipc;
	ushort  bytesThisLine;
	pc_t    pcb;       /* Byte address PC */
	pc_t    pcw;       /* Word address PC */

	p = obuf;
	pcb = baddr(pc);    /* Byte PC */
	pcw = pc;           /* Word PC (same if word size = 1 ) */

	/* If the Nocodes flag is true then do no formatting of the
	 * source line, just print it as read from the source file.
	 */
	if(Nocodes)
	{
		listprt(srcbuf);
		return;
	}

	/* Show the depth of the include by '+' suffix to the linenumber.
	 * Don't show more than +++, though.
	 */
	switch(Include_level){
	case 0:
	case 1:
		sprintf(p,"%04d   ",linenumber);
		break;
	case 2:
		sprintf(p,"%04d+  ",linenumber);
		break;
	case 3:
		sprintf(p,"%04d++ ",linenumber);
		break;
	default:
		sprintf(p,"%04d+++",linenumber);
		break;
	}

	/* Put a '~' right after the pc if we are skipping this line
	 *  (e.g. ifdef, ifndef, if invoked ). 
	 */
	if(Skip)
		skipc = '~';
	else
		skipc = ' ';

	switch(nbytes){
	case 0:
		sprintf(&obuf[7],"%04lx%c            ",pcw,skipc);
		break;

	case 1:
		sprintf(&obuf[7],"%04lx %02x          ",pcw,getop(pcb));
		break;

	case 2:
		sprintf(&obuf[7],"%04lx %02x %02x       ",pcw,getop(pcb),
			getop(pcb+1));
		break;

	case 3:
		sprintf(&obuf[7],"%04lx %02x %02x %02x    ",pcw,
			getop(pcb),getop(pcb+1),getop(pcb+2));
		break;

	case 4:
	default:
		sprintf(&obuf[7],"%04lx %02x %02x %02x %02x ",pcw,
			getop(pcb),getop(pcb+1),getop(pcb+2),getop(pcb+3));
		pcb += 4;  /* Set PC to the next byte to be printed */
		break;


// No longer support 5 & 6 bytes per line (for more uniformity in output)
#if 0
	case 5:
		sprintf(&obuf[7],"%04lx %02x%02x%02x%02x%02x  ",pcw,
			getop(pcb),getop(pcb+1),getop(pcb+2),getop(pcb+3),
			getop(pcb+4));
		break;

	case 6:
		sprintf(&obuf[7],"%04lx %02x%02x%02x%02x%02x%02x",pcw,
			getop(pcb),getop(pcb+1),getop(pcb+2),getop(pcb+3),
			getop(pcb+4),getop(pcb+5));
			pcb += 6;  /* Set PC to the next byte.  Only needed if more bytes
					*    are to be printed. */
		break;
#endif
// End disabled block.


	}
	stoupper(obuf);                            /* Convert Hex to upper case */
	while(*(++p)) /* void */;                  /* Advance p to end of line thus far */
	while((*p++ = *srcbuf++) != 0) /* void */; /* Put in line just as user typed it */

	/* Output to list file */
	listprt(obuf);

	/* If we have more bytes than we can get on one line, then
	 * generate additional lines, 6 bytes per line.
	 */
	while(nbytes > OBJBYTESPERLINE)
	{
		nbytes -= OBJBYTESPERLINE;
		pcw += waddr(OBJBYTESPERLINE);
		
		sprintf(&obuf[7],"%04lx%c", pcw, skipc);

		/* Compute number of bytes to output on this line */
		if( nbytes > OBJBYTESPERLINE ) bytesThisLine = OBJBYTESPERLINE;
		else                           bytesThisLine = nbytes;

		while(bytesThisLine--)
		{
			sprintf(tbuf,"%02x ",getop(pcb++));
			strcat( obuf, tbuf );
		}

		stoupper(obuf);
		strcat(obuf,"\n");
		listprt(obuf);
	}

			
}

/**********************************************************************/
/* 
 * Function: pr_labels
 * Description:
 *         Format a label table and send to the listing file.
 */
/**********************************************************************/


static void
pr_labels(int show_no_locals)
/* Send label table to list file */
{

	ushort  i;
	char    labbuf[LINESIZE];
	char    linebuf[LINESIZE];
	char    ebuf[LINESIZE];
	char    *p;
	int     type_seg;
	int     type_local;
	int     type_export;
	int     flags;

	listprt("\n");
	listprt("\n");
	listprt("\n");

	if(Long_label_list){

		listprt("Type Key: N=NULL_SEG C=CODE_SEG B=BIT_SEG X=EXTD_SEG D=DATA_SEG\n");
		listprt("          L=Local\n");
		listprt("          E=Export\n");
 
		listprt("\n");
		listprt("Value    Type   Label\n");
		listprt("-----    ----   ------------------------------\n");
	}
	else{ 
	  listprt(
	  "Label        Value      Label        Value      Label        Value\n");
	  listprt(
	  "------------------      ------------------      ------------------\n");
	}

	linebuf[0] = '\0';
	for(i = 0; i < Nlab; i++){
		/* Suppress local labels if requested */
		if((GETLABTAB(i)->flags & F_LOCAL) && (show_no_locals))continue;
 
		p = GETLABTAB(i)->lab;
		if(!isprint(*p)){
			sprintf(ebuf,"Corrupt label entry.  Val=%lx index=%d\n",
				GETLABTAB(i)->val, i);
			listprt(ebuf);
			continue;
		}

		/* Capital X for upper case hex */
		if(Long_label_list){
			flags = GETLABTAB(i)->flags;
			type_seg    = ' ';
			type_local  = ' ';
			type_export = ' ';

			switch(flags & F_SEG){
			case NULL_SEG:  type_seg =  'N';  break;
			case CODE_SEG:  type_seg =  'C';  break;
			case BIT_SEG:   type_seg =  'B';  break;
			case EXTD_SEG:  type_seg =  'X';  break;
			case DATA_SEG:  type_seg =  'D';  break;
			default: /* OK */                 break;
			}

			if(flags & F_LOCAL)   type_local  = 'L';
			if(flags & F_EXPORT)  type_export = 'E';

			sprintf(linebuf,"%04lX     %c%c%c    %-32s\n", GETLABTAB(i)->val, 
				type_seg, type_local, type_export, GETLABTAB(i)->lab);
			listprt(linebuf);
		}
		else{
			sprintf(labbuf,"%-13s %04lX      ",GETLABTAB(i)->lab, GETLABTAB(i)->val);
			strcat(linebuf,labbuf);
			if((((i+1) % 3) == 0) || ((i+1) == Nlab)){
				strcat(linebuf,"\n");
				listprt(linebuf);
				linebuf[0] = '\0';
			}
		}
	}
	listprt("\n");
}


/**********************************************************************/
/* 
 * Function: pr_hextab
 * Description:
 *         Send a hexadecimal table of the code to the list file
 */
/**********************************************************************/

static void
pr_hextab(
pc_t    pc_lo,         /* minimum address to output */
pc_t    pc_hi)         /* maximum address to output (Program Counter)*/
{
	ushort  i;
	int     nlines;
	pc_t    addr;
	char    linebuf[LINESIZE];
	char    *p;
	ubyte   op;

	/* decrement the max pc since it points to one location
		beyond the last byte to output.  (see comments
		in wrtobj). */

	/* First test a few error cases */
	if((pc_hi == pc_lo) && (pc_lo > 0))return;
	if((pc_hi == pc_lo) && (Codegen == FALSE))return;
	if(pc_hi == 0) return;   /* No code generated */

	pc_hi--;
	nlines = ((pc_hi - pc_lo) / 16) + 1;

	listprt("\n");
	listprt("ADDR  00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F\n");
	listprt("-----------------------------------------------------\n");

	for(addr = pc_lo; nlines--; addr += 16)
	{
		sprintf(linebuf,"%04lx ",addr);
		p = linebuf;
		for(i = 0; i < 16; i++)
		{
			op = getop(addr+i);
			while(*(++p)) /* void */;
			sprintf(p," %02x",op);
		}
		stoupper(linebuf);
		strcat(linebuf,"\n");
		listprt(linebuf);
	}
	listprt("\n");
	listprt("\n");
}

/**********************************************************************/
/* Function    : errprt()
 * Description :  send input buffer to stdout
 */
/**********************************************************************/

void
errprt(char *err_mess)
{
	char c;

	while(*err_mess)
	{
		c = *err_mess++;
		putchar(c);
	}
}

/**********************************************************************/
/*
 * Function    :  lstprt()
 * Description :  send input buffer to the listing file
 */
/**********************************************************************/

void
listprt(char *buf)
{

/* Note that the line numbering assumes that each time listprt is
 * called a single line is output (which is not necessarily the case).
 */
	if(Listflag)
	{
		fputs(buf,Fp_list);
		Page_linenumber++;
		if((Pageflag) && (Page_linenumber >= Pagesize))eject();
	}
}

/**********************************************************************/
/* Function     : eject
 * Description  : Go to Top-of-Page on the listing file and
 *                output the banner.
 */
/**********************************************************************/

static void
eject(void)
{
	char    buf[LINESIZE];

	Page_num++;
	Page_linenumber = 0;
	listprt(TOF);
	sprintf(buf,"%-30s    %-30s   page %d\n",Banner,SRC_FN,Page_num);
	listprt(buf);
	sprintf(buf,"%s\n",Title);
	listprt(buf);
	listprt("\n");

}

/**********************************************************************/
/* Function     : export
 * Description  : Export labels designated by the EXPORT directive so
 *                that they can be
 *                referenced in other assemblies.
 */
/**********************************************************************/

static void
export()
{

	char        errbuf[LINESIZE];
	ushort      i;
	FILE        *fp;

	if((fp = fopen(EXP_FN,"w")) == NULL){
		sprintf(errbuf,"tasm: export file open error on %s\n",EXP_FN);
		errprt(errbuf);
		return;

	}

	for(i = 0; i < Nlab; i++)
	{
		if((GETLABTAB(i)->flags) & F_EXPORT)
		{
			fprintf(fp,"%-16s .EQU  $%04x\n",
				GETLABTAB(i)->lab, (ushort)GETLABTAB(i)->val);
		}
	}

	fclose(fp);

}


/**********************************************************************/
/* Function     : write_symbols()
 * Description  : Write labels and values to a symbol file.
 */
/**********************************************************************/

static void
write_symbols(void)
{

	char        errbuf[LINESIZE];
	ushort      i;
	FILE        *fp;
	char        prefix[4];

	if((fp = fopen(SYM_FN,"w")) == NULL)
	{
		sprintf(errbuf,"tasm: symbol file open error on %s\n",SYM_FN);
		errprt(errbuf);
		return;

	}

	for(i = 0; i < Nlab; i++){

		if(Avsim51){
			switch(GETLABTAB(i)->flags & F_SEG){
			case NULL_SEG:  strcpy(prefix, "N:");  break;
			case CODE_SEG:  strcpy(prefix, "C:");  break;
			case BIT_SEG:   strcpy(prefix, "B:");  break;
			case EXTD_SEG:  strcpy(prefix, "X:");  break;
			case DATA_SEG:  strcpy(prefix, "D:");  break;
			default: /* OK */                      break;
			}
			fprintf(fp,"AS %-16s  %s%04x\n",
				GETLABTAB(i)->lab, prefix, (ushort)GETLABTAB(i)->val);
		}
		else{
			fprintf(fp,"%-16s  %04x\n",
				GETLABTAB(i)->lab,  (ushort)GETLABTAB(i)->val);
		}

	}

	fclose(fp);

}

/**********************************************************************/
/*
 * Function: baddr()
 * Description:  
 *      Convert word address to byte address.
 *      If wordsize is 1 (byte) then this is a null operation.
 */
/**********************************************************************/

static pc_t
baddr(pc_t pc)
{
		if(Wordsize == 1) 
			return(pc);         /* 8 bit words */
		else
			return(pc << 1);    /* 16 bit words */
}

/**********************************************************************/
/*
 * Function: waddr()
 * Description:  
 *      Convert byte address to word address.
 *      If wordsize is 1 (byte) then this is a null operation.
 */
/**********************************************************************/

static pc_t
waddr( pc_t pc)
{
		if(Wordsize == 1) 
			return(pc);         /* 8 bit words */
		else
			/* round up */
			return((pc+1) >> 1);    /* 16 bit words */
}

/**********************************************************************/
/* Function: compute_checksum
 * Description:
 *      Compute a simple single byte exclusive OR checksum over the indicated
 *      address range.
 *      Assume start_addr and end_addr are byte (not word) addresses.
 */
/**********************************************************************/

static ubyte
compute_checksum( pc_t start_addr, pc_t end_addr)
{

		ubyte   checksum;
		pc_t    i;

		checksum = 0;

		for (i = start_addr; i <= end_addr; i++) 
		{
			checksum = checksum ^ getop ( i );
		}

		return (checksum);
}


/**********************************************************************/
/* Function: isequate
 * Description:
 *      Return TRUE of the current source line is an EQUate statement.
 */
/**********************************************************************/

int
isequate( void )
{

	if ( (Linetype == DIRECTIVE) && (Directive == EQU)) return (TRUE);
	else                                                return (FALSE);

}

/**********************************************************************/
/*
 * Function: putop
 * Description:
 *      Write a byte to the memory image. 
 */
/**********************************************************************/

static void
putop(pc_t pcb, ubyte op)
{
	Opbuf[pcb]=op;

	/* Keep track of the address range written */
	/* Note that Min_pc and Max_pc are always byte addresses. */
	Min_pc = min ( pcb, Min_pc );
	Max_pc = max ( pcb, Max_pc );
}

/**********************************************************************
 * Function: getop
 * Description:
 *      Fetch a byte from the memory image.
 **********************************************************************
 */

ubyte
getop(pc_t pcb)
{
	return ( Opbuf[pcb] );
}

/* That's all folks. */
