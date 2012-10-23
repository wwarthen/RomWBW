/* Copyright (C) 1984 by Manx Software Systems */

extern char ctp_[];

#define isalpha(x) (ctp_[(x)+1]&0x03)
#define isupper(x) (ctp_[(x)+1]&0x01)
#define islower(x) (ctp_[(x)+1]&0x02)
#define isdigit(x) (ctp_[(x)+1]&0x04)
#define isxdigit(x) (ctp_[(x)+1]&0x08)
#define isalnum(x) (ctp_[(x)+1]&0x07)
#define isspace(x) (ctp_[(x)+1]&0x10)
#define ispunct(x) (ctp_[(x)+1]&0x40)
#define iscntrl(x) (ctp_[(x)+1]&0x20)
#define isprint(x) (ctp_[(x)+1]&0xc7)
#define isgraph(x) (ctp_[(x)+1]&0x47)
#define isascii(x) (((x)&0x80)==0)

#define toascii(x) ((x)&127)
#define _tolower(x) ((x)|0x20)
#define _toupper(x) ((x)&0x5f)
