===== Microsoft Basic-80 Compiler v.5.30a =====

The Microsoft BASIC Compiler is a highly efficient programming tool that
converts BASIC programs from BASIC source code into machine code. This
provides much faster BASIC program execution than has previously been
possible. It can make programs run an average of 3 to 10 times faster than
programs run under BASIC-80. Compiled programs can be up to 30 times
faster than interpreted programs if maximum use of integer variables is
made.

View BASCOM.HLP included in the disk image using HELP.COM for documentation.

-----------------------------------------------------------
Example of a session:
-----------------------------------------------------------

>MBASIC 

BASIC-80 Rev. 5.21
[CP/M Version]
Copyright 1977-1981 (C) by Microsoft
Created: 28-Jul-81
31800 Bytes free
Ok
10 PRINT "Hello World"
list
10 PRINT "Hello World"
Ok
RUN
Hello World
Ok
SAVE "HELLO",A
Ok
SYSTEM

A>TYPE BAS.SUB

BASCOM =$1 /E
L80 $1,$1/N/E

A>SUPERSUB BAS HELLO

SuperSUB V1.1

A>BASCOM =HELLO /E

00000 Fatal Error(s)
24196 Bytes Free

A>L80 HELLO,HELLO/N/E

Link-80  3.44  09-Dec-81  Copyright (c) 1981 Microsoft

Data    4000    4197    <  407>

40207 Bytes Free
[4011   4197       65]

A>hello

Hello World


A> 

