#ifndef _HTC_UNIXIO_H
#define _HTC_UNIXIO_H

/*
 *	Declarations for Unix style low-level I/O functions.
 */

#ifndef	_STDDEF
typedef	int		ptrdiff_t;	/* result type of pointer difference */
typedef	unsigned	size_t;		/* type yielded by sizeof */
#define	_STDDEF
#define	offsetof(ty, mem)	((int)&(((ty *)0)->mem))
#endif	_STDDEF

#ifndef	NULL
#define	NULL	((void *)0)
#endif	NULL

extern int	errno;			/* system error number */

extern int	open(char *, int);
extern int	close(int);
extern int	creat(char *, int);
extern int	dup(int);
extern long	lseek(int, long, int);
extern int	read(int, void *, int);
extern int	rename(char *, char *);
extern int	unlink(char *);
extern int	write(int, void *, int);
extern int	isatty(int);
extern int	chmod(char *, int);

#endif
