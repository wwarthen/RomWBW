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
static char* skipUser(char* localname);
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

	redir_Msg("DRDOS detected.\n");

	redir_drdos = 1;

  #else /* __GO32__ */

	union REGS ir, or ;

	ir.w.ax = 0x4452;	/* "DR" */

	intdos(&ir, &or );
	if (or .w.cflag) return;	/* Not DRDOS */

	redir_Msg("DRDOS detected.\n");

	redir_drdos = 1;
  #endif /* __GO32__ */
}
#endif /* __MSDOS__ */

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

void xlt_name(char* localname, char* cpmname)
{
	char ibuf[CPM_MAXPATH + 1];
	char nbuf[CPM_MAXPATH + 1];
	char* pname = ibuf;
	char* s;
	int n;

	sprintf(ibuf, "%-.*s", CPM_MAXPATH, skipUser(localname));

	while ((s = strpbrk(pname, DIRSEP))) {	/* find the last directory separator allows mixed \ and / in windows */
#ifdef _WIN32
		if (*s == '\\')						/* convert separators to common format so directory tracking works more efficiently */
			*s = '/';
#endif
		pname = s + 1;
	}

	if (pname == ibuf) {	/* No path separators in the name. It is therefore a
							   local filename, so map it to drive P: */
		strcpy(cpmname, "p:");
		strcat(cpmname, ibuf);
		return;
	}

	/* catch user specified current drive a,b,c,p or A,B,C,P only, which map to predefined directories  */
	if (pname == ibuf + 2 && ibuf[1] == ':' && (s = strchr("aAbBcCpP", ibuf[0]))) {
		cpmname[0] = tolower(*s);			/* make sure it's lower case */
		strcpy(cpmname + 1, ibuf + 1);
		return;
	}

	strcpy(nbuf, pname);	/* nbuf holds filename component */
	*pname = 0;				/* ibuf holds path component */

	/* See if the path is one of those already mapped to drives */

	for (n = 0; n < 15; n++)
	{
		if (redir_drive_prefix[n][0] && !strcmp(ibuf, redir_drive_prefix[n]))
		{
			sprintf(cpmname, "%c:%s", n + 'a', nbuf);
			return;
		}
	}

	/* It is not, see if another drive can be allocated */

	for (n = 0; n < 15; n++) if (!redir_drive_prefix[n][0])
	{
		strcpy(redir_drive_prefix[n], ibuf);
		sprintf(cpmname, "%c:%s", n + 'a', nbuf);
		return;
	}

	/* No other drive can be allocated */

	strcpy(cpmname, "p:");
	strcat(cpmname, nbuf);
}

/* It is sometimes convenient to set some fixed mappings. This will create
 * a mapping for a given directory.
 * Pass drive = -1 for "first available", or 0-15 for A: to P:
 */

int xlt_map(int drive, char* localdir)
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

char* xlt_getcwd(int drive)
{
	if (drive < 0 || drive > 16) return "";

	return redir_drive_prefix[drive];
}

/* as zxcc doesn't really support user spaces, remove any user specification
 * hitech c supports
 * [[0-9]+[:]][[a-pA-P]:]name[.ext] | [[a-pA-p][[0-9]+]:]name[.ext]
 * this function also checks that user is no more than 2 digits and user # <= 31
 * the hitech fcb checks for : as char 2, 3, or 4 which aligns to this
 */
static char* skipUser(char* localname) {
	char* s;
	int user;
	int drive;

	if (!localname || !(s = strchr(localname, ':')) || s > localname + 3)
		return localname;
	s = localname;
	if (isdigit(*s)) {
		user = *s++ - '0';
		if (isdigit(*s)) {
			user = user * 10 + *s++ - '0';
			if (user > 31)				/* check sensible user id */
				return localname;
		}
		if (*s == ':')					/* just strip the user id assume rest is a filename */
			return s + 1;
		if ('a' <= (drive = tolower(*s)) && drive <= 'p' && s[1] == ':')
			return s;					/* was form [0-9]+[a-pA-P] so strip user id */
		else
			return localname;			/* not vaild so don't change */
	}
	if ((drive = tolower(*s++)) < 'a' || 'p' < drive || !isdigit(*s))
		return localname;				/* not a valid drive prefix or simple drive spec */

	user = *s++ - '0';
	if (isdigit(*s))
		user = user * 10 + *s++ - '0';
	if (*s != ':' || user > 31)
		return localname;
	*--s = drive;						/* reinsert the drive just before the : */
	return s;
}
