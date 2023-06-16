sin.c
#include "math.h"
#include "errno.h"

double cos(x)
double x;
{
	double sincos();

	return sincos(x, fabs(x) + 1.57079632679489661923, 0);
}

double sin(x)
double x;
{
	double sincos();
	
	if (x < 0.0)
		return sincos(x,-x,1);
	else
		return sincos(x,x,0);
}

#define R1 -0.16666666666666665052e+00
#define R2 +0.83333333333331650314e-02
#define R3 -0.19841269841201840457e-03
#define R4 +0.27557319210152756119e-05
#define R5 -0.25052106798274584544e-07
#define R6 +0.16058936490371589114e-09
#define R7 -0.76429178068910467734e-12
#define R8 +0.27204790957888846175e-14

#define YMAX 6.7465e09

static double sincos(x,y,sgn)
double x,y;
{
	double f, xn, r, g;
	extern int errno;

	if (y >= YMAX) {
		errno = ERANGE;
		return 0.0;
	}
	if (modf(y * 0.31830988618379067154, &xn) >= 0.5)
		++xn;
	if ((int)xn & 1)
		sgn = !sgn;
	if (fabs(x) != y)
		xn -= 0.5;
	g = modf(fabs(x), &x);		/* break into fraction and integer parts */
	f = ((x - xn*3.1416015625) + g) + xn*8.9089102067615373566e-6;
	if (fabs(f) > 2.3283e-10) {
		g = f*f;
		r = (((((((R8*g R7)*g R6)*g R5)*g
				R4)*g R3)*g R2)*g R1)*g;
		f += f*r;
	}
	if (sgn)
		f = -f;
	return f;
}
tan.c
#include "math.h"
#include "errno.h"

extern int errno;

static double tansub();

double cotan(x)
double x;
{
	double y;
	
	y = fabs(x);
	if (y < 1.91e-152) {
		errno = ERANGE;
		if (x < 0.0)
			return -HUGE;
		else
			return HUGE;
	}
	return tansub(x,y,2);
}

double tan(x)
double x;
{
	return tansub(x, fabs(x), 0);
}

#define P1 -0.13338350006421960681e+0
#define P2 +0.34248878235890589960e-2
#define P3 -0.17861707342254426711e-4
#define Q0 +1.0
#define Q1 -0.46671683339755294240e+0
#define Q2 +0.25663832289440112864e-1
#define Q3 -0.31181531907010027307e-3
#define Q4 +0.49819433993786512270e-6

#define P(f,g) (((P3*g P2)*g P1)*g*f + f)
#define Q(g) ((((Q4*g Q3)*g Q2)*g Q1)*g Q0)

#define YMAX 6.74652e09

static double tansub(x, y, flag)
double x,y;
{
	double f, g, xn;
	double xnum, xden;
	
	if (y > YMAX) {
		errno = ERANGE;
		return 0.0;
	}
	if (modf(x*0.63661977236758134308, &xn) >= 0.5)
		xn += (x < 0.0) ? -1.0 : 1.0;
	f = (x - xn*1.57080078125) + xn*4.454455103380768678308e-6;
	if (fabs(f) < 2.33e-10) {
		xnum = f;
		xden = 1.0;
	} else {
		g = f*f;
		xnum = P(f,g);
		xden = Q(g);
	}
	flag |= ((int)xn & 1);
	switch (flag) {
	case 1:		/* A: tan, xn odd */
		xnum = -xnum;
	case 2:		/* B: cotan, xn even */
		return xden/xnum;
		
	case 3:		/* C: cotan, xn odd */
		xnum = -xnum;
	case 0:		/* D: tan, xn even */
		return xnum/xden;
	}
	return 0.0;
}
asin.c
#include "math.h"
#include "errno.h"

double arcsine();

double asin(x)
double x;
{
	return arcsine(x,0);
}

double acos(x)
double x;
{
	return arcsine(x,1);
}

#define P1 -0.27368494524164255994e+2
#define P2 +0.57208227877891731407e+2
#define P3 -0.39688862997504877339e+2
#define P4 +0.10152522233806463645e+2
#define P5 -0.69674573447350646411
#define Q0 -0.16421096714498560795e+3
#define Q1 +0.41714430248260412556e+3
#define Q2 -0.38186303361750149284e+3
#define Q3 +0.15095270841030604719e+3
#define Q4 -0.23823859153670238830e+2

#define P(g) ((((P5*g P4)*g P3)*g P2)*g P1)
#define Q(g) (((((g Q4)*g Q3)*g Q2)*g Q1)*g Q0)

double arcsine(x,flg)
double x;
{
	double y, g, r;
	register int i;
	extern int errno;
	static double a[2] = { 0.0, 0.78539816339744830962 };
	static double b[2] = { 1.57079632679489661923, 0.78539816339744830962 };

	y = fabs(x);
	i = flg;
	if (y < 2.3e-10)
		r = y;
	else {
		if (y > 0.5) {
			i = 1-i;
			if (y > 1.0) {
				errno = EDOM;
				return 0.0;
			}
			g = (0.5-y)+0.5;
			g = ldexp(g,-1);
			y = sqrt(g);
			y = -(y+y);
		} else
			g = y*y;
		r = y + y*
				((P(g)*g)
				/Q(g));
	}
	if (flg) {
		if (x < 0.0)
			r = (b[i] + r) + b[i];
		else
			r = (a[i] - r) + a[i];
	} else {
		r = (a[i] + r) + a[i];
		if (x < 0.0)
			r = -r;
	}
	return r;
}
atan.c
#include "libc.h"
#include "math.h"
#include "errno.h"

static int nopper() {;}

#define PI		3.14159265358979323846
#define PIov2	1.57079632679489661923

double atan2(v,u)
double u,v;
{
	double f;
	int (*save)();
	extern int flterr;
	extern int errno;

	if (u == 0.0) {
		if (v == 0.0) {
			errno = EDOM;
			return 0.0;
		}
		return PIov2;
	}

	save = Sysvec[FLT_FAULT];
	Sysvec[FLT_FAULT] = nopper;
	flterr = 0;
	f = v/u;
	Sysvec[FLT_FAULT] = save;
	if (flterr == 2)	/* overflow */
		f = PIov2;
	else {
		if (flterr == 1)	/* underflow */
			f = 0.0;
		else
			f = atan(fabs(f));
		if (u < 0.0)
			f = PI - f;
	}
	if (v < 0.0)
		f = -f;
	return f;
}

#define P0 -0.13688768894191926929e+2
#define P1 -0.20505855195861651981e+2
#define P2 -0.84946240351320683534e+1
#define P3 -0.83758299368150059274e+0
#define Q0 +0.41066306682575781263e+2
#define Q1 +0.86157349597130242515e+2
#define Q2 +0.59578436142597344465e+2
#define Q3 +0.15024001160028576121e+2

#define P(g) (((P3*g P2)*g P1)*g P0)
#define Q(g) ((((g Q3)*g Q2)*g Q1)*g Q0)

double atan(x)
double x;
{
	double f, r, g;
	int n;
	static double Avals[4] = {
		0.0,
		0.52359877559829887308,
		1.57079632679489661923,
		1.04719755119659774615
	};
	
	n = 0;
	f = fabs(x);
	if (f > 1.0) {
		f = 1.0/f;
		n = 2;
	}
	if (f > 0.26794919243112270647) {
		f = (((0.73205080756887729353*f - 0.5) - 0.5) + f) /
				(1.73205080756887729353 + f);
		++n;
	}
	if (fabs(f) < 2.3e-10)
		r = f;
	else {
		g = f*f;
		r = f + f *
			((P(g)*g)
			/Q(g));
	}
	if (n > 1)
		r = -r;
	r += Avals[n];
	if (x < 0.0)
		r = -r;
	return r;
}
sinh.c
#include "math.h"
#include "errno.h"

extern int errno;

#define P0 -0.35181283430177117881e+6
#define P1 -0.11563521196851768270e+5
#define P2 -0.16375798202630751372e+3
#define P3 -0.78966127417357099479e+0
#define Q0 -0.21108770058106271242e+7
#define Q1 +0.36162723109421836460e+5
#define Q2 -0.27773523119650701667e+3

