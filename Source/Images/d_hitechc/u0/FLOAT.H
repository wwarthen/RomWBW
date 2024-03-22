#ifndef _HTC_FLOAT_H
#define _HTC_FLOAT_H

/*	Characteristics of floating types */

#define	DBL_RADIX	2		/* radix of exponent for a double */
#define	DBL_ROUNDS	1		/* doubles round when converted to int */
#define	FLT_RADIX	2		/* radix of float exponent */
#define	FLT_ROUNDS	1		/* float also rounds to int */

#if	z80
#define	FLT_MANT_DIG	24		/* 24 bits in mantissa */
#define	DBL_MANT_DIG	24		/* ditto for double */
#define	DBL_MANT_DIG	24		/* ditto long double */
#define	FLT_EPSILON	-1.192093	/* smallest x, x+1.0 != 1.0 */
#define	DBL_EPSILON	-1.192093	/* smallest x, x+1.0 != 1.0 */
#define	FLT_DIG		6		/* decimal significant digs */
#define	DBL_DIG		6
#define	FLT_MIN_EXP	-62		/* min binary exponent */
#define	DBL_MIN_EXP	-62
#define	FLT_MIN		1.084202e-19	/* smallest floating number */
#define	DBL_MIN		1.084202e-19
#define	FLT_MIN_10_EXP	-18
#define	DBL_MIN_10_EXP	-18
#define	FLT_MAX_EXP	64		/* max binary exponent */
#define	DBL_MAX_EXP	64
#define	FLT_MAX		1.84467e19	/* max floating number */
#define	DBL_MAX		1.84467e19
#define	FLT_MAX_10_EXP	19		/* max decimal exponent */
#define	DBL_MAX_10_EXP	19
#endif	z80

#if	i8086 || m68k

/*	The 8086 and 68000 use IEEE 32 and 64 bit floats */

#define	FLT_RADIX	2
#define	FLT_MANT_DIG	24
#define	FLT_EPSILON	1.19209290e-07
#define	FLT_DIG		6
#define	FLT_MIN_EXP	-125
#define	FLT_MIN		1.17549435e-38
#define	FLT_MIN_10_EXP	-37
#define	FLT_MAX_EXP	128
#define	FLT_MAX		3.40282347e+38
#define	FLT_MAX_10_EXP	38
#define	DBL_MANT_DIG	53
#define	DBL_EPSILON	2.2204460492503131e-16
#define	DBL_DIG		15
#define	DBL_MIN_EXP	-1021
#define	DBL_MIN		2.225073858507201e-308
#define	DBL_MIN_10_EXP	-307
#define	DBL_MAX_EXP	1024
#define	DBL_MAX		1.797693134862316e+308
#define	DBL_MAX_10_EXP	308
#endif	i8086 || m68k


/*	long double equates to double */


#define	LDBL_MANT_DIG	DBL_MANT_DIG
#define	LDBL_EPSILON	DBL_EPSILON
#define	LDBL_DIG	DBL_DIG
#define	LDBL_MIN_EXP	DBL_MIN_EXP
#define	LDBL_MIN	DBL_MIN
#define	LDBL_MIN_10_EXP	DBL_MIN_10_EXP
#define	LDBL_MAX_EXP	DBL_MAX_EXP
#define	LDBL_MAX	DBL_MAX
#define	LDBL_MAX_10_EXP	DBL_MAX_10_EXP

#endif
