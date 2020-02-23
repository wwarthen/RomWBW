	.org 0x100
beep: .text 	"\"\"\"" ; comment
	.align 4
	.text "foo"
	.align 16
	.text "bar"
	.db	$45,0x67,'7'
	.end