#define PS(x) (((P3*x P2)*x P1)*x P0)
#define QS(x) (((x Q2)*x Q1)*x Q0)

double sinh(x)
double x;
{
	double y, w, z;
	int sign;
	
	y = x;
	sign = 0;
	if (x < 0.0) {
		y = -x;
		sign = 1;
	}
	if (y > 1.0) {
		w = y - 0.6931610107421875000;
		if (w > 349.3) {
			errno = ERANGE;
			z = HUGE;
		} else {
			z = exp(w);
			if (w < 19.95)
				z -= 0.24999308500451499336 / z;
			z += 0.13830277879601902638e-4 * z;
		}
		if (sign)
			z = -z;
	} else if (y < 2.3e-10)
		z = x;
	else {
		z = x*x;
		z = x + x *
				(z*(PS(z)
				/QS(z)));
	}
	return z;
}

double cosh(x)
double x;
{
	double y, w, z;
	
	y = fabs(x);
	if (y > 1.0) {
		w = y - 0.6931610107421875000;
		if (w > 349.3) {
			errno = ERANGE;
			return HUGE;
		}
		z = exp(w);
		if (w < 19.95)
			z += 0.24999308500451499336 / z;
		z += 0.13830277879601902638e-4 * z;
	} else {
		z = exp(y);
		z = z*0.5 + 0.5/z;
	}
	return z;
}
tanh.c
#include "math.h"

#define P0 -0.16134119023996228053e+4
#define P1 -0.99225929672236083313e+2
#define P2 -0.96437492777225469787e+0
#define Q0 +0.48402357071988688686e+4
#define Q1 +0.22337720718962312926e+4
#define Q2 +0.11274474380534949335e+3

#define gP(g) (((P2*g P1)*g P0)*g)
#define Q(g) (((g Q2)*g Q1)*g Q0)

double tanh(x)
double x;
{
	double f,g,r;
	
	f = fabs(x);
	if (f > 25.3)
		r = 1.0;
	else if (f > 0.54930614433405484570) {
		r = 0.5 - 1.0/(exp(f+f)+1.0);
		r += r;
	} else if (f < 2.3e-10)
		r = f;
	else {
		g = f*f;
		r = f + f*
			(gP(g)
			/Q(g));
	}
	if (x < 0.0)
		r = -r;
	return r;
}
pow.c
#include "math.h"
#include "errno.h"

double pow(a,b)
double a,b;
{
	double loga;
	extern int errno;
	
	if (a<=0.0) {
		if (a<0.0 || a==0.0 && b<=0.0) {
			errno = EDOM;
			return -HUGE;
		}
		else return 0.0;
	}
	loga = log(a);
	loga *= b;
	if (loga > LOGHUGE) {
		errno = ERANGE;
		return HUGE;
	}
	if (loga < LOGTINY) {
		errno = ERANGE;
		return 0.0;
	}
	return exp(loga);
}
sqrt.c
#include "math.h"
#include "errno.h"

double sqrt(x)
double x;
{
	double f, y;
	int n;
	extern int errno;
	
	if (x == 0.0)
		return x;
	if (x < 0.0) {
		errno = EDOM;
		return 0.0;
	}
	f = frexp(x, &n);
	y = 0.41731 + 0.59016 * f;
	y = (y + f/y);
	y = 0.25*y + f/y;	/* fast calculation of y2 */
	y = 0.5 * (y + f/y);
	y = y + 0.5 * (f/y - y);
	
	if (n&1) {
		y *= 0.70710678118654752440;
		++n;
	}
	return ldexp(y,n/2);
}
log.c
#include "math.h"
#include "errno.h"

double log10(x)
double x;
{
	return log(x)*0.43429448190325182765;
}

#define A0 -0.64124943423745581147e+2
#define A1 +0.16383943563021534222e+2
#define A2 -0.78956112887491257267e+0
#define A(w) ((A2*w A1)*w A0)

#define B0 -0.76949932108494879777e+3
#define B1 +0.31203222091924532844e+3
#define B2 -0.35667977739034646171e+2
#define B(w) (((w B2)*w B1)*w B0)

#define C0 0.70710678118654752440
#define C1 0.693359375
#define C2 -2.121944400546905827679e-4

double log(x)
double x;
{
	double Rz, f, z, w, znum, zden, xn;
	int n;
	extern int errno;
	
	if (x <= 0.0) {
		errno = EDOM;
		return -HUGE;
	}
	f = frexp(x, &n);
	if (f > C0) {
		znum = (f-0.5)-0.5;
		zden = f*0.5 + 0.5;
	} else {
		--n;
		znum = f - 0.5;
		zden = znum*0.5 + 0.5;
	}
	z = znum/zden;
	w = z*z;
/* the lines below are split up to allow expansion of A(w) and B(w) */
	Rz = z + z * (w *
			 A(w)
			/B(w));
	xn = n;
	return (xn*C2 + Rz) + xn*C1;
}
random.c
/*
 * Random number generator -
 * adapted from the FORTRAN version 
 * in "Software Manual for the Elementary Functions"
 * by W.J. Cody, Jr and William Waite.
 */
double ran()
{
	static long int iy = 100001;
	
	iy *= 125;
	iy -= (iy/2796203) * 2796203;
	return (double) iy/ 2796203.0;
}

double randl(x)
double x;
{
	double exp();

	return exp(x*ran());
}
exp.c
#include "math.h"
#include "errno.h"

#define P0 0.249999999999999993e+0
#define P1 0.694360001511792852e-2
#define P2 0.165203300268279130e-4
#define Q0 0.500000000000000000e+0
#define Q1 0.555538666969001188e-1
#define Q2 0.495862884905441294e-3

#define P(z) ((P2*z + P1)*z + P0)
#define Q(z) ((Q2*z + Q1)*z + Q0)

#define EPS	2.710505e-20

double
exp(x)
double x;
{
	int n;
	double xn, g, r, z;
	extern int errno;
	
	if (x > LOGHUGE) {
		errno = ERANGE;
		return HUGE;
	}
	if (x < LOGTINY) {
		errno = ERANGE;
		return 0.0;
	}
	if (fabs(x) < EPS)
		return 1.0;
	z = modf(x * 1.4426950408889634074, &xn);
	if (z >= 0.5)
		++xn;
	n = xn;
	z = modf(x, &x);	/* break x up into fraction and integer part */
	g = ((x - xn*0.693359375) + z) + xn*2.1219444005469058277e-4;
	z = g*g;
	r = P(z)*g;
	r = 0.5 + r/(Q(z)-r);
	return ldexp(r,n+1);
}
floor.c
#include "math.h"

double floor(d)
double d;
{
	if (d < 0.0)
		return -ceil(-d);
	modf(d, &d);
	return d;
}

double ceil(d)
double d;
{
	if (d < 0.0)
		return -floor(-d);
	if (modf(d, &d) > 0.0)
		++d;
	return d;
}
atof.asm
; Copyright (C) 1983 by Manx Software Systems
; :ts=8
	extrn	.dml10, .utod, .dswap, .dad
	extrn	.dlis, .ddv, .dng
	dseg
msign:	ds	1
esign:	ds	1
dpflg:	ds	1
dexp:	ds	2
	cseg
	public	atof_
atof_:
	push	b
	xra	a
	sta	msign		;clear mantissa sign
	sta	esign		;clear exponent sign
	sta	dpflg		;have not seen decimal point yet
	lxi	h,0
	shld	dexp		;clear exponent to zero
	call	.utod		;clear floating point accumulator
;
	lxi	h,4
	dad	sp
	mov	c,m		;get address of string to convert
	inx	h
	mov	b,m
skipbl:
	ldax	b
	cpi	' '
	jz	blank
	cpi	9
	jnz	notblank
blank:
	inx	b
	jmp	skipbl
notblank:
	cpi	'-'
	jnz	notneg		;not minus sign
	sta	msign		;set negative for later
	jmp	skpsign
