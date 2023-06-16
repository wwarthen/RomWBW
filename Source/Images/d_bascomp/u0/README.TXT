Microsoft Basic-80 Compiler v.5.30a

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
