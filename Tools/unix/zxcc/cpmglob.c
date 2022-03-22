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

	This file implements those BDOS functions that use wildcard expansion.
*/

#include "cpmint.h"
#ifdef _MSC_VER
  #define	S_ISDIR(mode)	(((mode) & _S_IFDIR) != 0)
#endif

static cpm_byte* find_fcb;
static int find_n;
static int find_ext = 0;
static int find_xfcb = 0;
static int entryno;
static cpm_byte lastdma[0x80];
static long lastsize;
static char target_name[CPM_MAXPATH];

static char upper(char c)
{
	if (islower(c)) return toupper(c);
	return c;
}

/*
 * we need to handle case sensitive filesystems correctly.
 * underlying files need to just work, irrespective if the files
 * in the native filesystem are mixed, upper or lower.
 * the naive code in the distributed zx will not work everywhere.
 */

 /*
  * Does the string "s" match the CP/M FCB?
  * pattern[0-10] will become a CP/M name parsed from "s" if it matches.
  * If 1st byte of FCB is '?' then anything matches.
  */

static int cpm_match(char* s, cpm_byte* fcb, cpm_byte* pattern)
{
	int n;
	size_t m;
	char* dotpos;

	m = strlen(s);

	/*
	 * let's cook the filename into something that we can match against
	 * the fcb.  we reject any that can't be valid cp/m filenames,
	 * normalizing case as we go.  all this goes into 'pattern'
	 */

	for (n = 0; n < 11; n++) pattern[n] = ' ';

	/* The name must have 1 or 0 dots */
	dotpos = strchr(s, '.');
	if (!dotpos) {	/* No dot. The name must be at most 8 characters */
		if (m > 8) return 0;
		for (n = 0; n < m; n++) {
			pattern[n] = upper(s[n]) & 0x7F;
		}
	}
	else {	/* at least one dot */
		if (strchr(dotpos + 1, '.')) {		/* More than 1 dot */
			return 0;
		}
		if (dotpos == s) {					/* Dot right at the beginning */
			return 0;
		}
		if ((dotpos - s) > 8) {				/* "name" > 8 characters */
			return 0;
		}
		if (strlen(dotpos + 1) > 3) {		/* "type" > 3 characters */
			return 0;
		}
		for (n = 0; n < (dotpos - s); n++) {	/* copy filename portion */
			pattern[n] = upper(s[n]) & 0x7F;
		}
		m = strlen(dotpos + 1);
		for (n = 0; n < m; n++) {				/* copy extention portion */
			pattern[n + 8] = upper(dotpos[n + 1]) & 0x7F;
		}
	}

	/*
	 * handle special case where fcb[0] == '?' or fcb[0] & 0x80
	 * this is used to return a full directory list on bdos's
	 */

	if (((fcb[0] & 0x7F) == '?') || (fcb[0] & 0x80)) {
		return 1;
	}
	for (n = 0; n < 11; n++)
	{
		if (fcb[n + 1] == '?') continue;
		if ((pattern[n] & 0x7F) != (fcb[n + 1] & 0x7F))
		{
			return 0;
		}
	}
	return 1;	/* Success! */
}

/* Get the next entry from the host's directory matching "fcb" */

static struct dirent* next_entry(DIR* dir, cpm_byte* fcb, cpm_byte* pattern,
	struct stat* st)
{
	struct dirent* en;
	int unsatisfied;
	int drv = fcb[0] & 0x7F;

	if (drv == '?') drv = 0;
	if (!drv) drv = redir_cpmdrive;
	else      drv--;

	for (unsatisfied = 1; unsatisfied; )
	{
		/* 1. Get the next entry */
		en = readdir(dir);
		if (!en) return NULL;	/* No next entry */
		++entryno;	/* 0 for 1st, 1 for 2nd, etc. */

		/* 2. See if it matches. We do this first (in preference to
		 * seeing if it's a subdirectory first) because it doesn't
		 * require disc access */
		if (!cpm_match(en->d_name, fcb, pattern))
		{
			continue;
		}

		/* 3. Stat it, & reject it if it's a directory */
		strcpy(target_name, redir_drive_prefix[drv]);
		strcat(target_name, en->d_name);

		if (stat(target_name, st))
		{
			DBGMSGV("Can't stat %s so omitting it.\n", target_name);
			continue;	/* Can't stat */
		}
		if (S_ISDIR(st->st_mode))
		{
			/* Searching for files only */
			if (fcb[0] != '?' && fcb[0] < 0x80)
			{
				continue;
			}
		}
		unsatisfied = 0;
	}
	return en;
}

