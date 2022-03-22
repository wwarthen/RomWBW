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

cpm_word fcb_open(cpm_byte* fcb, cpm_byte* dma)
{
	char fname[CPM_MAXPATH];
	int handle;
	int drv;
	size_t l;
	char* s;
	DIR* dir;

	FCBENT(fcb);

	/* Don't support ambiguous filenames */
	if (redir_fcb2unix(fcb, fname)) FCBRET(0x09FF);

	redir_log_fcb(fcb);

	drv = fcb[0] & 0x7F;
	if (!drv) drv = redir_cpmdrive; else --drv;

	if (fcb[0] & 0x80) /* Open directory */
	{
		if (fcb[0x0C]) FCBRET(0x0BFF); /* Can't assign "floating" dir */

		if (!memcmp(fcb + 1, ".          ", 11))
		{
			FCBRET(0); /* Opening "." */
		}
		if (!memcmp(fcb + 1, "..         ", 11))
		{
			l = strlen(redir_drive_prefix[drv]) - 1;
			s = redir_drive_prefix[drv];
			while (--l > 0 && !strchr(DIRSEP, s[l]))
				--l;
			if (l == 0) FCBRET(0);		/* "/" or "\" */
#ifdef _WIN32
			if (s[l] == ':' && l < 2) FCBRET(0);	/* "C:" */
#endif
			s[l + 1] = 0;
			FCBRET(0);
		}
		/* Opening some other directory */

		dir = opendir(fname);
		if (!dir) FCBRET(0xFF);		/* Not a directory */
		closedir(dir);
		strcpy(redir_drive_prefix[drv], fname);
		strcat(redir_drive_prefix[drv], "/");
		FCBRET(0);
	}

	/* Note: Some programs (MAC is an example) don't close a file
	 * if they opened it just to do reading. MAC then reopens the
	 * file (which rewinds it); this causes FCB leaks under some
	 * DOS-based emulators */

	handle = redir_ofile(fcb, fname);
	//DBGMSGV("fcb_open('%s')\n", fname);
	if (handle < 0 && redir_password_error())
	{
		DBGMSGV("1st chance open failed on %s\n", fname);
		redir_password_append(fname, dma);
		DBGMSGV("Trying with %s\n", fname);
		handle = redir_ofile(fcb, fname);
	}

	if (handle == -1)
	{
		if (redir_password_error()) FCBRET(0x7FF);
		FCBRET(0xFF);
	}
	fcb[MAGIC_OFFSET] = 0xFD;		/* "Magic number"  */
	fcb[MAGIC_OFFSET + 1] = 0x00;

	/* TODO: Should the magic number perhaps be 0x8080, as in DOSPLUS? */

	redir_wrhandle(fcb + HANDLE_OFFSET, handle);

	redir_put_fcb_pos(fcb, fcb[0x0C] * 16384);
	/* (v1.01) "seek" to beginning of extent, not file.
	 *         This is necessary for the awful I/O code
	 *         in LINK-80 to work
	 */

	 /* Get the file length */
	redir_wr32(fcb + LENGTH_OFFSET, zxlseek(handle, 0, SEEK_END));
	zxlseek(handle, 0, SEEK_SET);

	/* Set the last record byte count */
	if (fcb[0x20] == 0xFF) fcb[0x20] = fcb[LENGTH_OFFSET] & 0x7F;

	FCBRET(0);
}

