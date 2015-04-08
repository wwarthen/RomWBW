# makefile for tools
#
#       Uses DJGCC for Windows -- GCC v. 4.4.4 compiles it
#
CC = gcc
COPT = -O2 -Wall
RM = del >nul
CP = copy

E = .exe
O = .o

.c$E:
        $(CC) $(COPT) -o $*$E $*.c

TOOLS = hex2bin$E bin2hex$E
HFILES = mytypes.h


all:    $(TOOLS)

bin2hex$E:      hex2bin$E
        $(CP) hex2bin$E bin2hex$E

clean:
        $(RM) *$O
        $(RM) hex2bin$E
        $(RM) bin2hex$E
        $(RM) foo*.*

spotless:   clean
        $(RM) *.bin
        $(RM) *.hex

##Dependencies
hex2bin$E:      hex2bin.c $(HFILES)
