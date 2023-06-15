#ifndef _HTC_STDARG_H
#define _HTC_STDARG_H

/*	Macros for accessing variable arguments */

typedef void *	va_list[1];

#define	va_start(ap, parmn)	*ap = (char *)&parmn + sizeof parmn

#define	va_arg(ap, type)	(*(*(type **)ap)++)

#define	va_end(ap)

#endif
