libc.h
/* Copyright (C) 1981, 1982 by Manx Software Systems */

extern int errno;
#define FLT_FAULT	0		/* vector for floating-point faults */
extern int (*Sysvec[])();

#define NULL 0
#define EOF -1
#define BUFSIZ 1024

#define _BUSY	0x01
#define _ALLBUF	0x02
#define _DIRTY	0x04
#define _EOF	0x08
#define _IOERR	0x10

typedef struct {
	char *_bp;			/* current position in buffer */
	char *_bend;		/* last character in buffer + 1 */
	char *_buff;		/* address of buffer */
	char _flags;		/* open mode, etc. */
	char _unit;			/* token returned by open */
	char _bytbuf;		/* single byte buffer for unbuffer streams */
	int	_buflen;		/* length of buffer */
} FILE;

extern FILE Cbuffs[];
extern char *Stdbufs;			/* free list of buffers */
long ftell();

#define stdin (&Cbuffs[0])
#define stdout (&Cbuffs[1])
#define stderr (&Cbuffs[2])
#define getchar() agetc(stdin)
#define putchar(c) aputc(c, stdout)
#define feof(fp) (((fp)->_flags&_EOF)!=0)
#define ferror(fp) (((fp)->_flags&_IOERR)!=0)
#define clearerr(fp) ((fp)->_flags &= ~(_IOERR|_EOF))
#define fileno(fp) ((fp)->_unit)
errno.h
extern int errno;
#define ENOENT	-1
#define E2BIG	-2
#define EBADF	-3
#define ENOMEM	-4
#define EEXIST	-5
#define EINVAL	-6
#define ENFILE	-7
#define EMFILE	-8
#define ENOTTY	-9
#define EACCES	-10

#define ERANGE	-20
#define EDOM	-21
fcntl.h
#define O_RDONLY	0
#define O_WRONLY	1
#define O_RDWR		2
#define O_CREAT		0x0100
#define O_TRUNC		0x0200
#define O_EXCL		0x0400
#define O_APPEND	0x0800
io.h
/* Copyright (C) 1982 by Manx Software Systems */
/*
 * if MAXCHAN is changed then the initialization of chantab in croot.c
 * should be adjusted so that it initializes EXACTLY MAXCHAN elements of 
 * the array.  If this is not done, the I/O library may exhibit
 * strange behavior.
 */
#define MAXCHAN	11	/* maximum number of I/O channels */

/*
 * argument to device routines.
 *		this is a typedef to allow future redeclaration to guarantee 
 *		enough space to store either a pointer or an integer.
 */
typedef char *_arg;

/*
 * device control structure
 */
struct device {
	char d_read;
	char d_write;
	char d_ioctl;	/* used by character special devices (eg CON:) */
	char d_seek;	/* used by random I/O devices (eg: a file) */
	int (*d_open)();	/* for special open handling */
};

/*
 * device table, contains names and pointers to device entries
 */
struct devtabl {
	char *d_name;
	struct device *d_dev;
	_arg d_arg;
};

/*
 * channel table: relates fd's to devices
 */
struct channel {
	char c_read;
	char c_write;
	char c_ioctl;
	char c_seek;
	int (*c_close)();
	_arg c_arg;
} ;
extern struct channel chantab[MAXCHAN];

struct fcb {
	char f_driv;
	char f_name[8];
	char f_type[3];
	char f_ext;
	char f_resv[2];
	char f_rc;
	char f_sydx[16];
	char f_cr;
	unsigned f_record; char f_overfl;
};

struct fcbtab {
	struct fcb fcb;
	char offset;
	char flags;
	char user;
};

#define	OPNFIL	15
#define CLSFIL	16
#define DELFIL	19
#define READSQ	20
#define WRITSQ	21
#define MAKFIL	22
#define SETDMA	26
#define GETUSR	32
#define READRN	33
#define WRITRN	34
#define FILSIZ	35
#define SETREC	36

#define Wrkbuf ((char *)0x80)
math.h
double sin(), cos(), tan(), cotan();
double asin(), acos(), atan(), atan2();
double ldexp(), frexp(), modf();
double floor(), ceil();
double log(), log10(), exp(), sqrt(), pow();
double sinh(), cosh(), tanh(), fabs();

