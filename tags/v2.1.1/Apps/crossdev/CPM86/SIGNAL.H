/* Copyright (C) 1985 by Manx Software Systems, Inc. */

#define SIG_DFL	((void (*)())0)
#define SIG_IGN	((void (*)())1)
#define SIG_ERR	((void (*)())-1)

#define SIGINT	1
#define SIGTERM	2
#define SIGABRT	3
#define SIGFPE	4
#define SIGILL	5
#define SIGSEGV	6

#define _NUMSIG	6
#define _FSTSIG	1