notneg:
	cpi	'+'		;check for plus sign
	jnz	getnumb
skpsign:
	inx	b		;skip over sign character
getnumb:
	ldax	b
	cpi	'0'
	jc	notdigit
	cpi	'9'+1
	jnc	notdigit
	push	psw
	call	.dml10
	call	.dswap
	pop	psw
	sui	'0'
	mov	l,a
	mvi	h,0
	call	.utod
	call	.dad
	lda	dpflg
	ora	a
	jz	skpsign
	lhld	dexp
	dcx	h
	shld	dexp
	jmp	skpsign
notdigit:
	cpi	'.'
	jnz	nomore
	lxi	h,dpflg
	mvi	m,1		;set dec. pt. seen
	jmp	skpsign
;
nomore:
	lxi	h,0		;clear exponent
	ori	20H		;force to lower case
	cpi	'e'
	jnz	scaleit
	inx	b
	ldax	b
	cpi	'-'
	jnz	exppos
	sta	esign		;set exponent negative
	jmp	nxtchr
exppos:
	cpi	'+'
	jnz	getexp
nxtchr:
	inx	b
getexp:
	ldax	b
	cpi	'0'
	jc	expdone
	cpi	'9'+1
	jnc	expdone
	sui	'0'
	dad	h	; exp *= 2
	mov	d,h
	mov	e,l
	dad	h	;exp *= 4
	dad	h	;exp *= 8
	dad	d	;exp *= 10
	mov	e,a
	mvi	d,0
	dad	d	;exp = exp*10 + char - '0'
	jmp	nxtchr
;
expdone:
	lda	esign		;check sign of exponent
	ora	a
	jz	addexp
	mov	a,h		;negate if sign was minus
	cma
	mov	h,a
	mov	a,l
	cma
	mov	l,a
	inx	h
addexp:
	xchg
	lhld	dexp		;get digit count
	dad	d		;add in exponent value
	shld	dexp		;save for scaling later
;
scaleit:		;scale number to correct value
	lhld	dexp
	mov	a,h
	ora	a
	jp	movup
			;negative exponent
	cpi	0ffH	;test if exponent too large
	jnz	rngerr
	mov	a,l
	cma
	inr	a
	mov	c,a	;save for loop later
	cpi	166
	jnc	rngerr
	cpi	150
	jc	sizeok
	call	.dlis		;divide by 1e16 since smallest will overflow
	db	47H,23H,86H,0f2H,6fH,0c1H,0,0
	call	.ddv
	mov	a,c	;get exponent value back
	sui	16
	mov	c,a
sizeok:
	call	.dswap
	lxi	h,1
	call	.utod
sclp1:
	call	.dml10		;compute number to divide by
	dcr	c
	jnz	sclp1
	call	.dswap		;get everybody back in place
	call	.ddv		;move into range
	jmp	dosign
;
movup:				;positive exponent scale number up
	jnz	rngerr
	mov	a,l		;get loop count
	ora	a
	jz	dosign
	mov	c,a
sclp2:
	call	.dml10
	dcr	c
	jnz	sclp2
;
dosign:
	lda	msign		;check sign of number
	ora	a
	jz	return
	call	.dng		;negate accumulator
return:
	pop	b
	ret
;
rngerr:
	pop	b
	ret
	end
ftoa.asm
; Copyright (C) 1982, 1983 by Manx Software Systems
; :ts=8
	extrn	.dldp, .dlds, .utod, .dlis, .dswap, .dtst
	extrn	.dng, .dlt, .dge, .dad, .ddv, .dml10
	extrn	flprm
	dseg
chrptr:	ds	2
maxdig:	ds	1
ndig:	ds	2
exp:	ds	2
count:	ds	1
fflag:	ds	1
	cseg
rounding:
;	0.5,
	DB 040H,080H,00H,00H,00H,00H,00H,00H
;	0.05,
	DB 040H,0CH,0CCH,0CCH,0CCH,0CCH,0CCH,0CDH
;	0.005,
	DB 040H,01H,047H,0AEH,014H,07AH,0E1H,048H
;	0.0005,
	DB 03FH,020H,0C4H,09BH,0A5H,0E3H,054H,00H
;	0.00005,
	DB 03FH,03H,046H,0DCH,05DH,063H,088H,066H
;	0.000005,
	DB 03EH,053H,0E2H,0D6H,023H,08DH,0A3H,0CDH
;	0.0000005,
	DB 03EH,08H,063H,07BH,0D0H,05AH,0F6H,0C8H
;	0.00000005,
	DB 03DH,0D6H,0BFH,094H,0D5H,0E5H,07AH,066H
;	0.000000005,
	DB 03DH,015H,079H,08EH,0E2H,030H,08CH,03DH
;	0.0000000005,
	DB 03DH,02H,025H,0C1H,07DH,04H,0DAH,0D3H
;	0.00000000005,
	DB 03CH,036H,0F9H,0BFH,0B3H,0AFH,07BH,080H
;	0.000000000005,
	DB 03CH,05H,07FH,05FH,0F8H,05EH,059H,026H
;	0.0000000000005,
	DB 03BH,08CH,0BCH,0CCH,09H,06FH,050H,09AH
;	0.00000000000005,
	DB 03BH,0EH,012H,0E1H,034H,024H,0BBH,043H
;	0.000000000000005,
	DB 03BH,01H,068H,049H,0B8H,06AH,012H,0BAH
;
;
	public ftoa_
ftoa_:
	push	b
	lxi	h,12
	dad	sp
	mov	e,m
	inx	h
	mov	d,m
	xchg
	shld	chrptr		;buffer for converted data
	lxi	h,16
	dad	sp
	mov	a,m
	sta	fflag		;e/f/g format flag
;
	lxi	h,4
	dad	sp
	call	.dldp		;fetch number to convert
	lxi	h,14
	dad	sp
	mov	a,m		;fetch precision
	sta	maxdig
	inr	a
	mov	l,a
	mvi	h,0
	shld	ndig
;
	lhld	flprm
	mov	a,m
	ora	a
	jp	notneg
	call	.dng
	lhld	chrptr
	mvi	m,'-'
	inx	h
	shld	chrptr
notneg:
	lxi	b,0		;clear integer exponent
	call	.dtst
	jz	numbok
	call	.dlis
	db	041H,0aH,0,0,0,0,0,0
adjust:
	lhld	flprm
	inx	h
	mov	a,m
	cpi	1
	jm	toosml
	jz	tentest
	cpi	2
	jnz	bignum
	inx	h
	inx	h
	mov	a,m
	cpi	27H		;number < 10000, just do divides
	jc	quick

bignum:
	call	inverse
	call	.dlis
	db	40H,19H,99H,99H,99H,99H,99H,9aH
bignlp:
	call	.dml10
	inx	b
	call	.dlt
	jnz	bignlp
	call	inverse
	lhld	flprm
	inx	h
	inx	h
	inx	h
	mov	a,m
	cpi	10
	jc	numbok
	dcx	b
	call	.dml10
	jmp	numbok
	
qcklp:
	lhld	flprm
	inx	h
	mov	a,m
	cpi	1
	jnz	quick
tentest:	
	inx	h
	inx	h
	mov	a,m
	cpi	10
	jc	numbok
quick:
	call	.ddv		;divide by ten till 1 <= number < 10
	inx	b		;count for exponent
	jmp	qcklp
	
sml.lp:
	lhld	flprm
	inx	h
	mov	a,m
	cpi	1
	jp	numbok
toosml:
	call	.dml10		;multiply by ten till 1 <= number < 10
	dcx	b		;count for exponent
	jmp	sml.lp
;
numbok:
	lda	fflag		;check conversion format
	ora	a
	jz	eformat
	cpi	1
	jz	fformat
	lda	maxdig		;if %g then precision is # sig. digits
	mov	l,a
	mvi	h,0
	shld	ndig
	mov	a,b		;select %f if maxdig > exp > -4, else use %e
	ora	a
	jm	chkm4
	mov	a,c
	cmp	l
	jnc	eformat
	mvi	a,1		;exp < maxdig, so use %f
	jmp	setformat
