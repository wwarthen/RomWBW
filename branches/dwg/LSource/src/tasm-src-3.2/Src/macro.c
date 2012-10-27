/****************************************************************************
 *  $Id: macro.c 1.10 2000/06/08 01:50:26 toma Exp $
 **************************************************************************** 
 *  File: macro.c
 *
 *  Description:
 *    Modules to save and expand macros for TASM, the table driven assembler.
 *    Also, expression evaluator.
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
 *
 *      See rlog for file revision history.
 *
 */

//static char *id_macro_c = "$Id: macro.c 1.10 2000/06/08 01:50:26 toma Exp $";

/* INCLUDES */
#include        "tasm.h"

#ifdef T_MEMCHECK
#include        <memcheck.h>
#endif

/* DEFINES */


#define         MAXMACRO        1000   /* Max number of macros           */
#define         MAXPARMS        10     /* Max number of parms per macro  */
#define         MAXARGSIZE      16     /* Max length of parm  label      */

/* Constants to indicate the rules for finding the end of a string for
 * save_string() (malloc).
 */
typedef enum {STR_NULLEND, STR_SPACEEND} strend_t;


/* STATIC */
int     Num_macros             = 0;
int     Num_macros_predefined  = 0;
char    Emptystring[] = "";

static  ptok_t  Lasttok;
static  int     Elevel;
static  char    Last_inst[10];

/* these pointer arrays keep track of where in heap the appropriate
 *  macro definitions are */
static  char    *macrolabel[MAXMACRO+1];
static  char    *macrodef[MAXMACRO+1];

/* Make the following static so that they are available to add to macro
 * definitions with the DEFCONT directive.
 */

static  int     Nparms;
static  char    Parm[MAXPARMS+1][MAXARGSIZE+1];

/* STATIC FUNCTION PROTOTYPES */
static void      add_reg    (char *s);
static expr_t    eval       (void);
static ptok_t    gettok     (expr_t *tokval);
static expr_t    nextval    (void);
static int       next_operator (char *s);
static tok_t     toktype    (ptok_t token);
static char     *save_string(char *s, strend_t strtype);


/* EXTERNALS */
extern  ushort  Debug;
extern  char    Errorbuf[LINESIZE];

/************************************************************************/
/* FUNCTIONS */

/* Function: macro_expand()
 * Description:
 *     Scan an input line for an invocation of a macro.
 *     If one is found then expand it.
 */
void
macro_expand(
char    *src,             /* Source line to scan          */
char    *target)          /* Put expanded line here       */
{

    int     len;
    int     pos;
    int     i,j;
    int     macargi;
    int     nnparms;
    int     c;
    int     comment;
    int     macro_found;
    char    parm[MAXPARMS+1][MAXARGSIZE+1];
    char    *s;
    char    *ss;
    char    *mm;
    char    *pparm;
    char    *save_targ;
    char    sbuf[LINESIZE];
    char    comment_buf[LINESIZE];

    extern  char    Comment_char1;

    save_targ = target;
    s         = sbuf;

    strcpy(target,src);

    if(Num_macros == 0)return;

    /* First make sure this is not a preprocessor command (define, ifdef,
     *  or ifndef) because if it is, to expand it would mess things up.
     *  For now require first character to be a '#'.  This could cause
     *  problems if the user does things like '.define' or '#word'.
     *
     *  Actually, expand should be done on everything except
     *  DEFINE, IFDEF, IFNDEF  (fix later).
     *
     *  Also, do not expand comments.
     */
    /* Skip past leading white space */
    while( isspace(*src) && (*src != '\0')) src++;
    if((*src == '#') || (*src == Comment_char1))return;

    /* locate the position of the start of a comment (if any) */
    comment = find_comment(target); 
    if (comment > 0){
        strcpy( comment_buf, &target[comment]);
        target[comment] = '\0';
    }
    else{
        comment_buf[0] = '\0';
    }

    do{
      /* Continue to scan for macros until a complete scan results in 
       * no hits.  This, to ensure that multiple instances on a line
       * and macros-in-macros get expanded.
       */
      macro_found = FALSE;

      for(i=0; i < Num_macros; i++){
        target =  save_targ;
        strcpy(s, save_targ);

        /* look for macro label in the input string */
        if((pos = search(s,macrolabel[i])) >= 0){
            /* We have found a match.
             * Abort if it is after the start of comments or in quotes.
             */
            if(inquotes(s, pos)) continue;

            macro_found = TRUE;

            /* first extract parameters, if any */
            nnparms = 0;
            len = strlen(macrolabel[i]);
            ss = &s[pos+len];
            if(*ss == '('){
                ss++;
                do{
                    j = 0;
                    while((*ss != ',') && (*ss != ')')
                                       && (*ss != '\0')
                                       && (j < MAXARGSIZE)){
                        parm[nnparms][j++] = *ss++;
                    }
                    parm[nnparms][j] = '\0';
                    nnparms++;
                }while((*ss++ != ')') && (*ss != '\0')&&( nnparms < MAXPARMS));
            }


            /* copy preceeding part to temp buffer directly */
            for(j=0; j < pos; j++)*target++ = s[j];

            /* now copy the macro expansion and expand args as we go */
            mm = macrodef[i];
            while((c = *mm++) != '\0'){
               if(c == '?'){
                   macargi = *mm++ - '0';
                   /* Make sure we saw the appropriate number of macros
                    * in the source.
                    */
                   if (macargi >= nnparms) {
                       errlog("Macro expects args but none found",   
                           PASS2_ONLY);
                   }
                   else{
                       pparm = parm[macargi];
                       while(*pparm)*target++ = *pparm++;
                   }
               }else
                   *target++ = c;
            }

            /* copy the rest of the line in */
            while(*ss)*target++ = *ss++;
            *target = 0;

            if(target > (save_targ + LINESIZE - 20)){
                errlog("Macro expansion too long         ",   PASS2_ONLY);
                return;
            }

        }
      } /* end for */
    }while (macro_found == TRUE);

    /* Append the comment that was removed (if any) */
    if(comment > 0) strcat (target, comment_buf);

}


