/* Copyright (C) 1984, 1985 by Manx Software Systems */

#define CLK_TCK 100
typedef long time_t;
typedef long clock_t;

struct tm {
	short tm_sec;
	short tm_min;
	short tm_hour;
	short tm_mday;
	short tm_mon;
	short tm_year;
	short tm_wday;
	short tm_yday;
	short tm_isdst;
	short tm_hsec;
};

struct tm *gmtime(), *localtime();
char *asctime(), *ctime();
time_t time();
