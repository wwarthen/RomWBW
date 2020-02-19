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

#ifdef WIN32

static char *drive_to_hostdrive(int cpm_drive)
{
	static char prefix[CPM_MAXPATH];
	char *lpfp;
	DWORD dw;

	if (!redir_drive_prefix[cpm_drive]) return NULL;
	dw = GetFullPathName(redir_drive_prefix[cpm_drive], sizeof(prefix),
				prefix, &lpfp);
		
	if (!dw) return NULL;
	if (prefix[1] == ':')	/* If path starts with a drive, limit it */
	{			/* to just that drive */
		prefix[2] = '/';
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

	redir_l_drives  = 0;
	redir_cpmdrive  = 0;	/* A reset forces current drive to A: */
/*	redir_ro_drives = 0; Software write protect not revoked by func 0Dh.
 * 
 * This does not follow true CP/M, but does match many 3rd-party replacements.
 */
	return 0;
}


cpm_word fcb_drive (cpm_byte drv)
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


cpm_byte fcb_user  (cpm_byte usr)
{
	if (usr != 0xFF) redir_cpmuser = usr % 16;

	redir_Msg("User: parameter %d returns %d\r\n", usr, redir_cpmuser);

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
#ifdef WIN32
	return 0;
#else
	sync(); return 0;	/* Apparently some sync()s are void not int */
#endif
}


cpm_word fcb_purge()
{
#ifdef WIN32
	return 0;
#else
	sync(); return 0;	/* Apparently some sync()s are void not int */
#endif
}


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

cpm_word fcb_getdpb(cpm_byte *dpb)
{
#ifdef WIN32
	DWORD spc, bps, fc, tc;
	unsigned bsh, blm, psh, phm;
	char *hostd = drive_to_hostdrive(redir_cpmdrive);

        if (!hostd) return 0x01FF;  /* Can't select */

	if (!GetDiskFreeSpace(hostd, &spc, &bps, &fc, &tc))
		return 0x01FF;	/* Can't select */

	/* Store total clusters */
	//if (tc > 0x10000L) tc = 0x10000L;
	if (tc > 0xFFFFL) tc = 0xFFFFL;

	psh = 0; phm = 0;

	while (bps > 128)	/* Get sector size */
	{
		bps /= 2;
		psh++;
		phm = (phm << 1) | 1;
	}	
	bsh = psh; blm = phm;
	while (spc > 1)	/* Get cluster size */
	{
		spc /= 2;
		bsh++;
		blm = (blm << 1) | 1;
	}	
	

	exdpb[2] = bsh;
	exdpb[3] = blm;
	exdpb[5] = tc & 0xFF;
	exdpb[6] = tc >> 8;

	exdpb[15] = psh;
	exdpb[16] = phm;
#else
        struct statfs buf;
	cpm_word nfiles;

	/* Get DPB for redir_cpmdrive. Currently just returns a dummy. */
        if (!statfs(redir_drive_prefix[redir_cpmdrive], &buf))
	{
		/* Store correct directory entry count */

		if (buf.f_files >= 0x10000L) nfiles = 0xFFFF;
		else                         nfiles = buf.f_files;

		exdpb[7] = nfiles & 0xFF;
		exdpb[8] = nfiles >> 8;
	}
#endif
	
	memcpy(dpb, &exdpb, 0x11);
	return 0x11;
}


/* Create an entirely bogus ALV
 * TODO: Make it a bit better */

cpm_word fcb_getalv(cpm_byte *alv, cpm_word max)
{
	if (max > 1024) max = 1024;

	memset(alv,             0xFF, max / 2);
	memset(alv + (max / 2), 0,    max / 2);
	
	return max;
}

/* Get disk free space */

cpm_word fcb_dfree (cpm_byte drive, cpm_byte *dma)
{
#ifdef WIN32
	DWORD spc, bps, fc, tc;
	DWORD freerec;
	char *hostd = drive_to_hostdrive(drive);
	
	if (!hostd) return 0x01FF;
        if (!hostd) return 0x01FF;  /* Can't select */

	if (!GetDiskFreeSpace(hostd, &spc, &bps, &fc, &tc))
		return 0x01FF;	/* Can't select */

	freerec = fc;		/* Free clusters */
	freerec *= spc;		/* Free sectors */
	freerec *= (bps / 128);	/* Free CP/M records */

	/* Limit to maximum CP/M drive size */
	if (freerec > 4194303L) freerec = 4194303L;
	redir_wr24(dma, freerec);
		
#else
	struct statfs buf;
	long dfree;

	if (!redir_drive_prefix[drive]) return 0x01FF;	/* Can't select */
	
	if (statfs(redir_drive_prefix[drive], &buf)) return 0x01FF;

	dfree = (buf.f_bavail * (buf.f_bsize / 128));

	if (dfree < buf.f_bavail ||	/* Calculation has wrapped round */
	    dfree > 4194303L)           /* Bigger than max CP/M drive size */
	{
		dfree = 4194303L;
	}

	redir_wr24(dma, dfree);
#endif
	return 0;
}



