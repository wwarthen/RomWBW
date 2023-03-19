/*

	CPMREDIR: CP/M filesystem redirector
	Copyright (C) 1998,2003 John Elliott <jce@seasip.demon.co.uk>

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

	This file deals with drive-based functions.
*/

#include "cpmint.h"

#ifdef _WIN32
static char* drive_to_hostdrive(int cpm_drive)
{
	static char prefix[CPM_MAXPATH];
	char* lpfp;
	dword dw;

	if (!redir_drive_prefix[cpm_drive]) return NULL;
	dw = GetFullPathName(redir_drive_prefix[cpm_drive], sizeof(prefix),
		prefix, &lpfp);

	if (!dw) return NULL;
	if (prefix[1] == ':')	/* If path starts with a drive, limit it */
	{			/* to just that drive */
		prefix[2] = '\\';   /* GetDiskFreeSpace should have trailing backslash */
		prefix[3] = 0;
	}
	return prefix;
}
#endif


cpm_byte fcb_reset(void)
{
#ifdef __MSDOS__
	bdos(0x0D, 0, 0);
#endif

	redir_l_drives = 0;
	redir_cpmdrive = 0;	/* A reset forces current drive to A: */
/*	redir_ro_drives = 0; Software write protect not revoked by func 0Dh.
 *
 * This does not follow true CP/M, but does match many 3rd-party replacements.
 */
	return 0;
}


cpm_word fcb_drive(cpm_byte drv)
{
	if (redir_drive_prefix[drv][0])
	{
		redir_cpmdrive = drv;
		redir_log_drv(drv);
		return 0;
	}
	else return 0x04FF;	/* Drive doesn't exist */
}

cpm_byte fcb_getdrv(void)
{
	return redir_cpmdrive;
}


cpm_byte fcb_user(cpm_byte usr)
{
	if (usr != 0xFF) redir_cpmuser = usr % 16;

	DBGMSGV("User: parameter %d returns %d\n", usr, redir_cpmuser);

	return redir_cpmuser;
}



cpm_word fcb_logvec(void)
{
	return redir_l_drives;
}


cpm_word fcb_rovec(void)
{
	return redir_ro_drives;
}


cpm_word fcb_rodisk(void)
{
	cpm_word mask = 1;

	if (redir_cpmdrive) mask = mask << redir_cpmdrive;

	redir_ro_drives |= mask;
	return 0;
}


cpm_word fcb_resro(cpm_word bitmap)
{
	redir_ro_drives &= ~bitmap;

	return 0;
}


cpm_word fcb_sync(cpm_byte flag)
{
#ifdef _WIN32
	return 0;
#else
	sync(); return 0;	/* Apparently some sync()s are void not int */
#endif
}


cpm_word fcb_purge()
{
#ifdef _WIN32
	return 0;
#else
	sync(); return 0;	/* Apparently some sync()s are void not int */
#endif
}

/* Generic 8MB disk definition */

static cpm_byte exdpb[0x11] = {
	0x80, 0, 	/* 128 records/track */
	0x04, 0x0F,	/* 2k blocks */
	0x00,		/* 16k / extent */
	0xFF, 0x0F,	/* 4095 blocks */
	0xFF, 0x03,	/* 1024 dir entries */
	0xFF, 0xFF,	/* 16 directory blocks */
	0x00, 0x80,	/* Non-removable media */
	0x00, 0x00,	/* No system tracks */
	0x02, 0x03	/* 512-byte sectors */
};

cpm_word fcb_getdpb(cpm_byte* dpb)
{
	/* Return the example dpb */
	memcpy(dpb, &exdpb, 0x11);
	return 0x11;
}

/* Create an entirely bogus ALV
 * TODO: Make it a bit better */

cpm_word fcb_getalv(cpm_byte* alv, cpm_word max)
{
	if (max > 1024) max = 1024;

	memset(alv, 0xFF, max / 2);
	memset(alv + (max / 2), 0, max / 2);

	return max;
}

/* Get disk free space */

cpm_word fcb_dfree(cpm_byte drive, cpm_byte* dma)
{
	/* Return half of disk capacity */
	redir_wr24(dma, 0x8000L);	/* 8MB / 128 / 2 */
	return 0;
}