void volume_label(int drv, cpm_byte* dma)
{
	struct stat st;

	memset(dma, 0x20, 12);	/* Volume label */

	/* Get label name */
	redir_get_label(drv, (char*)(dma + 1));

	/* [0x0c]      = label byte
	 * [0x0d]      = password byte (=0)
	 * [0x10-0x17] = password
	 * [0x18]      = label create date
	 * [0x1c]      = label update date
	 */
#ifdef __MSDOS__
	dma[0x0c] = 0x21;                   /* Under DOS, only "update" */
	if (redir_drdos) dma[0x0c] |= 0x80; /* Under DRDOS, passwords allowed */
#else
	dma[0x0c] = 0x61;	/* Label exists and time stamps allowed */
#endif				/* (update & access) */
	dma[0x0d] = 0;		/* Label not passworded */
	dma[0x0f] = 0x80;	/* Non-CP/M media */

	if (stat(redir_drive_prefix[drv], &st))
	{
		DBGMSGV("stat() fails on '%s'\n", redir_drive_prefix[drv]);
		return;
	}

	redir_wr32(dma + 0x18, redir_cpmtime(st.st_atime));
	redir_wr32(dma + 0x1C, redir_cpmtime(st.st_mtime));
}

cpm_word redir_find(int n, cpm_byte* fcb, cpm_byte* dma)
{
	DIR* hostdir;
	int drv, attrib;
	long recs;
	struct stat st;
	struct dirent* de;
	cpm_word rights;

	drv = (fcb[0] & 0x7F);
	if (!drv || drv == '?') drv = redir_cpmdrive;
	else                    drv--;

	if (find_xfcb)	/* Return another extent */
	{
		memcpy(dma, lastdma, 0x80);
		dma[0] |= 0x10;				/* XFCB */
		dma[0x0c] = dma[0x69];		/* Password mode */
		dma[0x0d] = 0x0A;			/* Password decode byte */
		memset(dma + 0x10, '*', 7);
		dma[0x17] = ' ';			/* Encoded password */
		memcpy(lastdma, dma, 0x80);

		find_xfcb = 0;
		return 0;
	}

	if (find_ext)	/* Return another extent */
	{
		memcpy(dma, lastdma, 0x80);
		dma[0x0c]++;
		if (dma[0x0c] == 0x20)
		{
			dma[0x0c] = 0;
			dma[0x0e]++;
		}
		lastsize -= 0x4000;
		recs = (lastsize + 127) / 128;
		dma[0x0f] = (recs > 127) ? 0x80 : (recs & 0x7F);

		if (lastsize <= 0x4000) find_ext = 0;
		memcpy(lastdma, dma, 0x80);

		return 0;
	}

	memset(dma, 0, 128);	/* Zap the buffer */

	/* If returning all entries, return a volume label. */

	if ((fcb[0] & 0x7F) == '?')
	{
		if (!n)
		{
			volume_label(drv, dma);
			return 0;
		}
		else --n;
	}

	/* Note: This implies that opendir() works on a filename with a
	 * trailing slash. It does under Linux, but that's the only assurance
	 * I can give. */

	entryno = -1;
	hostdir = opendir(redir_drive_prefix[drv]);

	if (!hostdir)
	{
		DBGMSGV("opendir() fails on '%s'\n", redir_drive_prefix[drv]);
		return 0xFF;
	}

	/* We have a handle to the directory. */
	while (n >= 0)
	{
		de = next_entry(hostdir, fcb, dma + 1, &st);
		if (!de)
		{
			closedir(hostdir);
			return 0xFF;
		}
		--n;
	}
	/* Valid entry found & statted. dma+1 holds filename. */

	dma[0] = redir_cpmuser;	/* Uid always matches */
	dma[0x0c] = 0; 			/* Extent counter, low */
	dma[0x0d] = st.st_size & 0x7F;	/* Last record byte count */
	dma[0x0e] = 0;			/* Extent counter, high */

#ifdef _WIN32
	attrib = GetFileAttributesA(target_name);
	rights = redir_drdos_get_rights(target_name);
	if (rights && ((fcb[0] & 0x7F) == '?')) find_xfcb = 1;
#else
	attrib = 0;
	rights = 0;
#endif
	if (attrib & 1)       dma[9] |= 0x80;  /* read only */
	if (attrib & 4)       dma[10] |= 0x80;  /* system */
	if (!(attrib & 0x20)) dma[11] |= 0x80;  /* archive */

/* TODO: Under Unix, work out correct RO setting */

	recs = (st.st_size + 127) / 128;
	dma[0x0f] = (recs > 127) ? 0x80 : (recs & 0x7F);
	dma[0x10] = 0x80;
	if (S_ISDIR(st.st_mode)) dma[0x10] |= 0x40;
	if (attrib & 2) dma[0x10] |= 0x20;
	dma[0x10] |= ((entryno & 0x1FFF) >> 8);
	dma[0x11] = dma[0x10];
	dma[0x12] = entryno & 0xFF;

	redir_wr32(dma + 0x16, (dword)st.st_mtime);	/* Modification time. */
	/* TODO: It should be in DOS format */
	/* TODO: At 0x1A, 1st cluster */
	redir_wr32(dma + 0x1C, st.st_size);	/* True size */

	if (rights)	/* Store password mode. Don't return an XFCB. */
	{
		dma[0x69] = redir_cpm_pwmode(rights);
		memcpy(lastdma, dma, 0x80);
	}

	dma[0x60] = 0x21;	/* XFCB */
	redir_wr32(dma + 0x61, redir_cpmtime(st.st_atime));
	redir_wr32(dma + 0x65, redir_cpmtime(st.st_mtime));

	closedir(hostdir);

	if (st.st_size > 0x4000 && (fcb[0x0C] == '?')) /* All extents? */
	{
		lastsize = st.st_size;
		find_ext = 1;
		memcpy(lastdma, dma, 0x80);
	}
	return 0;
}

