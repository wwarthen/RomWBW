/****************************************************************************
 *  $Id: parse.c 1.7 2001/10/23 01:38:00 toma Exp $
 ****************************************************************************
 *  File: parse.c
 *
 *  Description:
 *    Modules to parse source lines for TASM, the table driven assembler.
 *
 *    Copyright 1985-1995  Speech Technology Incorporated.
 *    Copyright 1997-2000  Squak Valley Software
 *    Restrictions apply to the duplication of this software.
 *    See the COPYRIGH.TXT file on this disk for restrictions.
 *
 *    Thomas N. Anderson
 *    837 Front Street South
 *    Issaquah, WA  98027
 *
 *
 */

//static char *id_parse_c = "$Id: parse.c 1.7 2001/10/23 01:38:00 toma Exp $";

/* INCLUDES */
#include        "tasm.h"
#ifdef T_MEMCHECK
#include        <memcheck.h>
#endif


/* Externals */
extern  ushort          Debug;
extern  pc_t            Pc;
extern  char            Local_char;

/* Static */
static ushort argvect( char *args, char *argv[], ushort  *argc);

/**********************************************************************/

/* Function     : parse
 * Description  : Parse one line of assembly source code.
 *                1.  Identify the instruction or directive
 *                2.  If a directive then perform the directive
 *                3.  If an instruction encode according to the
 *                        applicable rule.
 */