/* Function: macro_get_index()
 * Description:
 *     Find the index to the macro, if it exists.
 */

int
macro_get_index(char *s)
{

        int     i;

        for(i = 0; i < Num_macros; i++){
            if(strcmp(s,macrolabel[i]) == SAME) return(i);
        }

        return (-1);

}


/* Function: macro_save()
 * Description:
 *     Save this macro definition.
 */

void
macro_save(char *s)
{

    static char    argtoken[] = {'?', '0','\0'};
    int     j;
    char    *macp;
    char    buf[LINESIZE];
    char    *p;

    /* discard initial whitespace */
    while((*s == ' ') || (*s == '\t'))s++;

    /* save macro label (excluding arguments) */
    p = buf;
    while((*s != ' ') && (*s != '\t') && (*s != '(') && (*s != '=') && (*s))
        *p++ = *s++;

    *p++ = '\0';

    macrolabel[Num_macros] = save_string(buf, STR_NULLEND);

    if(*s == '=')s++;       /* gobble '=' in macro defs from the command line */

    Nparms = 0;
    if(*s == '('){
        s++;
        do{
            j = 0;
            while((*s != ',') && (*s != ')') && (*s)
                          && (j < MAXARGSIZE))
                           Parm[Nparms][j++] = *s++;

            Parm[Nparms][j] = '\0';
            Nparms++;
        }while((*s++ != ')') && ( Nparms < MAXPARMS));
    }

    /* SKip forward to start of macro definition */
    while((*s == ' ') || (*s == '\t'))s++;

    /* make temp copy to replace parm tokens (since resulting string
     * may be longer).
     */ 
    strcpy(buf, s);

    /* substitute the appropriate argument strings in macro definition.
     *  Replace each argument with a two character string of the
     *  form '?n' where n = 0-9. 
     */
    macp = buf;
    for(j = 0; j < Nparms; j++){
        argtoken[1] = '0' + j;
        replace(macp,Parm[j],argtoken);
    }

    macrodef[Num_macros] = save_string(buf, STR_NULLEND);

    Num_macros++;

    if(Num_macros >= MAXMACRO){
        sprintf(Errorbuf,"MAXMACRO=%d",MAXMACRO);
        errlog("maximum number of macros exceeded ",   ALWAYS);
    }
}


/* Function: macro_append()
 * Description:
 *     Add to an existing macro (the last one defined).
 */

