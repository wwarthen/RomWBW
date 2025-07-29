#ifndef _HTC_STDIO_H
#define _HTC_STDIO_H

/*
 * STDIO.H	HI-TECH C standard I/O for V3.09-xx
 *
 *		This version incorporates changes to stdio routines
 *		resulting from backporting features from V4.11
 */

#define _HTC_VERSION	"3.09-19"
#define _HTC_MAJOR	3
#define _HTC_MINOR	9
#define _HTC_REV	19

#if	z80
#define	BUFSIZ		512
#define	_NFILE		8
#else	z80
#define	BUFSIZ		1024
#define	_NFILE		20
#endif	z80

#ifndef	_STDDEF
typedef	int		ptrdiff_t;
typedef	unsigned	size_t;
#define	_STDDEF
#define	offsetof(ty, mem)	((int)&(((ty *)0)->mem))
#endif	_STDDEF

#ifndef FILE
#define	uchar		unsigned char

extern	struct	_iobuf
{
	char		*_ptr;
	int		 _cnt;
	char		*_base;
	unsigned short	 _flag;
	char		 _file;
	size_t		 _size;
} _iob[_NFILE];

#define	FILE		struct _iobuf
#endif	FILE

#ifndef SEEK_SET
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
#endif

/* I/O status flag word bits */
#define	_IOREAD		01	/* Allow file reading */
#define	_IOWRT		02	/* Allow file writing */
#define	_IORW		03	/* Mask for reading or writing */
#define	_IONBF		04	/* Not being buffered */
#define	_IOMYBUF	010	/* Using buffer */
#define	_IOEOF		020	/* At end-of-file */
#define	_IOERR		040	/* An I/O error has occurred */
#define	_IOSTRG		0100	/* End of string reached */
#define	_IOBINARY	0200	/* Binary mode */
#define	_IOLBF		0400	/* Using line buffering */
#define	_IODIRN		01000	/* Direction - writing to a R/W file */
#define _IOAPPEND	02000	/* Append mode */
#define _IOSEEKED	04000	/* A seek has occurred since last write */
#define	_IOFBF		010000	/* Using full buffering */

#ifndef	NULL
#define	NULL	((void *)0)
#endif	NULL

#define	EOF		(-1)

#define	stdin		(&_iob[0])
#define	stdout		(&_iob[1])
#define	stderr		(&_iob[2])
#define	getchar()	getc(stdin)
#define	putchar(x)	putc(x,stdout)

/*
 *	getc() and putc() must be functions for CP/M to allow the special
 *	handling of '\r', '\n' and '\032'. The same for MSDOS except that
 *	it at least knows the length of a file.
 */

#if	UNIX
#define	getc(p)   (--(p)->_cnt>=0?(unsigned)*(p)->_ptr++:_filbuf(p))
#define	putc(x,p) (--(p)->_cnt>=0?((unsigned)(*(p)->_ptr++=x)):_flsbuf((unsigned)(x),p))
#else	UNIX
#define	getc(p)		fgetc(p)
#define	putc(x,p)	fputc(x,p)
#endif	UNIX

#define	feof(p)		(((p)->_flag&_IOEOF)!=0)
#define	ferror(p)	(((p)->_flag&_IOERR)!=0)
#define	fileno(p)	((uchar)p->_file)
#define	clrerr(p)	p->_flag &= ~_IOERR
#define	clreof(p)	p->_flag &= ~_IOEOF

extern int	 fclose(FILE *);
extern int	 fflush(FILE *);
extern int	 fgetc(FILE *);
extern int	 ungetc(int, FILE *);
extern int	 fputc(int, FILE *);
extern int	 getw(FILE *);
extern int	 putw(int, FILE *);
extern char	*gets(char *);
extern int	 puts(char *);
extern int	 fputs(char *, FILE *);
extern int	 fread(void *, unsigned, unsigned, FILE *);
extern int	 fwrite(void *, unsigned, unsigned, FILE *);
extern int	 fseek(FILE *, long, int);
extern int	 rewind(FILE *);
extern void	 setbuf(FILE *, char *);
extern int	 setvbuf(FILE *, char *, int, size_t);
extern int	 printf(char *, ...);
extern int	 fprintf(FILE *, char *, ...);
extern int	 sprintf(char *, char *, ...);
extern int	 scanf(char *, ...);
extern int	 fscanf(FILE *, char *, ...);
extern int	 sscanf(char *, char *, ...);
extern int	 remove(char *);
extern FILE	*fopen(char *, char *);
extern FILE	*freopen(char *, char *, FILE *);
extern FILE	*fdopen(int, char *);
extern long	 ftell(FILE *);
extern char	*fgets(char *, int, FILE *);
extern char	*_bufallo(void);

#endif _HTC_STDIO_H
