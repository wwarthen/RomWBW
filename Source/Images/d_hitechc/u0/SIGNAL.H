#ifndef _HTC_SIGNAL_H
#define _HTC_SIGNAL_H

/*
 *	Signal definitions for CP/M
 */
#ifdef	unix
#define NSIG 17
#define	SIGHUP	1	/* hangup    (not used by terminal driver) */
#define	SIGINT	2	/* interrupt (^C or BREAK) */
#define	SIGQUIT	3	/* quit      (^\) */
#define	SIGILL	4	/* illegal instruction (not reset when caught) */
#define	SIGTRAP	5	/* trace trap (not reset when caught) */
#define	SIGIOT	6	/* IOT instruction */
#define	SIGEMT	7	/* EMT instruction */
#define	SIGFPE	8	/* floating point exception */
#define	SIGKILL	9	/* kill (cannot be caught or ignored) */
#define	SIGBUS	10	/* bus error */
#define	SIGSEGV	11	/* segmentation violation */
#define	SIGSYS	12	/* bad argument to system call */
#define	SIGPIPE	13	/* write on a pipe with no one to read it */
#define	SIGALRM	14	/* alarm clock */
#define	SIGTERM	15	/* software termination signal from kill */
#else
#define NSIG 1
#define	SIGINT	1		/* control-C */
#endif

typedef void* signal_t;
#define	SIG_DFL	((signal_t)0)	/* default action is to exit */
#define	SIG_IGN	((signal_t)1)	/* ignore them */

signal_t signal(int sig, signal_t action);

#endif