void
macro_append(char *s)
{

    static char    argtoken[] = {'?', '0','\0'};
    int     j;
    int     cnt;
    char    *macp;
    char    *ss;

    /* discard initial whitespace */
    while((*s == ' ') || (*s == '\t'))s++;

    /* Compute additional bytes needed to save this */
    cnt = 0;
    ss = s;
    while(*ss++)cnt++;

    /* Increase the size of the memory block used to save the macro */
    ss = macrodef[Num_macros-1];
    while(*ss++)cnt++;
    macp = (char *)realloc(macrodef[Num_macros-1], cnt + 2);
    if(macp == NULL)
    {
        errprt("tasm: Cannot realloc for macro definition\n");
        tasmexit(EXIT_MALLOC);
    }
    macrodef[Num_macros-1] = macp;

    /* tag additional stuff on the end of the existing macro buffer */
    strcat(macp,s);

    /* Substitute the appropriate argument strings in macro definition.
     *  Replace each argument with a two character string of the
     *  form '?n' where n = 0-9.
     */
    for(j = 0; j < Nparms; j++)
    {
        argtoken[1] = '0' + j;
        replace(macp,Parm[j],argtoken);
    }

    if(Num_macros >= MAXMACRO)
    {
        sprintf(Errorbuf,"MAXMACRO=%d",MAXMACRO);
        errlog("Maximum number of macros exceeded ",   ALWAYS);
    }
}


/* Function: macro_free()
 * Description:
 *     Free all the macro storage expect those macros defined on the 
 *     the command line.
 */

void
macro_free(int freeAll)
{
    int macro;

    if ( freeAll )  macro = 0;
    else            macro = Num_macros_predefined;

    for (; macro < Num_macros; macro++)
    {
        if (macrodef[macro] != Emptystring) free ( macrodef   [ macro ] );  
        free ( macrolabel [ macro ] ); 
    }

    if (freeAll) Num_macros = 0;
    else         Num_macros = Num_macros_predefined;

}

/*********************************************************************/
/* Expression evaluation functions */

/* Function: val()
 * Description:
 *     Compute value of an expression.    
 *     This function merely sets up static pointers to the beginning
 *     of the expression and calls eval() to do the real work.
 */
expr_t
val(char *expr_buf)
{
    extern  char    *Expr;
    expr_t  ival;
    extern  int     Err_check;
    extern  line_t  Linetype;

    /* If expression surrounded by parens then complain if strict 
     * error checking is enabled.  This is to avoid ambiguity with
     * some micros that use a paren group around an address
     * to indicate indirection.  The error message is just a warning.
     */
    if(Err_check & EC_OUTER_PAREN){
        if(Linetype == INSTRUCT){
            if((*expr_buf == '(') && (expr_buf[strlen(expr_buf)-1] == ')')){
                strcpy(Errorbuf,expr_buf);
                errlog("Invalid operand.  No indirection for this instruction.",
                      PASS2_ONLY);
            }
        }
    }
    /* Check for non-unary operators starting out.
     *  This is sometimes useful since some tables use valid operators
     *  to indicate addressing mode.  For example, the TMS7000
     *  uses '%' to indicate immediate.  Thus, a user may give
     *  %01 as an operand and if no immediate instruction applied
     *  it could match a wild card and no warning would be issued.
     *  Further ambiguity arises from the fact that % could either
     *  be a binary prefix, or a stray modulo operator.
     *  Such is life when trying to accommodate many dialects.
     */ 
    if(Err_check & EC_NON_UNARY){
        if(Linetype == INSTRUCT){
            if((*expr_buf == '%') || /* This could be OK if binary pref*/
               (*expr_buf == '*') || /* This could be OK if PC         */
               (*expr_buf == '/') ||
               (*expr_buf == '<') ||
               (*expr_buf == '>') ||
               (*expr_buf == '=') ||
               (*expr_buf == '&') ||
               (*expr_buf == '!') ){
                strcpy(Errorbuf,expr_buf);
                errlog("Non-unary operator at beginning of expression.",
                      PASS2_ONLY);
            }
        }
    }
    /* Go ahead and evaluate anyway */

    /* Initialize parsing buffer pointer to start of expression
     *  buffer and evaluate */
    Lasttok = UNDEFTOKEN;
    Elevel  = 0;        /* eval stack level  */
    Expr = expr_buf;
    ival = eval();

    if (Elevel != 0){
        /* Parenthesis are imbalanced */
        strcpy(Errorbuf, expr_buf);
        errlog ("Paren imbalance.",   PASS2_ONLY);
    }

    return(ival);
}

/* Function: eval()
 * Description:
 *     Compute value of expression in the expression buffer
 *     Scan left to right calling eval recursively to evaluate the
 *     remaining portion of the expression.
 */
