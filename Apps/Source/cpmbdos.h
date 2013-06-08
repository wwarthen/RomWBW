
#define TERMCPM		0
#define	CONIN		1
#define CWRITE		2
#define	DIRCONIO	6
#define PRINTSTR	9
#define	RDCONBUF	10
#define	GETCONST	11
#define RETVERNUM	12
#define	RESDISKSYS	13
#define	SELECTDISK	14
#define	FOPEN		15
#define	FCLOSE		16
#define SEARCHFIRST	17
#define	SEARCHNEXT	18
#define	FDELETE		19
#define	FREADSEQ	20
#define	FWRITESEQ	21
#define FMAKEFILE	22
#define	FRENAME		23
#define	RETLOGINVEC	24
#define	RETCURRDISK	25
#define	SETDMAADDR	26
#define	GETALLOCVEC	27
#define	WRPROTDISK	28
#define	GETROVECTOR	29
#define	FSETATTRIB	30
#define	GETDPBADDR	31
#define	SETGETUSER	32
#define	FREADRANDOM	33
#define	FWRITERAND	34
#define FCOMPSIZE	35
#define	SETRANDREC	36
#define	RESETDRIVE	37
#define	WRRANDFILL	38

#define BDOSDEFDR 0			/* BDOS Default (current) Drive Number      */
#define	BDOSDRA	1
#define	BDOSDRB	2
#define	BDOSDRC	3
#define	BDOSDRD	4
#define	BDOSDRE	5
#define	BDOSDRF	6
#define	BDOSDRG	7
#define	BDOSDRH 8

struct FCB {
	char drive;
	char filename[8];
	char filetype[3];
	char filler[24];
};
