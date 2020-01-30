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
*/

/* This file handles actual reading and writing */

#define CPMDEF
#include "cpmint.h"

#ifdef DEBUG
#define SHOWNAME(func)                       \
              {                              \
              char fname[CPM_MAXPATH];       \
              redir_fcb2unix(fcb, fname);          \
              redir_Msg(func "(\"%s\")\n", fname); \
              }
                
#else
	#define SHOWNAME(func)
#endif


/* DISK BDOS FUNCTIONS */

/* General treatment:
 *
 * We use the "disk block number" fields in the FCB to store our file handle;
 * this is a similar trick to that used by DOSPLUS, which stores its cluster
 * number in there. It works if:
 *
 * a) sizeof(int) <= 8 bytes (64 bits). If it's more, this needs rewriting
 *   to use a hash table;
 * b) the program never touches these bytes. Practically no CP/M program does.
 *
 * We store a "magic number" (0x00FD) in the first two bytes of this field, and
 * if the number has been changed then we abort.
 *
 * nb: Since I wrote ZXCC, I have found that DOSPLUS uses 0x8080 as a magic 
 *    number [well, actually this is an oversimplification, but a hypothetical
 *    program written against DOSPLUS would work with 0x8080]. Perhaps 0x8080
 *    should be used instead.
 *
 * Format of the field:
 *
 * [--2 bytes--] magic number
 * [--8 bytes--] file handle. 8 bytes reserved but only 4 currently used.
 * [--2 bytes--] reserved.
 * [--4 bytes--] file length.
 */
#define MAGIC_OFFSET  0x10
#define HANDLE_OFFSET 0x12
#define LENGTH_OFFSET 0x1C

cpm_word fcb_open(cpm_byte *fcb, cpm_byte *dma)
{
	char fname[CPM_MAXPATH];
	int handle;
	int drv, l;
	char *s;
	DIR *dir;
	
	/* Don't support ambiguous filenames */
	if (redir_fcb2unix(fcb, fname)) return 0x09FF;

	redir_log_fcb(fcb);

	drv = fcb[0] & 0x7F;
	if (!drv) drv = redir_cpmdrive; else --drv;

	if (fcb[0] & 0x80) /* Open directory */
	{
		if (fcb[0x0C]) return 0x0BFF; /* Can't assign "floating" dir */

		if (!memcmp(fcb + 1, ".          ", 11))
		{
			return 0; /* Opening "." */
		}
		if (!memcmp(fcb + 1, "..         ", 11))
		{
			l = strlen(redir_drive_prefix[drv]) - 1;
			s = redir_drive_prefix[drv];
			--l;
			while (l > 0)	
			{
				if (s[l] == '/') break;
#ifdef __MSDOS__
				if (s[l] == '\\') break;
				if (s[l] == ':')  break;
#endif
				--l;
			} 
#ifdef __MSDOS__
			if (l < 2) return 0; /* "C:" */
#else
			if (l <= 0) return 0; /* "/" */ 
#endif
			++l;
			s[l] = 0;
			return 0;
		}
/* Opening some other directory */

		dir = opendir(fname);
		if (!dir) return 0xFF;	/* Not a directory */
		closedir(dir);
		strcpy(redir_drive_prefix[drv], fname);
		strcat(redir_drive_prefix[drv], "/");
		return 0;
	}

	/* Note: Some programs (MAC is an example) don't close a file 
         * if they opened it just to do reading. MAC then reopens the
         * file (which rewinds it); this causes FCB leaks under some 
         * DOS-based emulators */

	handle = redir_ofile(fcb, fname);
        redir_Msg("fcb_open(\"%s\")\r\n", fname);
	if (handle < 0 && redir_password_error())
	{
	        redir_Msg("1st chance open failed on %s\r\n", fname);
		redir_password_append(fname, dma);
	        redir_Msg("Trying with %s\r\n", fname);
		handle = redir_ofile(fcb, fname);
	}


	if (handle == -1) 
	{
		redir_Msg("Ret: -1\n");
		if (redir_password_error()) return 0x7FF;
		return 0xFF;
	}
	fcb[MAGIC_OFFSET    ] = 0xFD;		/* "Magic number"  */
	fcb[MAGIC_OFFSET + 1] = 0x00;
	
/* TODO: Should the magic number perhaps be 0x8080, as in DOSPLUS? */
	
	redir_wrhandle(fcb + HANDLE_OFFSET, handle);

	redir_put_fcb_pos(fcb, fcb[0x0C] * 16384);	
		/* (v1.01) "seek" to beginning of extent, not file. 
                 *         This is necessary for the awful I/O code 
                 *         in LINK-80 to work                 
                 */

	/* Get the file length */
	redir_wr32(fcb + 0x1C, zxlseek(handle, 0, SEEK_END));
	zxlseek(handle, 0, SEEK_SET);

	/* Set the last record byte count */
	if (fcb[0x20] == 0xFF) fcb[0x20] = fcb[0x1C] & 0x7F;

	redir_Msg("Ret: 0\n");

	return 0;
}


