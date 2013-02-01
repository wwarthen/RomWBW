;--------------------------------------------------------------------------
;  cpm0.s - Generic cpm0.s for a Z80 CP/M-80 v2.2 Application
;  Copyright (C) 2011, Douglas Goodall All Rights Reserved.
;--------------------------------------------------------------------------

       	.globl	_main
	.area	_CODE

	.ds	0x0100
init:
	;; Define an adequate stack   
	ld	sp,#stktop

        ;; Initialise global variables
        call    gsinit

	;; Call the C main routine
	call	_main

	ld	c,#0
	call	5

	;; Ordering of segments for the linker.
	.area	_TPA

	.area	_HOME
	.area	_CODE
        .area   _GSINIT
        .area   _GSFINAL
	.area	_DATA

	.area	_STACK
	.ds	256
stktop:

        .area   _GSINIT
gsinit::

        .area   _GSFINAL
        ret
	.db	0xe5

;;;;;;;;;;;;;;;;
; eof - cpm0.s ;
;;;;;;;;;;;;;;;;

