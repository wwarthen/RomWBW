extern int errno;
extern char *sys_errlist[];
extern int sys_nerr;

/* MsDos return codes */
#define EINVAL	1
#define ENOENT	2
#define ENOTDIR	3
#define EMFILE	4
#define EACCES	5
#define EBADF	6
#define EARENA	7
#define ENOMEM	8
#define EFAULT	9
#define EINVENV	10
#define EBADFMT	11
#define EINVACC	12
#define EINVDAT	13
#define ENODEV	15
#define ERMCD	16
#define EXDEV	17
#define ENOMORE	18

/* additional codes used by Aztec C */
#define EEXIST	19
#define ENOTTY	20
/* used by the math library */
#define ERANGE	21
#define EDOM	22
