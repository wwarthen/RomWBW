#ifndef _HTC_ASSERT_H
#define _HTC_ASSERT_H

/*
 *	Assertion - use liberally for debugging. Defining NDEBUG
 *	turns assertions off.
 *	assert(exp) where exp is non-zero does nothing, while
 *	assert(exp) where exp evaluates to zero aborts the program
 *	with a message like
 *
 *	Assertion failed: prog.c line 123: "exp"
 *
 */

#ifndef	NDEBUG
extern void	_fassert(int, char *, char *);
#define	assert(exp)	if(!(exp)) {_fassert(__LINE__, __FILE__, "exp");}
#else
#define	assert(exp)
#endif

#endif
