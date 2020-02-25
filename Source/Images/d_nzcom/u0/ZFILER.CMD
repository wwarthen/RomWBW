	Z System Distribution ZFILER.CMD, 11 Oct 89 by Carson Wilson
0 ! $"Enter ZFILER macro script: "
E ! echo f%>ull file spec:%< $p;echo f%>ile directory:%< $d$u:;echo f%>ile name.....:%< $n;echo f%>ile type.....:%< $t
K ! $d$u:;$!crunch $f $"Destination directory: ";$h:
L ! $!if eq $t lbr;ldir $p;else;echo f%>ile %<$f%> is not a library;fi
T ! $!lt $p
U ! $d$u:;uncr $f;$h:
X ! if ~eq $t com;echo n%>ot a %<com%> file;else;$d$u:;:$n $" Command Tail: ";$h:;fi
Z ! $d$u:;$" Command to perform on file: " $f $" Tail: ";$h:
#
	SAMPLE ZFILER COMMAND MACROS FOR USE WITH NZCOM AND Z3PLUS

macros:		0. on-line macro
		E. Echo data about file name
		K. Krunch the file
		L. display directory of Library
		T. Type the file
		U. Uncrunch the file
		X. eXecute the file
		Z. perform command on file

ZFILER parameters for use with macro '0'

	$!     ZEX 'GO'		$P  DU:FN.FT	$D  DRIVE
	$".."  PROMPT  		$F  FN.FT	$U  USER
	$'..'  PROMPT  		$N  FN		$H  HOME DU
		    		$T  FT