cpm_word fcb_close(cpm_byte* fcb)
{
	int handle, drv;

	FCBENT(fcb);

	if ((handle = redir_verify_fcb(fcb)) < 0) FCBRET(-1);
	DBGMSGV("         (at   0x%lX)\n", zxlseek(handle, 0, SEEK_CUR));

	if (fcb[0] & 0x80)	/* Close directory */
	{
		drv = fcb[0] & 0x7F;
		if (!drv) drv = redir_cpmdrive; else drv--;
#ifdef __MSDOS__
		strcpy(redir_drive_prefix[drv] + 1, ":/");
#else
		strcpy(redir_drive_prefix[drv], "/");
#endif
		FCBRET(0);
	}

	if (fcb[5] & 0x80)	/* CP/M 3: Flush rather than close */
	{
#ifdef _WIN32
		BOOL b;
		DBGMSGV("flush file #%i\n", handle);
		b = FlushFileBuffers((HANDLE)handle);
		if (!b)
			DBGMSGV("failed to flush file #%i (Error=%lu): %s\n", handle, GetLastError(), GetErrorStr(GetLastError()));
#else
		DBGMSGV("flush file #%i\n", handle);
		sync();
#endif
		FCBRET(0);
	}

#ifdef _WIN32
	{
		BOOL b;
		DBGMSGV("close file #%i\n", handle);
		b = CloseHandle((HANDLE)handle);
		if (!b)
		{
			DBGMSGV("failed to close file #%i (Error=%lu): %s\n", handle, GetLastError(), GetErrorStr(GetLastError()));
			FCBRET(0xFF);
		}
	}
#else
	DBGMSGV("close file #%i\n", handle);
	if (close(handle))
	{
		DBGMSGV("failed to close file #%i (Error=%lu): %s\n", handle, errno, strerror(errno));
		FCBRET(0xFF);
	}
#endif

	trackFile(NULL, fcb, handle);

	FCBRET(0);
}

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

cpm_word fcb_read(cpm_byte* fcb, cpm_byte* dma)
{
	int handle;
	int rv, n, rd_len;
	long npos;

	FCBENT(fcb);

	if ((handle = redir_verify_fcb(fcb)) < 0) FCBRET(9);	/* Invalid FCB */

	/* The program may have mucked about with the counters, so
	 * do an lseek() to where it should be. */

	npos = redir_get_fcb_pos(fcb);
	zxlseek(handle, npos, SEEK_SET);
	DBGMSGV("        (from 0x%lX)\n", zxlseek(handle, 0, SEEK_CUR));

	/* Read in the required amount */

#ifdef _WIN32
	{
		BOOL b;
		DBGMSGV("read file #%i @ 0x%X, %i bytes\n", handle, dma - RAM, redir_rec_len);
		b = ReadFile((HANDLE)handle, dma, redir_rec_len, (unsigned long*)(&rv), NULL);
		if (!b)
		{
			DBGMSGV("failed to read file #%i (Error=%lu): %s\n", handle, GetLastError(), GetErrorStr(GetLastError()));
			rv = -1;
		}
	}
#else
	DBGMSGV("read file #%i @ 0x%X, %i bytes\n", handle, dma - RAM, redir_rec_len);
	rv = read(handle, dma, redir_rec_len);
	if (rv == -1)
		DBGMSGV("failed to read file #%i (errno=%lu): %s\n", handle, errno, strerror(errno));
#endif

	/* read() can corrupt buffer area following data read if length
	 * of data read is less than buffer.  Clean it up. */
	if (rv == -1)
		memset(dma, 0x00, redir_rec_len);
	else
		memset(dma + rv, 0x00, redir_rec_len - rv);

	/* rd_len = length supposedly read, bytes. Round to nearest 128
	 * bytes. */
	rd_len = ((rv + 127) / 128) * 128;

	npos += rd_len;

	/* Write new file pointer into FCB */

	redir_put_fcb_pos(fcb, npos);

	if (rv < 0)
	{
		DBGMSG("Ret: -1\n");
		FCBRET(redir_xlt_err()); /* unwritten extent */
	}

	/* if not multiple of 128 bytes, pad sector with 0x1A */
	for (n = rv; n < rd_len; n++) dma[n] = 0x1A;

	/* Less was read in than asked for. Report the number of 128-byte
	 * records that _were_ read in.
	 */

	if (rd_len < redir_rec_len) /* eof */
	{
		/* Pack from the size actually read up to the size we claim
		 * to have read */
		rd_len = rd_len * 2;	/* rd_len already sector * 128, so * 2 to move to High byte */
		FCBRET(rd_len | 1); /* eof */
	}

	DBGMSGV("Ret: 0 (bytes read=%d)\n", rv);
	FCBRET(0);
}