;
chkm4:
	mov	a,c
	cpi	-4
	jc	eformat		;exp < -4, so use %e
fformat:
	lhld	ndig
	dad	b
	shld	ndig
	mvi	a,1
	jmp	setformat
eformat:
	xra	a
setformat:
	sta	fflag
;		now round number according to the number of digits
	lhld	ndig
	dcx	h
	mov	a,h
	ora	a
	jp	L1
	lxi	h,0
	jmp	L5
L1:
	jnz	toomany
	mov	a,l
	cpi	14
	jc	L5
toomany:
	lxi	h,14
L5:
	dad	h		;*2
	dad	h		;*4
	dad	h		;*8
	lxi	d,rounding
	dad	d
	call	.dlds
	call	.dad		;add in rounding counstant
;
	call	.dlis
	db	041H,0aH,0,0,0,0,0,0
	call	.dge		;check for rounding overflow
	jz	rndok
	lxi	h,1
	call	.utod		;and repair if necessary
	inx	b
	lda	fflag
	ora	a
	jz	rndok
	lhld	ndig
	inx	h
	shld	ndig
rndok:
	mov	h,b
	mov	l,c
	shld	exp
	lda	fflag
	ora	a
	jz	unpack
	mov	a,b
	ora	a
	mov	a,c		;move for unpack
	jp	unpack
;				F format and negative exponent
;				put out leading zeros
	lhld	chrptr
	mvi	m,'0'
	inx	h
	mvi	m,'.'
	inx	h
	lda	ndig+1
	ora	a
	jm	under
	mov	a,c
	cma
	jmp	L2
under:
	lda	maxdig
L2:
	ora	a
	jz	zdone
zdiglp:
	mvi	m,'0'
	inx	h
	dcr	a
	jnz	zdiglp
zdone:
	shld	chrptr
	mvi	a,0ffH		;mark decpt already output
;
unpack:			;when we get here A has the position for the
			;decimal point
	mov	c,a			;save decimal point position
	lxi	h,ndig+1		;check if ndigits is <= zero
	mov	a,m
	ora	a
	jm	unpdone		;if so just quit now
	dcx	h
	ora	m
	jz	unpdone		;if so just quit now
	lhld	flprm
	lxi	d,10
	dad	d
	mvi	m,0		;zap guard bytes
	inx	h
	mvi	m,0
	mvi	b,0
unplp:
	mov	a,b
	cpi	15
	mvi	a,'0'
	jnc	zerodigit
	lhld	flprm
	inx	h		;skip sign byte
	mov	a,m
	cpi	1
	mvi	a,'0'
	jnz	zerodigit
	inx	h		;skip exponent
	inx	h		;skip overflow
	add	m
	mvi	m,0		;subtract integer portion (virtual)
zerodigit:
	lhld	chrptr
	mov	m,a
	inx	h
	shld	chrptr
	lxi	h,ndig
	dcr	m
	jz	unpdone
	mov	a,b
	cmp	c
	jnz	mul10
	lhld	chrptr
	mvi	m,'.'
	inx	h
	shld	chrptr
mul10:
	call	.dml10		;multiply by 10 and re-normalize
	inr	b
	jmp	unplp
;
unpdone:
	lda	fflag
	ora	a
	jnz	alldone
;
	lhld	chrptr
	mvi	m,'e'
	inx	h
	mvi	m,'+'
	lda	exp+1
	ora	a
	lda	exp
	jp	posexp
	mvi	m,'-'
	cma
	inr	a
posexp:
	inx	h
	cpi	100
	jc	lt100
	mvi	m,'1'
	inx	h
	sui	100
lt100:
	mvi	b,0
tens:
	cpi	10
	jc	lt10
	inr	b
	sui	10
	jmp	tens
lt10:
	adi	'0'		;ascii of last digit
	mov	e,a		;save last digit
	mvi	a,'0'
	add	b		;compute second digit
	mov	m,a
	inx	h
	mov	m,e
	inx	h
	shld	chrptr
;
alldone:
	lhld	chrptr
	mvi	m,0
	pop	b
	ret
;
inverse:
	call	.dswap
	lxi	h,1
	call	.utod
	jmp	.ddv			;implied return
;
	end
frexp.asm
; Copyright (C) 1982, 1983, 1984 by Manx Software Systems
; :ts=8
	extrn	flprm
	extrn	.dldp, .utod
	public	frexp_, ldexp_, modf_
;
frexp_:		;return mantissa and exponent
	push	b
	lxi	h,4
	dad	sp
	call	calcexp		;calculate power of two exponent
	jnz	retexp
	lxi	b,0
retexp:
	lxi	h,12		;address second argument
	dad	sp
	mov	e,m
	inx	h
	mov	d,m
	xchg
	mov	m,c		;return base 2 exponent
	inx	h
	mov	m,b
popret:
	pop	b
	ret
;
ldexp_:		;load new exponent value (actualy add to exponent)
	push	b
	lxi	h,4
	dad	sp
	call	calcexp
	jz	popret		;do nothing if number is zero or unnormalized
	lxi	h,12		;fetch number to add to exponent
	dad	sp
	mov	e,m
	inx	h
	mov	d,m
	xchg
	dad	b		;add exponents
	mov	a,h
	ora	a		;check sign of exponent
	jp	posexp
	cma			;make positive for div and modulo below
	mov	h,a
	mov	a,l
	cma
	mov	l,a
	inx	h
	mov	a,l
	ani	7
	mov	c,a		;save amount to shift
	call	rsexp		;make power of 256
	mov	a,l
	cma
	inr	a		;fix sign back
	mov	l,a
	jmp	ldrs
posexp:
	ora	l		;check if zero
	jz	popret		;no adjustment needed
	mov	c,l		;save to compute left shift
	call	rsexp		;make power of 256
	mov	a,c
	ani	7
	jz	ldrsx
	inr	l		;bump exponent to make right shift
	cma
	adi	9		;compensate for +1 (c = -(x-8))
ldrsx:
	mov	c,a		;save for loop below
ldrs:
	xchg
	lhld	flprm
	inx	h
	mov	m,e		;save exponent
rsloop:
	dcr	c
	jm	popret
	lhld	flprm
	inx	h
	inx	h
	mvi	b,7
	ora	a		;clear carry
rslp:
	inx	h
	mov	a,m
	rar
	mov	m,a
	dcr	b
	jnz	rslp
	jmp	rsloop
;
rsexp:
	ora	a
	mvi	b,3
rselp:
	mov	a,h
	rar
	mov	h,a
	mov	a,l
	rar
	mov	l,a
	dcr	b
	jnz	rselp
	ret
;
calcexp:
	call	.dldp		;load into floating accumulator
	lhld	flprm
	inx	h
	mov	a,m		;get exponent value
	cpi	-64
	rz
	mvi	m,0		;make exponent zero for return
	mov	l,a		;get low byte of exponent
	rlc			;sign extend value
	sbb	a
	mov	h,a		;save high byte of exponent
	dad	h
	dad	h
	dad	h		; exp*8 to make power of two
	mov	b,h		; bc = exponent
	mov	c,l
	lhld	flprm
	inx	h
	inx	h
	inx	h		;hl = first byte of mantissa
	mov	a,m
	ora	a
	rz			;unnormalized number?  give up
lshft:
	mov	a,m
	ani	80H			;test high bit of mantissa
	rnz			;mantissa >= 0.5 ? yes return
			;otherwise, shift number to the left one place
	dcx	b		;and adjust exponent
	lxi	d,7
	dad	d		;address of end of fraction
lsloop:
	dcx	h
	mov	a,m
	ral
	mov	m,a
	dcr	e
	jnz	lsloop
	jmp	lshft
;
modf_:			;split into integral and fraction parts
	push	b
	lxi	h,12		;pick up address to store integral part
	dad	sp
	mov	c,m
	inx	h
	mov	b,m
	mov	l,c
	mov	h,b
	mvi	e,8		;clear out integer
	xra	a
