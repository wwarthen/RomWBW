;
;-----------------------------------------------------------------------
;   p-System IORESULT values
;-----------------------------------------------------------------------
;
ior_ok		.equ	0		; No error
ior_badblk	.equ	1		; Bad block, CRC error (parity)
ior_baddev	.equ	2		; Bad device number
ior_badio	.equ	3		; Illegal I/O request
ior_timout	.equ	4		; Data-com timeout
ior_offlin	.equ	5		; Volume is no longer on-line
ior_nofile	.equ	6		; File is no longer in directory
ior_filnamerr	.equ	7		; Illegal file name
ior_full	.equ	8		; No room; insufficient space on disk
ior_novol	.equ	9		; No such volume on-line
ior_notfnd	.equ	10		; No such file name in directory
ior_dupfil	.equ	11		; Duplicate file
ior_notclos	.equ	12		; Not closed: attempt to open an open file
ior_notopen	.equ	13		; Not open: attempt to access a closed file
ior_badfmt	.equ	14		; Bad format: error reading real or integer
ior_bufovr	.equ	15		; Ring buffer overflow
ior_diskwp	.equ	16		; Write attempt to protected disk
ior_blknumerr	.equ	17		; Illegal block number
ior_bufadrerr	.equ	18		; Illegal buffer address
ior_badsiz	.equ	19		; Bad text file size
