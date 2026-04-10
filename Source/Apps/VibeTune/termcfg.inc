;
; Local copy of shared terminal config helper for Tune build.
; Source of truth: Source/Apps/lib/termcfg.inc
;

cfg_defaults:
	xor	a
	ld	(cfg_found),a
	ld	(cfg_term),a
	ld	(cfg_flags),a
	ld	a,CFG_DFL_ROWS
	ld	(cfg_rows),a
	ld	a,CFG_DFL_COLS
	ld	(cfg_cols),a
	ret

cfg_load:
	call	cfg_fcb_init
	ld	c,15
	ld	de,cfg_fcb
	call	bdos
	inc	a
	ret	z
	ld	de,cfg_dma
	ld	c,26
	call	bdos
	ld	c,20
	ld	de,cfg_fcb
	call	bdos
	push	af
	ld	c,16
	ld	de,cfg_fcb
	call	bdos
	pop	af
	ld	de,dma_default
	ld	c,26
	call	bdos
	or	a
	ret	nz
	ld	hl,cfg_dma
	ld	a,(hl)
	cp	'T'
	ret	nz
	inc	hl
	ld	a,(hl)
	cp	'Q'
	ret	nz
	inc	hl
	ld	a,(hl)
	cp	'C'
	ret	nz
	inc	hl
	ld	a,(hl)
	cp	'F'
	ret	nz
	inc	hl
	ld	a,(hl)
	cp	CFGVER
	ret	nz
	inc	hl
	ld	a,(hl)
	cp	3
	jr	c,cfg_load_term_ok
	xor	a
cfg_load_term_ok:
	ld	(cfg_term),a
	inc	hl
	ld	a,(hl)
	and	CFGF_ANSI
	ld	(cfg_flags),a
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,cfg_load_rows_ok
	ld	a,CFG_DFL_ROWS
cfg_load_rows_ok:
	ld	(cfg_rows),a
	inc	hl
	ld	a,(hl)
	or	a
	jr	nz,cfg_load_cols_ok
	ld	a,CFG_DFL_COLS
cfg_load_cols_ok:
	ld	(cfg_cols),a
	ld	a,$FF
	ld	(cfg_found),a
	ret

cfg_save:
	call	cfg_fcb_init
	ld	de,cfg_dma
	xor	a
	ld	(de),a
	ld	hl,cfg_dma
	ld	de,cfg_dma+1
	ld	bc,127
	ldir
	ld	hl,cfg_dma
	ld	(hl),'T'
	inc	hl
	ld	(hl),'Q'
	inc	hl
	ld	(hl),'C'
	inc	hl
	ld	(hl),'F'
	inc	hl
	ld	(hl),CFGVER
	inc	hl
	ld	a,(cfg_term)
	ld	(hl),a
	inc	hl
	ld	a,(cfg_flags)
	ld	(hl),a
	inc	hl
	ld	a,(cfg_rows)
	ld	(hl),a
	inc	hl
	ld	a,(cfg_cols)
	ld	(hl),a

	call	cfg_fcb_init
	ld	c,19
	ld	de,cfg_fcb
	call	bdos

	call	cfg_fcb_init
	ld	c,22
	ld	de,cfg_fcb
	call	bdos
	inc	a
	ret	z

	ld	de,cfg_dma
	ld	c,26
	call	bdos
	ld	c,21
	ld	de,cfg_fcb
	call	bdos
	push	af
	ld	c,16
	ld	de,cfg_fcb
	call	bdos
	pop	af
	ld	de,dma_default
	ld	c,26
	call	bdos
	ld	a,$FF
	ld	(cfg_found),a
	ret

cfg_fcb_init:
	ld	hl,cfg_fcb_tmpl
	ld	de,cfg_fcb
	ld	bc,36
	ldir
	ret

cfg_fcb_tmpl:
	.db	0
	.db	'T','E','R','M',' ',' ',' ',' '
	.db	'C','F','G'
	.fill	24,0
cfg_fcb:
	.fill	36,0

cfg_found:	.db	0
cfg_term:	.db	0
cfg_flags:	.db	0
cfg_rows:	.db	CFG_DFL_ROWS
cfg_cols:	.db	CFG_DFL_COLS
cfg_dma:	.fill	128,0