static expr_t
eval(void)
{
    expr_t  ival;
    expr_t  tokval;
    ptok_t  token;

    ival    = 0;
    Elevel++;           /* eval() stack level */

    /* Extract next token from line and perform cooresponding action.
     *  Evaluate recursively from left to right.
     *  Note that because of the recursive nature of the
     *  parsing, if expressions are not grouped with
     *  parenthesis, they will be evaluated from right to left.
     *  Thus, 1+2*3+4 = 1+(2*(3+4)) = 15
     */
    while((token = gettok(&tokval)) != EOL){

        switch(token){
        case LABEL:
            ival = tokval;
            break;
        case PLUS:
            ival += nextval();
            break;
        case MINUS:
            ival -= nextval();
            break;
        case MULTIPLY:
            ival *= nextval();
            break;
        case DIVIDE:
            ival /= nextval();
            break;
        case MODULO:
            ival %= nextval();
            break;
        case SHIFTR:
            ival >>= nextval();
            break;
        case SHIFTL:
            ival <<= nextval();
            break;
        case BINAND:
            ival &= nextval();
            break;
        case BINOR:
            ival |= nextval();
            break;
        case BINEOR:
            ival ^= nextval();
            break;
        case EQUAL:
            ival = (ival == nextval());
            break;
        case LESSTHAN:
            ival = (ival < nextval());
            break;
        case GREATERTHAN:
            ival = (ival > nextval());
            break;
        case GEQUAL:
            ival = (ival >= nextval());
            break;
        case LEQUAL:
            ival = (ival <= nextval());
            break;
        case NOTEQUAL:
            ival = (ival != nextval());
            break;
        case TILDE:
            ival = (~(uexpr_t)nextval());
            break;
        case LOGICALNOT:
            ival = (!(uexpr_t)nextval());
            break;
        case PC:
            ival = tokval;
            break;
        case LITERAL:
            ival = tokval;
            break;
        case CHAR:
            ival = tokval;
            break;
        case LPAREN:
            ival = eval();
            break;
        case RPAREN:
            Elevel--;
            return(ival);
        case SPACE:
            break;
		  case EOL:
				break;
		  case UNDEFTOKEN:
        default:
            strcpy(Errorbuf,"");
            errlog("Unknown token.   ",   PASS2_ONLY);
            break;
        }
    }
    Elevel--;
    return(ival);

}

/* Function: gettok()
 * Description:
 *     Extract the next token from the expression buffer and return
 *     the token ID and value of the token if applicable (for labels
 *     and constants.
 */