mdclr:
	mov	m,a
	inx	h
	dcr	e
	jnz	mdclr
;
	lxi	h,4
	dad	sp
	call	.dldp
	lhld	flprm
	inx	h
	mov	a,m
	ora	a
	jm	popret
	jz	popret
	adi	64
	ani	7fH
	mov	e,a
	dcx	h
	mov	a,m		;get sign of number
	ani	80H		;isolate
	ora	e		;combine with exponent
	stax	b		;store away
	inx	b
	inx	h
	mov	a,m		;refetch exponent
	inx	h		;skip over exponent
	inx	h		;skip over overflow byte
	cpi	7
	jc	expok		;limit move loop to 7 bytes
	mvi	a,7
expok:
	mov	e,a		;save count for loop
	cma
	adi	8		; 7 - loop count
	mov	d,a		;save # bytes in fraction
intmov:			;copy integer part into given area
	mov	a,m
	stax	b
	inx	h
	inx	b
	dcr	e
	jnz	intmov
;
fnorm:			;note: E is zero at start of this loop
	dcr	d
	jm	zfrac		;fraction is zero
	mov	a,m		;look for non-zero byte
	inx	h
	dcr	e		;count for exponent of fraction
	ora	a
	jz	fnorm
;
	dcx	h		;back up to good byte
	inr	e		;fix exponent
	mov	b,h		;save position in accumulator
	mov	c,l
	lhld	flprm
	inx	h
	mov	m,e		;store exponent
	inx	h		;skip overflow byte
	mvi	e,7		;count of # that must be cleared
frcmov:
	inx	h
	ldax	b
	mov	m,a
	inx	b
	dcr	e
	dcr	d
	jp	frcmov
	xra	a
frcclr:			;clear out rest of register
	inx	h
	mov	m,a
	dcr	e
	jnz	frcclr
	pop	b
	ret
zfrac:				;fraction is zero
	lxi	h,0
	call	.utod
	pop	b
	ret
fsubs.asm
;	Copyright (C) 1982, 1983, 1984 by Manx Software Systems
; :ts=8
	extrn	Sysvec_
	extrn	lnprm
	extrn	puterr_
	dseg
	public	flprm,flsec
flprm:	dw	acc1
flsec:	dw	acc2
	public	flterr_
flterr_: dw	0
retsave:ds	2
YU:	ds	2
VEE:	ds	2
expdiff:ds	1
acc1:	ds	18
acc2:	ds	18
	;work area for divide and multiply routines
lcnt:	ds	1	;iterations left
tmpa:	ds	8	;quotient 
tmpb:	ds	8	;remainder work area
tmpc:	ds	8	;temp for divisor
	cseg
	public	.flds		;load single float into secondary accum
.flds:
	xchg
	lhld	flsec
	jmp	fload
;
	public .fldp		;load single float into primary accum
.fldp:
	xchg
	lhld	flprm
fload:
	push	b
	ldax	d		;get first byte of number
	mov	m,a		;save sign
	inx	h
	ani	7fH		;isolate exponent
	sui	64		;adjust from excess 64 notation
	mov 	m,a		;and save
	inx	h
	mvi	m,0		;extra byte for carry
	mvi	b,3		;copy 3 byte fraction
ldloop:
	inx	h
	inx	d
	ldax	d
	mov	m,a
	dcr	b
	jnz	ldloop

	mvi	b,5		;clear rest to zeros
	xra	a
clloop:
	inx	h
	mov	m,a
	dcr	b
	jnz	clloop
	pop	b
	ret
;
	public .fst		;store single at addr in HL
.fst:
	push	b
	xchg
	lhld	flprm
	mov	a,m		;get sign
	ani	80H		;and isolate
	mov	b,a		;save
	inx	h
	mov	a,m		;get exponent
	adi	64		;put into excess 64 notation
	ani	7fH		;clear sign bit
	ora	b		;merge exponent and sign
	stax	d
	inx	h		;skip overflow byte
	mvi	b,3		;copy 3 bytes of fraction
fstlp:
	inx	d
	inx	h
	mov	a,m
	stax	d
	dcr	b
	jnz	fstlp
	pop	b
	ret
;
	public	.dlis		;load double immediate secondary
.dlis:
	pop	d		;get return addr
	lxi	h,8		;size of double
	dad	d
	push	h		;put back correct return addr
	xchg
			;fall through into .dlds
;
	public	.dlds		;load double float into secondary accum
.dlds:
	xchg
	lhld	flsec
	jmp	dload
;
	public	.dlip		;load double immediate primary
.dlip:
	pop	d		;get return addr
	lxi	h,8		;size of double
	dad	d
	push	h		;put back correct return addr
	xchg
			;fall through into .dldp
;
	public .dldp		;load double float into primary accum
.dldp:
	xchg
	lhld	flprm
dload:
	push	b
	ldax	d		;get first byte of number
	mov	m,a		;save sign
	inx	h
	ani	7fH		;isolate exponent
	sui	64		;adjust from excess 64 notation
	mov 	m,a		;and save
	inx	h
	mvi	m,0		;extra byte for carry
	mvi	b,7		;copy 7 byte fraction
dloop:
	inx	h
	inx	d
	ldax	d
	mov	m,a
	dcr	b
	jnz	dloop

	inx	h
	mvi	m,0		;clear guard byte
	pop	b
	ret
;
	public .dst		;store double at addr in HL
.dst:
	push	b
	push	h		;save address
	call	dornd		;round fraction to 7 bytes
	pop	d		;restore address
	lhld	flprm
	mov	a,m		;get sign
	ani	80H		;and isolate
	mov	b,a		;save
	inx	h
	mov	a,m		;get exponent
	adi	64		;put into excess 64 notation
	ani	7fH		;clear sign bit
	ora	b		;merge exponent and sign
	stax	d
	inx	h		;skip overflow byte
	mvi	b,7		;copy 7 bytes of fraction
dstlp:
	inx	d
	inx	h
	mov	a,m
	stax	d
	dcr	b
	jnz	dstlp
	pop	b
	ret
;
	public .dpsh		;push double float onto the stack
.dpsh:				;from the primary accumulator
	pop	h		;get return address
	shld	retsave		;and save for later
	call	dornd
	lhld	flprm
	lxi	d,9
	dad	d
	mov	d,m		;bytes 6 and 7
	dcx	h
	mov	e,m
	dcx	h
	push	d
	mov	d,m		;bytes 4 and 5
	dcx	h
	mov	e,m
	dcx	h
	push	d
	mov	d,m		;bytes 2 and 3
	dcx	h
	mov	e,m
	dcx	h
	push	d
	mov	d,m		;byte 1
	dcx	h
	dcx	h		;skip over carry byte
	mov	a,m		;get exponent
	adi	64		;and restore to excess 64 notation
	ani	7fH
	mov	e,a
	dcx	h
	mov	a,m
	ani	80H		;isolate sign bit
	ora	e		;combine exponent and sign
	mov	e,a
	push	d
	lhld	retsave
	pchl
;
	public	.dpop		;pop double float into secondary accum
.dpop:
	pop	h		;get return address
	shld	retsave		;and save
	lhld	flsec
	pop	d		;exponent/sign and first fraction
	mov	m,e		;save sign
	inx	h
	mov	a,e
	ani	7fH		;isolate exponent
	sui	64		;adjust for excess 64 notation
	mov	m,a
	inx	h
	mvi	m,0		;extra byte for carry
	inx	h
	mov	m,d
	inx	h
	pop	d		;bytes 2 and 3 of fraction
	mov	m,e
	inx	h
	mov	m,d
	inx	h
	pop	d		;bytes 4 and 5 of fraction
	mov	m,e
	inx	h
	mov	m,d
	inx	h
	pop	d		;bytes 6 and 7 of fraction
	mov	m,e
	inx	h
	mov	m,d
	inx	h
	mvi	m,0		;clear guard byte
	lhld	retsave
	pchl
;
	public	.dswap		;exchange primary and secondary
