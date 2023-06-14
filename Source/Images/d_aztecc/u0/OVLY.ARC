r.c
/* Copyright (C) 1984 by Manx Software Systems */
#include <stdio.h>

main(argc, argv)
char **argv;
{
	register int (*func)();
	int (*prgload())();

	if (argc < 2) {
		fprintf(stderr, "usage: r progname args ...\n");
		exit(4);
	}
	++argv;
	if ((func = prgload(*argv)) == 0) {
		fprintf(stderr, "Cannot load program\n");
		exit(4);
	}
	(*func)(argc-1, argv);
}

#define OVMAGIC	0xf1

struct header {
	int magic;
	unsigned ovaddr;
	unsigned ovsize;
	unsigned ovbss;
	int (*ovbgn)();
};

static int (*prgload(argv0))()
char *argv0;
{
	int fd;
	char *topmem, *ovend, *sbrk();
	unsigned size;
	struct header header;
	char name[20];
	
	strcpy(name, argv0);
	strcat(name, ".ovr");
	if ((fd = open(name, 0)) < 0)
		return 0;
	if (read(fd, &header, sizeof header) < 0)
		return 0;
	/* check magic number on overlay file */
	if (header.magic != OVMAGIC || header.ovsize == 0)
		return 0;

	topmem = sbrk(0);
	ovend = header.ovaddr + header.ovsize + header.ovbss;
	if (topmem < ovend) {
		if (sbrk(ovend - topmem) == (char *)-1)
			return 0;
	}
	if (read(fd, header.ovaddr, header.ovsize) < header.ovsize)
		return 0;
	close(fd);
	return header.ovbgn;
}
crbegin.asm
; Copyright (C) 1983 by Manx Software Systems
; :ts=8
	public	.ovbgn
	extrn	main_
	extrn	_Uorg_, _Uend_
	bss	saveret,2
.ovbgn:
	lxi	h,_Uorg_
	lxi	b,_Uend_-_Uorg_
	mvi	e,0
clrbss:
	mov	m,e
	inx	h
	dcx	b
	mov	a,c
	ora	b
	jnz	clrbss
;
	pop	h
	shld	saveret
	call	main_
	lhld	saveret		;get return addr
	pchl			;return to caller
	end	.ovbgn
rext.asm
	extrn	.begin
	extrn	execv_
	extrn	execl_
	extrn	agetc_
	extrn	aputc_
	extrn	atoi_
	extrn	atol_
	extrn	calloc_
	extrn	Croot_
	extrn	fdopen_
	extrn	fgets_
	extrn	fopen_
	extrn	freopen_
	extrn	format_
	extrn	fprintf_
	extrn	fputs_
	extrn	fread_
	extrn	fscanf_
	extrn	fseek_
	extrn	ftell_
	extrn	fwrite_
	extrn	getchar_
	extrn	gets_
	extrn	getw_
	extrn	ioctl_
	extrn	isatty_
	extrn	lseek_
	extrn	realloc_
	extrn	malloc_
	extrn	free_
	extrn	creat_
	extrn	open_
	extrn	close_
	extrn	posit_
	extrn	printf_
	extrn	fclose_
	extrn	putchar_
	extrn	puterr_
	extrn	puts_
	extrn	putw_
	extrn	qsort_
	extrn	rename_
	extrn	scanfmt_
	extrn	scanf_
	extrn	setbuf_
	extrn	sprintf_
	extrn	sscanf_
	extrn	ungetc_
	extrn	unlink_
	extrn	bios_
	extrn	index_
	extrn	movmem_
	extrn	rindex_
	extrn	sbrk_
	extrn	rsvstk_
	extrn	setjmp_
	extrn	setmem_
	extrn	strcat_
	extrn	strncat_
	extrn	strcmp_
	extrn	strncmp_
	extrn	strcpy_
	extrn	strlen_
	extrn	strncpy_
	extrn	swapmem_
	extrn	toupper_
	extrn	tolower_
	extrn	getusr_
	extrn	setusr_
	extrn	rstusr_
	extrn	.dv,.ud
	extrn	.ml
