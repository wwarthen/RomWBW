/****************************************************************************
 *  $Id: errlog.c 1.3 1999/08/20 00:36:42 toma Exp $
 **************************************************************************** 
 *  File: errlog.c
 *
 *  Description:
 *    Modules to log error messages for TASM, the table driven assembler.
 *
 *    Copyright 1985-1995  Speech Technology Incorporated.
 *    Copyright 1997       Squak Valley Software
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

//static char *id_errlog_c = "$Id: errlog.c 1.3 1999/08/20 00:36:42 toma Exp $";

/* INCLUDES */
#include        "tasm.h"

#ifdef T_MEMCHECK
#include        <memcheck.h>
#endif

/* DEFINES */



/************************************************************************/
/*
 * Function: errlog()
 *
 * Description:
 *     Format an error message and output to the list file and the
 *     standard output.
 *
 */

void
errlog(
char    *err_mess,      /* Error message                        */
errout_t output_mode)   /* Enable output on Pass1/Pass2         */
{

    char    errbuf[LINESIZE];
    char    err_data[LINESIZE];
    char    file_name[PATHSIZE];
    char    *err_format;
    char    *file;

    extern  int         Errcnt;
    extern  pass_t      Pass;
    extern  int         Line_number;
    extern  int         Skip;
    extern  char        Errorbuf[];

    /* Suppress errors if this is the first pass or if we are
     *  just skipping over source code looking for an 'endif'. 
     */
    if( (Skip == FALSE) && ((output_mode == ALWAYS) || (Pass == SECOND))){
        Errcnt++;

        if(Errorbuf[0]) 
            sprintf(err_data,"(%s)",Errorbuf);
        else
            err_data[0] = '\0';

        /* Fetch the name of the current source file */
        file = fname_get ( );

        /* Use the applicable file name if we know it */
        if((file != NULL) && (*file))
            strcpy(file_name, file  );
        else
            strcpy(file_name, "tasm");

        /* Check for alternate error log format string and 
         *   use it if it exists
         */
        if( (err_format=getenv("TASMERRFORMAT")) == NULL)
            sprintf(errbuf,"%s line %04d: %s %s",
                   file, Line_number, err_mess, err_data);
        else
            sprintf(errbuf,err_format,
                   file, Line_number, err_mess, err_data);
            
     
        strcat (errbuf, "\n");     /* Add newline */
        errprt (errbuf);
        listprt(errbuf);
    }
}

/* that's all folks */