static ptok_t
gettok(expr_t *tokval)
{
    extern  char    *Expr;          /* Pointer to expression buffer */
    extern  pc_t    Pc;             /* Instruction pointer */
    extern  LABTAB  *Labtab[];       /* Label data */
    extern  char    Local_char;     /* First char for local labels */

    int     i;
    int     base;
    int     lastc;
    expr_t  tval;
    char    lbuf[80];
    ptok_t  tok;
    tok_t   ttype;

    tok = UNDEFTOKEN;

    switch(*Expr){
    case '\0': tok = EOL;               break;
    case '+' : tok = PLUS;      Expr++; break;
    case '-' : tok = MINUS;     Expr++; break;
    case '/' : tok = DIVIDE;    Expr++; break;
    case '(' : tok = LPAREN;    Expr++; break;
    case ')' : tok = RPAREN;    Expr++; break;
    case '~' : tok = TILDE;     Expr++; break;
    case '&' : tok = BINAND;    Expr++; break;
    case '|' : tok = BINOR;     Expr++; break;
    case '^' : tok = BINEOR;    Expr++; break;
    case ' ' : tok = SPACE;     Expr++; break;
    case '\t': tok = SPACE;     Expr++; break;

    case '*':       /* allow '*' to be MULTIPLY or PC.  If followed by
                   nothing or an operator then it is the PC */
        Expr++;
        if(next_operator(Expr) >= 0){
            *tokval = Pc;
            tok = PC;
        }
        else{
            tok = MULTIPLY;
        }
        break;

    case '\'':
        Expr++;
        /* Make sure that a valid character follows.
         * Premature end of expression can result from stuff like 
         *     .byte ';'   
         * which is not parsed correctly (; is not escaped in single
         * quotes).  This is all a side effect of supporting 
         * char tokens with a single quote and not paired quotes.
         */
        if (*Expr == '\0'){

            *tokval = 0;
            strcpy(Errorbuf,"");
            errlog("Premature end of CHAR token",   PASS2_ONLY);
        }
        else
        {
            *tokval = *Expr++;

            if(*Expr == '\''){
                Expr++;
            }
            else{
                strcpy(Errorbuf,(Expr - 2));
                errlog("No terminating quote:",   PASS2_ONLY);

            }
             
        }
        tok = CHAR;
        break;

    case '>':
        Expr++;
        switch(*Expr){
        case '>': tok = SHIFTR;         Expr++; break;
        case '=': tok = GEQUAL;         Expr++; break;
        default : tok = GREATERTHAN;            break;
        }
        break;

    case '<':
        Expr++;
        switch(*Expr){
        case '<': tok = SHIFTL;         Expr++; break;
        case '=': tok = LEQUAL;         Expr++; break;
        default : tok = LESSTHAN;               break;
        }
        break;

    case '=':       /* accept either '=' or '==' for equal comparison */
        Expr++;
        if(*Expr == '=')Expr++;
        tok = EQUAL;
        break;

    case '!':       /* not equal  or  logical not */
        Expr++;
        if(*Expr == '=')
        {
            Expr++;
            tok = NOTEQUAL;
        }
        else
        {
            tok = LOGICALNOT;
        }
        break;


    case '%':       /* allow % to be either modulo or binary prefix */
        Expr++;
        /* Assume it is binary radix specifier unless the context implies 
         * the need for a binary operator.
         */
        ttype = toktype(Lasttok);
        if((ttype == TOK_VAL) || (ttype == TOK_RPAREN)){
            tok = MODULO;
        }else{
            tval  = 0;
            while((*Expr == '0') || (*Expr == '1')){
               tval *= 2;
               tval += hex_val(*Expr++);
            }
            *tokval = tval;
            tok = LITERAL;
        }
        break;

    case '$':       /* allow $ to be either PC or hex prefix */
        Expr++;
        if(isxdigit(*Expr)){
            tval  = 0;
            base = 16;
            while(isxdigit(*Expr)){
               tval *= base;
               tval += hex_val(*Expr++);
            }
            *tokval = tval;
            tok = LITERAL;

        }else{
            *tokval = Pc;
            tok = PC;
        }
        break;

    case '@':       /* allow @ for alternate octal prefix */
        Expr++;
        tval  = 0;
        while(isdigit(*Expr)){
            tval *= 8;
            tval += hex_val(*Expr++);
        }
        *tokval = tval;
        tok = LITERAL;
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
        /* numeric literal */
        base = 10;              /* default base = decimal */
        i = 0;
        while(isxdigit(*Expr))lbuf[i++] = *Expr++;
        lbuf[i] = '\0';
        /* check for last character being 'd' or 'b'.  Since
         *  these are valid hex digits they won't terminate
         *  the literal even when they are supposed to
         *  be radix suffixes. */
        lastc = *(Expr -1);
        if(islower(lastc))lastc = toupper(lastc);
        if(((*Expr != 'H') && (*Expr != 'h'))
            && ((lastc == 'B') || (lastc == 'D'))){
                /* back up one character */
                Expr--;
                lbuf[--i] = '\0';
        }

        switch(*Expr){
            case 'h':
            case 'H':               /* hexadecimal base */
               base = 16;
               Expr++;
               break;

            case 'B':               /* binary base */
            case 'b':
               base = 2;
               Expr++;
               break;
            case 'Q':
            case 'q':
            case 'O':               /* octal base */
            case 'o':
               base = 8;
               Expr++;
               break;

            case 'D':               /* decimal base */
            case 'd':
               base = 10;
               Expr++;
               break;

            default:
               break;

        }

        tval     = 0;
        i       = 0;
        while(lbuf[i] != '\0'){
            tval *= base;
            tval += hex_val(lbuf[i++]);
        }
        *tokval = tval;
        tok = LITERAL;
        break;

    default:
        if((isalpha(*Expr)) || (*Expr == '_') || (*Expr == Local_char)){
            i = 0;
            while(isalnum(*Expr) || 
                         (*Expr == '_') || 
                         (*Expr == '.') ||
                         (*Expr == Local_char))
               lbuf[i++] = *Expr++;

            lbuf[i] = '\0';


            if((i = find_label(lbuf)) != FAILURE){
                *tokval = GETLABTAB(i)->val;
                tok = LABEL;
            }
            else{

                /* Do not tolerate undefined labels in EQUate statements
                 * even on pass 1.
                 */
                if ( isequate () ){
                    strcpy(Errorbuf,lbuf);
                    errlog("Forward reference in equate:",   ALWAYS);
                    *tokval = UNDEF_LABVAL;
                }
                else{
                    strcpy(Errorbuf,lbuf);
                    errlog("Label not found:",   PASS2_ONLY);
                    *tokval = UNDEF_LABVAL;
                }
                tok = LABEL;
            }

        }
        else{
            sprintf(Errorbuf,"%c", *Expr);
            errlog("Unknown token:",   PASS2_ONLY);
            tok = UNDEFTOKEN;
            Expr++;
        }
        break;
    }

    if(tok != SPACE){
        Lasttok = tok;
    }

    return(tok);

}