cpm_word fcb_write(cpm_byte* fcb, cpm_byte* dma)
{
	int handle;
	int rv;
	long npos, len;

	FCBENT(fcb);

	if ((handle = redir_verify_fcb(fcb)) < 0) FCBRET(9);	/* Invalid FCB */

	/* Software write-protection */
	if (redir_ro_fcb(fcb)) FCBRET(0x02FF);

	/* Check for a seek */
	npos = redir_get_fcb_pos(fcb);
	zxlseek(handle, npos, SEEK_SET);

	DBGMSGV("         (to   %lX)\n", zxlseek(handle, 0, SEEK_CUR));

#ifdef _WIN32
	{
		BOOL b;
		DBGMSGV("write file #%i @ 0x%X, %i bytes\n", handle, dma - RAM, redir_rec_len);
		b = WriteFile((HANDLE)handle, dma, redir_rec_len, (unsigned long*)(&rv), NULL);
		if (!b)
		{
			DBGMSGV("failed to write file #%i (Error=%lu): %s\n", handle, GetLastError(), GetErrorStr(GetLastError()));
			rv = -1;
		}
	}
#else
	DBGMSGV("write file #%i @ 0x%X, %i bytes\n", handle, dma - RAM, redir_rec_len);
	rv = write(handle, dma, redir_rec_len);
	if (rv == -1)
		DBGMSGV("failed to write file #%i (errno=%lu): %s\n", handle, errno, strerror(errno));
#endif
	npos += redir_rec_len;

	redir_put_fcb_pos(fcb, npos);

	/* Update the file length */
	len = redir_rd32(fcb + LENGTH_OFFSET);
	if (len < npos) redir_wr32(fcb + LENGTH_OFFSET, npos);

	if (rv < 0)       FCBRET(redir_xlt_err()); /* error */
	if (rv < redir_rec_len) FCBRET(1);    /* disk full */
	FCBRET(0);
}

