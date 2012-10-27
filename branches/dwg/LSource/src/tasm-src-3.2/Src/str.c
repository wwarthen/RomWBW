/****************************************************************************
 *  $Id: str.c 1.5 1997/11/15 13:13:04 toma Exp $
 **************************************************************************** 
 *  File: str.c
 *
 *  Description:
 *    Various string functions for TASM, the table driven assembler.
 *
 *    Copyright 1989-1995   Speech Technology Incorporated.
 *    Copyright 1997        Squak Valley Software
 *    Restrictions apply to the duplication of this software.
 *    See the COPYRIGH.TXT file on this disk for restrictions.
 *
 *    Thomas N. Anderson
 *    Squak Valley Software
 *    837 Front Street South
 *    Issaquah, WA  98027
 *
 */

//static char *id_str_c = "$Id: str.c 1.5 1997/11/15 13:13:04 toma Exp $";

/* INCLUDES */
#include        "tasm.h"

#ifdef T_MEMCHECK
#include        <memcheck.h>
#endif


/* EXTERNALS */
extern  ushort  Debug;

/******************************************************************/
/* Function: search()
 * Description:
 *     Search for a substring (unanchored).
 *     (Ought to change to a more efficient algorithm like BM).
 */
int
search(
char    *p,             /* String to search */
char    *s)             /* sub string to search for in  p */

{
    int     n;
    char    *ss;
    char    *pp;
    extern  char        Comment_char2;  /* embedded comment char */

    n = 0;
    while((*p != '\0') && (*p != Comment_char2)){
        /* Only start the detail search if we are at the start of a valid
         * symbol.  Allow '.' in symbols so that macro expansion will 
         * work for stuff like: #define equ .equ
         */
        if((isalpha(*p) || *p == '.') && 
                ( (n== 0) ||
                  !( (isalnum(*(p-1))) || (*(p-1) == '_') ) ) ){
            
            pp = p;
            ss = s;
            while(*ss++ == *pp++){
                if(*ss == 0){
                    /* Require the string to match up to the end of a
                     * valid C identifier.
                     */
                    if((isalnum(*pp)) || (*pp == '_')){
                        /* The substring is found in a longer identifier */
                        continue;
                    }
                    else{
                        /* Match found.  Return position. */
                        return(n);
                    }
                }
            }
            /* Gobble the rest of this identifier so we only match
             * whole identifiers and not substrings within identifiers.
             */
            while((isalnum(*p)) || (*p == '_') || (*p == '.') ){
                p++;
                n++;
            }

        }
        else{
            n++;
            p++;
        }
    }

    /* No match found */
    return(-1);

}

/* Function: replace()
 * Description:
 *     Replace substring in the target string.
 */
void
replace(
char    *target,
char    *psearch,
char    *preplace)
{

    short   pos;
    ushort  i;
    char    temp[LINESIZE];

    while((pos = search(target,psearch)) >= 0){
        for(i = 0; i < (ushort)pos; i++)temp[i] = target[i];
        temp[i] = '\0';
        strcat(temp,preplace);
        strcat(temp,&target[(ushort)pos+strlen(psearch)]);
        strcpy(target,temp);
    }
}

/* Function: stouppoer()
 * Description:
 *     Convert string to upper case (in place).
 */
void
stoupper(char    *s)
{
    do{
        if(islower(*s))*s = toupper(*s);
    }while(*++s);
}

/* most libraries provide this now */
#if 0
/* Function: strcmpi()
 * Description:
 *     String compare (stcmp) with case ignore.
 */
int
strcmpi(
char    *s,
char    *p)
{
    int c1;
    int c2;

    do{
        if(islower((c1 = *s)))c1 = toupper(*s);
        if(islower((c2 = *p)))c2 = toupper(*p);
        s++;
        p++;

    }while((c1 == c2) && (c1) && (c2));

    return(c2 -c1);

}
#endif

/* Function: crush()
 * Description:
 *     Remove spaces and tabs from string (in place).
 */
void
crush(char    *s)
{
    int i,j;
    char d[LINESIZE];

    i = 0;
    j = 0;
    do{
        if(!isspace(s[i])){
            d[j++] = s[i];
        }
        else{
            /* Copy the space if we are inside quotes, otherwise discard. */
            if(inquotes(s, i)) d[j++] = s[i];
        }
    } while(s[i++] != '\0');
    d[j++] = '\0';

    /* Copy the crushed string over the top of the source string.  It 
     * should always be shorter.
     */
    strcpy (s, d);

    return;
}


