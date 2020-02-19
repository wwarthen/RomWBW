/*

    CPMREDIR: CP/M filesystem redirector
    Copyright (C) 1998, John Elliott <jce@seasip.demon.co.uk>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

    This file holds functions dealing with name translation; also the 
    initialisation code.
*/

#include "cpmint.h"

/* Detect DRDOS */

#ifdef __MSDOS__
static void drdos_init(void)
{

/* The DJGPP DOS extender won't detect DRDOS using intdos(), so we have
  to use __dpmi_int() instead. */

#ifdef __GO32__
	__dpmi_regs ir;

	ir.x.ax = 0x4452;	/* "DR" */

	__dpmi_int(0x21, &ir);
	if (ir.x.flags & 1) return;	/* Not DRDOS */

	redir_Msg("DRDOS detected.\r\n");

	redir_drdos = 1;	

#else	/* __GO32__ */

	union REGS ir, or;

	ir.w.ax = 0x4452;	/* "DR" */

	intdos(&ir, &or);
	if (or.w.cflag) return;	/* Not DRDOS */

	redir_Msg("DRDOS detected.\r\n");

	redir_drdos = 1;	
#endif	/* __GO32__ */
}
#endif	/* __MSDOS__ */



int fcb_init(void)
{
	int n;

	/* A: to O: free */
	for (n = 0; n < 15; n++) redir_drive_prefix[n][0] = 0;

	strcpy(redir_drive_prefix[15], "./");	/* P: is current directory */

	/* Log on to P:. It is the only drive at this point which we
         * know works. */
	redir_cpmdrive = 15;
#ifdef __MSDOS__
	drdos_init();
#endif	

	return 1;
}

/* Deinitialise the library. */

void fcb_deinit(void)
{
	/* Nothing */
}

/* Translate a name from the host FS to a CP/M name. This will (if necessary)
 * create a mapping between a CP/M drive and a host directory path. 
 *
 * CP/M drives A: to O: can be mapped in this way. P: is always the current
 * drive. 
 *
 */

void xlt_name(char *localname, char *cpmname)
{
	char ibuf[CPM_MAXPATH + 1];
	char nbuf[CPM_MAXPATH + 1];
	char *pname;
	int n;

	sprintf(ibuf, "%-.*s", CPM_MAXPATH, localname);
	pname = strrchr(ibuf, '/'); 
#ifdef __MSDOS__
	if (!pname) pname = strrchr(ibuf,'\\');
	if (!pname) pname = strrchr(ibuf,':');
#endif
	if (!pname)	/* No path separators in the name. It is therefore a
                           local filename, so map it to drive P: */
	{
		strcpy(cpmname, "p:");
		strcat(cpmname, ibuf);
		return;
	}
	++pname;
	strcpy(nbuf, pname);	/* nbuf holds filename component */
	*pname = 0;		/* ibuf holds path component */

	/* See if the path is one of those already mapped to drives */
	
	for (n = 0; n < 15; n++)
	{
		if (redir_drive_prefix[n][0] && !strcmp(ibuf, redir_drive_prefix[n]))
		{
			sprintf(cpmname,"%c:%s", n + 'a', nbuf);
			return;
		}
	}

	/* It is not, see if another drive can be allocated */

	for (n = 0; n < 15; n++) if (!redir_drive_prefix[n][0])
	{
		strcpy(redir_drive_prefix[n], ibuf);
                sprintf(cpmname,"%c:%s", n + 'a', nbuf);
		return;
	}

	/* No other drive can be allocated */

	strcpy(cpmname,"p:");
	strcat(cpmname, nbuf);
}

/* It is sometimes convenient to set some fixed mappings. This will create
 * a mapping for a given directory.  
 * Pass drive = -1 for "first available", or 0-15 for A: to P:
 */

int xlt_map(int drive, char *localdir)
{
	int n;

	if (drive == -1)
	{
		for (n = 0; n < 15; n++) if (!redir_drive_prefix[n][0]) 
		{
			drive = n;
			break;
		}
		if (drive == -1) return 0;	/* No space for mappings */
	}
	if (redir_drive_prefix[drive][0]) return 0;	/* Drive taken */

        sprintf(redir_drive_prefix[drive], "%-.*s", CPM_MAXPATH, localdir);
	return 1;
}


/* Unmap a drive
 */

int xlt_umap(int drive)
{
	if (!redir_drive_prefix[drive][0]) return 0;	/* Drive not taken */
	redir_drive_prefix[drive][0] = 0;
	return 1;
}


char *xlt_getcwd(int drive)
{
	if (drive < 0 || drive > 16) return "";

	return redir_drive_prefix[drive];
}