cpm_word fcb_close(cpm_byte *fcb)
{
        int handle, drv;

	SHOWNAME("fcb_close")

        if ((handle = redir_verify_fcb(fcb)) < 0) return -1;
        redir_Msg("         (at   %lx)\n", zxlseek(handle, 0, SEEK_CUR));

	if (fcb[0] & 0x80)	/* Close directory */
	{
		drv = fcb[0] & 0x7F;
		if (!drv) drv = redir_cpmdrive; else drv--;
#ifdef __MSDOS__
		strcpy(redir_drive_prefix[drv] + 1, ":/");
#else
		strcpy(redir_drive_prefix[drv], "/");
#endif
		return 0;
	}

	if (fcb[5] & 0x80)	/* CP/M 3: Flush rather than close */
	{
#ifndef WIN32
		sync();
#endif
		return 0;
	}

#ifdef WIN32
	{
		BOOL b;
		redir_Msg(">CloseHandle() Handle=%lu\n", handle);
		b = CloseHandle((HANDLE)handle);
		redir_Msg("<CloseHandle() Result=%c, LastErr=%lu\n", b ? 'T' : 'F', GetLastError());
		if (!b)
		{
			redir_Msg("Ret: -1\n");
			return 0xFF;
		}
	}
#else
	if (close(handle)) 
	{
		redir_Msg("Ret: -1\n");
		return 0xFF;
	}
#endif

	redir_Msg("Ret: 0\n");
        return 0;
}

/** Moved to cpmglob.c, because it expands wildcards
cpm_word fcb_unlink(cpm_byte *fcb, cpm_byte *dma)
{
	int handle
        char fname[CPM_MAXPATH];

#ifdef DEBUG
        redir_fcb2unix(fcb, fname);
        redir_Msg("fcb_unlink(\"%s\")\n", fname);
#endif
        handle = unlink(fname);
        if (handle) 
	{
		redir_Msg("Ret: -1\n");
		return 0xFF;
	}
	redir_Msg("Ret: 0\n");
        return 0;
}
**/

/* In theory, fcb_read() is supposed to be sequential access - the program 
  just reads one record after another and lets the OS worry about file 
  pointers.

   In practice, it isn't so easy. For example, DR's LINK-80 does seeks when 
  the file size gets above 8k, and SAVE rewinds the file by setting the 
  counter fields to 0. 

   Seeking is done by relying on the following fields:

   ex (FCB+12) = (position / 16k) % 32 
   s2 (FCB+14) =  position / 512k
   cr (FCB+32) = (position % 16k) / 128

  TODO: Set rc to number of 80h-byte records in last extent: ie:

        length of file - (file ptr - (file ptr % 16384)) / 128

        if >80h, let it be 80h

*/