cpm_word fcb_find1(cpm_byte* fcb, cpm_byte* dma) /* 0x11 */
{
#ifdef DEBUG
	int rv;
#endif

	FCBENT(fcb);

	redir_log_fcb(fcb);

	find_n = 0;
	find_fcb = fcb;
	find_ext = 0;
	find_xfcb = 0;

#ifdef DEBUG
	rv = redir_find(find_n, fcb, dma);

	if (rv < 4)
	{
		DBGMSGV("Ret: %-11.11s\n", dma + 1);
	}
	else  DBGMSG("Ret: Fail\n");
	FCBRET(rv);
#else
	FCBRET(redir_find(find_n, find_fcb, dma));
#endif
}

/* We don't bother with the FCB parameter - it's undocmented, and
 * programs that do know about it will just pass in the same parameter
 * that they did to function 0x11 */

cpm_word fcb_find2(cpm_byte* fcb, cpm_byte* dma) /* 0x12 */
{
#ifdef DEBUG
	int rv;
	char fname[CPM_MAXPATH];
#endif

	FCBENT(find_fcb);

#ifdef DEBUG
	redir_fcb2unix(find_fcb, fname);
	DBGMSGV("file number %d, '%s'\n", find_n, fname);
#endif

	++find_n;

#ifdef DEBUG
	rv = redir_find(find_n, find_fcb, dma);

	if (rv < 4)
	{
		DBGMSGV("Ret: %-11.11s\n", dma + 1);
	}
	else DBGMSG("Ret: Fail\n");
	FCBRET(rv);
#else
	FCBRET(redir_find(find_n, find_fcb, dma));
#endif
}

/* Under CP/M, unlinking works with wildcards */