.dswap:
	lhld	flsec
	xchg
	lhld	flprm
	shld	flsec
	xchg
	shld	flprm
	ret
;
	public	.dng		;negate primary
.dng:
	lhld	flprm
	mov	a,m
	xri	80H		;flip sign
	mov	m,a
	ret
;
	public	.dtst		;test if primary is zero
.dtst:
	lhld	flprm
;	mov	a,m
;	ora	a
;	jnz	true
	inx	h
	mov	a,m
	cpi	-64
	jnz	true
;	inx	h
;	inx	h
;	mov	a,m
;	ora	a
;	jnz	true
	jmp	false
;
	public	.dcmp		;compare primary and secondary
;
			;return 0 if p == s
p.lt.s:			;return < 0 if p < s
	xra	a
	dcr	a
	pop	b
	ret
;
p.gt.s:			;	> 0 if p > s
	xra	a
	inr	a
	pop	b
	ret
;
.dcmp:
	push	b
	lhld	flprm
	xchg
	lhld	flsec
	ldax	d
	ora	a
	jm	dcneg
;			primary is positive
	xra	m		;check if signs the same
	jm	p.gt.s		;differ then p > s
	jmp	docomp
dcneg:
			;primary is negative
	xra	m		;check if signs the same
	jm	p.lt.s		;differ the p < s
	xchg			;both negative reverse sense of test
docomp:
	inx	h
	inx	d
	ldax	d
	cmp	m		;compare exponents
	jm	p.lt.s		;sign test ok since -64 < exp < 64
	jnz	p.gt.s
	mvi	b,9		;test overflow byte + 8 bytes of fraction
cmploop:
	inx	h
	inx	d
	ldax	d
	cmp	m
	jc	p.lt.s
	jnz	p.gt.s
	dcr	b
	jnz	cmploop
			;return 0 if p == s
	xra	a
	pop	b
	ret
;
	public	.dsb		;subtract secondary from primary
.dsb:
	lhld	flsec
	mov	a,m
	xri	80H		;flip sign of secondary
	mov	m,a
			;fall thru into add routine
;
	public .dad		;add secondary to primary
.dad:
			;DE is used as primary address
			;and HL is used as secondary address
	push	b
			;clear extra bytes at end of accumulators
	lhld	flprm
	lxi	d,11		;leave guard byte alone
	dad	d
	mvi	b,7
	xra	a
clp1:
	mov	m,a
	inx	h
	dcr	b
	jnz	clp1

	lhld	flsec
	lxi	d,11		;leave guard byte alone
	dad	d
	mvi	b,7
clp2:
	mov	m,a
	inx	h
	dcr	b
	jnz	clp2

	lhld	flprm
	xchg
	lhld	flsec
	inx	h
	inx	d
	ldax	d		;primary exponent
	sub	m		;compute difference
	jp	ordok
	xchg			;swap so primary is larger
	cma
	inr	a
ordok:
	dcx	d
	dcx	h
	shld	flsec		;fix primary and secondary
	xchg
	shld	flprm
	cpi	9		;check for exp diff too large
	jnc	normalize
	mov	c,a		;save exponent difference
	push	h
	push	d
	adi	9		;adjust for offset
	mov	e,a
	mvi	d,0
	dad	d		;adjust address for exponent difference
	shld	YU
	pop	d
	lxi	h,9
	dad	d
	shld	VEE
	pop	h
	xchg			;get prm in DE and scnd in HL
	ldax	d		;sign of primary
	xra	m		;check if signs same
	jp	doadd

	ldax	d
	ora	a		;test which one is negative
	jm	UfromV		;jump if primary is negative
			;subtract V from U
	mvi	b,7
	lhld	YU
	xchg
	lhld	VEE
sublpa:			;carry is already cleared
	ldax	d
	sbb	m
	stax	d
	dcx	d
	dcx	h
	dcr	b
	jnz	sublpa
brlpa:
	ldax	d
	sbi	0
	stax	d
	dcx	d
	dcr	c
	jp	brlpa
	xchg			;get destination into HL
	jmp	subchk		;check for negative result
;
UfromV:
			;subtract U from V
	mvi	b,7
	lhld	VEE
	xchg
	lhld	YU
sublpb:			;carry is already cleared
	ldax	d
	sbb	m
	mov	m,a
	dcx	d
	dcx	h
	dcr	b
	jnz	sublpb
brlpb:
	mvi	a,0
	sbb	m
	mov	m,a
	dcx	h
	dcr	c
	jp	brlpb
subchk:			;check for negative result
	inx	h
	mov	a,m	;check carry byte
	ora	a	;test sign
	mvi	a,1
	jp	makpos
	lxi	d,15
	dad	d	;point to end of number
neglp:
	mvi	a,0
	sbb	m
	mov	m,a
	dcx	h
	dcr	e
	jp	neglp
	mvi	a,81H		;make number negative
makpos:
	lhld	flprm
	mov	m,a		;set sign of number
	jmp	normalize
;
doadd:
			;add V to U
	mvi	b,7
	lhld	YU
	xchg
	lhld	VEE
addlp:			;carry is already cleared
	ldax	d
	adc	m
	stax	d
	dcx	d
	dcx	h
	dcr	b
	jnz	addlp
crylp:
	ldax	d
	aci	0
	stax	d
	dcx	d
	dcr	c
	jp	crylp
	jmp	normalize
;
	public	.ddv
.ddv:		;double floating divide	(primary = primary/secondary)
	push	b
	lhld	flprm
	xchg
	lhld	flsec
	ldax	d
	xra	m		;compute sign of result
	stax	d		;and store
	inx	h
	inx	d
	ldax	d		;primary exponent
	sub	m		;eu-ev
	mov	c,a		;save exponent
	push	d
	push	h
	mov	a,m
	cpi	-64
	jnz	d.ok
	pop	h
	pop	h		;throw away
	mvi	a,3		;flag divide by zero error
	sta	flterr_
	jmp	setbig		;set to biggest possible number
d.ok:
	inx	d
	inx	h
	mvi	b,8
cmloop:
	inx	d
	inx	h
	ldax	d
	cmp	m
	jnz	differ
	dcr	b
	jnz	cmloop
			;numbers are the same give 1 as the answer
	pop	h	;throw away
	pop	h	;get destination addr
	inr	c	;adjust exponent
	mov	m,c	;save exponent
	inx	h
	mvi	m,0		;clear extra byte
	inx	h
	mvi	m,1		;set result
	mvi	b,8
	xra	a
	sta	flterr_
	jmp	zclr
;
differ:			;check carry to find out smaller number
	pop	d	;restore divisor address
	pop	h	;restore dividend address
	mov	m,c	;store exponent
	jc	uok
	inr	c	;bump exponent
	mov	m,c
	dcx	h	;and shift dividend right (logically)
uok:
	push	d	;save for later
	lxi	d,9
	dad	d		;compute end address
	mvi	b,8
	lxi	d,tmpb		;copy dividend into work area
remsav:
	mov	a,m
	stax	d
	dcx	h
	inx	d
	dcr	b
	jnz	remsav
	pop	h	;restore divisor addr
	lxi	d,9
	dad	d	;move backwards
	mvi	b,8
	lxi	d,tmpc	;copy divisor into work area
divsav:
	mov	a,m
	stax	d
	dcx	h
	inx	d
	dcr	b
	jnz	divsav
	mvi	b,8
	lxi	h,tmpa		;clear quotient buffer
	xra	a
quinit:
	mov	m,a
	inx	h
	dcr	b
	jnz	quinit

	mvi	a,64
	sta	lcnt		;initialize loop counter
divloop:
	lxi	h,tmpa
	mvi	b,16
	ora	a		;clear carry
shlp:
	mov	a,m
	adc	a		;shift one bit to the left
	mov	m,a
	inx	h
	dcr	b
	jnz	shlp
	sbb	a
	ani	1
	mov	c,a

	mvi	b,8
	lxi	d,tmpb
	lxi	h,tmpc
	ora	a		;clear carry
