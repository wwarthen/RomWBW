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

	This file holds miscellaneous utility functions.
*/

#include "cpmint.h"

#ifdef _WIN32

char* GetErrorStr(dword dwErr)
{
	LPVOID lpMsgBuf;
	static char ErrStr[256] = "";

	FormatMessage(
		FORMAT_MESSAGE_ALLOCATE_BUFFER |
		FORMAT_MESSAGE_FROM_SYSTEM |
		FORMAT_MESSAGE_IGNORE_INSERTS |
		FORMAT_MESSAGE_MAX_WIDTH_MASK,
		NULL,
		dwErr,
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
		(LPTSTR)&lpMsgBuf,
		sizeof(ErrStr), NULL);

	strncpy(ErrStr, lpMsgBuf, sizeof(ErrStr));

	LocalFree(lpMsgBuf);

	return ErrStr;
}

#endif

char* whence(int wh)
{
	switch (wh)
	{
	case SEEK_SET: return("SEEK_SET");
	case SEEK_CUR: return("SEEK_CUR");
	case SEEK_END: return("SEEK_END");
	default: return("SEEK_???");
	}
}

/* In debug mode, lseek()s can be traced. */

long zxlseek(int fd, long offset, int wh)
{
#ifdef _WIN32

	long v;
	DBGMSGV("seek on file #%i to 0x%lX using %s\n", fd, offset, whence(wh));
	v = SetFilePointer((HANDLE)fd, offset, NULL, wh);
	if (v != INVALID_SET_FILE_POINTER) return v;
	DBGMSGV("seek failed (Error=%lu): %s\n", GetLastError(), GetErrorStr(GetLastError()));
	return -1;

#else

	DBGMSGV("seek on #%i to 0x%lX using %s\n", fd, offset, whence(wh));
	long v = lseek(fd, offset, wh);
	if (v >= 0) return v;
	DBGMSGV("seek failed (errno=%lu): %s\n", errno, strerror(errno));
	return -1;

#endif
}

#ifdef DEBUG

void redir_showfcb(cpm_byte* fd)
{
	int n;

	for (n = 0; n < 32; n++)
	{
		if (!n || n >= 12) printf("%02x ", fd[n]);
		else printf("%c", fd[n] & 0x7F);
	}
	printf("\n");
}

#endif

/* Get the "sequential access" file pointer out of an FCB */

long redir_get_fcb_pos(cpm_byte* fcb)
{
	long npos;

	npos = 524288L * fcb[0x0E];		/* S2 */
	npos += 16384L * fcb[0x0C];		/* Extent */
	npos += 128L * fcb[0x20];		/* Record */

	return npos;
}

void redir_put_fcb_pos(cpm_byte* fcb, long npos)
{
	fcb[0x20] = (npos / 128) % 128;		/* Record */
	fcb[0x0C] = (npos / 16384) % 32;	/* Extent */
	fcb[0x0E] = (npos / 524288L) % 64;	/* S2 */
}

/*
 * find a filename that works.
 * note that this is where we handle the case sensitivity/non-case sensitivity
 * horror.
 * the name that is passed in should be in lower case.
 * we'll modify it to the first one that matches
 */
void swizzle(char* fullpath)
{
	struct stat ss;
	char* slash;
	DIR* dirp;
	struct dirent* dentry;

	/* short circuit if ok */
	if (stat(fullpath, &ss) == 0) {
		return;
	}

	slash = strrchr(fullpath, '/');
	if (!slash) {
		return;
	}
	*slash = '\0';
	dirp = opendir(fullpath);
	*slash = '/';
	while ((dentry = readdir(dirp)) != NULL) {
		if (strcasecmp(dentry->d_name, slash + 1) == 0) {
			strcpy(slash + 1, dentry->d_name);
			break;
		}
	}
	closedir(dirp);
}

/* Passed a CP/M FCB, convert it to a unix filename. Turn its drive back into
 * a path. */

int redir_fcb2unix(cpm_byte* fcb, char* fname)
{
	int n, q, drv, ddrv;
	char s[2];
	char buf[256];

	s[1] = 0;
	q = 0;
	drv = fcb[0] & 0x7F;
	if (drv == '?') drv = 0;

	ddrv = fcb[0] & 0x7F;
	if (ddrv < 0x1F) ddrv += '@';

	if (!drv) strcpy(fname, redir_drive_prefix[redir_cpmdrive]);
	else	  strcpy(fname, redir_drive_prefix[drv - 1]);

	for (n = 1; n < 12; n++)
	{
		s[0] = (fcb[n] & 0x7F);
		if (s[0] == '?') q = 1;
		if (isupper(s[0])) s[0] = tolower(s[0]);
		if (s[0] != ' ')
		{
			if (n == 9) strcat(fname, ".");
			strcat(fname, s);
		}
	}

	sprintf(buf, "'%c:%-8.8s.%-3.3s' --> '%s'", ddrv, fcb + 1, fcb + 9, fname);
	for (n = 0; buf[n] != '\0'; n++)
	{
		buf[n] &= 0x7F;
		if (buf[n] < ' ') buf[n] = 'x';
	}

	DBGMSGV("%s\n", buf);

	return q;
}