cpm_word fcb_read(cpm_byte *fcb, cpm_byte *dma)
{
        int handle;
        int rv, n, rd_len;
	long npos;

	SHOWNAME("fcb_read")

  if ((handle = redir_verify_fcb(fcb)) < 0) return 9;	/* Invalid FCB */

	/* The program may have mucked about with the counters, so
         * do an lseek() to where it should be. */

	npos = redir_get_fcb_pos(fcb);
	zxlseek(handle, npos, SEEK_SET);
        redir_Msg("        (from %lx)\n", zxlseek(handle, 0, SEEK_CUR));

	/* Read in the required amount */

#ifdef WIN32
	{
		BOOL b;
		redir_Msg(">ReadFile() Handle=%lu, DMA=%lu, Len=%lu\n", handle, dma, redir_rec_len);
		b = ReadFile((HANDLE)handle, dma, redir_rec_len, (unsigned long *)(&rv), NULL);
		redir_Msg("<ReadFile() Result=%c, Bytes Read=%lu, LastErr=%lu\n", b ? 'T' : 'F', rv, GetLastError());
		if (!b) rv = -1;
	}
#else
	rv = read(handle, dma, redir_rec_len);
#endif

	/* rd_len = length supposedly read, bytes. Round to nearest 128 bytes.
         */
	rd_len = ((rv + 127) / 128) * 128;

	npos += rd_len;

	/* Write new file pointer into FCB */

	redir_put_fcb_pos(fcb, npos);

  if (rv < 0)  
	{
		redir_Msg("Ret: -1\n");
		return redir_xlt_err(); /* unwritten extent */
	}

	/* Less was read in than asked for. Report the number of 128-byte 
         * records that _were_ read in. 
         */

        if (rd_len < redir_rec_len) /* eof */
	{
		/* Pack from the size actually read up to the size we claim
		 * to have read */
        	for (n = rv; n < rd_len; n++) dma[n] = 0x1A;
		rd_len = ((rv + 127) / 128) << 8;	/* High byte */
		redir_Msg("Ret: 0x%x\n", rd_len | 1);
		return rd_len | 1; /* eof */
	}

	/* We have reported that all records were read in. But the last 
         * record might be less than 128 bytes, so pack it with 0x1A bytes */

        for (n = rv; n < rd_len; n++) dma[n] = 0x1A;
	redir_Msg("Ret: 0 (bytes read=%d)\n", rv);
        return 0;
}


cpm_word fcb_write(cpm_byte *fcb, cpm_byte *dma)
{
        int handle;
        int rv;
	long npos, len;

	SHOWNAME("fcb_write")

        if ((handle = redir_verify_fcb(fcb)) < 0) return 9;	/* Invalid FCB */

        /* Software write-protection */
        if (redir_ro_fcb(fcb)) return 0x02FF;

	/* Check for a seek */
	npos = redir_get_fcb_pos(fcb);
	zxlseek(handle, npos, SEEK_SET);

	redir_Msg("         (to   %lx)\n", zxlseek(handle, 0, SEEK_CUR));

#ifdef WIN32
	{
		BOOL b;
		redir_Msg(">WriteFile() Handle=%lu, DMA=%lu, Len=%lu\n", handle, dma, redir_rec_len);
		b = WriteFile((HANDLE)handle, dma, redir_rec_len, (unsigned long *)(&rv), NULL);
		redir_Msg("<WriteFile() Result=%c, Bytes Written=%lu, LastErr=%lu\n", b ? 'T' : 'F', rv, GetLastError());
		if (!b) rv = -1;
	}
#else	
	rv = write(handle, dma, redir_rec_len);
#endif
	npos += redir_rec_len;

	redir_put_fcb_pos(fcb, npos);

        /* Update the file length */
	len = redir_rd32(fcb + 0x1C);
	if (len < npos) redir_wr32(fcb + 0x1C, npos);

	if (rv < 0)       return redir_xlt_err(); /* error */
        if (rv < redir_rec_len) return 1;    /* disk full */
        return 0;
}



