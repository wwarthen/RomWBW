#ifndef _HTC_CTYPE_H
#define _HTC_CTYPE_H

#define	_U	0x01
#define	_L	0x02
#define	_N	0x04
#define	_S	0x08
#define _P	0x10
#define _C	0x20
#define	_X	0x40

extern	unsigned char	_ctype_[];	/* in libc.lib */

#define	isalpha(c)	((_ctype_+1)[c]&(_U|_L))
#define	isupper(c)	((_ctype_+1)[c]&_U)
#define	islower(c)	((_ctype_+1)[c]&_L)
#define	isdigit(c)	((_ctype_+1)[c]&_N)
#define	isxdigit(c)	((_ctype_+1)[c]&(_N|_X))
#define	isspace(c)	((_ctype_+1)[c]&_S)
#define ispunct(c)	((_ctype_+1)[c]&_P)
#define isalnum(c)	((_ctype_+1)[c]&(_U|_L|_N))
#define isprint(c)	((_ctype_+1)[c]&(_P|_U|_L|_N|_S))
#define isgraph(c)	((_ctype_+1)[c]&(_P|_U|_L|_N))
#define iscntrl(c)	((_ctype_+1)[c]&_C)
#define isascii(c)	(!((c)&0xFF80))
/*--------------------------------------*\
 |    Changed  2014-07-04 (Jon Saxton)	|
 |--------------------------------------|
 |	Original macro definitions	|
 | #define toupper(c)	((c)-'a'+'A')	|
 | #define tolower(c)	((c)-'A'+'a')	|
 |--------------------------------------|
 |	  Use functions instead		|
\*--------------------------------------*/
extern int toupper(int);	/* in LIBC.LIB */
extern int tolower(int);	/* in LIBC.LIB */

#define toascii(c)	((c)&0x7F)

#endif