/* Function: remquotes()
 * Description:
 *     Remove quotes from string and return new byte count (in place).
 */
int
remquotes(char *s)
{
    int     i;
    int     j;
    char    c;
    char    cc;
    int     ascii;
    int     starts_with_quote = FALSE;
    char    t[LINESIZE];

    extern char Errorbuf[LINESIZE];

    i = 0;
    j = 0;
    /* copy the string to the error buffer in case we find something
     * wrong with it later (for reporting purposes).
     */
    strcpy(Errorbuf, s);
    DEBUG("remquotes: #%s#\n", s);

    while((isspace(s[i])) && (s[i] != '\0'))i++;
    if(s[i] == '\"'){
        starts_with_quote = TRUE;
        i++;
    }

    while((c = s[i++]) != '\0'){
        /* If a backslash then escape the following character */
        if(c == '\\'){
            cc = s[i++];
            switch(cc){
            case 'n':
               t[j++] = '\n';   /* Newline */
               break;
            case 'r':
               t[j++] = '\r';   /* Carraige Return */
               break;
            case 't':
               t[j++] = '\t';   /* Tab */
               break;
            case 'b':
               t[j++] = '\b';   /* Backspace */
               break;
            case 'f':
               t[j++] = '\f';   /* Formfeed */
               break;
            case '\"':
               t[j++] = '\"';   /* Double quote */
               break;
            case '0':
            case '1':
            case '2':
            case '3':
               /* if numeric then assume 3 digit octal ASCII code */
               ascii = (cc - '0')*64 + (s[i++] - '0')*8;
               ascii = ascii + (s[i++] - '0');
               t[j++] = ascii;
               break;
            default:
               t[j++] = cc;
            }
        }
        else {  /* not backslash */
            t[j++] = s[i-1];
        }

        /* Break out of the loop when we find a double quote that is
         * not escaped by a backslash.
         */
        if ((s[i-1] == '\"') && (s[i-2] != '\\')) break;

    }
    /* Only complain about no trailing quote if there was no starting quote */
    if ((c != '\"') && (starts_with_quote == TRUE))
        errlog ("No terminating quote:", PASS2_ONLY);

    /* Remove the trailing quote */
    if (c == '\"') j--;
    t[j]   = '\0';

    /* Copy the output (t) back into the source (s) */
    for (i = 0; i <= j; i++) s[i] = t[i];

    DEBUG("remquotes: #%s#\n", s);

    return(j);

}

/* Function: strget()
 * Description:
 *     Copy source string to target string until termination conditions are
 *      encountered.
 *     Used to copy labels and instructions only.
 */
int
strget(
char    *ptarget,
char    *psource)
{
    int     cnt;
    int     lastc;
    char    *save_psource;

    extern char Errorbuf[LINESIZE];

/* updated to terminate following an '=' so it will properly copy over
 *  the '*=' part of an expression like '*=*+10' without requiring
 *  a space after the '='.
 * Only used with labels, instructions, and directives which cannot
 * be longer than LABLEN, so detect overruns.
 */
    save_psource = psource;
    cnt   = 0;
    lastc = 0;
    while((*psource != ' ') &&
        (*psource != '\\')&&
        (*psource != '\t')&&
        (*psource != '\0')&&
        (*psource != '\n')&&
        (*psource != ':') &&
        (lastc   != '=')){
        lastc     = *psource;
        *ptarget++ = *psource++;
        cnt++;
        if (cnt >= LABLEN) {
            strcpy(Errorbuf, save_psource);
            errlog ("Label or instruction too long.", PASS2_ONLY);
            break;
        }
    }
    *ptarget = '\0';
    return(cnt);
}

/* Function: lhex_to_bin()
 * Description:
 *     Convert hex digits (ASCII) to binary (long word)
 */

ulong
lhex_to_bin(char    *hex_string)
{
    ulong   word;
    char    *middle;
    ushort  low;
    ulong   hi;
    int     l;
    char    buf[80];

    l = 0;
    while(isxdigit(*hex_string)){
        buf[l++] = *hex_string++;
    }
    buf[l] = '\0';

    if(l > 4){
        middle = &buf[l-4];
        low    = hex_to_bin(middle);
        *middle= '\0';
        hi     = hex_to_bin(buf);
        word   = (hi << 16) + low;
    }
    else{
        word   = hex_to_bin(buf);
    }
    return(word);
}