#define HUGE	5.2e+151
#define LOGHUGE	349.3
#define TINY	7.5e-155
#define LOGTINY	-354.8
setjmp.h
/* Copyright (C) 1983 by Manx Software Systems */
#define JBUFSIZE	(5*sizeof(int))

typedef char jmp_buf[JBUFSIZE];
sgtty.h
/* Copyright (C) 1983 by Manx Software Systems */

#define TIOCGETP	0		/* read contents of tty control structure */
#define TIOCSETP	1		/* set contents of tty control structure */
#define TIOCSETN	1		/* ditto only don't wait for output to flush */

struct sgttyb {
	char sg_erase;		/* ignored */
	char sg_kill;		/* ignored */
	short sg_flags;		/* control flags */
};

/* settings for flags */
#define _VALID	0x3a
#define RAW		0x20	/* no echo or mapping of input/output BDOS(6) */
#define CRMOD	0x10	/* map input CR to NL, output NL to CR LF */
#define ECHO	0x08	/* ignored unless CBREAK is set */
#define CBREAK	0x02	/* input using BDOS(1), unless echo off then */
						/* same as RAW */
stdio.h
/* Copyright (C) 1982, 1984 by Manx Software Systems */
#define fgetc getc
#define fputc putc
#define NULL 0
#define EOF -1

#ifdef TINY
struct fcb {
	char f_driv;
	char f_name[8];
	char f_type[3];
	char f_ext;
	char f_resv[2];
	char f_rc;
	char f_sydx[16];
	char f_cr;
	unsigned f_record; char f_overfl;
};

typedef struct {
	char *_bp;
	struct fcb _fcb;
	char user;
} FILE;

#else

#define BUFSIZ 1024
#define MAXSTREAM	11

#define _BUSY	0x01
#define _ALLBUF	0x02
#define _DIRTY	0x04
#define _EOF	0x08
#define _IOERR	0x10

typedef struct {
	char *_bp;			/* current position in buffer */
	char *_bend;		/* last character in buffer + 1 */
	char *_buff;		/* address of buffer */
	char _flags;		/* open mode, etc. */
	char _unit;			/* token returned by open */
	char _bytbuf;		/* single byte buffer for unbuffer streams */
	int	_buflen;		/* length of buffer */
} FILE;

extern FILE Cbuffs[];
FILE *fopen();
long ftell();

#define stdin (&Cbuffs[0])
#define stdout (&Cbuffs[1])
#define stderr (&Cbuffs[2])
#define getchar() agetc(stdin)
#define putchar(c) aputc(c, stdout)
#define feof(fp) (((fp)->_flags&_EOF)!=0)
#define ferror(fp) (((fp)->_flags&_IOERR)!=0)
#define clearerr(fp) ((fp)->_flags &= ~(_IOERR|_EOF))
#define fileno(fp) ((fp)->_unit)
#define fflush(fp) flsh_(fp,-1)
#endif
ctype.h
/* Copyright (C) 1984 by Manx Software Systems */

extern char ctp_[];

#define isalpha(x) (ctp_[(x)+1]&0x03)
#define isupper(x) (ctp_[(x)+1]&0x01)
#define islower(x) (ctp_[(x)+1]&0x02)
#define isdigit(x) (ctp_[(x)+1]&0x04)
#define isxdigit(x) (ctp_[(x)+1]&0x08)
#define isalnum(x) (ctp_[(x)+1]&0x07)
#define isspace(x) (ctp_[(x)+1]&0x10)
#define ispunct(x) (ctp_[(x)+1]&0x40)
#define iscntrl(x) (ctp_[(x)+1]&0x20)
#define isprint(x) (ctp_[(x)+1]&0xc7)
#define isgraph(x) (ctp_[(x)+1]&0x47)
#define isascii(x) (((x)&0x80)==0)

#define toascii(x) ((x)&127)
#define _tolower(x) ((x)|0x20)
#define _toupper(x) ((x)&0x5f)