int
parse(
/* Inputs: */
char    *buf,           /* buffer containing input line to parse */

/* Outputs: */
char    *label,         /* label string (if any)                        */
char    *inst,          /* instruction string                           */
dir_t   *directive,     /* directive code (if a directive lint          */
ulong   *op_code,       /* op code (if an instruction lint)             */
ushort  *obytes,        /* number of bytes of opcode                    */
ushort  *abytes,        /* number of bytes of argument                  */
ushort  *argc,          /* number of arguments found                    */
char    **argv,         /* pointers to argument strings                 */
ulong   *argval)        /* value of args (adjusted if necessary for this
                           particular instruction)       */
{

    extern  error_t Errorno;        /* global error number */
    extern  char    Errorbuf[LINESIZE];
    extern  char    Comment_char1;  /* First column comment char */
    extern  char    Comment_char2;  /* Embedded comment char     */
    extern  line_t  Linetype;
    extern  int     No_arg_shift;   /* Disable shift/or to args  */
    extern  int     Use_argvalv;    

    int     i,j;
    ushort  modop;
    ubyte   shift;
    ulong   bor;
    int     withinquotes;       /* inside        quotes */
    int     withinquotes1;      /* inside single quotes */
    int     withinquotes2;      /* inside double quotes */

    static  char    args[LINESIZE];

    /* initialize */
    *label          = '\0';
    *inst           = '\0';
    argv[0]         = (char *) 0;
    *argc           = 0;
    *obytes         = 0;
    *abytes         = 0;
    Linetype        = UNKNOWN;
    Errorno         = ER_NOERR;
    args[0]         = '\0';
    Errorbuf[0]     = '\0';

    i     = 0;          /* buf character counter */

    /* if first character  is a ';' then it is a comment */
    if(buf[0] == Comment_char1){
        /* comment */
        Linetype = COMMENT;
        while(buf[i])i++;
    }
    else{
        /* must be an instruction or directive.
           strip out label, instruction and argument fields first */
        /* If first character is alpha or '_' then it is a label */
        if((isalpha(buf[i])) || (buf[i] == '_') || (buf[i] == Local_char)){
            i = i + strget(label,buf);
            if(buf[i] == ':')i++;   /* skip ':' at end of label*/
        }

        /* look for next nonblank character */
        while((buf[i] == ' ') || (buf[i] == '\t'))i++;

        /* check to see if it is just a comment.  If it is then
            don't try to extract instruction and args. */
        if(buf[i] != Comment_char2){

            /* get the instruction (or directive) */
            i = i + strget(inst,&buf[i]);

            while(isspace(buf[i]))i++;  /* skip white space */

            j = 0;
            if(isalpha(inst[0])){
                /* Instruction */
                Linetype = INSTRUCT;
                while((buf[i] != '\0') &&
                  (buf[i] != Comment_char2 ) &&
                  (buf[i] != '\n') &&
                  (buf[i] != DELIM)){
                        args[j++] = buf[i++];
                }
            }
            else{
                /* Directive */
                Linetype = DIRECTIVE;
                withinquotes1 = FALSE;
                withinquotes2 = FALSE;
                withinquotes  = FALSE;

                while((buf[i] != '\0') &&
                     ((buf[i] != Comment_char2) || (withinquotes)) &&
                     ((buf[i] != DELIM)         || (withinquotes)) &&
                      (buf[i] != '\n')){

                    /* Detect the withinquotes state.  Do not
                     * consider quotes that are escaped with backslash.
                     */
                    if(buf[i] == '\"' && (buf[i-1] != '\\'))
                                              withinquotes2 = !withinquotes2;
                    if(buf[i] == '\'' && (buf[i-1] != '\\'))
                                              withinquotes1 = !withinquotes1;
                    withinquotes = withinquotes1 || withinquotes2;

                    args[j++] = buf[i++];
                }
            }

            args[j] = '\0';
        }

        /*   Check  the  next  character  to  see  if  any
         *   special  adjustments  need  to  be made.  If it is
         *   the  multiple  instruction  delimiter,   skip past
         *   it.   If a ';'  (thus a comment)  then skip to the
         *   end  of the line.  If a newline then skip past it.
         */

        if     (buf[i] == DELIM)         i++;
        else if(buf[i] == '\n')          i++;
        else if(buf[i] == Comment_char2) while(buf[i])i++; /*skip to eol */

        if(inst[0] == '\0'){
            Linetype = BLANK;
            return(i);
        }

        /* if first character of instruction/directive field
            is not alpha, then it must be a directive.
            Directives should start with a '.', '#', '=', '*', or '='. */
        if(Linetype == DIRECTIVE){
            /* Directive */

            /*  Look up the directive code.
                If the first character is '.' or '#' then
                skip past it before doing the lookup,
                otherwise use the whole field. */
            if((inst[0] == '.') || (inst[0] == '#')){

                if((*directive = dir_lookup(inst+1)) == NOTDIR)
                    Errorno = ER_BADDIR;

                strcpy(Errorbuf,inst);
            }
            else{
                if((*directive = dir_lookup(inst)) ==NOTDIR)
                    Errorno = ER_BADDIR;
                strcpy(Errorbuf,inst);
            }
            switch (*directive ){
                case BYTE: 
                    crush(args); 
                    *abytes = argvect(args,argv,argc);
                    break;

                case WORD: 
                    crush (args);
                    *abytes = argvect(args,argv,argc) * 2;  
                    break;

                case EXPORT:  
                    crush(args);
                    (void) argvect(args, argv, argc);
                    break;

                case CHK:  *abytes = 1;                            break;

                case FILL:
                    crush(args);
                    (void) argvect(args, argv, argc);
                    *abytes= (ushort)val(argv[0]);
                    break;

                case TEXT:
                    /* remove double quotes and count characters between them */
                    *abytes = remquotes(args);
                    break;

                case ECHO:
                    if ( *args == '\"')
                        (void)remquotes (args);
                    else
                        sprintf ( args, "%ld", val(args));
                    break;

                case INCLUDE:    
                case TITLE:
                case SYM:
                case AVSYM:            
                    (void)remquotes(args);
                    break;

                /* If this is a DEFINE or DEFCONT statement then take the rest
                 * of the line as the args and don't stop at
                 * the multiple line delimiter 
                 */

                case DEFINE:
                case DEFCONT:
                    if(buf[i-1] == DELIM){
                        i--;
                        j = strlen(args);
                        while(buf[i])
                                args[j++] = buf[i++];
                        /* terminate before last newline */
                        args[j-1] = 0;
                    }
                    break;

                case UNDEF:
                    break;

                default:
                    break;

            } /* end switch */

            if(argv[0]  == (char *)0) argv[0] = args;
            if((*argc == 0) && (args[0] != '\0')) *argc = 1;
                        /* Set op_code to illegal value since it is not
                         * applicable.  directive contains the real info.
                         */
            *op_code = 0;       
        }
        else{
            /* INSTRUCTION
             * Check instruction and args against legal inst table.
             */
            crush(args);

            Errorno = inst_lookup(inst,args,op_code,obytes,
                abytes,&modop,&shift,&bor,argc,argv);

            /* Handle special cases here.
             *  For 8048 fix up JMP and CALL instructions.
             *  For 6502 handle zero page addressing
             *  and relative branches.
			 *  etc. etc.
             * Use as the default argval as the value of the first
             *  expression.  If there are additional
             *  expressions to be considered, let rules()
             *  take care of it.   Perform the shift/or
             *  operation on the first arg also.
             *
             */

            *argval = 0;

            if((*abytes > 0) && (argv[0])){
                *argval = val(argv[0]);
            }

            /* Make sure this is false for every instruction so it is 
             * not left with the value from the previous instruction if
             * if this is a NOTOUCH rule.
             */
            Use_argvalv = FALSE;

            if((Errorno == ER_NOERR) && (modop != NOTOUCH)){
                rules(modop, op_code, obytes, abytes, argval, Pc,
                    *argc, argv, shift, bor);
            }

            if((No_arg_shift == FALSE) && (*abytes > 0) && (shift || bor)){
                *argval = (*argval << shift) | bor;
            }
        }
    }
    DEBUG3("%04lx %04lx %s",*op_code, *argval, buf);
    return(i);

}

