#ifndef _HTC_STRING_H
#define _HTC_STRING_H

/*	String functions v3.09-4 */

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

extern void	*memcpy(void *, void *, size_t);
extern void	*memmove(void *, void *, size_t);
extern char	*strcpy(char *, char *);
extern char	*strncpy(char *, char *, size_t);
extern char	*strcat(char *, char *);
extern char	*strncat(char *, char *, size_t);
extern int	 memcmp(void *, void *, size_t);
extern int	 strcmp(char *, char *);
extern int	 strcasecmp(char *, char *);
#define stricmp strcasecmp
extern int	 strncmp(char *, char *, size_t);
extern int	 strncasecmp(char *, char *, size_t);
#define strnicmp strncasecmp
/* extern size_t	 strcoll(char *, size_t, char *); */ /* missing */
extern void	*memchr(void *, int, size_t);
/* extern size_t	 strcspn(char *, char *); */ /* missing */
/* extern char	*strpbrk(char *, char *); */ /* missing */
/* extern size_t	 strspn(char *, char *); *//* missing */
extern char	*strstr(char *, char *);
extern char	*strtok(char *, char *);
extern void	*memset(void *, int, size_t);
extern char	*strerror(int);
extern size_t	 strlen(char *);
extern char	*strchr(char *, int);
/* #define index	strchr */	/* these are equivalent */
extern char	*index(char *, int);
extern char	*strrchr(char *, int);
/* #define	rindex	*strrchr */	/* these are equivalent */
extern char	*rindex(char *, int);
extern char	*strcasestr(char *, char *);
#define stristr	strcasestr
extern char	*strncasestr(char *, char *, size_t);
#define	strnistr strncasestr

#endif