#ifndef EROFS	/* Open fails because of read-only FS */
#define EROFS EACCES
#endif

int redir_ofile(cpm_byte* fcb, char* s)
{
	int h;

	/* Software write-protection */

#ifdef _WIN32

	releaseFCB(fcb);

	if (!redir_ro_fcb(fcb))
	{
		// Attempt to open existing file with read/write access
		DBGMSGV("open existing file '%s' with read/write access\n", s);
		h = (int)CreateFile(s, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
		if (h != HFILE_ERROR)
		{
			DBGMSGV("file '%s' opened R/W as #%i\n", s, h);
			return trackFile(s, fcb, h);
		}
		DBGMSGV("open R/W failed (errno=%lu): %s\n", GetLastError(), GetErrorStr(GetLastError()));
	}

	// Attempt to open existing file with read-only access
	DBGMSGV("open existing file '%s' with read-only access\n", s);
	h = (int)CreateFile(s, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if (h == HFILE_ERROR)
	{
		DBGMSGV("open R/O failed (errno=%lu): %s\n", GetLastError(), GetErrorStr(GetLastError()));
		return -1;
	}
	DBGMSGV("file '%s' opened R/O as #%i\n", s, h);
	fcb[9] |= 0x80;

#elif defined(__MSDOS__)

	int rv;
	if (!redir_ro_fcb(fcb))
	{
		rv = _dos_open(s, O_RDWR, &h);
		if (!rv) return h;
		DBGMSGV("Open of %s fails: error %x\n", s, rv);
	}
	rv = _dos_open(s, O_RDONLY, &h);
	if (rv) return -1;
	fcb[9] |= 0x80;

#else

	releaseFCB(fcb);

	swizzle(s);

	if (!redir_ro_fcb(fcb))
	{
		// Attempt to open existing file with read/write access
		DBGMSGV("open existing file '%s' with read/write access\n", s);
		h = open(s, O_RDWR | O_BINARY);
		if (h >= 0 || (errno != EACCES && errno != EROFS))
		{
			DBGMSGV("file '%s' opened R/W as #%i\n", s, h);
			return trackFile(s, fcb, h);
		}
		DBGMSGV("failed to open R/W (errno=%lu): %s\n", errno, strerror(errno));
	}

	// Attempt to open existing file with read-only access
	DBGMSGV("open existing file '%s' with read-only access\n", s);
	h = open(s, O_RDONLY | O_BINARY);
	if (h < 0)
	{
		DBGMSGV("failed to open R/O (errno=%lu): %s\n", errno, strerror(errno));
		return -1;
	}
	DBGMSGV("file '%s' opened R/O as #%i\n", s, h);
	fcb[9] |= 0x80;

#endif

	return trackFile(s, fcb, h);
}

/* Extract a file handle from where it was stored in an FCB by fcb_open()
  or fcb_creat(). Aborts if the FCB has been tampered with.

  Note: Some programs (like GENCOM) close FCBs they never opened. This causes
  the Corrupt FCB message, but no harm seems to ensue. */

int redir_verify_fcb(cpm_byte* fcb)
{
	if (fcb[16] != 0xFD || fcb[17] != 0x00)
	{
		fprintf(stderr, "cpmredir: Corrupt FCB\n");
		return -1;
	}
	return (int)(redir_rd32(fcb + 18));
}

/* Print a trace message */

#ifdef DEBUG

void DbgMsg(const char* file, int line, const char* func, char* s, ...)
{
	va_list ap;

	va_start(ap, s);
	fprintf(stderr, "%s(%s@%i): ", func, file, line);
	vfprintf(stderr, s, ap);
	va_end(ap);
	fflush(stderr);
}

#endif

#define BCD(x) (((x % 10)+16*(x/10)) & 0xFF)

/* Convert time_t to CP/M day count/hours/minutes */
dword redir_cpmtime(time_t t)
{
	/* Microsoft compiler warned around the conversion from time_t to long
	 * as to support dates beyond 2038 time_t is set as a long long
	 * and for the Microsoft compiler sizeof(long) == 4 and sizeof(long long) == 8
	 * for other compilers both have size 8
	 * As the result is a dword (unsigned long), the code below is modified to reflect this
	 */

	dword d = (dword)((t / 86400) - 2921);  /* CP/M day 0 is unix day 2921 */
	dword h = (t % 86400) / 3600;  /* Hour, 0-23 */
	dword m = (t % 3600) / 60;    /* Minute, 0-59 */

	return (d | (BCD(h) << 16) | (BCD(m) << 24));
}

#undef BCD

#define UNBCD(x) (((x % 16) + 10 * (x / 16)) & 0xFF)

time_t redir_unixtime(cpm_byte* c)
{
	time_t t;
	cpm_word days;

	days = (c[0] + 256 * c[1]) + 2921;

	t = 60L * UNBCD(c[3]);
	t += 3600L * UNBCD(c[2]);
	t += 86400L * days;

	return t;
}

#undef UNBCD

/* Functions to access 24-bit & 32-bit words in memory. These are always
   little-endian. */

void redir_wr24(cpm_byte* addr, dword v)
{
	addr[0] = v & 0xFF;
	addr[1] = (v >> 8) & 0xFF;
	addr[2] = (v >> 16) & 0xFF;
}

void redir_wr32(cpm_byte* addr, dword v)
{
	addr[0] = v & 0xFF;
	addr[1] = (v >> 8) & 0xFF;
	addr[2] = (v >> 16) & 0xFF;
	addr[3] = (v >> 24) & 0xFF;
}

dword redir_rd24(cpm_byte* addr)
{
	register dword rv = addr[2];

	rv = (rv << 8) | addr[1];
	rv = (rv << 8) | addr[0];
	return rv;
}

dword redir_rd32(cpm_byte* addr)
{
	register dword rv = addr[3];

	rv = (rv << 8) | addr[2];
	rv = (rv << 8) | addr[1];
	rv = (rv << 8) | addr[0];
	return rv;
}

void redir_log_drv(cpm_byte drv)
{
	if (!drv) redir_l_drives |= 1;
	else redir_l_drives |= (1L << drv);
}

void redir_log_fcb(cpm_byte* fcb)
{
	int drv = fcb[0] & 0x7F;

	if (drv && drv != '?') redir_log_drv(drv - 1);
	else redir_log_drv(redir_cpmdrive);
}

int redir_ro_drv(cpm_byte drv)
{
	if (!drv) return redir_ro_drives & 1;
	else return redir_ro_drives & (1L << drv);
}

int redir_ro_fcb(cpm_byte* fcb)
{
	int drv = fcb[0] & 0x7F;

	if (drv && drv != '?') return redir_ro_drv(drv - 1);
	else return redir_ro_drv(redir_cpmdrive);
}

cpm_word redir_xlt_err(void)
{
	if (redir_password_error()) return 0x7FF;	/* DRDOS pwd error */

	switch (errno)
	{
	case EISDIR:
	case EBADF:  return 9;			/* Bad FCB */
	case EINVAL: return 0x03FF;		/* Readonly file */
	case EPIPE:  return 0x01FF;		/* Broken pipe */
	case ENOSPC: return 1;			/* No space */
	default:     return 0xFF;		/* Software error */
	}
}

#ifdef _WIN32

int truncate(const char* path, off_t length)
{
	BOOL bResult;
	HANDLE hFile;
	DWORD dwOffset;

	DBGMSGV("truncate file %s to %lu\n", path, length);

	hFile = CreateFile(path, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
	if (hFile == INVALID_HANDLE_VALUE)
	{
		DBGMSGV("truncate failed to open file (Error=%lu): %s\n", GetLastError(), GetErrorStr(GetLastError()));
		return -1;
	}

	dwOffset = SetFilePointer(hFile, length, NULL, FILE_BEGIN);
	if (dwOffset == INVALID_SET_FILE_POINTER)
	{
		DBGMSGV("truncate failed to open file (Error=%lu): %s\n", GetLastError(), GetErrorStr(GetLastError()));
		CloseHandle(hFile);
		return -1;
	}

	bResult = SetEndOfFile(hFile);
	if (!bResult)
	{
		DBGMSGV("truncate failed to set end of file (Error=%lu): %s\n", GetLastError(), GetErrorStr(GetLastError()));
		CloseHandle(hFile);
		return -1;
	}

	bResult = CloseHandle(hFile);
	if (!bResult)
	{
		DBGMSGV("truncate failed to close file (Error=%lu): %s\n", GetLastError(), GetErrorStr(GetLastError()));
		return -1;
	}

	DBGMSGV("truncate set file length to %lu\n", dwOffset);
	return 0;
}

#endif