sublp:
	ldax	d
	sbb	m
	stax	d
	inx	d
	inx	h
	dcr	b
	jnz	sublp
	mov	a,c
	sbi	0
	jnz	zerobit
onebit:
	lxi	h,tmpa
	inr	m
	lxi	h,lcnt
	dcr	m
	jnz	divloop
	jmp	divdone
;
zerobit:
	lxi	h,lcnt
	dcr	m
	jz	divdone
	lxi	h,tmpa
	mvi	b,16
	ora	a		;clear carry
zshlp:
	mov	a,m
	adc	a		;shift one bit to the left
	mov	m,a
	inx	h
	dcr	b
	jnz	zshlp

	sbb	a
	mov	c,a
	mvi	b,8
	lxi	d,tmpb
	lxi	h,tmpc
	ora	a		;clear carry
daddlp:
	ldax	d
	adc	m
	stax	d
	inx	d
	inx	h
	dcr	b
	jnz	daddlp
	mov	a,c
	aci	0
	jnz	zerobit
	jmp	onebit
;
divdone:
	lhld	flprm
	lxi	d,12
	dad	d
	mvi	m,0
	dcx	h
	mvi	m,0
	lxi	d,tmpa
	mvi	b,8
qusav:
	dcx	h
	ldax	d
	mov	m,a
	inx	d
	dcr	b
	jnz	qusav
	jmp	normalize
;
	public	.dml
.dml:		;double floating multiply	(primary = primary * secondary)
	push	b
	lhld	flprm
	xchg
	lhld	flsec
	ldax	d
	xra	m		;compute sign of result
	stax	d		;and store
	inx	h
	inx	d
	ldax	d		;primary exponent
	cpi	-64
	jz	zresult
	add	m		;eu+ev
	stax	d		;save exponent
	mov	a,m		;check for mult by zero
	cpi	-64
	jz	zresult

	push	d		;save for later
	lxi	d,9
	dad	d		;compute end address
	mvi	b,8
	lxi	d,tmpc		;copy muliplicand into work area
msav1:
	mov	a,m
	stax	d
	dcx	h
	inx	d
	dcr	b
	jnz	msav1
	pop	h	;restore multiplier addr
	lxi	d,9
	dad	d	;move backwards
	mvi	b,8
	lxi	d,tmpb	;copy multiplier into work area
msav2:
	mov	a,m
	stax	d
	dcx	h
	inx	d
	dcr	b
	jnz	msav2
	mvi	b,8
	lxi	h,tmpa		;clear buffer
	xra	a
clrmul:
	mov	m,a
	inx	h
	dcr	b
	jnz	clrmul

	mvi	a,64
	sta	lcnt		;initialize loop counter
muloop:
	lxi	h,tmpa
	mvi	b,16
	ora	a		;clear carry
mshlp:
	mov	a,m
	adc	a		;shift one bit to the left
	mov	m,a
	inx	h
	dcr	b
	jnz	mshlp
	jnc	mnext

	mvi	b,8
	lxi	d,tmpa
	lxi	h,tmpc
	ora	a		;clear carry
maddlp:
	ldax	d
	adc	m
	stax	d
	inx	d
	inx	h
	dcr	b
	jnz	maddlp
;
	mvi	b,8
madclp:
	ldax	d
	aci	0
	stax	d
	jnc	mnext
	inx	d
	dcr	b
	jnz	madclp
;
mnext:
	lxi	h,lcnt
	dcr	m
	jnz	muloop

	lhld	flprm
	lxi	d,12
	dad	d
	lxi	d,tmpb-2
	mvi	b,10
msav:
	ldax	d
	mov	m,a
	inx	d
	dcx	h
	dcr	b
	jnz	msav
	jmp	normalize
;
;
	public .deq
.deq:
	call	.dcmp
	jz	true
false:
	lxi	h,0
	xra	a
	ret
;
	public .dne
.dne:
	call	.dcmp
	jz	false
true:
	lxi	h,1
	xra	a
	inr	a
	ret
;
	public .dlt
.dlt:
	call	.dcmp
	jm	true
	jmp	false
;
	public .dle
.dle:
	call	.dcmp
	jm	true
	jz	true
	jmp	false
;
	public .dge
.dge:
	call	.dcmp
	jm	false
	jmp	true
;
	public .dgt
.dgt:
	call	.dcmp
	jm	false
	jz	false
	jmp	true
;
	public	.utod
.utod:
	push	b
	mov	a,h
	ora	l
	jz	zresult
	xchg
	mvi	b,0
	jmp	posconv
;
	public	.itod
.itod:
	push	b
	mov	a,h
	ora	l
	jz	zresult
	xchg
	mvi	b,0
	mov	a,d
	ora	a
	jp	posconv
	cma
	mov	d,a
	mov	a,e
	cma
	mov	e,a
	inx	d
	mvi	b,80H
posconv:
	lhld	flprm
	mov	m,b		;store sign
	inx	h
	mov	a,d
	ora	a
	jnz	longcvt
	mvi	m,1		;set up exponent
	inx	h
	mvi	m,0		;clear extra byte
	inx	h
	mov	m,e		;move number into accumulator
	mvi	b,7
	xra	a
	jmp	cnvlp
;
longcvt:
	mvi	m,2		;setup exponent
	inx	h
	mvi	m,0		;clear extra byte
	inx	h
	mov	m,d		;move number into accumulator
	inx	h
	mov	m,e
	mvi	b,6
	xra	a
cnvlp:
	inx	h
	mov	m,a
	dcr	b
	jnz	cnvlp
	jmp	goodexit
;
dornd:		; round the number in the primary accumulator
	lhld	flprm
	lxi	d,10		;offset of guard byte
	dad	d
	mov	a,m
	cpi	128
	rc			; < 128 do nothing
	jnz	rndit
	dcx	h		; == 128 make number odd
	mov	a,m
	ori	1
	mov	m,a
	ret
;
rndit:				; > 128 add one to fraction
	push	b
	lxi	b,0800H		;b = 8, and c = 0
	stc			; make loop add 1
rndlp:
	dcx	h
	mov	a,m
	adc	c
	mov	m,a
	dcr	b
	jnz	rndlp
	ora	a		;check for fraction overflow
	jnz	normalize	;re-normalize number if so.
	pop	b
	ret			;return if none
;
normalize:
	lhld	flprm		;get address of accum
	inx	h
	mov	a,m		;fetch exponent

	mov	d,h		;save address for later
	mov	e,l
	inx	h
	mov	c,a
	xra	a
	cmp	m		;check extra byte
	jnz	movrgt		;non-zero move number right

	mvi	b,8		;search up to 8 bytes
nloop:
	inx	h
	cmp	m
	jnz	movleft
	dcr	c		;adjust exponent
	dcr	b		;count times thru
	jnz	nloop
			;zero answer
zresult:
	xra	a
	sta	flterr_
under0:
	lhld	flprm
	mvi	b,10
	mov	m,a
	inx	h
	mvi	m,-64		;so exponent will be zero after store
zclr:
	inx	h
	mov	m,a
	dcr	b
	jnz	zclr
	pop	b
	ret
;
movleft:
	mvi	a,8
	sub	b
	mov	b,a
	jz	chkexp		;no change in counter, no move needed
	dcx	h		;back up to zero
	mov	a,c
	stax	d		;save new exponent
	push	d		;save for rounding
	inx	d
	mvi	a,15
	sub	b		;compute # of bytes to move
	mov	c,a		;save for loop
lmovlp:
	mov	a,m
	stax	d
	inx	d
	inx	h
	dcr	c
	jnz	lmovlp
	xra	a
lclrlp:
	stax	d		;pad with zeros
	inx	d
	dcr	b
	jnz	lclrlp
	pop	d		;restore accum address
;
chkexp:			;check for over/under flow
	ldax	d		;get exponent
	ora	a
	jm	chkunder
	cpi	64
	jc	goodexit
	jmp	overflow
;
chkunder:
	cpi	-63
	jc	underflow
goodexit:
	mvi	a,0
	sta	flterr_
	pop	b
	ret
