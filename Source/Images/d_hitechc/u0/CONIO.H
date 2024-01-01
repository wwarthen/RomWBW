#ifndef _HTC_CONIO_H
#define _HTC_CONIO_H

/*
 *	Low-level console I/O functions
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

extern char	getch(void);
extern char	getche(void);
extern void	putch(int);
extern void	ungetch(int);
extern int	kbhit(void);
extern char *	cgets(char *);
extern void	cputs(char *);

#endif
