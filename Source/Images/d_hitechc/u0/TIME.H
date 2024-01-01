#ifndef _HTC_TIME_H
#define _HTC_TIME_H

/* time.h for HI-TECH C Z80 v3.09-4*/

#ifndef	_HTC_TIME_T

typedef	long	time_t;		/* for representing times in seconds */
struct tm {
	int	tm_sec;
	int	tm_min;
	int	tm_hour;
	int	tm_mday;
	int	tm_mon;
	int	tm_year;
	int	tm_wday;
	int	tm_yday;
	int	tm_isdst;
};
#define	_HTC_TIME_T
#endif	_HTC_TIME_T

#ifndef _STDDEF
typedef int	ptrdiff_t;	/* result type of pointer difference */
typedef unsigned size_t;	/* type yielded by sizeof */
#define _STDDEF
#define offsetof(ty, mem)	((int)&(((ty *)0)->mem))
#endif

extern int	time_zone;	/* minutes WESTWARD of Greenwich */
				/* this value defaults to 0 since with
				   operating systems like MS-DOS there is
				   no time zone information available */

extern time_t	time(time_t *);		/* seconds since 00:00:00 Jan 1 1970 */
extern char *	asctime(struct tm *);	/* converts struct tm to ascii time */
extern char *	ctime(time_t *);	/* current local time in ascii form */
extern struct tm *	gmtime(time_t *);	/* Universal time */
extern struct tm *	localtime(time_t *);	/* local time */
extern size_t strftime(char *s, size_t maxs, char *f, struct tm *t);
extern time_t	mktime(struct tm *);	/* convert struct tm to time value */

#endif