/* Function: nextval()
 * Description:
 *     Extract the value of the next token in the expression buffer.
 */
static expr_t
nextval(void)
{

    expr_t              tokval;
    ptok_t              token;
    tok_t               ttype;
    extern      char    *Expr;          /* Pointer to expression buffer */

    /* Ignore spaces */
    while((token  = gettok(&tokval)) == SPACE) /* void */;

    /* Catch the unary operators here */
    switch(token){
    case MINUS:        return (-nextval());
    case TILDE:        return (~(uexpr_t)nextval());
    case LOGICALNOT:   return (!(uexpr_t)nextval());
    default: /* OK */  break;
    }

    ttype  = toktype(token);


    switch(ttype){
    case TOK_VAL:
        return(tokval);

    case TOK_LPAREN:
        return(eval());

    case TOK_BINOP:
        sprintf(Errorbuf,"%c", *(Expr-1));
        errlog("Binary operator where a value expected:",   PASS2_ONLY);
        break;

    case TOK_UNOP:
    default:
        sprintf(Errorbuf,"%s", (Expr-1));
        errlog("Invalid token where value expected:",   PASS2_ONLY);

    }

    return(0L);

}


tok_t
toktype(ptok_t token)
{

        switch(token){
        case PLUS:
        case MINUS:              /* could be UNOP */
        case MULTIPLY:
        case DIVIDE:
        case MODULO:
        case SHIFTR:
        case SHIFTL:
        case BINAND:
        case BINOR:
        case BINEOR:
        case EQUAL:
        case LESSTHAN:
        case GREATERTHAN:
        case GEQUAL:
        case LEQUAL:
        case NOTEQUAL:
                return(TOK_BINOP);

        case TILDE:
        case LOGICALNOT:
                return(TOK_UNOP);

        case PC:
        case LABEL:
        case LITERAL:
        case CHAR:
                return(TOK_VAL);

        case RPAREN:
                return(TOK_RPAREN);

        case LPAREN:
                return(TOK_LPAREN);

		  case UNDEFTOKEN:
	     case EOL:	
        case SPACE:
        default:
                return(TOK_VOID);
        }
}

/* Function: next_operator()
 * Description:
 *     See if the next non whitespace character in s is an operator or not
 *
 * Return:
 *     1        if operator is found
 *     0        if null is found
 *     -1       if a non-operator is found
 */
static int 
next_operator(char *s)
{
    /* scan forward until non-white or null is found */
    while((*s) && (isspace(*s)))s++;

    if(*s == '\0')return(0);
    if(isalnum(*s)) return(-1);
    if(*s == '(')   return(-1);
    if(*s == '$')   return(-1);
    if(*s == '@')   return(-1);

    return(1);
}

/* Function: read_table()
 * Description:
 *     Read instruction set definition table
 */