;
movrgt:			;fraction overflow
	inr	c		;bump exponent
	mov	a,c
	stax	d		;save in accum
	mvi	b,15
	push	d		;save for check at end
	lxi	h,16
	dad	d		;end address for backwards move
	mov	d,h
	mov	e,l
rmovlp:
	dcx	d
	ldax	d
	mov	m,a
	dcx	h
	dcr	b
	jnz	rmovlp
	mvi	m,0		;zap overflow byte back to zero
	pop	d		;restore exponent addr
	jmp	chkexp
;
underflow:
	mvi	a,1
	sta	flterr_
	call	userrtn		;check for user routine to handle errors
	xra	a
	lhld	flprm
	inx	h			;leave sign alone
	mvi	m,-63		;set to smallest non-zero value
	inx	h
	mov	m,a
	inx	h
	mvi	m,1
	mvi	b,8
	jmp	zclr		;clear rest to zero
;
overflow:
	mvi	a,2
	sta	flterr_
setbig:
	call	userrtn		;check for user routine to handle errors
	lhld	flprm
	inx	h		;leave sign alone
	mvi	m,63		;set exponent at max
	inx	h
	mvi	m,0		;clear overflow byte
	mvi	a,0ffH		;and set fraction to max
	mvi	b,7
oclr:
	inx	h
	mov	m,a
	dcr	b
	jnz	oclr
	inx	h
	mvi	m,0
	pop	b
	ret
;
userrtn:		;handle messages
	lhld	Sysvec_	;any routine supplied?
	mov	a,h
	ora	l
	jz	myway
	xchg
	lxi	h,4
	dad	sp
	mov 	c,m
	inx	h
	mov	b,m
	push	b
	lhld	flterr_
	push	h
	xchg
	call	apchl
	pop	h
	pop	h	;clean up arguments
	ret
apchl:
	pchl
;
myway:
	call	pmsg
	db	'Floating point ',0
	lda	flterr_
	cpi	1
	jnz	notund
	call	pmsg
	db	'underflow',0
	jmp	mycontinue
notund:	cpi	2
	jnz	notovr
	call	pmsg
	db	'overflow',0
	jmp	mycontinue
notovr: call	pmsg
	db	'divide by zero',0
mycontinue:
	call	pmsg
	db	' at location 0x',0
	lxi	h,5
	dad	sp
	mov	a,m
	push	h
	push	psw
	call	phex2
	pop	psw
	call	phex
	pop	h
	dcx	h
	mov	a,m
	push	psw
	call	phex2
	pop	psw
	call	phex
	lxi	h,10		;newline
	push	h
	call	puterr_
	pop	h
	ret
;
phex2:
	rar
	rar
	rar
	rar
phex:
	ani	15
	adi	'0'
	cpi	'9'+1
	jc	hexok
	adi	'A'-'0'-10
hexok:
	mov	l,a
	mvi	h,0
	push	h
	call	puterr_
	pop	h
	ret
;
pmsg:
	pop	b		;get address of message
pmloop:
	ldax	b
	inx	b
	ora	a
	jz	pmsgdone
	mov	l,a
	mvi	h,0
	push	h
	call	puterr_
	pop	h
	jmp	pmloop
pmsgdone:
	push	b
	ret
;
	public	.xtod
.xtod:
	push	b
	lhld	flprm
	mvi	m,0		;clear sign
	inx	h
	mvi	m,3		;set up exponent
	lxi	d,4
	dad	d
	mov	e,l
	mov	d,h
	mvi	b,5
	xra	a
xtodclr:
	inx	h
	mov	m,a
	dcr	b
	jnz	xtodclr
;
	mvi	b,4
	lxi	h,lnprm
	lda	lnprm+3
	ora	a
	jp	lngok
;
lngloop:
	mvi	a,0
	sbb	m
	stax	d
	inx	h
	dcx	d
	dcr	b
	jnz	lngloop
	dcx	d		;back up to sign field
	mvi	a,080H		;mark as negative
	stax	d
	jmp	normalize
;
lngok:
	mov	a,m
	stax	d
	inx	h
	dcx	d
	dcr	b
	jnz	lngok
	jmp	normalize
;
	public	.dtox
.dtox:
	push	b
	lxi	h,0
	shld	lnprm
	shld	lnprm+2
	lxi	d,lnprm
;
	lhld	flprm
	mov	c,m		;get sign
	inx	h
	mov	a,m		;get exponent
	ora	a
	jz	goodexit	; |x| < 1.0 so return zero
	jm	goodexit
;
	cpi	5		;check for too big
	jnc	ltoobig
;
	mov	b,a		;save byte count
	inx	h		;skip overflow byte
	add	l
	mov	l,a
	jnc	lxx
	inr	h
lxx:
	mov	a,m
	stax	d
	inx	d
	dcx	h
	dcr	b
	jnz	lxx
;
	mov	a,c		;now check sign
	ora	a
	jp	goodexit
	mvi	b,4
	lxi	h,lnprm
d2xneg:
	mvi	a,0
	sbb	m
	mov	m,a
	inx	h
	dcr	b
	jnz	d2xneg
	jmp	goodexit
;
ltoobig:
	xchg
	mov	a,c
	ora	a
	jm	bigneg
	mvi	m,07fH
	inx	h
	mvi	m,0ffH
	inx	h
	mvi	m,0ffH
	inx	h
	mvi	m,0ffH
	jmp	oflow
bigneg:
	mvi	m,080H
	inx	h
	mvi	m,0
	inx	h
	mvi	m,0
	inx	h
	mvi	m,0
	jmp	oflow
;
;
	public	.dtou
.dtou:
	push	b
	mvi	c,0		;flag as dtou
	jmp	ifix
;
	public	.dtoi
.dtoi:
	push	b
	mvi	c,1		;flag as dtoi
ifix:
	lhld	flprm
	mov	b,m		;get sign
	inx	h
	mov	a,m		;get exponent
	ora	a
	jz	zeroint
	jp	nonzero
zeroint:
	lxi	h,0		; |x| < 1.0 so return zero
	jmp	goodexit
;
nonzero:
	cpi	3		;check for too big
	jnc	toobig
;
	inx	h		;skip overflow byte
	add	l
	mov	l,a
	jnc	xx
	inr	h
xx:	mov	e,m
	dcx	h
	mov	d,m
	xchg
	mov	a,c
	ora	a
	jz	goodexit
	mov	a,b
	ora	a
	jp	goodexit
	mov	a,h
	cma
	mov	h,a
	mov	a,l
	cma
	mov	l,a
	inx	h
	jmp	goodexit
;
toobig:
	mov	a,c
	ora	a
	jnz	bigsigned
	lxi	h,0ffffH		;return largest unsigned #
	jmp	oflow
;
bigsigned:
	mov	a,b
	ora	a
	jm	negover
	lxi	h,7fffH			;return largest positive #
	jmp	oflow
;
negover:
	lxi	h,8000H			;return largest negative #
oflow:
	mvi	a,2
	sta	flterr_
	pop	b
	ret
;
	public	fabs_
fabs_:
	lhld	flprm
	mvi	m,0		;force to positive sign
	ret
;
	public	.dml10
.dml10:
	push	b
	lhld	flprm
	inx	h
	inr	m			;adjust exponent
	lxi	d,9
	dad	d
	xra	a
	mvi	b,8
ml10lp:
	push	b
	mov	e,m
	xchg
	mvi	h,0
	dad	h		;num*2
	mov	b,h
	mov	c,l		;save
	dad	h		;num*4
	dad	h		;num*8
	dad	b		;num*10
	xchg
	add	e
	inx	h
	mov	m,a
	mov	a,d
	aci	0
	dcx	h
	dcx	h
	pop	b
	dcr	b
	jnz	ml10lp
	inx	h
	mov	m,a		;save last byte of result
	ora	a
	jz	normalize
	dcx	h
	dcx	h		;back up to exponent
	mov	a,m		;check to be sure no overflow
	ora	a
	jm	m10ok
	cpi	64
	jnc	overflow
m10ok:
	pop	b
	ret
	end
