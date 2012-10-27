/****************************************************************************
 *  $Id: tasmmain.c 1.3 1997/11/15 13:09:09 toma Exp $
 ****************************************************************************
 *  File: tasmmain.c
 *
 * Table Driven Absolute Assembler.
 *
 * Copyright 1985-1995  Speech Technology Incorporated.
 * Copyright 1997       Squak Valley Software.
 * Restrictions apply to the duplication of this software.
 * See the COPYRIGH.TXT file on this disk for restrictions.
 *
 *  Thomas N. Anderson
 *  Squak Valley Software
 *  837 Front Street South
 *  Issaquah, WA  98027
 *
 *  See rlog for revision history.
 *
 *
 */

//static char *id_tasmmain_c = "$Id: tasmmain.c 1.3 1997/11/15 13:09:09 toma Exp $";

#include "tasm.h"
#include <setjmp.h>

static jmp_buf Jump_buffer;    /* State information from return point */


/*
 *  This is just a top level main() to call the tasm() function
 *  which does all the work.  main was seperated from tasm() so 
 *  that tasm() can be called by the WinMain for the windows version.
 *
 */

//void

int main(int argc, char *argv[])
{
    int	exit_code;

    /* Setup the jump buffer for fatal exits */

    exit_code = setjmp ( Jump_buffer );
    if ( exit_code ) {
        /* A longjmp has occurred.  A fatal error must have been encountered */
        exit ( exit_code );
    
    }

    /* Pass all the args just as received. */
    exit_code = tasm (argc, argv);


    exit(exit_code);
    
}

void
tasmexit ( int exit_code )
{

    free_all();
    longjmp ( Jump_buffer, exit_code );

}
