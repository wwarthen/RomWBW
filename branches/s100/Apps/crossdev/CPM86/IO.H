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
