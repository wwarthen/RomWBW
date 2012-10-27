/****************************************************************************
 *  $Id: lookup.c 1.5 1997/11/15 13:10:50 toma Exp $
 **************************************************************************** 
 *  File: lookup.c
 *
 *  Description:
 *      Functions to lookup instructions and directives.
 *    
 *
 *    Copyright 1985-1995  Speech Technology Incorporated.
 *    Copyright 1997       Squak Valley Software.
 *    Restrictions apply to the duplication of this software.
 *    See the COPYRIGH.TXT file on this disk for restrictions.
 *
 *    Thomas N. Anderson
 *    Squak Valley Software
 *    837 Front Street South
 *    Issaquah, WA  98027
 *
 *
 *
 */

//static char *id_lookup_c = "$Id: lookup.c 1.5 1997/11/15 13:10:50 toma Exp $";

/* INCLUDES */
#include        "tasm.h"
#ifdef T_MEMCHECK
#include        <memcheck.h>
#endif

/* EXTERNALS */
extern  ushort  Debug;
extern  char    Errorbuf[LINESIZE];

/************************************************************************/
/* FUNCTIONS */

/* Function: inst_lookup()
 * Description:
 *     Lookup instruction and args string in tables to see if valid.
 *     If it is valid, then return op_code, number of bytes, and
 *     an argument expression (if any). 
 */
