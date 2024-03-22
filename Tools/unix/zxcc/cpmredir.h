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

	This file holds the public interface to CPMREDIR.
*/

#ifndef CPMREDIR_H_INCLUDED

#define CPMREDIR_H_INCLUDED 16-11-1998

/* The "cpm_byte" must be exactly 8 bits.
   The "cpm_word" must be exactly 16 bits. */

typedef unsigned char cpm_byte;
typedef unsigned short cpm_word;

/* Maximum length of a directory path */
#ifdef _POSIX_PATH_MAX
  #define CPM_MAXPATH _POSIX_PATH_MAX
#else
  #ifdef _MAX_PATH
    #define CPM_MAXPATH _MAX_PATH
  #else
    #define CPM_MAXPATH 260
  #endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

	/* Initialise this library. Call this function first.
	 *
	 * Returns 0 if failed to initialise.
	 */
	int fcb_init(void);

	/* Deinitialise the library. */

	void fcb_deinit(void);

	/* Translate a name from the host FS to a CP/M name. This will (if necessary)
	 * create a mapping between a CP/M drive and a host directory path.
	 *
	 * CP/M drives A: to O: can be mapped in this way. P: is always the current
	 * drive.
	 *
	 */

	void xlt_name(char* localname, char* cpmname);

	/* It is sometimes convenient to set some fixed mappings. This will create
	 * a mapping for a given directory.
	 * Pass drive = -1 for "first available", or 0-15 for A: to P:
	 * Returns 1 if OK, 0 if requested drive not available.
	 *
	 * NB: It is important that the localname should have a trailing
	 *    directory separator!
	 */

	int xlt_map(int drive, char* localdir);

	/*
	 * This revokes a mapping. No check is made whether CP/M has files open
	 * on the drive or not.
	 */

	int xlt_umap(int drive);

	/* Find out if a drive is mapped, and if so to what directory */

	char* xlt_getcwd(int drive);

	/* BDOS functions. Eventually this should handle all disc-related BDOS
	 * functions.
	 *
	 * I am assuming that your emulator has the CP/M RAM in its normal address
	 * space, accessible as a range 0-64k. If this is not the case
	 * (eg: you are emulating banked memory, or using a segmented architecture)
	 * you will have to use "copy in and copy out" techniques. The "fcb" area
	 * must be 36 bytes long; the "dma" area should be 128 * the value set
	 * in fcb_multirec() [default is 1, so 128 bytes].
	 *
	 */

	cpm_byte fcb_reset(void);							/* 0x0D */
	cpm_word fcb_drive(cpm_byte drv);					/* 0x0E */
	cpm_word fcb_open(cpm_byte* fcb, cpm_byte* dma);	/* 0x0F */
	cpm_word fcb_close(cpm_byte* fcb);					/* 0x10 */
	cpm_word fcb_find1(cpm_byte* fcb, cpm_byte* dma);	/* 0x11 */
	cpm_word fcb_find2(cpm_byte* fcb, cpm_byte* dma);	/* 0x12 */
	cpm_word fcb_unlink(cpm_byte* fcb, cpm_byte* dma);	/* 0x13 */
	cpm_word fcb_read(cpm_byte* fcb, cpm_byte* dma);	/* 0x14 */
	cpm_word fcb_write(cpm_byte* fcb, cpm_byte* dma);	/* 0x15 */
	cpm_word fcb_creat(cpm_byte* fcb, cpm_byte* dma);	/* 0x16 */
	cpm_word fcb_rename(cpm_byte* fcb, cpm_byte* dma);	/* 0x17 */
	cpm_word fcb_logvec(void);							/* 0x18 */
	cpm_byte fcb_getdrv(void);							/* 0x19 */
	/* DMA is a parameter to routines, not a separate call */
	cpm_word fcb_getalv(cpm_byte* alv, cpm_word max);	/* 0x1B */
	/* Get alloc vector: caller must provide space and say how big it is.  */
	cpm_word fcb_rodisk(void);							/* 0x1C */
	cpm_word fcb_rovec(void);							/* 0x1D */
	cpm_word fcb_chmod(cpm_byte* fcb, cpm_byte* dma);	/* 0x1E */
	cpm_word fcb_getdpb(cpm_byte* dpb);					/* 0x1F */
	cpm_byte fcb_user(cpm_byte usr);					/* 0x20 */
	cpm_word fcb_randrd(cpm_byte* fcb, cpm_byte* dma);	/* 0x21 */
	cpm_word fcb_randwr(cpm_byte* fcb, cpm_byte* dma);	/* 0x22 */
	cpm_word fcb_stat(cpm_byte* fcb);					/* 0x23 */
	cpm_word fcb_tell(cpm_byte* fcb);					/* 0x24 */
	cpm_word fcb_resro(cpm_word bitmap);				/* 0x25 */
	/* Access Drives and Free Drives are not supported. */
	cpm_word fcb_randwz(cpm_byte* fcb, cpm_byte* dma);	/* 0x28 */
	/* Record locking calls not supported (though they could be) */
	cpm_word fcb_multirec(cpm_byte rc);					/* 0x2C */
	/* Set hardware error action must be done by caller */
	cpm_word fcb_dfree(cpm_byte drive, cpm_byte* dma);	/* 0x2E */
	cpm_word fcb_sync(cpm_byte flag);					/* 0x30 */
	cpm_word fcb_purge(void);							/* 0x62 */
	cpm_word fcb_trunc(cpm_byte* fcb, cpm_byte* dma);	/* 0x63 */
	cpm_word fcb_setlbl(cpm_byte* fcb, cpm_byte* dma);	/* 0x64 */
	cpm_word fcb_getlbl(cpm_byte drive);				/* 0x65 */
	cpm_word fcb_date(cpm_byte* fcb);					/* 0x66 */
	cpm_word fcb_setpwd(cpm_byte* fcb, cpm_byte* dma);	/* 0x67 */
	cpm_word fcb_defpwd(cpm_byte* pwd);					/* 0x6A */
	cpm_word fcb_sdate(cpm_byte* fcb, cpm_byte* dma);	/* 0x74 */
	cpm_word fcb_parse(char* txt, cpm_byte* fcb);		/* 0x98 */

	/* fcb_parse returns length of filename parsed, 0 if EOL, 0xFFFF if error */

#ifdef __cplusplus
}
#endif

#endif	/* def CPMREDIR_H_INCLUDED */