/* Function: hex_to_bin()
 * Description:
 *     Convert hex digits to (ASCII) to binary (short word) 
 */

ushort
hex_to_bin(char    *hex_string)
{
    ushort  byte;

    byte = 0;

    while(isxdigit(*hex_string)){
        byte  = byte << 4;
        byte += hex_val(*hex_string++);
    }
    return(byte);
}

/* Function: hex_val()
 * Description:
 *     Convert ASCII hex digit to binary value (0-15).
 */

ushort
hex_val(char hex_digit)
{

    ushort  ival;

    if(hex_digit < 'A')
        ival = hex_digit & 0x0f;
    else{
        if(islower(hex_digit))
            ival = (hex_digit - 'a' + 10) & 0x0f;
        else
            ival = (hex_digit - 'A' + 10) & 0x0f;
    }

    return(ival);
}

/*
 * Function:     sort_labels
 * Description:  Sort the label table to facilitate faster access to 
 *               the label values on the second pass.
 */
void
sort_labels(void)
{
    int         i;
    int         j;
    int         k;
    int         bot;
    int         top;
    LABTAB      *tmp_p;

    extern  ushort  Lhash[];
    extern  ushort  Nlab;                  /* number of labels */
    extern  LABTAB  *Labtab[];             /* label pointer table */

    DEBUG("sort: sorting %d labels\n",Nlab);

    /* Bubble sort (shaker sort) */
    top = 0;
    bot = Nlab - 2;
    k   = bot;

    do{
        /* shake to the top */
        for(i = bot; i >= top; i--){
            if(*(GETLABTAB(i)->lab) > *(GETLABTAB(i+1)->lab)){
                /* Swap */
                tmp_p         = GETLABTAB(i);
                GETLABTAB(i)  = GETLABTAB(i+1);
                GETLABTAB(i+1)= tmp_p;
                k = i;
            }
        }
        top = k + 1;

        /* shake to the bottom */
        for(i = top; i <= bot; i++){
            if(*(GETLABTAB(i)->lab) > *(GETLABTAB(i+1)->lab)){
                /* Swap */
                tmp_p         = GETLABTAB(i);
                GETLABTAB(i)  = GETLABTAB(i+1);
                GETLABTAB(i+1)   = tmp_p;
                k = i;
            }
        }
        bot = k - 1;
        DEBUG5("n=%d top=%d bot=%d Lab0=%s Labn=%s\n",Nlab,top,bot,
            (GETLABTAB(0)->lab),(GETLABTAB(Nlab-1)->lab));
    }while(top < bot);

    /* Now build the label index table. 
     * Go backwards through the sorted table so the last assignment to
     * a given index element will be the first for that character in
     * in the table.
     */
    for(i = Nlab-1 ; i >=0 ; i--){
        j = *(GETLABTAB(i)->lab) - 'A';
        if((j >=0 ) && (j < MAXLHASH)) Lhash[j] = i;

    }

}

int
find_comment(char    s[])
{
    int     i;
    char    quote;
    extern  char        Comment_char2;  /* Embedded comment char */

    /* Scan line for position of the start of a comment */

    quote      = '\0'; 
    i          = 0;

    while (s[i] != '\0') {
        if ((s[i]== Comment_char2) && (quote=='\0')) {
            return(i);     
        } else {
            if ((quote == '\0') && ((s[i]=='\'')||(s[i]=='\"'))) {
                quote = s[i];
            } else if (quote == s[i]) {
                quote = '\0';
            }
            i++;
        }
    }
    return(i);
}


int
inquotes(
char    *s,
int     pos)
{
        int     j;
        int     quote;

        /* Check to see of the character at pos is inside quotes. */
        /* First handle the single quote case, which should only
         * have a single character with quotes on either side.
         */
        if (pos > 0){
            if( (s[pos-1] == '\'') && (s[pos+1] == '\'')) return(TRUE);
        }

        quote = 0;
        for (j=0; j < pos; j++) {
            if (s[j]=='\"') quote = !quote;
        }

        if (quote) return(TRUE);
        return(FALSE);

}

/* That's all folks */