cpm_word fcb_unlink(cpm_byte* fcb, cpm_byte* dma)
{
	DIR* hostdir;
	int drv;
	struct dirent* de;
	struct stat st;
	int handle = 0;
	int unpasswd = 0;
	char fname[CPM_MAXPATH];
	int del_cnt = 0;

	FCBENT(fcb);

	if (fcb[5] & 0x80) unpasswd = 1; /* Remove password rather than file */

	redir_log_fcb(fcb);

	drv = (fcb[0] & 0x7F);
	if (!drv || drv == '?') drv = redir_cpmdrive;
	else                    drv--;

	if (redir_ro_drv(drv))
	{
		/* Error: R/O drive */
		DBGMSG("delete failed - R/O drive\n");
		FCBRET(0x02FF);
	}

#ifdef DEBUG
	redir_fcb2unix(fcb, fname);
	DBGMSGV("fcb_unlink('%s')\n", fname);
#endif

	/* Note: This implies that opendir() works on a filename with a
	 * trailing slash. It does under Linux, but that's the only assurance
	 * I can give.*/

	hostdir = opendir(redir_drive_prefix[drv]);

	if (!hostdir)
	{
		DBGMSGV("opendir failed on '%s'\n", redir_drive_prefix[drv]);
		FCBRET(0xFF);
	}

	/* We have a handle to the directory. */
	do
	{
		de = next_entry(hostdir, fcb, (cpm_byte*)fname, &st);
		if (de)
		{
			strcpy(target_name, redir_drive_prefix[drv]);
			strcat(target_name, de->d_name);
			DBGMSGV("deleting '%s'\n", de->d_name);
			if (unpasswd)
			{
#ifdef __MSDOS__
				if (redir_drdos)
				{
					handle = redir_drdos_put_rights(target_name, dma, 0);
				}
				else handle = 0;
#endif
			}
			else if (fcb[0] & 0x80)
			{
				DBGMSGV("rmdir '%s'\n", target_name);
				handle = rmdir(target_name);
				if (handle && redir_password_error())
				{
					DBGMSGV("rmdir failed (errno=%lu): %s\n", errno, strerror(errno));
					redir_password_append(target_name, dma);
					DBGMSGV("rmdir '%s'\n", target_name);
					handle = rmdir(target_name);
				}
				if (handle)
					DBGMSGV("rmdir failed (errno=%lu): %s\n", errno, strerror(errno));
			}
			else
			{
				releaseFile(target_name);
				DBGMSGV("unlink '%s'\n", target_name);
				handle = unlink(target_name);
				if (handle && redir_password_error())
				{
					DBGMSGV("unlink failed (errno=%lu): %s\n", errno, strerror(errno));
					redir_password_append(target_name, dma);
					releaseFile(target_name);
					DBGMSGV("unlink '%s'\n", target_name);
					handle = unlink(target_name);
				}
				if (handle)
					DBGMSGV("unlink failed (errno=%lu): %s\n", errno, strerror(errno));
			}

			if (handle)
				de = NULL;	/* Delete failed */
			else
				del_cnt++;
		}
	} while (de != NULL);

	if (!handle && !del_cnt)
		DBGMSG("no matching directory entries\n");
	else
		DBGMSGV("deleted %i file(s)\n", del_cnt);

	if (handle || !del_cnt)
	{
		DBGMSG("delete processing failed\n");
		closedir(hostdir);
		FCBRET(0xFF);
	}

	DBGMSG("delete processing succeeded\n");
	closedir(hostdir);
	FCBRET(0);
}

#ifdef __MSDOS__
cpm_word redir_get_label(cpm_byte drv, char* pattern)
{
	char strs[10];
	struct ffblk fblk;
	int done;
	char* s;
	int n;

	/* We need the drive prefix to be of the form "C:\etc..." */

	memset(pattern, ' ', 11);
	if (!redir_drive_prefix[drv][0] || redir_drive_prefix[drv][1] != ':')
		return 0;

	sprintf(strs, "%c:/*.*", redir_drive_prefix[drv][0]);

	done = findfirst(strs, &fblk, FA_LABEL);
	while (!done)
	{
		if ((fblk.ff_attrib & FA_LABEL) &&
			!(fblk.ff_attrib & (FA_SYSTEM | FA_HIDDEN)))
		{
			s = strchr(fblk.ff_name, '/');
			if (!s) s = strchr(fblk.ff_name, '\\');
			if (!s) s = strchr(fblk.ff_name, ':');
			if (!s) s = fblk.ff_name;
			for (n = 0; n < 11; n++)
			{
				if (!(*s)) break;
				if (*s == '.')
				{
					n = 7;
					++s;
					continue;
				}
				pattern[n] = upper(*s);
				++s;
			}
			return 1;
		}
		done = findnext(&fblk);
	}
	return 0;
}
#else
cpm_word redir_get_label(cpm_byte drv, char* pattern)
{
	char* dname;
	size_t l;
	int n;

	memset(pattern, ' ', 11);

	dname = strrchr(redir_drive_prefix[drv], '/');
	if (dname)
	{
		++dname;
		l = strlen(dname);
		if (l > 11) l = 11;
		for (n = 0; n < l; n++) pattern[n] = upper(dname[l]);
	}
	else
	{
		pattern[0] = '.';
	}
	return 0;
}

#endif
