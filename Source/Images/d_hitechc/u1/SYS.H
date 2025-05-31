#ifndef _HTC_SYS_H
#define _HTC_SYS_H

/*
 *	System-dependent functions.
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

extern int	execl(char *, char *, char *, ...);
extern int	execv(char *, char **);
extern int	spawnl(char *, char *, char *, ...);
extern int	spawnv(char *, char **);
extern int	spawnle(char *, char *, char *, char *, ...);
extern int	spawnve(char *, char **, char *);
extern short	getuid(void);
extern short	setuid(short);
extern int	chdir(char *);
extern int	mkdir(char *);
extern int	rmdir(char *);
extern int	getcwd(int);
extern char   **_getargs(char *, char *);
extern int	_argc_;
extern int	inp(int);
extern void	outp(int, int);

#endif