cpm_word fcb_creat(cpm_byte *fcb, cpm_byte *dma)
{
        char fname[CPM_MAXPATH];
        int handle;

	/* Don't support ambiguous filenames */
        if (redir_fcb2unix(fcb, fname)) return 0x09FF;
        redir_Msg("fcb_creat(\"%s\")\n", fname);

        /* Software write-protection */
        if (redir_ro_fcb(fcb)) return 0x02FF;

	redir_log_fcb(fcb);

	if (fcb[0] & 0x80)
	{
#ifdef WIN32
		handle = mkdir(fname);
#else
		handle = mkdir(fname, 0x777);
#endif
		if (handle) return redir_xlt_err();
		return 0;
	}

#ifdef WIN32
	redir_Msg(">CreateFile([CREATE_ALWAYS]) Name='%s'\n", fname);
	handle = (int)CreateFile(fname, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	redir_Msg("<CreateFile([CREATE_ALWAYS]) Handle=%lu, LastErr=%lu\n", handle, GetLastError());
	if (handle == HFILE_ERROR) return 0xFF;
#else
	handle = open(fname, O_RDWR | O_CREAT | O_EXCL | O_BINARY, 
	  S_IREAD | S_IWRITE);
	if (handle < 0 ) return 0xFF;
#endif

	fcb[MAGIC_OFFSET    ] = 0xFD;   /* "Magic number"  */
	fcb[MAGIC_OFFSET + 1] = 0;
  redir_wrhandle(fcb + HANDLE_OFFSET, handle);
	redir_wr32(fcb + LENGTH_OFFSET, 0);
	redir_put_fcb_pos(fcb, 0);	/* Seek to 0 */

#ifdef __MSDOS__
	if (redir_drdos && (fcb[6] & 0x80))
	{
		cpm_word rights = redir_drdos_pwmode(dma[9]);
		redir_drdos_put_rights(fname, dma, rights | 0x8000);
	}
#endif

        return 0;
}



cpm_word fcb_rename(cpm_byte *fcb, cpm_byte *dma)
{
        char ofname[CPM_MAXPATH], nfname[CPM_MAXPATH];
	cpm_byte sdrv, ddrv;

	redir_log_fcb(fcb);

	/* Don't support ambiguous filenames */
        if (redir_fcb2unix(fcb,      ofname)) return 0x09FF;
	if (redir_fcb2unix(fcb+0x10, nfname)) return 0x09FF;

        /* Software write-protection */
        if (redir_ro_fcb(fcb)) return 0x02FF;

	if (fcb[0] & 0x80) return 0xFF;	/* Can't rename directories */

	/* Check we're not trying to rename across drives. Otherwise, it
         * might let you do it if the two "drives" are on the same disk. */

	sdrv = fcb[0] & 0x7F;     if (!sdrv) sdrv = redir_cpmdrive + 1;
	ddrv = fcb[0x10] & 0x7F;  if (!ddrv) ddrv = redir_cpmdrive + 1;

	if (sdrv != ddrv) return 0xFF;

        redir_Msg("fcb_rename(\"%s\", \"%s\")\n", ofname, nfname);

	if (rename(ofname, nfname))
	{
		if (redir_password_error())
		{
			redir_password_append(ofname, dma);
			if (!rename(ofname, nfname)) return 0;
			if (redir_password_error()) return 0x7FF;
		}
		return 0xFF;
	}
	
        return 0;
}




cpm_word fcb_randrd(cpm_byte *fcb, cpm_byte *dma)
{
        int handle;
        int rv, n, rd_len;
        dword offs = redir_rd24(fcb + 0x21) * 128;

	SHOWNAME("fcb_randrd")

        if ((handle = redir_verify_fcb(fcb)) < 0) return 9;	/* Invalid FCB */

        if (zxlseek(handle, offs, SEEK_SET) < 0) return 6; /* bad record no. */
#ifdef WIN32
	{
		BOOL b;
		redir_Msg(">ReadFile() Handle=%lu, DMA=%lu, Len=%lu\n", handle, dma, redir_rec_len);
		b = ReadFile((HANDLE)handle, dma, redir_rec_len, (unsigned long *)(&rv), NULL);
		redir_Msg("<ReadFile() Result=%c, Bytes Read=%lu, LastErr=%lu\n", b ? 'T' : 'F', rv, GetLastError());
		if (!b) rv = -1;
	}
#else
        rv = read(handle, dma, redir_rec_len);
#endif
	zxlseek(handle, offs, SEEK_SET);

	redir_put_fcb_pos(fcb, offs);

	rd_len = ((rv + 127) / 128) * 128;
	
        if (rv < 0)  return redir_xlt_err(); /* Error */
        if (rd_len < redir_rec_len)  /* eof */
	{
		rd_len = ((rv + 127) / 128) << 8;	/* High byte */
		redir_Msg("Ret: 0x%x\n", rd_len | 1);
		return rd_len | 1; /* eof */
	}
        for (n = rv; n < rd_len; n++) dma[n] = 0x1A;
        return 0;
}



cpm_word fcb_randwr(cpm_byte *fcb, cpm_byte *dma)
{
        int handle;
	int rv;
	dword offs = redir_rd24(fcb + 0x21) * 128;
	long len;

        SHOWNAME("fcb_randwr")

        if ((handle = redir_verify_fcb(fcb)) < 0) return 9;	/* Invalid FCB */
        /* Software write-protection */
        if (redir_ro_fcb(fcb)) return 0x02FF;

	if (zxlseek(handle, offs, SEEK_SET) < 0) return 6; /* bad record no. */
#ifdef WIN32
	{
		BOOL b;
		redir_Msg(">WriteFile() Handle=%lu, DMA=%lu, Len=%lu\n", handle, dma, redir_rec_len);
		b = WriteFile((HANDLE)handle, dma, redir_rec_len, (unsigned long *)(&rv), NULL);
		redir_Msg("<WriteFile() Result=%c, Bytes Written=%lu, LastErr=%lu\n", b ? 'T' : 'F', rv, GetLastError());
		if (!b) rv = -1;
	}
#else	
	rv = write(handle, dma, redir_rec_len);
#endif
	zxlseek(handle, offs, SEEK_SET);
	redir_put_fcb_pos(fcb, offs);

        /* Update the file length */
        len = redir_rd32(fcb + 0x1C);
        if (len < offs) redir_wr32(fcb + LENGTH_OFFSET, offs);

	if (rv < 0) return redir_xlt_err();	/* Error */
	if (rv < redir_rec_len) return 1;	/* disk full */
	return 0;
}

/* Write random with 0 fill */
cpm_word fcb_randwz(cpm_byte *fcb, cpm_byte *dma)
{
	dword offs, len;
	int handle, rl, rv;
	cpm_byte zerorec[128];

	SHOWNAME("fcb_randwz")

        if ((handle = redir_verify_fcb(fcb)) < 0) return 9;     /* Invalid FCB */
        offs = redir_rd24(fcb + 0x21) * 128;
	len  = redir_rd32(fcb + 0x1C);

	redir_wr32(fcb + LENGTH_OFFSET, offs);

	memset(zerorec, 0, sizeof(zerorec));

	while (len < offs) 
	{
		rl = sizeof(zerorec);
		if ((offs - len) < sizeof(zerorec)) rl = offs - len;
#ifdef WIN32
		{
			BOOL b;
			redir_Msg(">WriteFile() Handle=%lu, DMA=%lu, Len=%lu\n", handle, zerorec, rl);
			b = WriteFile((HANDLE)handle, zerorec, rl, (unsigned long *)(&rv), NULL);
			redir_Msg("<WriteFile() Result=%c, Bytes Written=%lu, LastErr=%lu\n", b ? 'T' : 'F', rv, GetLastError());
		}
#else	
		rv = write(handle, zerorec, rl);
#endif
		if (rv >= 0) len += rv;
	
		if (rv < rl)
		{
			redir_wr32(fcb + LENGTH_OFFSET, len);
			return redir_xlt_err();
		}	
	}
        redir_wr32(fcb + LENGTH_OFFSET, offs);

	return fcb_randwr(fcb, dma);
}

cpm_word fcb_tell(cpm_byte *fcb)
{
        int handle;
        off_t rv;

        SHOWNAME("fcb_tell")

        if ((handle = redir_verify_fcb(fcb)) < 0) return 9;   /* Invalid FCB */

	rv = zxlseek(handle, 0, SEEK_CUR);

        if (rv < 0) return 0xFF;

        rv = rv >> 7;
        fcb[0x21] =  rv        & 0xFF;
        fcb[0x22] = (rv >> 8)  & 0xFF;
        fcb[0x23] = (rv >> 16) & 0xFF;
        return 0;
}


cpm_word fcb_stat(cpm_byte *fcb)
{
        char fname[CPM_MAXPATH];
	struct stat st;
	int rv;
	
	/* Don't support ambiguous filenames */
        if (redir_fcb2unix(fcb, fname)) return 0x09FF;

        rv = stat(fname, &st);

        redir_Msg("fcb_stat(\"%s\") fcb=%x\n", fname, (int)fcb);
	if (rv < 0) 
	{
		redir_Msg("ret: -1\n");
		return 0xFF;
	}

	redir_wr24(fcb + 0x21, (st.st_size + 127) / 128);

	redir_Msg("ret: 0");
        return 0;
}


cpm_word fcb_multirec(cpm_byte rc)
{
	if (rc < 1 || rc > 128) return 0xFF;
	
	redir_rec_multi = rc;
	redir_rec_len   = 128 * rc;
	redir_Msg("Set read/write to %d bytes\n", redir_rec_len);
	return 0;
}


cpm_word fcb_date(cpm_byte *fcb)
{
        char fname[CPM_MAXPATH];
        struct stat st;
	int rv;

	/* Don't support ambiguous filenames */
        if (redir_fcb2unix(fcb, fname)) return 0x09FF;

        rv = stat(fname, &st);

        redir_Msg("fcb_stat(\"%s\")\n", fname);
        if (rv < 0) return 0xFF;
	
	redir_wr32(fcb + 0x18, redir_cpmtime(st.st_atime));
	redir_wr32(fcb + 0x1C, redir_cpmtime(st.st_ctime));

	fcb[0x0C] = redir_cpm_pwmode(redir_drdos_get_rights(fname));
	return 0;
}



cpm_word fcb_trunc(cpm_byte *fcb, cpm_byte *dma)
{
        char fname[CPM_MAXPATH];
        dword offs = redir_rd24(fcb + 0x21) * 128;

        /* Don't support ambiguous filenames */
        if (redir_fcb2unix(fcb, fname)) return 0x09FF;

        /* Software write-protection */
        if (redir_ro_fcb(fcb)) return 0x02FF;

        redir_log_fcb(fcb);
#ifdef WIN32
	(void)offs;
	return 0x06FF;	/* Simply not implemented */
#else
	if (truncate(fname, offs))
	{
		if (redir_password_error())
		{
			redir_password_append(fname, dma);
			if (!truncate(fname, offs)) return 0;
		}
		return redir_xlt_err();
	}
	return 0;
#endif
}


cpm_word fcb_sdate(cpm_byte *fcb, cpm_byte *dma)
{
        char fname[CPM_MAXPATH];
#ifdef WIN32
        /* TODO: Use SetFileTime() here */

       /* Don't support ambiguous filenames */
        if (redir_fcb2unix(fcb, fname)) return 0x09FF;

        /* Software write-protection */
        if (redir_ro_fcb(fcb)) return 0x02FF;

        redir_log_fcb(fcb);
#else
	struct utimbuf buf;

	buf.actime  = redir_unixtime(dma);
	buf.modtime = redir_unixtime(dma + 4);

        /* Don't support ambiguous filenames */
        if (redir_fcb2unix(fcb, fname)) return 0x09FF;

        /* Software write-protection */
        if (redir_ro_fcb(fcb)) return 0x02FF;

        redir_log_fcb(fcb);

	if (utime(fname, &buf))
	{
		if (redir_password_error())
		{
			redir_password_append(fname, dma);
			if (!utime(fname, &buf)) return 0;
		}
		return redir_xlt_err();
	}
#endif
        return 0;
}



cpm_word fcb_chmod(cpm_byte *fcb, cpm_byte *dma)
{
	char fname[CPM_MAXPATH];
	struct stat st;
	int handle, wlen, omode;
	long offs, newoffs;
	cpm_byte zero[128];

        /* Don't support ambiguous filenames */
        if (redir_fcb2unix(fcb, fname)) return 0x09FF;

        /* Software write-protection */
        if (redir_ro_fcb(fcb)) return 0x02FF;

        redir_log_fcb(fcb);

        if (stat(fname, &st)) return redir_xlt_err();

#ifdef __MSDOS__
	omode = 0;
	if (fcb[9]    & 0x80)  omode |= 1;
	if (fcb[10]   & 0x80)  omode |= 4;
	if (!(fcb[11] & 0x80)) omode |= 0x20;

	if (_chmod(fname, 1, omode) < 0)
	{
		if (redir_password_error())
		{
			redir_password_append(fname, dma);
			if (_chmod(fname, 1, omode) >= 0) return 0;
		}
		return redir_xlt_err();
	}
#elif defined (WIN32)
	omode = 0;

        if (fcb[9]    & 0x80)  omode |= FILE_ATTRIBUTE_READONLY;
        if (fcb[10]   & 0x80)  omode |= FILE_ATTRIBUTE_SYSTEM;
        if (!(fcb[11] & 0x80)) omode |= FILE_ATTRIBUTE_ARCHIVE;

	if (!omode) omode = FILE_ATTRIBUTE_NORMAL;

	SetFileAttributes(fname, omode); 
#else
	omode = st.st_mode;
	if (fcb[9] & 0x80)	/* Read-only */
	{
		st.st_mode &= ~(S_IWUSR | S_IWGRP | S_IWOTH);
	}
	else st.st_mode |= S_IWUSR;

	if (omode != st.st_mode)
	{
		if (chmod(fname, st.st_mode)) return redir_xlt_err();
	}

#endif

	if (fcb[6] & 0x80)	/* Set exact size */
	{
		if (stat(fname, &st)) return redir_xlt_err();

		handle = open(fname, O_RDWR | O_BINARY);
		if (handle < 0) return redir_xlt_err();

		newoffs = offs = ((st.st_size + 127) / 128) * 128;
		if (fcb[0x20] & 0x7F)
		{
			newoffs -= (0x80 - (fcb[0x20] & 0x7F)); 
		}
		if (newoffs == st.st_size)
		{
			;	/* Nothing to do! */
		}
		else if (newoffs < st.st_size)
		{
#ifndef WIN32		/* XXX Do this somehow in Win32 */
			if (ftruncate(handle, newoffs))
			{
				close(handle);
				return redir_xlt_err();
			}
#endif
		}
		else while (newoffs > st.st_size)
		{
			wlen = newoffs - st.st_size; 
			if (wlen > 0x80) wlen = 0x80;
			memset(zero, 0x1A, sizeof(zero));
			if (write(handle, zero, wlen) < wlen) 
			{
				close(handle);
				return redir_xlt_err();
			}
			st.st_size += wlen;
		}
		close(handle);
	}
	return 0;
}




cpm_word fcb_setpwd(cpm_byte *fcb, cpm_byte *dma)
{
#ifdef __MSDOS__
	char fname[CPM_MAXPATH];
	cpm_word rv;

        /* Don't support ambiguous filenames */
        if (redir_fcb2unix(fcb, fname)) return 0x09FF;

        /* Software write-protection */
        if (redir_ro_fcb(fcb)) return 0x02FF;

        redir_log_fcb(fcb);

	rv = redir_drdos_put_rights(fname, dma, redir_drdos_pwmode(fcb[0x0c]));
	if (rv || !(fcb[0x0c] & 1)) return rv;
	return redir_drdos_put_rights(fname, dma, redir_drdos_pwmode(fcb[0x0c]) | 0x8000);
#else
	return 0xFF;	/* Unix doesn't do this */
#endif
}


cpm_word fcb_getlbl(cpm_byte drv)
{
	redir_Msg("fcb_getlbl()\r\n");
#ifdef __MSDOS__
	if (redir_drdos) return 0xA1;	/* Supports passwords & Update stamps */
	return 0x21;			/* Update stamps only */
#else
	return 0x61;		/* Update & Access stamps */
#endif
}

cpm_word fcb_setlbl(cpm_byte *fcb, cpm_byte *dma)
{
/* I am not letting CP/M fiddle with the host's FS settings - even if they
 * could be altered, which they mostly can't. */

	return 0x03FF;
}



cpm_word fcb_defpwd(cpm_byte *pwd)
{
#ifdef __MSDOS__
	union REGS r;
	struct SREGS s;

	if (pwd[0] == 0 || pwd[0] == ' ')
	{
		redir_passwd[0] = 0;
	}
	else memcpy(redir_passwd, pwd, 8);
	if (redir_drdos)
	{
		dosmemput(pwd, 8, __tb);
		r.w.ax = 0x4454;
		r.w.dx = __tb & 0x0F;
		s.ds   = __tb >> 4;
		intdosx(&r, &r, &s);
	}

#endif
	return 0;
}


