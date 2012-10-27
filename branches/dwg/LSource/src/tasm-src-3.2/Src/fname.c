/****************************************************************************
 *  $Id: fname.c 1.4 1997/11/15 13:08:12 toma Exp $
 **************************************************************************** 
 *  File: fname.c
 *
 *  Description:
 *    File name functions for TASM, the table driven assembler.
 *
 *    Copyright 1989-1995  Speech Technology Incorporated.
 *    Copyright 1997       Squak Valley Software.
 *    Restrictions apply to the duplication of this software.
 *    See the COPYRIGH.TXT file on this disk for restrictions.
 *
 *    Thomas N. Anderson
 *    Squak Valley Software
 *    837 Front Street South
 *    Issaquah, WA  98027
 *
 */

//static char *id_fname_c = "$Id: fname.c 1.4 1997/11/15 13:08:12 toma Exp $";

/* INCLUDES */
#include "tasm.h"

#ifdef T_MEMCHECK
#include <memcheck.h>
#endif


/* Static */
static char fname_list[MAXFILES][PATHSIZE];

static int  SourceIncludeDepth = 0;


/******************************************************************/
/* Function: fname_push()
 * Description:
 *     Save the indicated filename (by fd) for later use by errlog().
 */
void
fname_push(
char    *fname)         /* File name                      */

{

        SourceIncludeDepth++;

        if( (SourceIncludeDepth >=0)         && 
            (SourceIncludeDepth < MAXFILES)  && 
            (strlen(fname) < PATHSIZE))
        {
            strcpy( &fname_list[SourceIncludeDepth][0], fname);
        }
}

/******************************************************************/
/* Function: fname_pop()
 * Description:
 *     Pop a source filename off the source file name stack.
 */
void
fname_pop( void )

{
        SourceIncludeDepth--;
}

/******************************************************************/
/* Function: fname_get()
 * Description:
 *     Fetch the current source file name.
 */
char *
fname_get( void ) 
{
        return( &fname_list[SourceIncludeDepth][0]);
}

/* That's all folks. */