/* Function     : argvect
 * Description  : Vectorize an argument string.
 */

static ushort
argvect(
char    *args,     /* String buffer for the arguments                      */
char    *argv[],   /* Array of string pointers to each individual argument */
ushort  *argc)     /* Pointer to the argument count                        */
{
    static char argbuf[LINESIZE];
    static char strbuf[LINESIZE];
    static char txtbuf[LINESIZE][4];

    char        *p;
    int         withinquotes;
    ushort      acnt;
    char        *q;
    ushort      j;
    ushort      k;


    strcpy(argbuf,args);

    /* Add an extra null on the end */
    p  = argbuf;
    while(*p++) /* void */;
    *p++ = '\0';
    *p++ = '\0';

    p  = argbuf;
    do{
        /* skip past any white space */
        while(*p && isspace(*p))p++;

        if(*p == '\"'){
            /* Treat each character in a quoted string as a 
             * seperate arg and save as a decimal ASCII string.
             * This is an easy way to allow strings in places like
             * BYTE directives.
             */
            strcpy(strbuf, p);
            j = remquotes(strbuf);
            if((*argc + j) >= MAXARGS){
                j = MAXARGS - *argc;
                //errlog("Maximum number of args exceeded.",ALWAYS);
            }

            for (k = 0; k < j; k++)
            {
                /* Save the decimal strings in static local txtbuf.
                 * Avoid malloc just to avoid the hastle of freeing.
                 */
                q = txtbuf[*argc + k];
                sprintf(q, "%d", strbuf[k]);
                argv[*argc + k] = q;
            }
            acnt = j;

        }
        else{
            acnt = 1;
            argv[*argc] = p;
        }

        if((*argc + acnt) < MAXARGS){
            *argc = *argc + acnt;
        }
        else{
            errlog("Maximum number of args exceeded.",ALWAYS);
        }

        /* skip to next element.  Don't be confused by commas inside quotes */
        withinquotes = FALSE;
        while(*p) {

            if((*p == '\'') || ((*p == '\"') && (*(p-1) != '\\'))){
                withinquotes = !withinquotes;
            }

            if(*p == ','){
                /* If we get a comma outside of quotes break */
                if(!withinquotes) break;

            }
            p++;
        }
        *p++ = '\0';
    }while(*p);

    for (j=0; j < *argc; j++) {
//        DEBUG2( "argvect: #%s# len=%d\n", argv[j], strlen(argv[j]));
    }

    return(*argc);
}

/* That's all folks. */