void
read_table(
char    *pn)    /* part number */
{

    char    tab_filename[LINESIZE];
    char    *tabpath;
    char    buf[LINESIZE];
    FILE    *fp_tab;
    char    errbuf[LINESIZE];
    char    *s;
    char    *p;
    int     i;
    int     nextc;

    extern  char    Banner[];
    extern  ushort  Num_instr;
    extern  ushort  Num_reg;
    extern  ushort  Ihash[];
    extern  int     Ols_first;
    extern  char    Wild_char;
    extern  int     Wordsize;
    extern  int     No_arg_shift;

    Num_instr = 0;
    Num_reg   = 0;
    Last_inst[0] = '\0';

    /* Show version of the file */
    //DEBUG("%s\n", id_macro_c );

    /* Initialize the hash table.  Set each element to a large
     *    value which will be reduced as the instruction table
     *    is read in. 
     */
    for(i = 0; i < MAXIHASH; i++)Ihash[i] = MAXINSTR;

    tabpath = getenv("TASMTABS");
    if(tabpath == NULL)
    {
        sprintf(tab_filename,"tasm%s.tab",pn);
    }
    else
    {
        sprintf(tab_filename,"%s/tasm%s.tab",tabpath,pn);
    }

    fp_tab = fopen( tab_filename, "r");
    if(fp_tab == NULL)
    {
        sprintf(errbuf,"tasm: table file open error on %s\n",
               tab_filename);
        errprt(errbuf);
        tasmexit(EXIT_FILEACCESS);
    }

    /* Read the first line */
    if(fgets( buf, LINESIZE-1, fp_tab) == NULL)
    {
        tasmexit(EXIT_FILEACCESS);
    }

    /* the first line should contain the title (Banner) */
    /* look for starting quote */
    s = buf;
    p = Banner;
    while(*s++ != '"') /* void */;  
    while((*s   != '"') && (*s != '\0'))*p++ = *s++;
    *p = '\0';

    while(fgets( buf, LINESIZE-1, fp_tab) != NULL)
    {
        /* Lines that start with '.' are Table directives */
        if(buf[0] == '.'){
            if(strncmp(&buf[1],"MSFIRST"   ,7) == SAME) Ols_first    = FALSE;
            if(strncmp(&buf[1],"WORDADDRS" ,9) == SAME) Wordsize     = 2;
            if(strncmp(&buf[1],"NOARGSHIFT",10)== SAME) No_arg_shift = TRUE;
            if(strncmp(&buf[1],"REGSET"    ,6) == SAME) add_reg(&buf[7]);
            if(strncmp(&buf[1],"ALTWILD"   ,7) == SAME){
                Wild_char = '@';
                nextc     = buf[8];
                if((nextc > 32) && (nextc < 128)) Wild_char = nextc;
            }

        }
        else{    
            add_instruction(buf);
        }
    }

    /* set all unused elements in the hash table to point to
     *  the beginning of the Optab. */
    for(i = 0; i < MAXIHASH; i++)
        if(Ihash[i] > Num_instr)Ihash[i] = 0; 
    
    /* Close the Table file */
    fclose(fp_tab);

}

/* Function: add_instruction()
 * Description:
 *     Add an instruction to the instruction set definition tables
 */
void
add_instruction(char *s)
{
    extern  ushort  Num_instr;
    extern  ushort  Ihash[];
    extern  OPTAB   *Optab[];

    ushort  cfirst;
    ubyte   obytes;
    char    *ss;
    int     i;
    char    buf[LINESIZE];
    OPTAB   *op;

    /* If we have exceeded the max number of instructions, abort */
    if(Num_instr >= MAXINSTR){
        errprt("tasm: Max number of instructions exceeded\n");
        tasmexit(EXIT_FATALERROR);
    }

    /* If the first character is not A-Z then ignore */
    if((*s < 'A') || (*s > 'Z'))return;

    if(*s != '\0'){
        /* Update the hash table.  
         * The hash table has an entry for each letter A-Z
         *  indicating the point in the Optab to start 
         *  looking for a match (a simple algorithm, but
         *  it significantly speeds things up).   
         */
        i = HASHKEY(s);
        Ihash[i] = min(Ihash[i],Num_instr);

        /* Malloc memory for the Optab element */
        op = (OPTAB *)malloc(sizeof(OPTAB));
        if(op == NULL)
        {
            errprt("tasm: Cannot malloc for optab storage\n");
            tasmexit(EXIT_MALLOC);
        }
        Optab[Num_instr] = op;

        /* Process instruction string.
         * Malloc memory for it and copy to that memory.
         */
        op->instruction = save_string(s, STR_SPACEEND);

        if(strcmp(op->instruction, Last_inst) == SAME)
            op->same_inst = TRUE;
        else
            op->same_inst = FALSE;

        strcpy(Last_inst, op->instruction);

        /* skip to end of instruction */
        while((*s != ' ') && (*s != '\t')) s++;

        /* Read args */
        while(isspace(*s))s++;
        /* if the args are just double quotes then no arg is needed */
        if(*s == '"'){
            op->args = save_string("", STR_SPACEEND);
            s += 2;             /* skip past the double quotes */
        }
        else{
            op->args = save_string(s, STR_SPACEEND);
            while(!isspace(*s)) s++;
        }

        /* Read opcode (in hex) */
        while(isspace(*s))s++;
        op->opcode = lhex_to_bin(s);
        ss = s;       /* remember current position to compute number of bytes */
        while(isxdigit(*s))s++;
        obytes = (s - ss)/2;
        op->obytes = obytes;

        /* Read number of bytes total (in hex) */
        while(isspace(*s))s++;
        op->abytes = hex_to_bin(s) - obytes;
        while(isxdigit(*s))s++;

        /* Read Special case modifier   */
        while(isspace(*s))s++;
        if(*s){
            cfirst = (ubyte)*s++ << 8;
            op->modop = cfirst | (ubyte)(*s);
            while(isalnum(*s))s++;
        }
        else{
            op->modop = 0;
        }

        /* Read class (in hex) */
        while(isspace(*s))s++;
        if(*s)
            op->iclass = (ubyte)hex_to_bin(s++);
        else
            op->iclass = 1;

        /* next two fields (arg shift and or values) are
         *  optional.  Only procede to read these if
         *  the next non whitespace is a valid hex digit. 
         */

        while(isspace(*s))s++;
        if(isdigit(*s)){
            /* Read arg left shift value */
            if(*s){
                op->shift = (ubyte)hex_to_bin(s);
                while(isalnum(*s))s++;
            }
            else
                op->shift = 0;

            /* Read arg binary or mask (in hex) */
            while(isspace(*s))s++;
            if(*s){
                op->bor = lhex_to_bin(s);
                while(isalnum(*s))s++;
            }
            else
                op->bor = 0;
        }
        else{
            op->shift = 0;
            op->bor = 0;
        }    
        if(Debug){
            sprintf(buf,"%-6s %-10s %4x %x %x  %c%c %x %x %lx\n",
                   op->instruction,
                   op->args,
                   (short)op->opcode,
                   op->obytes,
                   op->abytes,
                   (op->modop >> 8) ,
                   (op->modop & 0x7f),
                   op->iclass,
                   op->shift,
                   op->bor);
            DEBUG(buf,0);
        }
        Num_instr++;
    }
}