error_t
inst_lookup(
char    *inst,          /* Instruction         */
char    *args,          /* Argument string     */
ulong   *op_code,
ushort  *obytes,
ushort  *abytes,
ushort  *modop,
ubyte   *shift,
ulong   *bor,
ushort  *argc,
char    **argv)
{
    static  char    expbuf[LINESIZE];

    extern  ushort  Class_mask;
    extern  ushort  Ihash[];
    extern  ushort  Num_instr;
    extern  ushort  Num_reg;
    extern  OPTAB   *Optab[];
    extern  REGTAB  *Regtab[];
    extern  char    Wild_char;
    extern  char    Reg_char;
    extern  char    Errorbuf[LINESIZE];

    char    argbuf[LINESIZE];
    ushort  j;
    ushort  jj;
    error_t errflag;
    ushort  len1;
    char    *argpattern;
    char    *argu;
    char    *argl;
    char    *arge;
    char    *p;
    char    *q;
    char    c;
    ushort  inst_match;
    ulong   regfield;

    /* Just for safety, make sure we do not return a NULL pointer in argv[0]
     * even if no args are found.  If we match an op_code that needs args
     * but none were provided in the source, then we might have such a case.
     */
    expbuf[0]  = '\0';
    argv[0]    = expbuf;

    /* search table for a match with inst and args */

    /* Set the error flag hoping it will be cleared when
          a legal instruction is found */
    errflag = ER_BADINST;

    /* Convert the instruction to upper case */
    p = inst;
    while(*p)
    {
        if((*p >= 'a') && (*p <= 'z')) *p -= ('a' - 'A');
        p++;
    }

    /* Convert the args to upper case.  Don't do it in place since 
     * we need to extract the expressions in mixed case so labels
     * remain true.
     */
    p = args;
    q = argbuf;
    while(*p)
    {
        if((*p >= 'a') && (*p <= 'z')) 
            *q++ = (*p++) - 'a' + 'A';
        else
            *q++ = *p++;
    }
    *q = '\0';

    /* Get the first element of Optab that we should look at for
     *   this instruction from the instruction hash table 
     */
    jj = Ihash[HASHKEY(inst)];
    inst_match = FALSE;

    for(; jj < Num_instr; jj++)
    {

        if(Optab[jj]->same_inst == FALSE)
        {
            /* New instruction.  Check to see if it matches. */
            p = inst;
            q = Optab[jj]->instruction;
            while((*p == *q) && (*p)){
                p++;
                q++;
            }
            inst_match = (*p == *q);
        }
        
        if(inst_match && (Optab[jj]->iclass & Class_mask))
        {
            /* Instruction matches, now check args.
             * Set the error flag hoping it will be cleared when
             *   a legal argument is found 
             */
            errflag = ER_BADARG;

            argpattern = Optab[jj]->args; /* fetch expected arg  */
            argu = argbuf;  /* pointer to args (upper case only) */
            argl = args;    /* pointer to args (mixed case)      */
            arge = expbuf;  /* pointer to  extracted expression  */
            *argc    = 0;   /* Arg count                         */
            regfield = 0;   /* optional register set bits        */

            do
            {
                /* Check for the wild card character '*'.
                 *      If '*' in argpattern is immediately
                 *      followed by a comma then that arg is
                 *      taken to be everything up to the next
                 *      comma.  If it isn't followed by a comma
                 *      then copy over enough chars so the same
                 *      number of chars remain in argpattern as
                 *      the args under test.
                 *
                 *      Thus, if multiple '*'s are used in an
                 *      argpattern, all but the last one must
                 *      be followed by a comma or ']' for proper
                 *      operation.
                 */
                if(*argpattern == Wild_char){
                    argv[*argc] = arge;
                    *argc += 1;
                    c = *(argpattern+1);
                    if((c == ',') || (c == ']') || (c == '[')){
                        /* copy over until a comma or ] or [ is found */
                        while((*argl) && (*argl != ',') && 
                                         (*argl != ']') &&
                                         (*argl != '[')){
                            *arge++ = *argl++;
                            argu++;
                        }
                        argpattern++;
                    }
                    else if((*(argpattern+1) == ')') &&
                            (*(argpattern+2) == ',') ){
                        /* copy over until '),' is found */
                        while((*argl) && !((*argl == ')')&&(*(argl+1) == ','))){
                            *arge++ = *argl++;
                            argu++;
                        }
                        argpattern++;
                    }
#if 0
                    else if(*(argpattern+1) == '(')
                    {
                        /* SPR 1008.  This is an attempt to allow a left
                         * paren to terminate an expression (instead of
                         * just the ,[] set).  Since parens are valid
                         * in expressions, this is difficult.  
                         * The approach here is to only terminate the
                         * gobble of the expression if a paren is encountered
                         * that is not preceeded by a binary operator.
                         * This is weak, since nested parens may also
                         * appear.  This parsing is not required by
                         * any existing TASM table (as of 3.0) but
                         * is in support of a user.
                         * Example of the application: @(@),@
                         * Note char2toktype() does not yet exist.
                         * Can't use toktype directly since it does not
                         * accept char as input.
                         */
                        while((*argl) && !((*argl == '(') && 
                                   (char2toktype((*(argl-1)) != TOK_BINOP))){
                            *arge++ = *argl++;
                            argu++;
                        }
                        argpattern++;
                    }
#endif
                    else
                    {
                        /* General case.  Last '*' in arg. */
                        short n,i;
                        n = strlen(argl) - strlen(argpattern) + 1;
                        for(i=0;i < n;i++)
                        {
                            *arge++ = *argl++;
                            argu++;
                        }
                        argpattern++;
                    }

                    *arge++ = '\0';
                } 
                else if (*argpattern == Reg_char)
                {
                    for (j=0; j < Num_reg; j++)
                    {
                        if((Regtab[j]->iclass & Class_mask) == 0)continue;
                        len1 = strlen (Regtab[j]->reg);
                        if (   strncmp(Regtab[j]->reg, argu, len1) == SAME){
                            regfield = Regtab[j]->opcode;
                            argpattern++;
                            argu += len1;
                            argl += len1;
                            break;
                        }
                    }

                }

                /* if we made it to the end of both the argument
                 * pattern (argpattern) and actual arg, it must match.
                 */
                if((*argpattern == '\0')&&(*argu == '\0'))
                {
                    *op_code = Optab[jj]->opcode | regfield;
                    *obytes  = Optab[jj]->obytes;
                    *abytes  = Optab[jj]->abytes;
                    *modop   = Optab[jj]->modop;
                    *shift   = Optab[jj]->shift;
                    *bor     = Optab[jj]->bor;
                    return(ER_NOERR);
                }
                argl++;
            }while(*argu++ == *argpattern++);
        }

    } /* end for (each instruction) */

    if(errflag == ER_BADARG)  
                           strcpy(Errorbuf, args);

    if(errflag == ER_BADINST) 
                           strcpy(Errorbuf, inst);

    return(errflag);
}

/* Function: dir_lookup()
 * Description:
 *     Look up the assembler directive in the table 
 */

dir_t
dir_lookup(char *directive)
{

    extern  char *Dirtab[];

    ushort  i;
    char    *p;
    char    *q;

    /* Convert the directive to upper case */
    p = directive;
    while(*p)
    {
        if((*p >= 'a') && (*p <= 'z')) *p -= ('a' - 'A');
        p++;
    }

    for(i = 0; i < (int)NDIR; i++)
    {
        p = directive;
        q = Dirtab[i];
        while((*p == *q) && (*p))
        {
            p++;
            q++;
        }
        if(*p == *q)break;
    }

    /* Treat the following as the same as some other directive */
    switch(i){
        case NDIR:      return(NOTDIR);    /* not found */
        case ORG2:      return(ORG);
        case ORG3:      return(ORG);
        case EQU2:      return(EQU);
        case DB:        return(BYTE);
        case DW:        return(WORD);
        default:        return((dir_t)i);
    }
}

/* Function: save_label()
 * Description:
 *     Save this label in the label table.
 */

void
save_label(char *plabel, expr_t labval)
{

    extern      LABTAB  *Labtab[];
    extern      ushort  Nlab;
    extern      int     Seg;
    extern      int     Err_check;
    extern      int     Ignore_case;
    extern      char    Local_char;
    extern      char    Module_name[];

    ushort      labsize;
    char        label[LINESIZE];
    int         local_flag;

    /* If this is a local label then build the full label by 
     * concatenating the current module name with the local label.
     * We can't really free local labels at the end of a module because
     * of the two pass nature of TASM.  All labels must be defined on the
     * first pass and must be retained for code generation in the second 
     * pass.
     */
    if(*plabel == Local_char){
        sprintf(label, "%s.%s", Module_name, plabel);
        local_flag = F_LOCAL;
    }
    else{
        strcpy(label, plabel);
        local_flag = 0;
    }

    if(Err_check & EC_DUP_LABELS)
    {
        if(find_label(label) != FAILURE)
        {
            strcpy(Errorbuf,label);
            errlog("Duplicate label:", ALWAYS);
            return;
        }
    }

    /* compute size of label */
    labsize = strlen(label);

    if(labsize >= LABLEN)
    {
        strcpy(Errorbuf,label);
        errlog("Label too long:", ALWAYS);
        return;
    }

    /* Compute size of labtab entry.  The 'lab' buffer is declared as
     * 2 chars.  Grow as necessary.  This approach is a little messy,
     * but avoids saving another pointer and incurring the overhead of
     * another malloc (another 4 bytes).
     */
    GETLABTAB(Nlab) = (LABTAB *)malloc(sizeof(LABTAB) + labsize - 1);
    if(GETLABTAB(Nlab) == NULL){
        sprintf(label, "Cannot malloc for label storage.  NumLabels=%d\n", Nlab);
        errprt(label);
        tasmexit(EXIT_MALLOC);
    }
    strcpy(GETLABTAB(Nlab)->lab, label);

    DEBUG2("Malloc %lx %s\n",(long)GETLABTAB(Nlab),GETLABTAB(Nlab)->lab);

    GETLABTAB(Nlab)->val    = labval;
    GETLABTAB(Nlab)->flags  = (Seg & F_SEG) | local_flag;

    /* If we are ignoring case then convert to upper case always */
    if(Ignore_case) stoupper(GETLABTAB(Nlab)->lab);

    Nlab++;
    return;
}

/* Function: find_label() 
 * Description: 
 *     Find this label in the label table. 
 */ 

int
find_label(char *plabel)
{
    extern      LABTAB  *Labtab[];
    extern      ushort  Lhash[];
    extern      ushort  Nlab;
    extern      pass_t  Pass;
    extern      int     Ignore_case;
    extern      char    Module_name[];
    extern      char    Local_char;

    ushort      i;
    short       j;
    char        firstc;
    char        label[LINESIZE];

    /* If we are looking for a local label then prefix with the module
     * name since that is how it will actually be stored in the table.
     */
    if(*plabel == Local_char)
    {
        sprintf(label, "%s.%s", Module_name, plabel);
    }
    else
    {
        strcpy(label, plabel);
    }

    i = 0;      /* starting point for search */
    if(Ignore_case == TRUE)
    {
        stoupper(label);
    }

    /* On second pass the label table is sorted, so do simple indexing */
    if(Pass != FIRST){
        /* lookup the starting point in the label table to begin
         * the search
         */
        j = *label - 'A';
        if((j >=0) && (j < MAXLHASH)) i = Lhash[j]; 

        for(; i < Nlab; i++)
        {
            if(strcmp(label, GETLABTAB(i)->lab) == SAME) return(i);
        }

    }
    else{
        firstc = *label;
        for(; i < Nlab; i++)
        {
            /* Check for first char match before calling strcmp
             * just for a little more speed.
             */
            if((firstc == *(GETLABTAB(i)->lab)) && 
               (strcmp(label, GETLABTAB(i)->lab) == SAME)) 
                return(i);
        }
    }

    return(FAILURE);
}

/* that's all folks */