cpm_word fcb_creat(cpm_byte* fcb, cpm_byte* dma)
{
	char fname[CPM_MAXPATH];
	int handle;

	FCBENT(fcb);

	releaseFCB(fcb);   /* release existing fcb usage */

	/* Don't support ambiguous filenames */
	if (redir_fcb2unix(fcb, fname)) FCBRET(0x09FF);
	DBGMSGV("fcb_creat('%s')\n", fname);

	/* Software write-protection */
	if (redir_ro_fcb(fcb)) FCBRET(0x02FF);

	redir_log_fcb(fcb);

	if (fcb[0] & 0x80)
	{
		handle = mkdir(fname, 0x777);
		if (handle) FCBRET(redir_xlt_err());
		FCBRET(0);
	}
	releaseFile(fname);  /* purge any open handles for this file */

#ifdef _WIN32
	DBGMSGV("create file '%s'\n", fname);
	handle = (int)CreateFile(fname, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
	if (handle == HFILE_ERROR)
	{
		DBGMSGV("failed to create file '%s' (Error=%lu): %s\n", fname, GetLastError(), GetErrorStr(GetLastError()));
		FCBRET(0xFF);
	}
#else
	DBGMSGV("create file '%s'\n", fname);
	handle = open(fname, O_RDWR | O_CREAT | O_EXCL | O_BINARY,
		S_IREAD | S_IWRITE);
	if (handle < 0)
	{
		DBGMSGV("failed to create file '%s' (Error=%lu): %s\n", fname, errno, strerror(errno));
		FCBRET(0xFF);
	}
#endif

	trackFile(fname, fcb, handle); /* track new file */

	fcb[MAGIC_OFFSET] = 0xFD;   /* "Magic number"  */
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

	FCBRET(0);
}

cpm_word fcb_rename(cpm_byte* fcb, cpm_byte* dma)
{
	char ofname[CPM_MAXPATH], nfname[CPM_MAXPATH];
	cpm_byte sdrv, ddrv;

	FCBENT(fcb);

	releaseFCB(fcb);		/* release any file associated with the fcb */
	redir_log_fcb(fcb);

	/* Don't support ambiguous filenames */
	if (redir_fcb2unix(fcb, ofname)) FCBRET(0x09FF);
	if (redir_fcb2unix(fcb + 0x10, nfname)) FCBRET(0x09FF);

	/* Software write-protection */
	if (redir_ro_fcb(fcb)) FCBRET(0x02FF);

	if (fcb[0] & 0x80) FCBRET(0xFF);	/* Can't rename directories */

	/* Check we're not trying to rename across drives. Otherwise, it
	 * might let you do it if the two "drives" are on the same disk. */

	sdrv = fcb[0] & 0x7F;     if (!sdrv) sdrv = redir_cpmdrive + 1;
	ddrv = fcb[0x10] & 0x7F;  if (!ddrv) ddrv = redir_cpmdrive + 1;

	if (sdrv != ddrv) FCBRET(0xFF);

	DBGMSGV("rename '%s' to '%s'\n", ofname, nfname);

	releaseFile(ofname);    /* need ofname and nfname to be closed */
	releaseFile(nfname);
	if (rename(ofname, nfname))
	{
		if (redir_password_error())
		{
			redir_password_append(ofname, dma);
			if (!rename(ofname, nfname)) FCBRET(0);
			if (redir_password_error()) FCBRET(0x7FF);
		}
		FCBRET(0xFF);
	}

	FCBRET(0);
}

cpm_word fcb_randrd(cpm_byte* fcb, cpm_byte* dma)
{
	int handle;
	int rv, n, rd_len;
	dword offs = redir_rd24(fcb + 0x21) * 128;

	FCBENT(fcb);

	if ((handle = redir_verify_fcb(fcb)) < 0) FCBRET(9);	/* Invalid FCB */

	if (zxlseek(handle, offs, SEEK_SET) < 0) FCBRET(6); /* bad record no. */

#ifdef _WIN32
	{
		BOOL b;
		DBGMSGV("read file #%i @ 0x%X, %i bytes\n", handle, dma - RAM, redir_rec_len);
		b = ReadFile((HANDLE)handle, dma, redir_rec_len, (unsigned long*)(&rv), NULL);
		if (!b)
		{
			DBGMSGV("failed to read file #%i (Error=%lu): %s\n", handle, GetLastError(), GetErrorStr(GetLastError()));
			rv = -1;
		}
	}
#else
	DBGMSGV("read file #%i @ 0x%X, %i bytes\n", handle, dma - RAM, redir_rec_len);
	rv = read(handle, dma, redir_rec_len);
	if (rv == -1)
		DBGMSGV("failed to read file #%i (errno=%lu): %s\n", handle, errno, strerror(errno));
#endif

	// read() can corrupt buffer area following data read if length
	// of data read is less than buffer.  Clean it up.
	if (rv == -1)
		memset(dma, 0x00, redir_rec_len);
	else
		memset(dma + rv, 0x00, redir_rec_len - rv);

	zxlseek(handle, offs, SEEK_SET);

	redir_put_fcb_pos(fcb, offs);

	if (rv < 0)  FCBRET(redir_xlt_err()); /* Error */

	rd_len = ((rv + 127) / 128) * 128;

	/* PMO: pad partial sector to 128 bytes, even if EOF reached in multi sector read */
	for (n = rv; n < rd_len; n++) dma[n] = 0x1A;	/* pad last read to 128 boundary with 0x1A*/

	if (rd_len < redir_rec_len)  /* eof */
	{
		rd_len = rd_len * 2;	/* rd_len already sector * 128, so * 2 to move to High byte */
		DBGMSGV("Ret: 0x%x\n", rd_len | 1);
		FCBRET(rd_len | 1); /* eof */
	}

	FCBRET(0);
}

cpm_word fcb_randwr(cpm_byte* fcb, cpm_byte* dma)
{
	int handle;
	int rv;
	dword offs = redir_rd24(fcb + 0x21) * 128;
	dword len;

	FCBENT(fcb);

	if ((handle = redir_verify_fcb(fcb)) < 0) FCBRET(9);	/* Invalid FCB */
	/* Software write-protection */
	if (redir_ro_fcb(fcb)) FCBRET(0x02FF);

	if (zxlseek(handle, offs, SEEK_SET) < 0) FCBRET(6); /* bad record no. */

#ifdef _WIN32
	{
		BOOL b;
		DBGMSGV("write file #%i @ 0x%X, %i bytes\n", handle, dma - RAM, redir_rec_len);
		b = WriteFile((HANDLE)handle, dma, redir_rec_len, (unsigned long*)(&rv), NULL);
		if (!b)
		{
			DBGMSGV("failed to write file #%i (Error=%lu): %s\n", handle, GetLastError(), GetErrorStr(GetLastError()));
			rv = -1;
		}
	}
#else
	DBGMSGV("write file #%i @ 0x%X, %i bytes\n", handle, dma - RAM, redir_rec_len);
	rv = write(handle, dma, redir_rec_len);
	if (rv == -1)
		DBGMSGV("failed to write file #%i (errno=%lu): %s\n", handle, errno, strerror(errno));
#endif
	zxlseek(handle, offs, SEEK_SET);
	redir_put_fcb_pos(fcb, offs);

	if (rv < 0) FCBRET(redir_xlt_err());	/* Error */
	/* Update the file length */
	len = redir_rd32(fcb + LENGTH_OFFSET);
	/* PMO: Bug fix, account for the data just written */
	if (len < offs + rv) {
		redir_wr32(fcb + LENGTH_OFFSET, offs + rv);
		/* WBW: Not actually a bug.  Causes problems w/ GENCPM */
		// fcb[0x20] = (offs + rv) % 256;
	}

	if (rv < redir_rec_len) FCBRET(1);	/* disk full */
	FCBRET(0);
}

#ifndef OLD_RANDWZ
/* PMO:
 * Under CP/M for random write with zero fill, the zero fill is only done for a newly allocated
 * block and not fill from previous end of file
 * to implement this fully would require tracking sparse files and filling to block
 * boundaries.
 * As the default for POSIX/Windows lseek is to effectively zero fill and for modern hard disks
 * the additional space used is small compared to capacity, fcb_randwz is the same as fcb_randwr
 * Note zero padding to the end of the block will be done automatically as required when data is
 * written to later offsets
 */
 /* Write random with 0 fill */
cpm_word fcb_randwz(cpm_byte* fcb, cpm_byte* dma)
{
	FCBENT(fcb);
	FCBRET(fcb_randwr(fcb, dma));
}
#else
/* Write random with 0 fill */
cpm_word fcb_randwz(cpm_byte* fcb, cpm_byte* dma)
{
	dword offs, len;
	int handle, rl, rv;
	cpm_byte zerorec[128];

	FCBENT(fcb);

	if ((handle = redir_verify_fcb(fcb)) < 0) FCBRET(9);     /* Invalid FCB */
		/* Software write-protection */
	if (redir_ro_fcb(fcb)) FCBRET(0x02FF);

	offs = redir_rd24(fcb + 0x21) * 128;
	len = redir_rd32(fcb + LENGTH_OFFSET);

	redir_wr32(fcb + LENGTH_OFFSET, offs);

	memset(zerorec, 0, sizeof(zerorec));

	while (len < offs)
	{
		memset(zerorec, 0, sizeof(zerorec));

		rl = sizeof(zerorec);
		if ((offs - len) < sizeof(zerorec)) rl = offs - len;
#ifdef _WIN32
		{
			BOOL b;
			DBGMSGV("write file #%i (zeroes), %i bytes\n", handle, redir_rec_len);
			b = WriteFile((HANDLE)handle, zerorec, rl, (unsigned long*)(&rv), NULL);
			if (!b)
			{
				DBGMSGV("failed to write file #%i (Error=%lu): %s\n", handle, GetLastError(), GetErrorStr(GetLastError()));
				rv = -1;
			}
		}
#else
		DBGMSGV("write file #%i (zeroes), %i bytes\n", handle, redir_rec_len);
		rv = write(handle, zerorec, rl);
		if (rv == -1)
			DBGMSGV("failed to write file #%i (errno=%lu): %s\n", handle, errno, strerror(errno));
#endif
		if (rv >= 0) len += rv;

		if (rv < rl)
		{
			redir_wr32(fcb + LENGTH_OFFSET, len);
			FCBRET(redir_xlt_err());
		}
	}
	redir_wr32(fcb + LENGTH_OFFSET, offs);

	FCBRET(fcb_randwr(fcb, dma));
}
#endif

cpm_word fcb_tell(cpm_byte* fcb)
{
	int handle;
	off_t rv;

	FCBENT(fcb);

	if ((handle = redir_verify_fcb(fcb)) < 0) FCBRET(9);   /* Invalid FCB */

	rv = zxlseek(handle, 0, SEEK_CUR);

	if (rv < 0) FCBRET(0xFF);

	rv = rv >> 7;
	fcb[0x21] = rv & 0xFF;
	fcb[0x22] = (rv >> 8) & 0xFF;
	fcb[0x23] = (rv >> 16) & 0xFF;
	FCBRET(0);
}

cpm_word fcb_stat(cpm_byte* fcb)
{
	char fname[CPM_MAXPATH];
	struct stat st;
	int rv;

	FCBENT(fcb);

	/* Don't support ambiguous filenames */
	if (redir_fcb2unix(fcb, fname)) FCBRET(0x09FF);

	DBGMSGV("stat '%s', FCB=%0.4X\n", fname, fcb - RAM);
	rv = stat(fname, &st);
	if (rv < 0)
	{
		DBGMSGV("failed to stat file '%s' (errno=%lu): %s\n", fname, errno, strerror(errno));
		FCBRET(0xFF);
	}

	redir_wr24(fcb + 0x21, (st.st_size + 127) / 128);

	FCBRET(0);
}

cpm_word fcb_multirec(cpm_byte rc)
{
	if (rc < 1 || rc > 128) return 0xFF;

	redir_rec_multi = rc;
	redir_rec_len = 128 * rc;
	DBGMSGV("Set read/write to %d bytes\n", redir_rec_len);
	return 0;
}

cpm_word fcb_date(cpm_byte* fcb)
{
	char fname[CPM_MAXPATH];
	struct stat st;
	int rv;

	FCBENT(fcb);

	/* as this function will overwrite the fcb info used by ZXCC
	 * release any file associated with it
	 */
	releaseFCB(fcb);
	/* Don't support ambiguous filenames */
	if (redir_fcb2unix(fcb, fname)) FCBRET(0x09FF);

	DBGMSGV("stat '%s', FCB=%0.4X\n", fname, fcb - RAM);
	rv = stat(fname, &st);
	if (rv < 0)
	{
		DBGMSGV("failed to stat file '%s' (errno=%lu): %s\n", fname, errno, strerror(errno));
		FCBRET(0xFF);
	}

	redir_wr32(fcb + 0x18, redir_cpmtime(st.st_atime));
	redir_wr32(fcb + 0x1C, redir_cpmtime(st.st_ctime));

	fcb[0x0C] = redir_cpm_pwmode(redir_drdos_get_rights(fname));
	FCBRET(0);
}

cpm_word fcb_trunc(cpm_byte* fcb, cpm_byte* dma)
{
	char fname[CPM_MAXPATH];
	dword offs = redir_rd24(fcb + 0x21) * 128;

	FCBENT(fcb);

	releaseFCB(fcb);	/* CP/M requires truncated files be closed */
	/* Don't support ambiguous filenames */
	if (redir_fcb2unix(fcb, fname)) FCBRET(0x09FF);

	/* Software write-protection */
	if (redir_ro_fcb(fcb)) FCBRET(0x02FF);

	releaseFile(fname);			/* after truncate open files are invalid */
	redir_log_fcb(fcb);

	DBGMSGV("truncate file '%s' at %lu\n", fname, offs);
	if (truncate(fname, offs))
	{
		DBGMSGV("failed to truncate file '%s' (errno=%lu): %s\n", fname, errno, strerror(errno));
		if (redir_password_error())
		{
			redir_password_append(fname, dma);
			DBGMSGV("truncate file '%s' w/ password at %lu\n", fname, offs);
			if (!truncate(fname, offs)) FCBRET(0);
			DBGMSGV("failed to truncate file '%s' (errno=%lu): %s\n", fname, errno, strerror(errno));
		}
		FCBRET(redir_xlt_err());
	}
	FCBRET(0);
}

cpm_word fcb_sdate(cpm_byte* fcb, cpm_byte* dma)
{
	char fname[CPM_MAXPATH];
	struct utimbuf buf;

	FCBENT(fcb);

	buf.actime = redir_unixtime(dma);
	buf.modtime = redir_unixtime(dma + 4);

	/* Don't support ambiguous filenames */
	if (redir_fcb2unix(fcb, fname)) FCBRET(0x09FF);

	/* Software write-protection */
	if (redir_ro_fcb(fcb)) FCBRET(0x02FF);

	redir_log_fcb(fcb);

	DBGMSGV("utime file '%s'\n", fname);
	if (utime(fname, &buf))
	{
		DBGMSGV("failed to utime file '%s' (Error=%lu): %s\n", fname, errno, strerror(errno));
		if (redir_password_error())
		{
			redir_password_append(fname, dma);
			DBGMSGV("utime file '%s' w/ password\n", fname);
			if (!utime(fname, &buf)) FCBRET(0);
			DBGMSGV("failed to utime file '%s' (Error=%lu): %s\n", fname, errno, strerror(errno));
		}
		FCBRET(redir_xlt_err());
	}
	FCBRET(0);
}

cpm_word fcb_chmod(cpm_byte* fcb, cpm_byte* dma)
{
	char fname[CPM_MAXPATH];
	struct stat st;
	int handle, wlen, omode;
	long offs, newoffs;
	cpm_byte zero[128];

	FCBENT(fcb);

	/* Don't support ambiguous filenames */
	if (redir_fcb2unix(fcb, fname)) FCBRET(0x09FF);

	/* Software write-protection */
	if (redir_ro_fcb(fcb)) FCBRET(0x02FF);

	redir_log_fcb(fcb);

	DBGMSGV("stat '%s', FCB=%0.4X\n", fname, fcb - RAM);
	if (stat(fname, &st))
	{
		DBGMSGV("failed to stat file '%s' (errno=%lu): %s\n", fname, errno, strerror(errno));
		FCBRET(redir_xlt_err());
	}

#ifdef __MSDOS__
	omode = 0;
	if (fcb[9] & 0x80)  omode |= 1;
	if (fcb[10] & 0x80)  omode |= 4;
	if (!(fcb[11] & 0x80)) omode |= 0x20;

	if (_chmod(fname, 1, omode) < 0)
	{
		if (redir_password_error())
		{
			redir_password_append(fname, dma);
			if (_chmod(fname, 1, omode) >= 0) FCBRET(0);
		}
		FCBRET(redir_xlt_err());
	}
#elif defined (_WIN32)
	omode = 0;

	if (fcb[9] & 0x80)  omode |= FILE_ATTRIBUTE_READONLY;
	if (fcb[10] & 0x80)  omode |= FILE_ATTRIBUTE_SYSTEM;
	if (!(fcb[11] & 0x80)) omode |= FILE_ATTRIBUTE_ARCHIVE;

	if (!omode) omode = FILE_ATTRIBUTE_NORMAL;

	{
		BOOL b;
		DBGMSGV("set attributes file '%s', FCB=%0.4X\n", fname, fcb - RAM);
		b = SetFileAttributes(fname, omode);
		if (!b)
		{
			DBGMSGV("failed to set attributes file '%s' (Error=%lu): %s\n", fname, GetLastError(), GetErrorStr(GetLastError()));
			FCBRET(redir_xlt_err());
		}
	}
#else
	omode = st.st_mode;
	if (fcb[9] & 0x80)	/* Read-only */
	{
		st.st_mode &= ~(S_IWUSR | S_IWGRP | S_IWOTH);
	}
	else st.st_mode |= S_IWUSR;

	if (omode != st.st_mode)
	{
		DBGMSGV("chmod '%s', FCB=%0.4X\n", fname, fcb - RAM);
		if (chmod(fname, st.st_mode))
		{
			DBGMSGV("failed to chmod file '%s' (errno=%lu): %s\n", fname, errno, strerror(errno));
			FCBRET(redir_xlt_err());
		}
	}
#endif

	if (fcb[6] & 0x80)	/* Set exact size */
	{
		DBGMSGV("stat '%s', FCB=%0.4X\n", fname, fcb - RAM);
		if (stat(fname, &st))
		{
			DBGMSGV("failed to stat file '%s' (errno=%lu): %s\n", fname, errno, strerror(errno));
			FCBRET(redir_xlt_err());
		}

		releaseFCB(fcb);	/* cpm required file to be closed so release FCB */
		releaseFile(fname);	/* also make sure no other handles open to file */
		DBGMSGV("open '%s', FCB=%0.4X\n", fname, fcb - RAM);
		handle = open(fname, O_RDWR | O_BINARY);
		if (handle < 0)
		{
			DBGMSGV("failed to open file '%s' (errno=%lu): %s\n", fname, errno, strerror(errno));
			FCBRET(redir_xlt_err());
		}
		DBGMSGV("file '%s' opened at #%i\n", fname, handle);

		newoffs = offs = ((st.st_size + 127) / 128) * 128;
		if (fcb[0x20] & 0x7F)
		{
			newoffs -= fcb[0x20] & 0x7f;
			//newoffs -= (0x80 - (fcb[0x20] & 0x7F));
		}
		if (newoffs == st.st_size)
		{
			;	/* Nothing to do! */
		}
		else if (newoffs < st.st_size)
		{
			DBGMSGV("ftruncate file #%i at %lu\n", handle, newoffs);
			if (ftruncate(handle, newoffs))
			{
				DBGMSGV("failed to ftruncate file #%i (errno=%lu): %s\n", handle, errno, strerror(errno));
				close(handle);
				FCBRET(redir_xlt_err());
			}
		}
		else while (newoffs > st.st_size)
		{
			wlen = newoffs - st.st_size;
			if (wlen > 0x80) wlen = 0x80;
			memset(zero, 0x1A, sizeof(zero));
			DBGMSGV("write file #%i (zeroes), %lu bytes\n", handle, wlen);
			if (write(handle, zero, wlen) < wlen)
			{
				DBGMSGV("failed to write file #%i (errno=%lu): %s\n", handle, errno, strerror(errno));
				close(handle);
				FCBRET(redir_xlt_err());
			}
			st.st_size += wlen;
		}
		close(handle);
	}
	FCBRET(0);
}

cpm_word fcb_setpwd(cpm_byte* fcb, cpm_byte* dma)
{
#ifdef __MSDOS__
	char fname[CPM_MAXPATH];
	cpm_word rv;

	FCBENT(fcb);

	/* Don't support ambiguous filenames */
	if (redir_fcb2unix(fcb, fname)) FCBRET(0x09FF);

	/* Software write-protection */
	if (redir_ro_fcb(fcb)) FCBRET(0x02FF);

	redir_log_fcb(fcb);

	rv = redir_drdos_put_rights(fname, dma, redir_drdos_pwmode(fcb[0x0c]));
	if (rv || !(fcb[0x0c] & 1)) FCBRET(rv);
	FCBRET(redir_drdos_put_rights(fname, dma, redir_drdos_pwmode(fcb[0x0c]) | 0x8000));
#else
	FCBRET(0xFF);	/* Unix doesn't do this */
#endif
}

cpm_word fcb_getlbl(cpm_byte drv)
{
	DBGMSG("fcb_getlbl()\n");
#ifdef __MSDOS__
	if (redir_drdos) return 0xA1;	/* Supports passwords & Update stamps */
	return 0x21;			/* Update stamps only */
#else
	return 0x61;		/* Update & Access stamps */
#endif
}

cpm_word fcb_setlbl(cpm_byte* fcb, cpm_byte* dma)
{
	/* I am not letting CP/M fiddle with the host's FS settings - even if they
	 * could be altered, which they mostly can't. */

	return 0x03FF;
}

cpm_word fcb_defpwd(cpm_byte* pwd)
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
		s.ds = __tb >> 4;
		intdosx(&r, &r, &s);
	}

#endif
	return 0;
}