/* Function: add_reg()
 * Description:
 *     Add a register definition to the table
 */
static void
add_reg(char *s)
{
    extern  ushort   Num_reg;
    extern  REGTAB  *Regtab[];

    char    buf[LINESIZE];
    REGTAB  *op;

    /* If we have exceeded the max number of Register definitions, abort */
    if(Num_reg >= MAXREG){
        errprt("tasm: Max number of registers exceeded\n");
        tasmexit(EXIT_FATALERROR);
    }

    while(isspace(*s))s++;

    if(*s != '\0'){

        /* Malloc memory for the Regtab element */
        op = (REGTAB *)malloc(sizeof(REGTAB));
        if(op == NULL){
            errprt("tasm: Cannot malloc for regtab storage\n");
            tasmexit(EXIT_MALLOC);
        }
        Regtab[Num_reg] = op;

        /* Process instruction string.
         * Malloc memory for it and copy to that memory.
         */
        op->reg = save_string(s, STR_SPACEEND);

        /* skip to end of instruction */
        while((*s != ' ') && (*s != '\t')) s++;

        /* Read opcode (in hex) */
        while(isspace(*s))s++;
        op->opcode = lhex_to_bin(s);
        while(isxdigit(*s))s++;

        /* Read class (in hex) */
        while(isspace(*s))s++;
        if(*s)
            op->iclass = (ubyte)hex_to_bin(s++);
        else
            op->iclass = 1;

        if(Debug){
            sprintf(buf,"%-6s %4x %x\n",
                   op->reg,
                   (short)op->opcode,
                   op->iclass);
            DEBUG(buf,0);
        }
        Num_reg++;
    }
}

/* Function: save_string()
 * Description:
 *     Save a string in the heap (malloc).
 */

static char *
save_string(
char    *s,                     /* string to save */
strend_t strtype)               /* type of string (to determine length) */
{
        int     i;
        char    buf[LINESIZE];
        char    *p;

        i = 0;
        switch(strtype){
        case STR_NULLEND:
            while(*s) buf[i++] = *s++;
            break;

        case STR_SPACEEND:
            while((*s) && (!isspace(*s))) buf[i++] = *s++;
            break;

        default:
            errprt("Bad string type.\n");
            tasmexit(EXIT_FATALERROR);

        }
        buf[i++] = '\0';
        /* if we were asked to save an empty string, then avoid the malloc */
        if(i == 1) return(Emptystring);
        p = (char *)malloc(i);
        if(p == NULL){
            errprt("Cannot malloc for string storage.\n");
            tasmexit(EXIT_MALLOC);
        }
        strcpy(p,buf);
//        DEBUG2("Malloc %x %s\n",(int)p,p);
        return(p);
}


/* that's all folks */

