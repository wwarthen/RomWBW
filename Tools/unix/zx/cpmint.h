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

    This file holds internal declarations for the library.
*/

#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#ifdef HAVE_DIRENT_H
# include <dirent.h>
#else
#ifdef __WATCOMC__
#  include <io.h>
#  include <direct.h>
#else
#  include "dirent.h"
#endif
#endif
#ifdef HAVE_NDIR_H
# include <ndir.h>
#endif
#ifdef HAVE_SYS_DIR_H
# include <sys/dir.h>
#endif
#ifdef HAVE_SYS_NDIR_H
# include <sys/ndir.h>
#endif
#ifdef HAVE_WINDOWS_H
# include <windows.h>
#endif
#ifdef HAVE_WINNT_H
# include <winnt.h>
#endif
#ifdef HAVE_SYS_VFS_H
# include <sys/vfs.h>
#endif
#ifdef HAVE_UTIME_H
# include <utime.h>
#endif
#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif 
#ifdef HAVE_UNISTD_H
# include <unistd.h>
#endif


#ifdef __MSDOS__
	#include <io.h>
	#include <dos.h>
	#include <dir.h>
	#ifdef __GO32__
		#include <dpmi.h>
		#include <go32.h>
		#include <sys/movedata.h>
	#endif
#endif

#define CASE_SENSITIVE_FILESYSTEM 0


#include "cpmredir.h"

typedef unsigned long dword;	/* Must be at least 32 bits, and
                                   >= sizeof(int) */
#ifdef CPMDEF
	#define EXT
	#define INIT(x) =x
#else
	#define EXT extern
	#define INIT(x)
#endif	

/* The 16 directories to which the 16 CP/M drives are mapped */

EXT char redir_drive_prefix[16][CPM_MAXPATH]; 

/* Current drive and user */

EXT int  redir_cpmdrive;
EXT int  redir_cpmuser;

/* Length of 1 read/write operation, bytes */

EXT int redir_rec_len INIT(128);

/* Same, but in 128-byte records */
EXT int redir_rec_multi INIT(1);

/* Using a DRDOS system? */
EXT int redir_drdos INIT(0);

/* Default password */
#ifdef __MSDOS__
EXT char redir_passwd[8] INIT("");
#endif

EXT cpm_word redir_l_drives  INIT(0);
EXT cpm_word redir_ro_drives INIT(0);

#undef EXT
#undef INIT



/* Convert FCB to a Unix filename, returning 1 if it's ambiguous */
int redir_fcb2unix(cpm_byte *fcb, char *fname);

/* Open FCB, set file attributes */
int redir_ofile(cpm_byte * fcb, char *s);

/* Check that the FCB we have is valid */
int redir_verify_fcb(cpm_byte *fcb);

#ifndef O_BINARY	/* Necessary in DOS, not present in Linux */
#define O_BINARY 0
#endif

/* Facilities for debug tracing */


long zxlseek(int fd, long offset, int wh);

#ifdef DEBUG
	void redir_Msg(char *s, ...);
	void redir_showfcb(cpm_byte *fcb);
#else
	/* Warning: This is a GCC extension */
	#define redir_Msg(x, ...)
	#define redir_showfcb(x)
#endif



/* Get the "sequential access" file pointer out of an FCB */

long redir_get_fcb_pos(cpm_byte *fcb);

/* Write "sequential access" pointer to FCB */

void redir_put_fcb_pos(cpm_byte *fcb, long npos);

/* Convert time_t to CP/M day count/hours/minutes */
dword redir_cpmtime(time_t t);
/* And back */
time_t redir_unixtime(cpm_byte *c);


/* Functions to access 24-bit & 32-bit words in memory. These are always
  little-endian. */

void  redir_wr24(cpm_byte *addr, dword v);
void  redir_wr32(cpm_byte *addr, dword v);
dword redir_rd24(cpm_byte *addr);
dword redir_rd32(cpm_byte *addr);

/* If you have 64-bit file handles, you'll need to write separate wrhandle()
  and rdhandle() routines */
#define redir_wrhandle redir_wr32
#define redir_rdhandle redir_rd32

/* Mark a drive as logged in */

void redir_log_drv(cpm_byte drv);
void redir_log_fcb(cpm_byte *fcb);

/* Check if a drive is software read-only */

int  redir_ro_drv(cpm_byte drv);
int  redir_ro_fcb(cpm_byte *fcb);

/* Translate errno to a CP/M error */

cpm_word redir_xlt_err(void);

/* Get disc label */
cpm_word redir_get_label(cpm_byte drv, char *pattern);


/* DRDOS set/get access rights - no-ops under MSDOS and Unix: 
 *
 * CP/M password mode -> DRDOS password mode */
cpm_word redir_drdos_pwmode(cpm_byte b);

/* DRDOS password mode to CP/M password mode */
cpm_byte redir_cpm_pwmode(cpm_word w);

/* Get DRDOS access rights for a file */
cpm_word redir_drdos_get_rights(char *path);

/* Set DRDOS access rights and/or password */
cpm_word redir_drdos_put_rights(char *path, cpm_byte *dma, cpm_word rights);

/* Was the last error caused by invalid password? */
cpm_word redir_password_error(void);

/* Append password to filename (FILE.TYP -> FILE.TYP;PASSWORD) */
void redir_password_append(char *s, cpm_byte *dma);