mrext.asm
	extrn	.begin
	extrn	atof_
	extrn	frexp_, ldexp_, modf_
	extrn	ftoa_
	extrn	asin_
	extrn	acos_
	extrn	arcsine_
	extrn	atan2_
	extrn	atan_
	extrn	exp_
	extrn	floor_
	extrn	ceil_
	extrn	log10_
	extrn	log_
	extrn	pow_
	extrn	ran_
	extrn	randl_
	extrn	cos_
	extrn	sin_
	extrn	sinh_
	extrn	cosh_
	extrn	sqrt_
	extrn	cotan_
	extrn	tan_
	extrn	tanh_

	extrn	execv_
	extrn	execl_
	extrn	agetc_
	extrn	aputc_
	extrn	atoi_
	extrn	atol_
	extrn	calloc_
	extrn	Croot_
	extrn	fdopen_
	extrn	fgets_
	extrn	fopen_
	extrn	freopen_
	extrn	format_
	extrn	fprintf_
	extrn	fputs_
	extrn	fread_
	extrn	fscanf_
	extrn	fseek_
	extrn	ftell_
	extrn	fwrite_
	extrn	getchar_
	extrn	gets_
	extrn	getw_
	extrn	ioctl_
	extrn	isatty_
	extrn	lseek_
	extrn	realloc_
	extrn	malloc_
	extrn	free_
	extrn	creat_
	extrn	open_
	extrn	close_
	extrn	posit_
	extrn	printf_
	extrn	fclose_
	extrn	putchar_
	extrn	puts_
	extrn	putw_
	extrn	qsort_
	extrn	rename_
	extrn	scanfmt_
	extrn	scanf_
	extrn	setbuf_
	extrn	sprintf_
	extrn	sscanf_
	extrn	ungetc_
	extrn	unlink_
	extrn	bios_
	extrn	index_
	extrn	movmem_
	extrn	rindex_
	extrn	sbrk_
	extrn	rsvstk_
	extrn	setjmp_
	extrn	setmem_
	extrn	strcat_
	extrn	strncat_
	extrn	strcmp_
	extrn	strncmp_
	extrn	strcpy_
	extrn	strlen_
	extrn	strncpy_
	extrn	swapmem_
	extrn	toupper_
	extrn	tolower_
	extrn	getusr_
	extrn	setusr_
	extrn	rstusr_
	extrn	.dv,.ud
	extrn	.ml
ovloader.c
/* Copyright (C) 1983, 1984 by Manx Software Systems */

#define OVMAGIC	0xf1

struct header {
	int magic;
	unsigned ovaddr;
	unsigned ovsize;
	unsigned ovbss;
	int (*ovbgn)();
};

static char *ovname;

#asm
	public	ovloader
ovloader:
	lxi	h,2
	dad	sp
	mov	e,m
	inx	h
	mov	d,m
	xchg
	shld	ovname_
;
	call	_ovld_
	pchl
#endasm

static
_ovld()
{
	int fd, flag;
	auto struct header hdr;
	extern char *_mbot;
	auto char filename[64];
	
	flag = 0;
	strcpy(filename, ovname);
	for (;;) {
		strcat(filename, ".ovr");
		if ((fd = open(filename, 0)) >= 0)
			break;
		if (flag++)
			loadabort(10);
		strcpy(filename, "a:");
		strcat(filename, ovname);
	}

	if (read(fd, &hdr, sizeof hdr) != sizeof hdr)
		loadabort(20);

	/* check magic number on overlay file */
	if (hdr.magic != OVMAGIC)
		loadabort(30);

	if (_mbot < hdr.ovaddr+hdr.ovsize+hdr.ovbss)
		loadabort(40);

	if (read(fd, hdr.ovaddr, hdr.ovsize) < hdr.ovsize)
		loadabort(50);
	close(fd);
	return hdr.ovbgn;
}

static
loadabort(code)
{
	char buffer[80];

	sprintf(buffer, "Error %d loading overlay: %s$", code, ovname);
	bdos(9, buffer);
	exit(10);
}
ovbgn.asm
; Copyright (C) 1983, 1984 by Manx Software Systems
; :ts=8
	public	.ovbgn, ovexit_
	extrn	ovmain_
	extrn	_Uorg_, _Uend_
	bss	ovstkpt,2
	bss	saveret,2
	bss	bcsave,2
	bss	ixsave,2
	bss	iysave,2
;
.ovbgn:
	lxi	h,_Uorg_
	lxi	b,_Uend_-_Uorg_
	mvi	e,0
clrbss:
	mov	m,e
	inx	h
	dcx	b
	mov	a,c
	ora	b
	jnz	clrbss
;
	mov	h,b
	mov	l,c
	shld	bcsave
	xra	a
	adi	3
	jpe	savedone
	db	221
	shld	ixsave
	db	253
	shld	iysave
savedone:
	pop	h
	shld	saveret
	pop	d
	lxi	h,0
	dad	sp
	shld	ovstkpt		;save stack pointer for ovexit
	call	ovmain_
	xchg			;save return value
ovret:
	lhld	saveret		;get return addr
	push	h		;place dummy overlay name ptr on stack
	push	h		;place return addr on stack
	xchg			;restore return value to hl
	ret			;return to caller
;
ovexit_:
	lhld	bcsave
	mov	b,h
	mov	c,l
	xra	a
	adi	3
	jpe	restdone
	db	221
	lhld	ixsave
	db	253
	lhld	iysave
restdone:
	lxi	h,2		;get return value
	dad	sp
	mov	e,m
	inx	h
	mov	d,m
	lhld	ovstkpt		;restore original stack pointer
	sphl
	jmp	ovret
	end	.ovbgn
