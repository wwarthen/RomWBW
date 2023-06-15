#ifndef _HTC_STDLIB_H
#define _HTC_STDLIB_H

/*	Standard utility functions */

#ifndef	_STDDEF
typedef	int		ptrdiff_t;	/* result type of pointer difference */
typedef	unsigned	size_t;		/* type yielded by sizeof */

#define	offsetof(ty, mem)	((int)&(((ty *)0)->mem))

#define	_STDDEF

#ifndef	NULL
#define	NULL	((void *)0)
#endif	NULL

extern int	errno;			/* system error number */
#endif	_STDDEF

#define	RAND_MAX	32767		/* max value returned by rand() */

extern double	 atof(char *);
extern int	 atoi(char *);
extern long	 atol(char *);
extern int	 rand(void);
extern void	 srand(unsigned int);
extern void	*calloc(size_t, size_t);
extern void	 free(void *);
extern void	*malloc(size_t);
extern void	*realloc(void *, size_t);
extern void	 abort(void);
extern void	 exit(int);
extern char	*getenv(char *);
extern int	 system(char *);
typedef int (*__qsort_compf)(void *, void *);  /* workaround compiler bug */
extern void	 qsort(void *, size_t, size_t, __qsort_compf);
extern int	 abs(int);
extern long	 labs(long);

#endif
