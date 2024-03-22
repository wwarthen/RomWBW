#ifndef _HTC_STAT_H
#define _HTC_STAT_H

struct stat
{
	short	st_mode;	/* flags */
	long	st_atime;	/* access time */
	long	st_mtime;	/* modification time */
	long	st_size;	/* file size in bytes */
};

/* Flag bits in st_mode */

#define	S_IFMT		0x600	/* type bits */
#define		S_IFDIR	0x400	/* is a directory */
#define		S_IFREG	0x200	/* is a regular file */
#define	S_IREAD		0400	/* file can be read */
#define	S_IWRITE	0200	/* file can be written */
#define	S_IEXEC		0100	/* file can be executed */
#define	S_HIDDEN	0x1000	/* file is hidden */
#define	S_SYSTEM	0x2000	/* file is marked system */
#define	S_ARCHIVE	0x4000	/* file has been written to */


extern int	stat(char *, struct stat *);

#endif
